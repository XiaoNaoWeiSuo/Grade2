/// 认证/账号簿 ViewModel —— 登录、恢复会话、多账号管理。
///
/// 职责（对应内核 [CrawlerSession] 生命周期）：
/// - 启动恢复：读取持久化 cookie → `ensureApi()`（CASTGC SSO 免密），
///   失败区分"凭据被拒 → 登录页"与"纯网络问题但历史会话在 → 离线降级进入"
/// - 登录：新建会话走完整四步鉴权（每会话最多 1 次密码 POST，防封号）
/// - 账号簿（"注册"）：CAS 无在线注册，此处为本机账号登记，支持多账号快速切换
///
/// 安全说明：记住密码以 base64 存于应用文档目录（工程期实现）；
/// 正式版建议替换为 flutter_secure_storage / Keychain-Keystore。
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crawler/crawler_exceptions.dart';
import '../core/crawler/models/config_models.dart';
import '../core/crawler/session/crawler_session.dart';
import '../core/crawler/session/state_store.dart';
import '../core/storage/local_cache.dart';
import 'providers.dart';

/// 认证状态机。
enum AuthStatus {
  /// 启动恢复中（显示 splash）。
  boot,

  /// 需要登录（显示登录页）。
  needsLogin,

  /// 登录中/恢复中（禁用表单）。
  busy,

  /// 网关风控：等待用户输入短信验证码。
  needsSms,

  /// 已建立爬虫会话（可进主页）。
  authed,
}

/// 认证状态（不可变）。
class AuthState {
  const AuthState({
    this.status = AuthStatus.boot,
    this.session,
    this.username,
    this.displayName,
    this.offline = false,
    this.accounts = const [],
    this.error,
    this.smsMaskedPhone,
    this.smsInterval = 60,
  });

  final AuthStatus status;

  /// 当前爬虫会话（needsLogin 时可能仍持有旧实例，UI 不应使用）。
  final CrawlerSession? session;
  final String? username;
  final String? displayName;

  /// 离线降级：历史会话存在但本次网络校验未通过，仅可用本地缓存数据。
  final bool offline;

  /// 本机账号簿 `[{username, password_b64, remember}]`。
  final List<Map<String, Object?>> accounts;

  /// 展示给用户的错误文案。
  final String? error;

  /// 短信验证码已发往的掩码手机号（needsSms 状态下非空）。
  final String? smsMaskedPhone;

  /// 短信重发间隔（秒）。
  final int smsInterval;

  AuthState copyWith({
    AuthStatus? status,
    CrawlerSession? session,
    bool clearSession = false,
    String? username,
    String? displayName,
    bool? offline,
    List<Map<String, Object?>>? accounts,
    String? error,
    bool clearError = false,
    String? smsMaskedPhone,
    int? smsInterval,
  }) =>
      AuthState(
        status: status ?? this.status,
        session: clearSession ? null : (session ?? this.session),
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        offline: offline ?? this.offline,
        accounts: accounts ?? this.accounts,
        error: clearError ? null : (error ?? this.error),
        smsMaskedPhone: smsMaskedPhone ?? this.smsMaskedPhone,
        smsInterval: smsInterval ?? this.smsInterval,
      );
}

/// 认证控制器。
class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() => _restore();

  // ---------------- 启动恢复 ----------------

  Future<AuthState> _restore() async {
    final cache = await ref.watch(localCacheProvider.future);
    final accounts = _book(await cache.readAs<List<Object?>>(
        _nsAuth, _keyAccounts, const []));
    final last = await cache.readAs<String>(_nsAuth, _keyLast, '');
    final remembered = _entryOf(accounts, last);

    final statePath = await ref.watch(sessionStatePathProvider.future);
    final session = CrawlerSession(
      config: ref.watch(grabberConfigProvider),
      credentials: CrawlerCredentials(
        username: remembered?['username'] as String? ?? '',
        password: _decodePwd(remembered?['password_b64'] as String?),
      ),
      stateStore: FileSessionStateStore(statePath),
      onLog: (m) {}, // 工程期静默；调试时可接 debugPrint
    );

    // ⚠ 必须先载入持久化 cookie 再判定（loadState 幂等，ensureApi 内的再次
    // 调用会跳过）；否则"未记住密码但会话仍存活"的场景会被误判进登录页，
    // 丢掉 CASTGC SSO 免密恢复机会
    await session.loadState();
    final hasCookies = session.hasCookie('JSESSIONID');
    if (remembered == null && !hasCookies) {
      return AuthState(status: AuthStatus.needsLogin, accounts: accounts);
    }

    try {
      await session.ensureApi();
      return AuthState(
        status: AuthStatus.authed,
        session: session,
        username: remembered?['username'] as String? ??
            session.extra['portal_username'] as String?,
        displayName: session.extra['display_name'] as String?,
        accounts: accounts,
      );
    } on CredentialError catch (e) {
      return AuthState(
          status: AuthStatus.needsLogin,
          accounts: accounts,
          error: e.message);
    } on NeedCaptchaError catch (e) {
      return AuthState(
          status: AuthStatus.needsLogin,
          accounts: accounts,
          error: e.message);
    } on NeedSecondaryAuthError catch (e) {
      // 网关风控二次认证（短信等）：绝不自动重试，交由用户处理
      return AuthState(
          status: AuthStatus.needsLogin,
          accounts: accounts,
          error: e.message);
    } on CrawlerException catch (e) {
      // 网络类失败：若历史会话在，降级为离线模式进入（可用缓存数据）
      if (hasCookies && session.extra['app_at'] != null) {
        return AuthState(
          status: AuthStatus.authed,
          session: session,
          username: remembered?['username'] as String?,
          offline: true,
          accounts: accounts,
          error: '网络异常(${e.message})，已进入离线模式（仅本地缓存数据）',
        );
      }
      return AuthState(
          status: AuthStatus.needsLogin,
          accounts: accounts,
          error: e.message);
    }
  }

  // ---------------- 登录 ----------------

  /// 账号密码登录（走完整四步鉴权）。成功后按 [remember] 更新账号簿。
  Future<void> login(String username, String password, bool remember) async {
    final cache = await ref.read(localCacheProvider.future);
    final accounts = _book(await cache.readAs<List<Object?>>(
        _nsAuth, _keyAccounts, const []));

    final cur = state.value ?? const AuthState();
    state = AsyncData(cur.copyWith(
        status: AuthStatus.busy, clearError: true, username: username));

    // 每次登录用全新会话（旧的若存在先释放）
    await _disposeSession();
    final statePath = await ref.read(sessionStatePathProvider.future);
    final session = CrawlerSession(
      config: ref.read(grabberConfigProvider),
      credentials: CrawlerCredentials(username: username, password: password),
      stateStore: FileSessionStateStore(statePath),
    );

    try {
      await session.ensureApi(forceRelogin: true);
      final newAccounts = _upsert(accounts, {
        'username': username,
        'password_b64': remember ? base64Encode(utf8.encode(password)) : '',
        'remember': remember,
      });
      await _persistBook(cache, newAccounts, last: username);
      state = AsyncData(AuthState(
        status: AuthStatus.authed,
        session: session,
        username: username,
        displayName: session.extra['display_name'] as String?,
        accounts: newAccounts,
      ));
    } on CredentialError catch (e) {
      await _disposeSession(session);
      state = AsyncData(const AuthState(status: AuthStatus.needsLogin)
          .copyWith(accounts: accounts, error: e.message));
    } on NeedCaptchaError catch (e) {
      await _disposeSession(session);
      state = AsyncData(const AuthState(status: AuthStatus.needsLogin)
          .copyWith(accounts: accounts, error: e.message));
    } on NeedSecondaryAuthError catch (e) {
      // 网关风控：同一会话直接发送短信验证码，进入 needsSms 等待用户输码
      try {
        final c = await session.startSmsVerification();
        state = AsyncData(AuthState(
          status: AuthStatus.needsSms,
          session: session,
          username: username,
          accounts: accounts,
          smsMaskedPhone: c.maskedPhone,
          smsInterval: c.intervalSeconds,
          error: e.message,
        ));
      } on CrawlerException catch (e2) {
        await _disposeSession(session);
        state = AsyncData(const AuthState(status: AuthStatus.needsLogin)
            .copyWith(accounts: accounts, error: e2.message));
      }
    } on CrawlerException catch (e) {
      await _disposeSession(session);
      state = AsyncData(const AuthState(status: AuthStatus.needsLogin)
          .copyWith(accounts: accounts, error: e.message));
    }
  }

  /// 用账号簿中已记住的账号直接登录。
  Future<void> loginWithSaved(Map<String, Object?> entry) async {
    await login(
      entry['username'] as String? ?? '',
      _decodePwd(entry['password_b64'] as String?),
      entry['remember'] == true,
    );
  }

  // ---------------- 短信二次认证 ----------------

  /// 重新发送短信验证码（服务端强制 60s 间隔，UI 层负责倒计时）。
  Future<String?> resendSms() async {
    final session = state.value?.session;
    if (session == null) return '会话不存在，请重新登录';
    try {
      final c = await session.startSmsVerification();
      state = AsyncData((state.value ?? const AuthState()).copyWith(
        smsMaskedPhone: c.maskedPhone,
        smsInterval: c.intervalSeconds,
        clearError: true,
      ));
      return null;
    } on CrawlerException catch (e) {
      return e.message;
    }
  }

  /// 提交短信验证码。成功 → authed；失败返回错误文案。
  Future<String?> submitSmsCode(String code) async {
    final cur = state.value;
    final session = cur?.session;
    if (session == null) return '会话不存在，请重新登录';
    if (code.trim().length < 4) return '请输入验证码';
    state = AsyncData(cur!.copyWith(status: AuthStatus.busy, clearError: true));
    try {
      await session.completeSmsVerification(code.trim());
      state = AsyncData((state.value ?? cur).copyWith(
        status: AuthStatus.authed,
        displayName: session.extra['display_name'] as String?,
        offline: false,
        clearError: true,
      ));
      return null;
    } on PortalError catch (e) {
      // 验证码错误等：回到 needsSms 让用户重试（不销毁会话）
      state = AsyncData((state.value ?? cur).copyWith(
        status: AuthStatus.needsSms,
        error: e.message,
      ));
      return e.message;
    } on CrawlerException catch (e) {
      await _disposeSession(session);
      state = AsyncData(const AuthState(status: AuthStatus.needsLogin)
          .copyWith(accounts: cur.accounts, error: e.message));
      return e.message;
    }
  }

  // ---------------- 账号簿（"注册"） ----------------

  /// 登记账号到本机账号簿（CAS 无在线注册，此即工程版的"注册"）。
  Future<String?> saveAccount(
      String username, String password, bool remember) async {
    final cache = await ref.read(localCacheProvider.future);
    final accounts = _book(await cache.readAs<List<Object?>>(
        _nsAuth, _keyAccounts, const []));
    if (accounts.any((a) => a['username'] == username)) {
      return '该账号已在账号簿中';
    }
    final newAccounts = _upsert(accounts, {
      'username': username,
      'password_b64': remember ? base64Encode(utf8.encode(password)) : '',
      'remember': remember,
    });
    await _persistBook(cache, newAccounts);
    state = AsyncData(
        (state.value ?? const AuthState()).copyWith(accounts: newAccounts));
    return null;
  }

  /// 删除账号簿条目。
  Future<void> removeAccount(String username) async {
    final cache = await ref.read(localCacheProvider.future);
    final accounts = _book(await cache.readAs<List<Object?>>(
        _nsAuth, _keyAccounts, const []));
    accounts.removeWhere((a) => a['username'] == username);
    await _persistBook(cache, accounts);
    state = AsyncData(
        (state.value ?? const AuthState()).copyWith(accounts: accounts));
  }

  // ---------------- 登出 ----------------

  /// 登出：清空会话状态（保留账号簿以便快速重登）。
  Future<void> logout({bool forgetCredentials = false}) async {
    final cache = await ref.read(localCacheProvider.future);
    await _disposeSession();
    final statePath = await ref.read(sessionStatePathProvider.future);
    await FileSessionStateStore(statePath).clear();
    await cache.remove(_nsAuth, _keyLast);
    var accounts = state.value?.accounts ?? const <Map<String, Object?>>[];
    if (forgetCredentials) {
      accounts = [
        for (final a in accounts) {...a, 'password_b64': '', 'remember': false}
      ];
      await _persistBook(cache, accounts);
    }
    state = AsyncData(AuthState(status: AuthStatus.needsLogin, accounts: accounts));
  }

  // ---------------- 内部 ----------------

  static const _nsAuth = 'auth';
  static const _keyAccounts = 'accounts';
  static const _keyLast = 'last';

  Future<void> _disposeSession([CrawlerSession? target]) async {
    final s = target ?? state.value?.session;
    if (s != null) {
      try {
        await s.reset();
      } on CrawlerException {
        // 尽力而为
      }
      s.dispose();
    }
  }

  static List<Map<String, Object?>> _book(List<Object?> raw) => [
        for (final e in raw) if (e is Map<String, Object?>) e
      ];

  static Map<String, Object?>? _entryOf(
      List<Map<String, Object?>> accounts, String username) {
    for (final a in accounts) {
      if (a['username'] == username && a['remember'] == true) return a;
    }
    return null;
  }

  static List<Map<String, Object?>> _upsert(
      List<Map<String, Object?>> accounts, Map<String, Object?> entry) {
    final out = List<Map<String, Object?>>.of(accounts);
    out.removeWhere((a) => a['username'] == entry['username']);
    out.add(entry);
    return out;
  }

  static Future<void> _persistBook(LocalCache cache,
      List<Map<String, Object?>> accounts, {String? last}) async {
    await cache.write(_nsAuth, _keyAccounts, accounts);
    if (last != null) await cache.write(_nsAuth, _keyLast, last);
  }

  static String _decodePwd(String? b64) {
    if (b64 == null || b64.isEmpty) return '';
    try {
      return utf8.decode(base64Decode(b64));
    } on FormatException {
      return '';
    }
  }
}

/// 认证状态 Provider（全局保活）。
final authProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
