/// 认证/账号簿 ViewModel —— 登录、恢复会话、多账号管理。
///
/// 职责（对应内核 [CrawlerSession] 生命周期）：
/// - 启动恢复：读取持久化 cookie → `ensureApi()`（CASTGC SSO 免密），
///   失败区分"凭据被拒 → 登录页"与"纯网络问题但历史会话在 → 离线降级进入"
/// - 登录：新建会话走完整四步鉴权（每会话最多 1 次密码 POST，防封号）
/// - 账号簿（"注册"）：CAS 无在线注册，此处为本机账号登记，支持多账号快速切换
///
/// 安全说明：账号簿密码存于系统安全存储（Keychain / Android Keystore，
/// 见 secureStorageProvider），账号簿仅保存 `{username, remember}` 元数据；
/// 旧版本 base64 明文条目首次恢复时自动迁移到安全存储并清除明文。
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    this.failureCount = 0,
  });

  final AuthStatus status;

  /// 当前爬虫会话（needsLogin 时可能仍持有旧实例，UI 不应使用）。
  final CrawlerSession? session;
  final String? username;
  final String? displayName;

  /// 离线降级：历史会话存在但本次网络校验未通过，仅可用本地缓存数据。
  final bool offline;

  /// 本机账号簿 `[{username, remember, autoLogin, startWithCache}]`（密码存于安全存储）。
  final List<Map<String, Object?>> accounts;

  /// 展示给用户的错误文案。
  final String? error;

  /// 短信验证码已发往的掩码手机号（needsSms 状态下非空）。
  final String? smsMaskedPhone;

  /// 短信重发间隔（秒）。
  final int smsInterval;

  /// 连续登录失败次数（用于驱动登录按钮分色裂变与缓存进入）。
  final int failureCount;

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
    int? failureCount,
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
        failureCount: failureCount ?? this.failureCount,
      );
}

/// 认证控制器。
class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() => _restore();

  // ---------------- 启动恢复 ----------------

  Future<AuthState> _restore() async {
    final cache = await ref.watch(localCacheProvider.future);
    var accounts = _book(await cache.readAs<List<Object?>>(
        _nsAuth, _keyAccounts, const []));
    final last = await cache.readAs<String>(_nsAuth, _keyLast, '');
    var remembered = _entryOf(accounts, last);

    // 旧版 base64 明文迁移：首个记住密码的账号迁入安全存储并清除明文
    final migrated = await _migrateLegacy(accounts);
    if (migrated != null) {
      accounts = migrated;
      remembered = _entryOf(accounts, last);
      await _persistBook(cache, accounts);
    }

    final username = remembered?['username'] as String? ?? last;
    final password = await _loadPwd(username);

    // 1) 检查是否启用了【下次缓存】：启动时直接读取上次登陆的缓存数据渲染，不登录刷新数据
    final startWithCache = remembered?['startWithCache'] == true;
    final hasCache = await _hasCacheInternal(cache, username);
    if (startWithCache && hasCache) {
      return AuthState(
        status: AuthStatus.authed,
        username: username,
        displayName: remembered?['displayName'] as String? ?? username,
        offline: true,
        accounts: accounts,
      );
    }

    // 2) 检查是否关闭了【自动登录】：若显式设为 false 且未开启下次缓存，停在登录页
    final autoLogin = remembered?['autoLogin'] ?? true;
    if (autoLogin == false) {
      return AuthState(
        status: AuthStatus.needsLogin,
        accounts: accounts,
        username: username,
      );
    }

    final statePath = await ref.watch(sessionStatePathProvider.future);
    final session = CrawlerSession(
      config: ref.watch(grabberConfigProvider),
      credentials: CrawlerCredentials(username: username, password: password),
      stateStore: FileSessionStateStore(statePath),
      onLog: (m) => debugPrint('[Crawler] $m'),
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
      // 网络类失败：若历史会话在或本地有缓存，降级为离线模式进入（可用缓存数据）
      if ((hasCookies && session.extra['app_at'] != null) || hasCache) {
        return AuthState(
          status: AuthStatus.authed,
          session: session,
          username: username.isNotEmpty ? username : (remembered?['username'] as String?),
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

  /// 账号密码登录（走完整四步鉴权）。成功后按选项更新账号簿与安全存储。
  Future<void> login(
    String username,
    String password, [
    bool remember = true,
    bool autoLogin = true,
    bool startWithCache = false,
  ]) async {
    final cache = await ref.read(localCacheProvider.future);
    var accounts = _book(await cache.readAs<List<Object?>>(
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
      onLog: (m) => debugPrint('[Crawler] $m'),
    );

    try {
      await session.ensureApi(forceRelogin: true);
      final displayName = session.extra['display_name'] as String?;
      accounts = _upsert(accounts, {
        'username': username,
        'remember': remember,
        'autoLogin': autoLogin,
        'startWithCache': startWithCache,
        'displayName': ?displayName,
      });
      await _persistBook(cache, accounts, last: username);
      if (remember) {
        await _savePwd(username, password);
      } else {
        await _deletePwd(username);
      }

      // 每次登录成功刷新这个缓存（异步预拉取课表并写入按账号隔离的缓存中）
      unawaited(() async {
        try {
          final raw =
              await session.withApi((api) => api.courseTable(kind: 'std'));
          raw.remove('file');
          final semId = raw['semester_id'] as int? ?? 409;
          await cache.write('timetable', 'table_std_$semId', raw);
          await cache.write('timetable', 'table_std_${username}_$semId', raw);
        } catch (_) {}
      }());

      state = AsyncData(AuthState(
        status: AuthStatus.authed,
        session: session,
        username: username,
        displayName: displayName,
        accounts: accounts,
        failureCount: 0,
      ));
    } on CredentialError catch (e) {
      await _disposeSession(session);
      state = AsyncData(cur.copyWith(
        status: AuthStatus.needsLogin,
        accounts: accounts,
        error: e.message,
        failureCount: cur.failureCount + 1,
      ));
    } on NeedCaptchaError catch (e) {
      await _disposeSession(session);
      state = AsyncData(cur.copyWith(
        status: AuthStatus.needsLogin,
        accounts: accounts,
        error: e.message,
        failureCount: cur.failureCount + 1,
      ));
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
          failureCount: cur.failureCount,
        ));
      } on CrawlerException catch (e2) {
        await _disposeSession(session);
        state = AsyncData(cur.copyWith(
          status: AuthStatus.needsLogin,
          accounts: accounts,
          error: e2.message,
          failureCount: cur.failureCount + 1,
        ));
      }
    } on CrawlerException catch (e) {
      await _disposeSession(session);
      state = AsyncData(cur.copyWith(
        status: AuthStatus.needsLogin,
        accounts: accounts,
        error: e.message,
        failureCount: cur.failureCount + 1,
      ));
    }
  }

  /// 用账号簿中已记住的账号直接登录。
  Future<void> loginWithSaved(Map<String, Object?> entry) async {
    final username = entry['username'] as String? ?? '';
    final remember = entry['remember'] != false;
    final autoLogin = entry['autoLogin'] != false;
    final startWithCache = entry['startWithCache'] == true;
    await login(
      username,
      await _loadPwd(username),
      remember,
      autoLogin,
      startWithCache,
    );
  }

  /// 检测特定账号是否存在有效本地缓存（课表等数据）。
  Future<bool> hasCacheFor(String username) async {
    if (username.isEmpty) return false;
    final cache = await ref.read(localCacheProvider.future);
    return _hasCacheInternal(cache, username);
  }

  static Future<bool> _hasCacheInternal(
      LocalCache cache, String username) async {
    if (username.isEmpty) return false;
    final keys = await cache.keys('timetable');
    final prefix = 'table_std_${username}_';
    if (keys.any((k) => k.startsWith(prefix))) return true;
    final last = await cache.readAs<String>(_nsAuth, _keyLast, '');
    if (last == username && keys.any((k) => k.startsWith('table_std_'))) {
      return true;
    }
    return false;
  }

  /// 直接从本地缓存进入（离线秒开，用于免登录或连续登录失败时降级）。
  Future<void> enterFromCache(String username) async {
    final cache = await ref.read(localCacheProvider.future);
    final accounts = _book(await cache.readAs<List<Object?>>(
        _nsAuth, _keyAccounts, const []));
    final entry = _entryOf(accounts, username);
    final cur = state.value ?? const AuthState();
    state = AsyncData(cur.copyWith(
      status: AuthStatus.authed,
      username: username,
      displayName: entry?['displayName'] as String? ?? username,
      offline: true,
      clearError: true,
      failureCount: 0,
    ));
  }

  /// 取消短信验证，返回常规登录。
  Future<void> cancelSms() async {
    final cur = state.value ?? const AuthState();
    await _disposeSession();
    state = AsyncData(cur.copyWith(
      status: AuthStatus.needsLogin,
      clearSession: true,
      clearError: true,
    ));
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
        failureCount: 0,
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
      'remember': remember,
    });
    await _persistBook(cache, newAccounts);
    if (remember) {
      await _savePwd(username, password);
    }
    state = AsyncData(
        (state.value ?? const AuthState()).copyWith(accounts: newAccounts));
    return null;
  }

  /// 删除账号簿条目（同时清除该账号安全存储的密码）。
  Future<void> removeAccount(String username) async {
    final cache = await ref.read(localCacheProvider.future);
    final accounts = _book(await cache.readAs<List<Object?>>(
        _nsAuth, _keyAccounts, const []));
    accounts.removeWhere((a) => a['username'] == username);
    await _persistBook(cache, accounts);
    await _deletePwd(username);
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
      for (final a in accounts) {
        await _deletePwd(a['username'] as String? ?? '');
      }
      accounts = [
        for (final a in accounts) {...a, 'remember': false}
      ];
      await _persistBook(cache, accounts);
    }
    state = AsyncData(AuthState(status: AuthStatus.needsLogin, accounts: accounts));
  }

  // ---------------- 内部 ----------------

  static const _nsAuth = 'auth';
  static const _keyAccounts = 'accounts';
  static const _keyLast = 'last';
  static const _pwdPrefix = 'grade_pwd_';

  String _pwdKey(String username) => '$_pwdPrefix$username';

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

  /// 旧版 base64 明文 → 安全存储迁移。返回清理后的账号簿；无需迁移返回 null。
  Future<List<Map<String, Object?>>?> _migrateLegacy(
      List<Map<String, Object?>> accounts) async {
    var changed = false;
    final out = <Map<String, Object?>>[];
    for (final a in accounts) {
      final username = a['username'] as String? ?? '';
      final b64 = a['password_b64'] as String? ?? '';
      final remember = a['remember'] == true;
      if (b64.isNotEmpty) {
        if (remember) {
          await _savePwd(username, _decodePwd(b64));
        }
        changed = true;
        out.add({'username': username, 'remember': remember});
      } else {
        out.add(a);
      }
    }
    return changed ? out : null;
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

  // ---- 安全存储读写（宽容处理：读失败视为空，写失败不崩状态机） ----

  FlutterSecureStorage _storage() => ref.read(secureStorageProvider);

  Future<String> _loadPwd(String username) async {
    if (username.isEmpty) return '';
    try {
      return await _storage().read(key: _pwdKey(username)) ?? '';
    } on Exception {
      return '';
    }
  }

  Future<void> _savePwd(String username, String password) async {
    if (username.isEmpty || password.isEmpty) return;
    try {
      await _storage().write(key: _pwdKey(username), value: password);
    } on Exception {
      // 安全存储不可用（如平台通道缺失）时静默降级，不阻塞登录
    }
  }

  Future<void> _deletePwd(String username) async {
    if (username.isEmpty) return;
    try {
      await _storage().delete(key: _pwdKey(username));
    } on Exception {
      // 尽力而为
    }
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
