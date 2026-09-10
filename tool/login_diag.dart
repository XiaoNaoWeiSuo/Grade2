// 登录链路实网诊断脚本（不入内核）。
// 运行: /Users/lin/develop/flutter/bin/dart run tool/login_diag.dart
import 'dart:io';

import 'package:grade2/core/crawler/crawler_exceptions.dart';
import 'package:grade2/core/crawler/models/config_models.dart';
import 'package:grade2/core/crawler/session/cookie_jar.dart';
import 'package:grade2/core/crawler/session/http_client.dart';
import 'package:grade2/core/crawler/session/step1_cas.dart';
import 'package:grade2/core/crawler/session/step2_portal.dart';
import 'package:grade2/core/crawler/session/step3_app.dart';

const username = '2022007923';
const password = 'changjiangdaxue@923';

void dump(HttpTextResponse r, {int bodyLen = 260}) {
  stdout.writeln('  ← ${r.statusCode} ${r.url}');
  final loc = r.header('location');
  if (loc != null) stdout.writeln('    location: $loc');
  if (r.setCookies.isNotEmpty) {
    stdout.writeln('    set-cookie:');
    for (final c in r.setCookies) {
      stdout.writeln('      ${c.split(';').take(2).join('; ')}');
    }
  }
  final b = r.body.replaceAll('\n', ' ');
  stdout.writeln('    body[${r.body.length}]: '
      '${b.substring(0, b.length > bodyLen ? bodyLen : b.length)}');
}

Future<void> main() async {
  final config = const GrabberConfig();
  final http = SessionHttpClient(config: config);
  void log(String m) => stdout.writeln('[LOG] $m');

  final step1 = Step1Cas(
      http: http,
      config: config,
      credentials: const CrawlerCredentials(username: username, password: password),
      onLog: log);

  try {
    // ---------- 第①步 CAS ----------
    stdout.writeln('=== ① CAS 登录 ===');
    final loginUrl = Uri.parse(
        '${config.casBase}/authserver/login?service=${Uri.encodeComponent(config.casService)}');
    stdout.writeln('GET $loginUrl');
    final page = await http.get(loginUrl, headers: {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Referer': '${config.portalBase}/portal/',
    });
    dump(page, bodyLen: 400);

    if (!page.isRedirect) {
      // 解析表单
      final fields = {
        'execution': RegExp(r'name="execution" value="([^"]*)"')
                .firstMatch(page.body)
                ?.group(1) ??
            '',
        'lt': RegExp(r'name="lt"[^>]*value="([^"]*)"').firstMatch(page.body)?.group(1) ?? '',
        'salt': RegExp(r'id="pwdEncryptSalt" value="([^"]*)"').firstMatch(page.body)?.group(1) ?? '',
      };
      stdout.writeln('表单字段: execution=${fields['execution']!.length}B '
          'lt=${fields['lt']!.length}B salt=${fields['salt']!.length}B');

      // 验证码检查
      final captchaResp = await http.get(Uri(
        scheme: Uri.parse(config.casBase).scheme,
        host: Uri.parse(config.casBase).host,
        port: Uri.parse(config.casBase).port,
        path: '/authserver/checkNeedCaptcha.htl',
        queryParameters: {
          'username': username,
          '_': DateTime.now().millisecondsSinceEpoch.toString(),
          'sf_request_type': 'ajax',
        },
      ), headers: {'X-Requested-With': 'XMLHttpRequest'});
      dump(captchaResp, bodyLen: 200);

      // 密码登录 POST
      final cas = await step1.login();
      stdout.writeln('① 结果: redirect=${cas.redirectUrl} usedSso=${cas.usedSso}');

      // ---------- 第②步 门户 ----------
      stdout.writeln('=== ② 门户会话 ===');
      final step2 = Step2Portal(http: http, config: config, onLog: log);
      final portal = await step2.establish(cas.redirectUrl, 'a' * 64);
      stdout.writeln('② 结果: ${portal.toMap()}');

      // ---------- 第③步 应用授权 ----------
      stdout.writeln('=== ③ 应用授权 ===');
      final step3 = Step3App(http: http, config: config, onLog: log);
      await step3.enter();
      stdout.writeln('③ 完成, JSESSIONID=${http.hasCookie('JSESSIONID')}');
      stdout.writeln('=== 全链路 OK ===');
    }
  } on CrawlerException catch (e) {
    stderr.writeln('!! ${e.runtimeType}: ${e.message}');
    exitCode = 1;
  } catch (e) {
    stderr.writeln('!! 未预期异常: $e');
    exitCode = 1;
  } finally {
    stdout.writeln('cookie 概览:');
    for (final line in cookieOverview(http.cookies)) {
      stdout.writeln('  $line');
    }
    http.close();
  }
}

List<String> cookieOverview(CookieJar jar) {
  // 通过 toJson 概览（不含完整值）
  return [
    for (final c in jar.toJson())
      '${c['domain']}${c['path']} ${c['name']}=${c['value']}'
          .replaceAll(RegExp(r'^(.*?=.{6}).*'), r'$1****')
  ];
}
