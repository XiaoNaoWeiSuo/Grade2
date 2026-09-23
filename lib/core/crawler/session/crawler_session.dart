/// 爬虫会话生命周期管理 + 四步鉴权链路编排
/// （对应 grabber/main.py 的 build_api + 状态机）。
///
/// ## 生命周期
/// ```text
/// 构造 ──▶ loadState() ──▶ ensureApi() ──────────────▶ EamsApi(第④步)
///              │                │                          │
///              │        缓存新鲜(app_at ≤ TTL            SessionLost
///              │        且有 JSESSIONID)?                 │
///              │          ├─ 是 → 直接返回 API             ▼
///              │          └─ 否 → ①CAS ─②门户 ─③应用授权  ensureApi() 重建(缓存必失效)
///              │                     (每步后持久化状态)
/// reset() ◀── 登出/凭据更换 ◀── CredentialError 时禁止重建,须人工干预
/// ```
///
/// ## 防封号约束
/// - 每个 [CrawlerSession] 实例最多 1 次密码登录 POST（[Step1Cas] 内部计数）
/// - [CredentialError] / [NeedCaptchaError] 绝不自动重试
/// - CASTGC(14天) 内全部走 SSO 免密，不消耗登录次数
///
/// ## Riverpod 对接建议
/// ```dart
/// final crawlerProvider = Provider<CrawlerSession>((ref) {
///   final s = CrawlerSession(
///     config: const GrabberConfig(),
///     credentials: CrawlerCredentials(username: '...', password: '...'),
///     stateStore: FileSessionStateStore('${appDocDir}/crawler_state.json'),
///   );
///   ref.onDispose(s.dispose);
///   return s;
/// });
/// ```
library;

import '../crawler_exceptions.dart';
import '../crypto/cas_crypto.dart';
import '../models/config_models.dart';
import '../api/eams_api.dart';
import 'http_client.dart';
import 'state_store.dart';
import 'step1_cas.dart';
import 'step2_portal.dart';
import 'step3_app.dart';

/// 完整爬虫会话：持有 HTTP 客户端、状态存储与四步鉴权器。
class CrawlerSession {
  CrawlerSession({
    required this.config,
    required this.credentials,
    SessionStateStore? stateStore,
    this.onLog,
  })  : http = SessionHttpClient(config: config),
        stateStore = stateStore ?? MemorySessionStateStore(),
        _step1 = null,
        _step2 = null,
        _step3 = null;

  final GrabberConfig config;
  final CrawlerCredentials credentials;
  final SessionHttpClient http;
  final SessionStateStore stateStore;
  final void Function(String message)? onLog;

  Step1Cas? _step1;
  Step2Portal? _step2;
  Step3App? _step3;

  /// 附加状态（device_id / cas_at / portal_at / app_at / display_name）。
  Map<String, Object?> extra = {};

  bool _stateLoaded = false;
  bool _disposed = false;

  /// 当前缓存的 API（生命周期内复用；SessionLost 后应重建）。
  EamsApi? _cachedApi;

  /// 惰性步骤对象（保持密码 POST 计数在会话生命周期内）。
  Step1Cas get step1 =>
      _step1 ??= Step1Cas(
          http: http, config: config, credentials: credentials, onLog: onLog);
  Step2Portal get step2 =>
      _step2 ??= Step2Portal(http: http, config: config, onLog: onLog);
  Step3App get step3 =>
      _step3 ??= Step3App(http: http, config: config, onLog: onLog);

  // ---------------- 生命周期 ----------------

  /// 恢复持久化状态（幂等；构造后首次 ensureApi 自动调用）。
  Future<void> loadState() async {
    if (_stateLoaded) return;
    _stateLoaded = true;
    final data = await stateStore.load();
    if (data == null) return;
    http.loadCookiesFromJson(data);
    final ex = data['extra'];
    if (ex is Map<String, Object?>) extra = ex;
  }

  /// 持久化当前 cookie + extra（原子写）。
  Future<void> saveState() async {
    if (_disposed) return;
    await stateStore.save({
      'saved_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'cookies': http.cookies.toJson(),
      'extra': extra,
    });
  }

  /// 走/复用 ①→③ 链路，返回第④步 API 对象。
  ///
  /// - 缓存复用：`app_at` 在 [GrabberConfig.sessionTtl] 内且存在 JSESSIONID
  ///   → 直接返回，零网络请求
  /// - [forceRelogin] = true 时跳过缓存，强制重走全链路（不清 cookie，
  ///   CASTGC 仍有效时第①步自动 SSO 免密）
  /// - [maxAttempts]：默认 2 次尝试。首次遇到非验证码/二次认证的异常（如密码 POST 偶发拒绝、
  ///   网络闪断、ST 或 verify 延迟）时，会自动清理污染的中间状态并延迟 1 秒重试，
  ///   不让用户在首次偶发失败时直接报错。
  ///
  /// 抛出：[CasError]/[NeedCaptchaError]/[CredentialError]/
  /// [PortalError]/[AppAuthError]/[HttpError]。
  Future<EamsApi> ensureApi({
    bool forceRelogin = false,
    int maxAttempts = 2,
  }) async {
    if (_disposed) throw const HttpError('会话已销毁');
    await loadState();

    if (!forceRelogin && _freshCache()) {
      onLog?.call('缓存会话有效,免登录复用');
      return _cachedApi ??= EamsApi(http: http, config: config);
    }

    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final deviceId = (extra['device_id'] as String?) ?? randomHex(32);
        extra['device_id'] = deviceId;

        // ① CAS
        final cas = await step1.login();
        extra['cas_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await saveState();

        // ② 门户
        final portal = await step2.establish(cas.redirectUrl, deviceId);
        extra['portal_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        extra['display_name'] = portal.displayName;
        extra['portal_username'] = portal.username;
        await saveState();

        // ③ 应用授权
        await step3.enter();
        extra['app_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await saveState();

        return _cachedApi = EamsApi(http: http, config: config);
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;

        // 人工干预型异常（图形验证码、网关风控短信）：直接交给外部流程，不盲目重试
        if (e is NeedCaptchaError || e is NeedSecondaryAuthError) {
          rethrow;
        }

        if (attempt < maxAttempts) {
          onLog?.call('第 $attempt 次登录未成功($e)，清理中间状态并在 1 秒后自动重试...');
          // 清理会话中可能残留的污染 Cookie 与中间步骤状态
          http.cookies.clear();
          extra.remove('app_at');
          extra.remove('portal_at');
          extra.remove('cas_at');
          _step2 = null;
          _step3 = null;
          await Future<void>.delayed(const Duration(milliseconds: 1000));
          continue;
        }
      }
    }

    if (lastError != null) {
      Error.throwWithStackTrace(lastError, lastStackTrace ?? StackTrace.current);
    }
    throw const CasError('登录失败：未知异常');
  }

  /// 会话失效自动重建的闭包封装（推荐 Riverpod 层使用）。
  ///
  /// 执行 [action]；若中途抛 [SessionLost]，自动重建链路后重试一次。
  /// [maxRebuilds] 为重建上限（默认 2，防循环）。
  Future<T> withApi<T>(Future<T> Function(EamsApi api) action,
      {int maxRebuilds = 2}) async {
    var rebuilds = 0;
    while (true) {
      try {
        return await action(await ensureApi());
      } on SessionLost {
        _cachedApi = null;
        extra['app_at'] = 0; // 缓存必失效
        if (rebuilds++ >= maxRebuilds) rethrow;
        onLog?.call('会话失效,自动重建链路(第 $rebuilds 次)');
      }
    }
  }

  // ---------------- 短信二次认证（网关风控） ----------------

  /// 发送短信验证码（增强认证第 1 步）。
  ///
  /// 前置：登录流程已抛出 [NeedSecondaryAuthError]（半建立的会话仍在本实例内）。
  /// 返回掩码手机号与重发间隔，UI 层据此提示用户收码。
  Future<SmsChallenge> startSmsVerification() {
    return step2.sendSmsCode();
  }

  /// 提交短信验证码（增强认证第 2 步）。
  ///
  /// 成功后自动完成第③步应用授权并返回可用的 [EamsApi]；
  /// 验证码错误抛 [PortalError]（不消耗登录 POST 次数，可重试）。
  Future<EamsApi> completeSmsVerification(String code) async {
    final portal = await step2.verifySmsCode(code);
    extra['portal_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    extra['display_name'] = portal.displayName;
    extra['portal_username'] = portal.username;
    await saveState();

    await step3.enter();
    extra['app_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await saveState();
    return _cachedApi = EamsApi(http: http, config: config);
  }

  /// 缓存新鲜判定：app_at 在 TTL 内且存在 JSESSIONID。
  bool _freshCache() {
    final at = extra['app_at'];
    if (at is! int) return false;
    final age = DateTime.now().millisecondsSinceEpoch ~/ 1000 - at;
    return age >= 0 && age < config.sessionTtl && http.hasCookie('JSESSIONID');
  }

  /// 登出/重置：清空 cookie、内存与持久化状态，并关闭底层连接。
  ///
  /// 之后如需继续使用，须重新构造 [CrawlerSession]。
  Future<void> reset() async {
    _cachedApi = null;
    extra = {};
    http.cookies.clear();
    await stateStore.clear();
  }

  /// 释放资源（Riverpod onDispose 调用）。仅关闭连接，不清状态。
  void dispose() {
    _disposed = true;
    http.close();
  }

  /// 便捷判定：当前是否存在指定 cookie（透传 http）。
  bool hasCookie(String name, {String? domainSuffix}) =>
      http.hasCookie(name, domainSuffix: domainSuffix);
}
