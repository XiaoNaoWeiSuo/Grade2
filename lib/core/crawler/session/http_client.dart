/// HTTP 会话客户端 —— 基于 dart:io 的纯原生实现
/// （对应 grabber/http_client.py，无任何第三方依赖）。
///
/// 关键语义（与 Python 版 1:1）：
/// - 关闭自动重定向，手动逐跳跟踪；302 后一律转 GET（与浏览器一致）
/// - 每一跳的 Set-Cookie 都会摄取（CASTGC/sid 等令牌均在 302 响应上下发）
/// - GET 类请求有限重试（指数退避）；POST 永不自动重试（防重复提交登录表单）
/// - 响应体自动解压（gzip），按 Content-Type/meta charset 解码为文本
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show BytesBuilder;

import '../crawler_exceptions.dart';
import '../models/config_models.dart';
import 'cookie_jar.dart';

/// 一次请求的文本响应（url = 发起该响应的请求 URL）。
class HttpTextResponse {
  HttpTextResponse({
    required this.url,
    required this.statusCode,
    required this.headers,
    required this.setCookies,
    required this.body,
  });

  final Uri url;
  final int statusCode;

  /// 小写头名 → 值（同名多值以逗号合并；Set-Cookie 除外，见 [setCookies]）。
  final Map<String, String> headers;

  /// 原始 Set-Cookie 头列表。
  final List<String> setCookies;

  final String body;

  String? header(String name) => headers[name.toLowerCase()];

  bool get isRedirect =>
      statusCode == 301 ||
      statusCode == 302 ||
      statusCode == 303 ||
      statusCode == 307 ||
      statusCode == 308;
}

/// 会话 HTTP 客户端：持有 [CookieJar] 与全局 UA。
class SessionHttpClient {
  SessionHttpClient({required this.config})
      : _io = HttpClient()..connectionTimeout = Duration(seconds: config.timeout);

  final GrabberConfig config;
  final CookieJar cookies = CookieJar();
  final HttpClient _io;
  bool _closed = false;

  /// 释放底层连接（会话终止时调用；此后不得再发请求）。
  void close() {
    _closed = true;
    _io.close();
  }

  // ---------------- 基础请求 ----------------

  /// GET（带 config.getRetries 次网络重试）。
  Future<HttpTextResponse> get(Uri url, {Map<String, String>? headers}) =>
      _request('GET', url, headers: headers, retries: config.getRetries);

  /// POST（绝不网络重试）。
  ///
  /// [form] 与 [json] 二选一：form → x-www-form-urlencoded；json → JSON body。
  Future<HttpTextResponse> post(
    Uri url, {
    Map<String, String>? headers,
    Map<String, String>? form,
    Object? json,
  }) =>
      _request('POST', url,
          headers: headers, form: form, json: json, retries: 0, retryable: false);

  /// 从当前响应开始跟踪 3xx（302 后一律转 GET），返回最终响应。
  ///
  /// [onHop] 每跳回调 (来源URL, 状态码, 目标URL)，用于链路日志。
  Future<HttpTextResponse> follow(
    HttpTextResponse resp, {
    void Function(String from, int code, Uri to)? onHop,
    int? maxHops,
  }) async {
    final limit = maxHops ?? config.maxHops;
    for (var i = 0; i < limit; i++) {
      if (!resp.isRedirect) return resp;
      final loc = resp.header('location') ?? '';
      if (loc.isEmpty) return resp;
      final next = resp.url.resolve(loc);
      onHop?.call(resp.url.toString(), resp.statusCode, next);
      resp = await get(next, headers: {'Referer': resp.url.toString()});
    }
    throw HttpError('重定向跳数超限, 最后落点: ${resp.url}');
  }

  // ---------------- 内部实现 ----------------

  Future<HttpTextResponse> _request(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Map<String, String>? form,
    Object? json,
    int retries = 0,
    bool retryable = true,
  }) async {
    if (_closed) throw const HttpError('HTTP 会话已关闭');
    Object? lastError;
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        return await _once(method, url,
            headers: headers, form: form, json: json);
      } catch (e) {
        if (e is HttpError) rethrow; // 业务层错误不重试
        lastError = e;
        if (!retryable || attempt == retries) break;
        await Future<void>.delayed(Duration(seconds: 1 + attempt));
      }
    }
    throw HttpError('$method $url 失败: $lastError');
  }

  Future<HttpTextResponse> _once(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Map<String, String>? form,
    Object? json,
  }) async {
    final req = await _io.openUrl(method, url).timeout(
        Duration(seconds: config.timeout),
        onTimeout: () =>
            throw TimeoutException('连接超时', Duration(seconds: config.timeout)));
    // 手动跟踪重定向（与 Python allow_redirects=False 一致）
    req.followRedirects = false;
    try {
      // 默认头 + 请求级头覆盖
      req.headers.set(HttpHeaders.userAgentHeader, config.userAgent);
      req.headers.set(HttpHeaders.acceptLanguageHeader, config.acceptLanguage);
      final cookieHeader = cookies.headerFor(url);
      if (cookieHeader != null) {
        req.headers.set(HttpHeaders.cookieHeader, cookieHeader);
      }
      for (final e in headers?.entries ?? const <MapEntry<String, String>>[]) {
        req.headers.set(e.key, e.value);
      }
      String? body;
      if (form != null) {
        req.headers.contentType = ContentType(
            'application', 'x-www-form-urlencoded',
            charset: 'utf-8');
        body = encodeForm(form);
      } else if (json != null) {
        req.headers.contentType = ContentType.json;
        body = jsonEncode(json);
      }
      if (body != null) req.write(body);
      final ioResp = await req.close().timeout(
          Duration(seconds: config.timeout),
          onTimeout: () =>
              throw TimeoutException('响应超时', Duration(seconds: config.timeout)));
      final bytes = await ioResp
          .fold<BytesBuilder>(
            BytesBuilder(copy: false),
            (acc, chunk) => acc..add(chunk),
          )
          .timeout(Duration(seconds: config.timeout));
      // 摄取本跳 Set-Cookie（重定向响应上的令牌同样生效）
      final setCookies =
          ioResp.headers[HttpHeaders.setCookieHeader]?.toList() ?? const [];
      cookies.ingest(url.host, setCookies);
      return HttpTextResponse(
        url: url,
        statusCode: ioResp.statusCode,
        headers: _flatten(ioResp.headers),
        setCookies: setCookies,
        body: _decode(bytes.takeBytes(),
            ioResp.headers.value(HttpHeaders.contentTypeHeader)),
      );
    } finally {
      // HttpClientRequest 已 close；无需额外处理
    }
  }

  static Map<String, String> _flatten(HttpHeaders h) {
    final out = <String, String>{};
    h.forEach((name, values) {
      if (name.toLowerCase() == HttpHeaders.setCookieHeader) return;
      out[name.toLowerCase()] = values.join(', ');
    });
    return out;
  }

  /// 字节 → 文本：优先 Content-Type charset，其次嗅探 meta charset，默认 UTF-8。
  static String _decode(List<int> bytes, String? contentType) {
    var charset = _charsetFromContentType(contentType);
    if (charset == null && bytes.length > 8) {
      final head = latin1.decode(bytes.take(2048).toList(), allowInvalid: true);
      final m = _metaCharsetRe.firstMatch(head);
      if (m != null) charset = m.group(1)!.toLowerCase();
    }
    switch (charset) {
      case null:
      case 'utf-8':
      case 'utf8':
      case 'ascii':
      case 'us-ascii':
        return utf8.decode(bytes, allowMalformed: true);
      case 'latin-1':
      case 'latin1':
      case 'iso-8859-1':
      case 'iso8859-1':
        return latin1.decode(bytes, allowInvalid: true);
      default:
        // gbk/gb2312 等需第三方 charset 库（零依赖原则不引入）；
        // 本系统实测全站 UTF-8，此处以替换符兜底不抛异常
        return utf8.decode(bytes, allowMalformed: true);
    }
  }

  static final RegExp _metaCharsetRe =
      RegExp(r"""charset\s*=\s*['"]?\s*([A-Za-z0-9_-]+)""", caseSensitive: false);

  static String? _charsetFromContentType(String? ct) {
    if (ct == null) return null;
    final m =
        RegExp(r'charset\s*=\s*"?([A-Za-z0-9_-]+)"?', caseSensitive: false)
            .firstMatch(ct);
    return m?.group(1);
  }

  /// 表单编码（quote_plus 语义，与 Python urlencode 一致）。
  static String encodeForm(Map<String, String> form) => form.entries
      .map((e) =>
          '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');

  // ---------------- 会话持久化桥接 ----------------

  Map<String, Object?> cookiesToJson() => {'cookies': cookies.toJson()};

  void loadCookiesFromJson(Map<String, Object?> data) {
    final list = data['cookies'];
    if (list is List) cookies.loadJson(list);
  }

  bool hasCookie(String name, {String? domainSuffix}) =>
      cookies.has(name, domainSuffix: domainSuffix);
}
