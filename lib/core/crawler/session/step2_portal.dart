/// 第②步：aTrust 门户会话建立（对应 grabber/step2_portal.py + 短信增强认证扩展）。
///
/// 链路（抓包实测，顺序保持一致）：
/// ```text
/// 1. GET  {PORTAL}/passport/v1/auth/cas?sfDomain=CAS&ticket=ST-xxx
///        → 302 /portal/shortcut.html?...&data={"ticket":"<unitId_uuid>",...}
///        → 该 302 响应下发门户会话 Cookie: sid / sid.sig(tag=secondary_auth)
/// 2. GET  shortcut.html(落地,后续请求的 Referer)
/// 3. GET  /passport/v1/public/authConfig?...&mod=1
///        → 响应 JSON 含 security.csrfToken —— 后续门户 API 必须带 x-csrf-token 头
/// 4. POST /controller/v1/public/reportEnv
///        (x-csrf-token + x-sdp-traceid;body = data 里的 ticket + deviceId)
/// 5. GET  /passport/v1/auth/authCheck → code:0 + isOnline:true
///        → 刷新 sid(tag=online),授权会话正式生效(实测有效期 15min)
/// ```
///
/// ## 短信增强认证（2026-09 实测补充）
/// 网关风控（同账号高频登录等）时 authCheck 拒绝并下发 ACL 指令
/// （`type:enhanced` + `nextService:auth/sms`），此时：
/// ```text
/// GET  /passport/v1/auth/sms?action=sendsms&taskId=…&authId=…   发送短信
/// GET  /passport/v1/public/phoneNumber                          掩码手机号
/// POST /passport/v1/auth/sms?action=checkcode  (form: code=…)   提交验证码
///      → 成功后同一会话 authCheck 复查即在线
/// ```
/// 注意：认证记忆绑定"存活的门户会话"，新 sid 会重新评估策略 ——
/// 会话 cookie 必须落盘复用（CrawlerSession 已做）。
library;

import 'dart:convert';

import '../crawler_exceptions.dart';
import '../crypto/cas_crypto.dart';
import '../models/config_models.dart';
import 'http_client.dart';

/// 门户建立结果。
class PortalInfo {
  PortalInfo({
    required this.username,
    required this.displayName,
    required this.sidTicket,
  });

  final String username;
  final String displayName;
  final String sidTicket;

  Map<String, Object?> toMap() => {
        'username': username,
        'display_name': displayName,
        'sid_ticket': sidTicket,
      };
}

/// 短信验证码下发信息。
class SmsChallenge {
  SmsChallenge({required this.maskedPhone, required this.intervalSeconds});

  /// 掩码手机号（如 `193****0952`）。
  final String maskedPhone;

  /// 重发间隔（秒，实测 60）。
  final int intervalSeconds;
}

class Step2Portal {
  Step2Portal({required this.http, required this.config, this.onLog});

  final SessionHttpClient http;
  final GrabberConfig config;
  final void Function(String message)? onLog;

  String _csrf = '';
  String _referer = '';

  Uri _portalUri(String path, [Map<String, String>? extra]) =>
      buildPortalUri(config.portalBase, path, config.clientQuery, extra);

  /// 组装门户 API URI。
  ///
  /// ⚠ 必须保留 [path] 自带的 query（如 `sms?action=sendsms`）：
  /// `Uri.replace(queryParameters:)` 是整串替换语义，直接用会丢掉 action
  /// 参数（曾致 sendsms 400）。此处先并 [path] 原有 query 再叠加公共参数。
  static Uri buildPortalUri(String portalBase, String path,
      Map<String, String> clientQuery,
      [Map<String, String>? extra]) {
    final base = Uri.parse('$portalBase$path');
    return base.replace(queryParameters: {
      ...base.queryParameters,
      ...clientQuery,
      ...?extra,
    });
  }

  Map<String, String> _apiHeaders(String csrf, String referer,
          {bool origin = false}) =>
      {
        'Accept': '*/*',
        'x-csrf-token': csrf,
        'x-sdp-traceid': randomHex(4),
        'Referer': referer,
        if (origin) 'Origin': config.portalBase,
      };

  /// 用 CAS 回跳 URL（带 ST ticket）建立门户会话。
  ///
  /// [casRedirectUrl] 来自第①步；[deviceId] 为设备指纹（64 位 hex）。
  /// 兼容两种情形：
  /// - 全新会话：auth/cas 302 → shortcut（含 login ticket）→ 完整建立
  /// - 会话仍在线：auth/cas 直接 302 回应用 URL → 仅做 authCheck 确认
  ///
  /// 抛出：[NeedSecondaryAuthError]/[PortalError]/[HttpError]。
  Future<PortalInfo> establish(String casRedirectUrl, String deviceId) async {
    // 1) 用 ST 换门户会话（302 响应头下发 sid Cookie）
    final resp = await http.get(Uri.parse(casRedirectUrl), headers: {
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Referer': '${config.casBase}/',
    });
    if (!resp.isRedirect) {
      throw PortalError('auth/cas 未按预期 302: HTTP ${resp.statusCode}');
    }
    final shortcutLoc = resp.header('location') ?? '';
    final loginTicket = _loginTicketFrom(shortcutLoc);

    if (loginTicket.isEmpty) {
      // 会话仍在线：网关直接 302 回应用入口（无 shortcut/login ticket）
      // —— 不重复建立，仅确认在线状态（快路径，零额外风险）
      onLog?.call('门户会话仍有效(auth/cas 直跳应用入口),走快速确认');
      _referer = '${config.portalBase}/portal/shortcut.html';
      return _confirmOnline();
    }

    // 2) shortcut.html 落地（参照浏览器行为）
    final shortcutUrl = resp.url.resolve(shortcutLoc);
    await http.get(shortcutUrl, headers: {'Referer': resp.url.toString()});
    // SPA 维护的在线状态 cookie（保真）
    http.cookies.set('online', '0', domain: config.portalHost);
    onLog?.call(
        '门户会话建立(sid),login_ticket=${loginTicket.length >= 13 ? loginTicket.substring(0, 13) : loginTicket}****');

    // 3) authConfig：取 csrfToken
    await _refreshCsrf(shortcutUrl.toString());

    // 4) reportEnv 环境上报（body 结构 1:1 复刻抓包）
    final envResp = await http.post(
      _portalUri('/controller/v1/public/reportEnv'),
      headers: _apiHeaders(_csrf, shortcutUrl.toString(), origin: true),
      json: {
        'ticket': loginTicket,
        'deviceId': deviceId,
        'env': {
          'endpoint': {
            'device_id': deviceId,
            'device': {'type': 'browser'},
          },
        },
      },
    );
    int rcode;
    try {
      rcode = _asMap(jsonDecode(envResp.body))['code'] as int? ?? -1;
    } on FormatException {
      throw PortalError(
          'reportEnv 响应异常: HTTP ${envResp.statusCode} ${_clip(envResp.body, 100)}');
    }
    if (rcode != 0) {
      throw PortalError(
          'reportEnv 失败: code=$rcode ${_clip(envResp.body, 120)}');
    }

    // 5) authCheck —— 在线状态确认（硬校验）
    return _confirmOnline();
  }

  /// 发送短信验证码（增强认证）。须在 establish 抛出
  /// [NeedSecondaryAuthError] 后、同一会话上调用。
  ///
  /// 返回掩码手机号与重发间隔；会话未处于增强认证状态抛 [PortalError]。
  Future<SmsChallenge> sendSmsCode() async {
    if (_csrf.isEmpty) await _refreshCsrf();
    final d = await _gateData();
    final authList = [
      for (final a in (d['nextServiceList'] as List? ?? const []))
        if (a is Map<String, Object?>) a
    ];
    final taskId = d['taskId'] as String? ?? '';
    final smsAuth = authList.firstWhere(
      (a) => a['authType'] == 'auth/sms',
      orElse: () => authList.isNotEmpty ? authList.first : const {},
    );
    final authId = smsAuth['authId'] as String?;
    final params = <String, String>{
      if (taskId.isNotEmpty) 'taskId': taskId,
      if (authId != null && authId.isNotEmpty) 'authId': authId,
    };
    final r = await http.get(
        _portalUri('/passport/v1/auth/sms?action=sendsms', params),
        headers: _apiHeaders(_csrf, _referer));
    return parseSmsSendResponse(_jsonBody(r, 'sendsms'));
  }

  /// 提交短信验证码并确认在线。成功返回 [PortalInfo]（随后调用方执行第③步）。
  ///
  /// 验证码错误抛 [PortalError]（message 含剩余尝试次数）。
  Future<PortalInfo> verifySmsCode(String code) async {
    if (_csrf.isEmpty) await _refreshCsrf();
    final d = await _gateData();
    final authList = [
      for (final a in (d['nextServiceList'] as List? ?? const []))
        if (a is Map<String, Object?>) a
    ];
    final smsAuth = authList.firstWhere(
      (a) => a['authType'] == 'auth/sms',
      orElse: () => authList.isNotEmpty ? authList.first : const {},
    );
    final authId = smsAuth['authId'] as String?;
    // 实测：表单编码，键为 code（附 authId 可选）
    final r = await http.post(
        _portalUri('/passport/v1/auth/sms?action=checkcode'),
        headers: _apiHeaders(_csrf, _referer, origin: true),
        form: {
          'code': code,
          if (authId != null && authId.isNotEmpty) 'authId': authId,
        });
    final j = _jsonBody(r, 'checkcode');
    if (j['code'] != 0) {
      throw PortalError('验证码校验失败: ${j['message'] ?? j['code']}');
    }
    onLog?.call('短信验证码校验通过');
    return _confirmOnline();
  }

  // ---------------- 内部 ----------------

  /// authCheck 在线确认。在线 → [PortalInfo]；风控 → [NeedSecondaryAuthError]。
  Future<PortalInfo> _confirmOnline() async {
    if (_csrf.isEmpty) await _refreshCsrf();
    final data = await _authCheck();
    final d = _asMap(data['data']);
    // 网关风控二次认证优先判定：实测两种形状 ——
    // a) code=10000006 顶层增强认证；b) code=0 但 data 内嵌 ACL 指令
    //    （type=enhanced / nextService=auth/sms / reason=PolicyDisobeyed）。
    if (isSecondaryAuthRequired(data)) {
      final services = d['nextServiceList'];
      final names = services is List
          ? [
              for (final s in services.cast<Object?>())
                if (s is Map) s['authName'] ?? s['authType']
            ].join('/')
          : (d['nextService'] ?? '未知');
      throw NeedSecondaryAuthError(
          '网关风控要求二次认证($names)：${d['message'] ?? data['message']}。'
          '请完成短信验证后继续');
    }
    if (data['code'] != 0) {
      throw PortalError('authCheck 失败: ${data['message']}');
    }
    final info = _asMap(d['onlineInfo']);
    if (info['isOnline'] != true) {
      throw const PortalError('authCheck 报告未在线');
    }
    http.cookies.set('online', '1', domain: config.portalHost);
    onLog?.call('authCheck 通过: ${info['displayName']}(${info['username']}) 在线');
    return PortalInfo(
      username: info['username'] as String? ?? '',
      displayName: info['displayName'] as String? ?? '',
      sidTicket: d['sidTicket'] as String? ?? '',
    );
  }

  /// 当前 gate 数据（authCheck 的 data 段；无论成败都返回，供 sms 流程取参）。
  Future<Map<String, Object?>> _gateData() async {
    final data = await _authCheck();
    return _asMap(data['data']);
  }

  Future<Map<String, Object?>> _authCheck() async {
    final r = await http.get(_portalUri('/passport/v1/auth/authCheck'),
        headers: _apiHeaders(_csrf, _referer));
    return _jsonBody(r, 'authCheck');
  }

  Future<void> _refreshCsrf([String? referer]) async {
    _referer = referer ?? _referer;
    final cfgResp = await http.get(
        _portalUri('/passport/v1/public/authConfig', {'mod': '1'}),
        headers: {
          'Accept': '*/*',
          'Referer': _referer.isEmpty
              ? '${config.portalBase}/portal/shortcut.html'
              : _referer,
        });
    Map<String, Object?> cfgJson;
    try {
      cfgJson = _asMap(jsonDecode(cfgResp.body));
    } on FormatException {
      throw PortalError(
          'authConfig 响应非 JSON: HTTP ${cfgResp.statusCode}');
    }
    final csrf = _asMap(_asMap(cfgJson['data'])['security'])['csrfToken'];
    if (csrf is! String || csrf.isEmpty) {
      throw const PortalError('authConfig 未下发 csrfToken');
    }
    _csrf = csrf;
    onLog?.call(
        'csrfToken 获取: ${csrf.length >= 8 ? csrf.substring(0, 8) : csrf}****');
  }

  Map<String, Object?> _jsonBody(HttpTextResponse r, String tag) {
    try {
      return _asMap(jsonDecode(r.body));
    } on FormatException {
      throw PortalError(
          '$tag 响应非 JSON: HTTP ${r.statusCode} ${_clip(r.body, 100)}');
    }
  }

  /// 判定 authCheck 失败响应是否为网关风控二次认证（增强认证）。
  ///
  /// 实测风控响应形状：
  /// - 显式增强认证：`type: "enhanced"` 或 `data.type: "enhanced"` 或 `data.reason: "PolicyDisobeyed"`
  /// - 二次认证服务：`nextService` 或 `nextServiceList` 中的 `authType`/`action` 属于二次认证类型
  ///   （如 `auth/sms`、`auth/totp`、`auth/otp` 等），绝不包含 `auth/authCheck`、`auth/firstAuth`、`auth/cas` 等基础认证流服务。
  static bool isSecondaryAuthRequired(Map<String, Object?> data) {
    final d = _asMap(data['data']);

    // 1) 显式增强认证标志或策略违规
    if (data['type'] == 'enhanced' ||
        d['type'] == 'enhanced' ||
        d['reason'] == 'PolicyDisobeyed') {
      return true;
    }

    // 2) 明确的二次认证目标服务（排除 authCheck/firstAuth/cas/pwd 等基础服务）
    const secondaryAuthServices = {
      'auth/sms',
      'auth/totp',
      'auth/otp',
      'auth/radius',
      'auth/email',
    };

    final nextService = (d['nextService'] as String?) ?? '';
    if (secondaryAuthServices.contains(nextService)) {
      return true;
    }

    // 3) 检查 nextServiceList 中是否包含二次认证项
    final list = d['nextServiceList'];
    if (list is List && list.isNotEmpty) {
      for (final item in list) {
        if (item is Map) {
          final authType = item['authType'] as String?;
          final action = item['action'] as String?;
          if (secondaryAuthServices.contains(authType) ||
              secondaryAuthServices.contains(action)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// 解析 sendsms 响应 → [SmsChallenge]（静态纯函数，便于测试）。
  static SmsChallenge parseSmsSendResponse(Map<String, Object?> j) {
    if (j['code'] != 0) {
      throw PortalError('短信发送失败: ${j['message'] ?? j['code']}');
    }
    final d = _asMap(j['data']);
    // tips 形如 "验证码已发送到您的手机：193****0952, 请查收！"
    final tips = d['tips'] as String? ?? '';
    final m = RegExp(r'(\d{3}\*{4}\d{4})').firstMatch(tips);
    // 实测 interval 是字符串 "60"（服务端不规范），做宽容解析
    final intervalRaw = d['interval'];
    final interval =
        intervalRaw is int ? intervalRaw : int.tryParse('$intervalRaw') ?? 60;
    return SmsChallenge(
      maskedPhone: m?.group(1) ?? d['maskIdentifierValue'] as String? ?? '',
      intervalSeconds: interval,
    );
  }

  static Map<String, Object?> _asMap(Object? v) =>
      v is Map<String, Object?> ? v : <String, Object?>{};

  static String _clip(String s, int n) =>
      s.length > n ? s.substring(0, n) : s;

  /// 从 shortcut 跳转 URL 解析 login ticket（含 URL 解码，容错异常编码）。
  static String _loginTicketFrom(String loc) {
    String decoded;
    try {
      decoded = Uri.decodeFull(loc);
    } catch (_) {
      try {
        decoded = Uri.decodeComponent(loc);
      } catch (_) {
        decoded = loc;
      }
    }
    final m = RegExp(r'"ticket"\s*:\s*"([^"]+)"').firstMatch(decoded);
    return m?.group(1) ?? '';
  }
}
