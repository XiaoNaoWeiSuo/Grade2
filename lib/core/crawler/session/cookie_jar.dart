/// Cookie 作用域管理（对应 Python requests 的 Session.cookies + 持久化）。
///
/// 能力：
/// - RFC 6265 域/路径匹配（域后缀、路径前缀）
/// - 从 Set-Cookie 响应头摄取（借用 dart:io Cookie 解析器，异常回退手工解析）
/// - 过期清理（Expires / Max-Age=0 即删除）
/// - JSON 序列化（连同作用域：域/路径/有效期），供 [SessionStateStore] 持久化
///
/// 管理的敏感令牌：CASTGC(14天 SSO) / sid / sid.sig / sdp_user_token /
/// JSESSIONID / GSESSIONID / semester.id 等，勿外传。
library;

import 'dart:io' show Cookie;

/// 单条 Cookie（含作用域）。
class StoredCookie {
  StoredCookie({
    required this.name,
    required this.value,
    required this.domain,
    this.path = '/',
    this.secure = false,
    this.expires, // epoch 秒；null = 会话期
  });

  final String name;
  final String value;

  /// 作用域域名（已去前导点；请求 host 与之精确相等或以其为后缀时发送）。
  final String domain;
  final String path;
  final bool secure;
  final int? expires;

  bool isExpired([int? now]) =>
      expires != null && (now ?? DateTime.now().millisecondsSinceEpoch ~/ 1000) >= expires!;

  Map<String, Object?> toJson() => {
        'name': name,
        'value': value,
        'domain': domain,
        'path': path,
        'secure': secure,
        'expires': expires,
      };

  static StoredCookie fromJson(Map<String, Object?> j) => StoredCookie(
        name: j['name'] as String? ?? '',
        value: j['value'] as String? ?? '',
        domain: j['domain'] as String? ?? '',
        path: j['path'] as String? ?? '/',
        secure: j['secure'] as bool? ?? false,
        expires: j['expires'] as int?,
      );
}

/// 线程模型：单 isolate 事件循环内串行使用（与爬虫会话生命周期一致）。
class CookieJar {
  final List<StoredCookie> _cookies = [];

  /// 从响应的 Set-Cookie 头列表摄取（[requestHost] 用于无 Domain 属性时定位）。
  void ingest(String requestHost, List<String> setCookieHeaders) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (final raw in setCookieHeaders) {
      final c = _parseSetCookie(raw);
      if (c == null) continue;
      var domain = c.domain?.trim() ?? '';
      if (domain.isEmpty) {
        domain = requestHost; // host-only cookie
      } else {
        domain = domain.startsWith('.') ? domain.substring(1) : domain;
      }
      final int? expires = c.maxAge != null
          ? now + c.maxAge!
          : (c.expires != null ? c.expires!.millisecondsSinceEpoch ~/ 1000 : null);
      // Max-Age=0 / 已过 Expires → 删除同名同域 cookie
      _remove(c.name, domain);
      if (expires != null && expires <= now) continue;
      _cookies.add(StoredCookie(
        name: c.name,
        value: c.value,
        domain: domain,
        path: c.path?.isNotEmpty == true ? c.path! : '/',
        secure: c.secure,
        expires: expires,
      ));
    }
    _purge(now);
  }

  /// 手工设置一条 cookie（如门户 online 标记、教务 semester.id）。
  void set(String name, String value,
      {required String domain, String path = '/'}) {
    _remove(name, domain);
    _cookies.add(
        StoredCookie(name: name, value: value, domain: domain, path: path));
  }

  /// 计算 Cookie 请求头值（"a=1; b=2"），无匹配返回 null。
  String? headerFor(Uri uri) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final parts = <String>[];
    for (final c in _cookies) {
      if (c.isExpired(now)) continue;
      if (!_domainMatch(uri.host, c.domain)) continue;
      if (!_pathMatch(uri.path.isEmpty ? '/' : uri.path, c.path)) continue;
      if (c.secure && uri.scheme != 'https') continue;
      parts.add('${c.name}=${c.value}');
    }
    return parts.isEmpty ? null : parts.join('; ');
  }

  /// 是否存在指定名称（可限域后缀）的 cookie。
  bool has(String name, {String? domainSuffix}) => _cookies.any((c) =>
      c.name == name &&
      !c.isExpired() &&
      (domainSuffix == null || c.domain.endsWith(domainSuffix)));

  /// 读取指定名称 cookie 的值（可限域后缀）。
  String? value(String name, {String? domainSuffix}) {
    for (final c in _cookies) {
      if (c.name == name &&
          !c.isExpired() &&
          (domainSuffix == null || c.domain.endsWith(domainSuffix))) {
        return c.value;
      }
    }
    return null;
  }

  /// 删除指定名称+域的 cookie；[domain] 为空则删全部同名。
  void delete(String name, {String? domain}) => _cookies.removeWhere(
      (c) => c.name == name && (domain == null || c.domain == domain));

  void clear() => _cookies.clear();

  /// 当前有效 cookie 数量（调试用）。
  int get length => _cookies.where((c) => !c.isExpired()).length;

  List<Map<String, Object?>> toJson() =>
      _cookies.where((c) => !c.isExpired()).map((c) => c.toJson()).toList();

  void loadJson(List<Object?> json) {
    clear();
    for (final e in json) {
      if (e is Map<String, Object?>) _cookies.add(StoredCookie.fromJson(e));
    }
  }

  // ---- 内部 ----

  void _remove(String name, String domain) => _cookies.removeWhere(
      (c) => c.name == name && c.domain == domain);

  void _purge(int now) => _cookies.removeWhere((c) => c.isExpired(now));

  /// RFC 6265 §5.1.3 域匹配。
  static bool _domainMatch(String host, String cookieDomain) =>
      host == cookieDomain || host.endsWith('.$cookieDomain');

  /// RFC 6265 §5.1.4 路径匹配。
  static bool _pathMatch(String requestPath, String cookiePath) {
    if (requestPath == cookiePath) return true;
    if (requestPath.startsWith(cookiePath)) {
      return cookiePath.endsWith('/') ||
          requestPath[cookiePath.length] == '/';
    }
    return false;
  }

  /// 借用 dart:io 的 Set-Cookie 解析器；格式异常时回退手工解析。
  static Cookie? _parseSetCookie(String raw) {
    try {
      return Cookie.fromSetCookieValue(raw);
    } catch (_) {
      final idx = raw.indexOf('=');
      if (idx <= 0) return null;
      final name = raw.substring(0, idx).trim();
      var value = raw.substring(idx + 1);
      final semi = value.indexOf(';');
      if (semi >= 0) value = value.substring(0, semi);
      if (name.isEmpty) return null;
      return Cookie(name, value.trim());
    }
  }
}
