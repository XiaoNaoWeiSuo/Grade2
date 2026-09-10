// authCheck 深度诊断：手动复刻 step2，dump 每个子响应全文。
// 运行: /Users/lin/develop/flutter/bin/dart run tool/authcheck_diag.dart
import 'dart:convert';
import 'dart:io';

import 'package:grade2/core/crawler/models/config_models.dart';
import 'package:grade2/core/crawler/session/http_client.dart';
import 'package:grade2/core/crawler/session/step1_cas.dart' as s1;
import 'package:grade2/core/crawler/crypto/cas_crypto.dart';

const u = '2022007923';
const p = 'changjiangdaxue@923';

void dump(String tag, String body, [int len = 1500]) {
  stdout.writeln('--- $tag ---');
  stdout.writeln(body.length > len ? body.substring(0, len) : body);
}

Future<void> main() async {
  final config = const GrabberConfig();
  final http = SessionHttpClient(config: config);

  // ===== step1: CAS 登录 =====
  final step1 = s1.Step1Cas(
      http: http,
      config: config,
      credentials: const CrawlerCredentials(username: u, password: p));
  final cas = await step1.login();
  stdout.writeln('step1 OK, usedSso=${cas.usedSso}');

  // ===== step2 手动复刻 =====
  // 1) auth/cas
  final r1 = await http.get(Uri.parse(cas.redirectUrl), headers: {
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Referer': '${config.casBase}/',
  });
  final shortcutLoc = r1.header('location') ?? '';
  final loginTicket =
      RegExp(r'"ticket"\s*:\s*"([^"]+)"').firstMatch(Uri.decodeFull(shortcutLoc))
              ?.group(1) ??
          '';
  stdout.writeln('auth/cas → ${r1.statusCode}, sid cookies: '
      '${[for (final c in r1.setCookies) c.split(';').first].join(' | ')}');

  // 2) shortcut
  final shortcutUrl = r1.url.resolve(shortcutLoc);
  await http.get(shortcutUrl, headers: {'Referer': r1.url.toString()});
  http.cookies.set('online', '0', domain: config.portalHost);

  // 3) authConfig
  final r3 = await http.get(
      Uri.parse('${config.portalBase}/passport/v1/public/authConfig').replace(
          queryParameters: {...config.clientQuery, 'mod': '1'}),
      headers: {'Accept': '*/*', 'Referer': shortcutUrl.toString()});
  final cfg = jsonDecode(r3.body) as Map<String, Object?>;
  final csrf =
      (((cfg['data'] as Map)['security'] as Map)['csrfToken'] as String);
  stdout.writeln('authConfig OK, csrf=${csrf.substring(0, 8)}****');

  // 4) reportEnv —— dump 全文
  final deviceId = randomHex(32);
  final r4 = await http.post(
      Uri.parse('${config.portalBase}/controller/v1/public/reportEnv')
          .replace(queryParameters: config.clientQuery),
      headers: {
        'Accept': '*/*',
        'x-csrf-token': csrf,
        'x-sdp-traceid': randomHex(4),
        'Referer': shortcutUrl.toString(),
        'Origin': config.portalBase,
      },
      json: {
        'ticket': loginTicket,
        'deviceId': deviceId,
        'env': {
          'endpoint': {
            'device_id': deviceId,
            'device': {'type': 'browser'}
          }
        }
      });
  dump('reportEnv(${r4.statusCode})', r4.body, 1200);
  // 5) authCheck —— dump 全文
  final r5 = await http.get(
      Uri.parse('${config.portalBase}/passport/v1/auth/authCheck')
          .replace(queryParameters: config.clientQuery),
      headers: {
        'Accept': '*/*',
        'x-csrf-token': csrf,
        'x-sdp-traceid': randomHex(4),
        'Referer': shortcutUrl.toString(),
      });
  dump('authCheck(${r5.statusCode})', const JsonEncoder.withIndent('  ')
      .convert(jsonDecode(r5.body)), 3000);

  // 6) 等待 2 秒后再查一次（排除时序）
  await Future<void>.delayed(const Duration(seconds: 2));
  final r6 = await http.get(
      Uri.parse('${config.portalBase}/passport/v1/auth/authCheck')
          .replace(queryParameters: config.clientQuery),
      headers: {
        'Accept': '*/*',
        'x-csrf-token': csrf,
        'x-sdp-traceid': randomHex(4),
        'Referer': shortcutUrl.toString(),
      });
  dump('authCheck again(${r6.statusCode})', const JsonEncoder.withIndent('  ')
      .convert(jsonDecode(r6.body)), 3000);

  stdout.writeln('当前 cookie: ${[for (final c in http.cookies.toJson()) '${c['domain']}|${c['name']}'].join(', ')}');
  http.close();
}
