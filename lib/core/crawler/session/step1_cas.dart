/// 第①步：CAS 统一身份认证（对应 grabber/step1_cas.py）。
///
/// 链路（抓包实测）：
/// ```text
/// GET  /authserver/login?service=<aTrust 回跳地址>
///      ├─ CASTGC 有效 → 302 直接下发 ST(SSO 免密,不消耗登录次数)
///      └─ 否则返回登录表单(含 pwdEncryptSalt)
/// POST /authserver/login (密码 AES 加密) → 302 带 ticket=ST-xxx
/// ```
///
/// 安全约束：
/// - 密码 POST 每个本实例最多 [GrabberConfig.maxLoginPostsPerRun] 次，
///   失败立即抛 [CredentialError]，绝不重试（防触发账号锁定）
/// - POST 前先查 checkNeedCaptcha，需要验证码则抛 [NeedCaptchaError]（不硬闯）
library;

import 'dart:convert';

import '../crawler_exceptions.dart';
import '../crypto/cas_crypto.dart';
import '../models/config_models.dart';
import 'http_client.dart';

/// CAS 登录结果：带 ST ticket 的 aTrust 回跳 URL。
class CasLoginResult {
  CasLoginResult({required this.redirectUrl, required this.usedSso});

  /// 带 `ticket=ST-xxx` 的回跳 URL（交给第②步）。
  final String redirectUrl;

  /// 是否 CASTGC 免密 SSO（true=未消耗密码登录次数）。
  final bool usedSso;
}

class Step1Cas {
  Step1Cas({
    required this.http,
    required this.config,
    required this.credentials,
    this.onLog,
  });

  final SessionHttpClient http;
  final GrabberConfig config;
  final CrawlerCredentials credentials;
  final void Function(String message)? onLog;

  int _loginPostsUsed = 0;

  String get _loginUrl =>
      '${config.casBase}/authserver/login?service=${Uri.encodeComponent(config.casService)}';

  /// 检查该账号本次是否需要验证码。
  Future<bool> checkNeedCaptcha() async {
    final resp = await http.get(Uri(
      scheme: Uri.parse(config.casBase).scheme,
      host: Uri.parse(config.casBase).host,
      port: Uri.parse(config.casBase).port,
      path: '/authserver/checkNeedCaptcha.htl',
      queryParameters: {
        'username': credentials.username,
        '_': (DateTime.now().millisecondsSinceEpoch).toString(),
        'sf_request_type': 'ajax',
      },
    ), headers: {'X-Requested-With': 'XMLHttpRequest'});
    try {
      final j = jsonDecode(resp.body);
      return j is Map && j['isNeed'] == true;
    } on FormatException {
      return false;
    }
  }

  /// CAS 登录：优先 SSO 免密，否则密码登录（AES 加密）。
  ///
  /// 抛出：[CasError]/[NeedCaptchaError]/[CredentialError]/[HttpError]。
  Future<CasLoginResult> login() async {
    // 1) 先试 SSO：CASTGC 有效时，登录页直接 302 下发新 ST（零风险、不占登录次数）
    final resp = await http.get(Uri.parse(_loginUrl), headers: {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Referer': '${config.portalBase}/portal/',
    });
    if (resp.isRedirect && resp.statusCode != 308) {
      final loc = resp.header('location') ?? '';
      if (loc.contains('ticket=ST-')) {
        onLog?.call('CAS SSO 命中(CASTGC 有效),免密获得新 ticket');
        return CasLoginResult(redirectUrl: loc, usedSso: true);
      }
      throw CasError('登录页异常跳转(无 ticket): ${loc.length > 120 ? loc.substring(0, 120) : loc}');
    }

    // 2) 走密码登录
    if (_loginPostsUsed >= config.maxLoginPostsPerRun) {
      throw const CasError('本次运行密码登录 POST 次数已达上限,拒绝继续(防封号)');
    }

    final form = _parseLoginForm(resp.body);
    if (form['execution']!.isEmpty) {
      throw const CasError('登录页解析失败(未找到 execution 字段)');
    }

    if (await checkNeedCaptcha()) {
      throw const NeedCaptchaError('该账号本次需要验证码,已主动放弃(请稍后再试或人工登录)');
    }

    final salt = form['salt']!;
    _loginPostsUsed++;
    onLog?.call('CAS 密码登录 POST'
        '(第 $_loginPostsUsed/${config.maxLoginPostsPerRun} 次,'
        '盐 ${salt.length >= 4 ? salt.substring(0, 4) : salt}****)');

    final postResp = await http.post(Uri.parse(_loginUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Origin': config.casBase,
          'Referer': _loginUrl,
        },
        form: {
          'username': credentials.username,
          'password': encryptPassword(credentials.password, salt),
          'captcha': '',
          'rememberMe': 'true',
          '_eventId': 'submit',
          'lt': form['lt'] ?? '',
          'cllt': 'userNameLogin',
          'dllt': 'generalLogin',
          'execution': form['execution'] ?? '',
        });

    if (postResp.isRedirect) {
      final loc = postResp.header('location') ?? '';
      if (loc.contains('ticket=ST-')) {
        onLog?.call('CAS 登录成功,获得 ST ticket');
        return CasLoginResult(redirectUrl: loc, usedSso: false);
      }
      throw CasError('登录后跳转异常: ${loc.length > 120 ? loc.substring(0, 120) : loc}');
    }

    // 200 = 登录失败页(错误信息在页面里)。绝不重试。
    throw CredentialError('CAS 登录被拒绝: ${_extractError(postResp.body)}');
  }

  // ---------------- 登录页解析 ----------------

  /// 提取 execution / lt / pwdEncryptSalt 三个隐藏字段。
  static Map<String, String> _parseLoginForm(String html) {
    String field(List<String> patterns) {
      for (final p in patterns) {
        final m = RegExp(p).firstMatch(html);
        if (m != null) return m.group(1)!;
      }
      return '';
    }

    return {
      'execution': field(
          [r'name="execution" value="([^"]*)"', r'id="execution"[^>]*value="([^"]*)"']),
      'lt': field(
          [r'name="lt"[^>]*value="([^"]*)"', r'id="lt"[^>]*value="([^"]*)"']),
      'salt': field([r'id="pwdEncryptSalt" value="([^"]*)"']),
    };
  }

  /// 从登录失败页提取错误文案。
  static String _extractError(String html) {
    final m = RegExp(r'id="msg"[^>]*>([^<]+)<').firstMatch(html) ??
        RegExp(r'class="auth_error"[^>]*>([^<]+)<').firstMatch(html) ??
        RegExp(r'class="errors?[" >][^>]*>([^<]{2,80})<').firstMatch(html);
    if (m == null) return '未知原因';
    return m.group(1)!.trim();
  }
}
