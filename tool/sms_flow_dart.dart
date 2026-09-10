// Dart 内核短信增强认证全流程（与 App AuthController 同一调用路径）。
// 运行: /Users/lin/develop/flutter/bin/dart run tool/sms_flow_dart.dart send
//       /Users/lin/develop/flutter/bin/dart run tool/sms_flow_dart.dart check <code>
import 'dart:io';

import 'package:grade2/core/crawler/crawler_exceptions.dart';
import 'package:grade2/core/crawler/models/config_models.dart';
import 'package:grade2/core/crawler/session/crawler_session.dart';
import 'package:grade2/core/crawler/session/state_store.dart';

const u = '2022007923';
const p = 'changjiangdaxue@923';
const statePath = '/tmp/sms_dart_state.json';

Future<CrawlerSession> _session() async {
  final s = CrawlerSession(
    config: const GrabberConfig(),
    credentials: const CrawlerCredentials(username: u, password: p),
    stateStore: FileSessionStateStore(statePath),
    onLog: (m) => stdout.writeln('[LOG] $m'),
  );
  await s.loadState();
  return s;
}

Future<void> main(List<String> args) async {
  final cmd = args.isNotEmpty ? args[0] : 'send';
  final session = await _session();
  try {
    switch (cmd) {
      case 'send':
        try {
          await session.ensureApi(forceRelogin: true);
          stdout.writeln('◆ 未触发风控？直接可用（策略可能已解除）');
          await session.saveState();
          return;
        } on NeedSecondaryAuthError catch (e) {
          stdout.writeln('◆ 风控拦截（预期）: ${e.message}');
        }
        final c = await session.startSmsVerification();
        await session.saveState();
        stdout.writeln('★ 短信已发送: ${c.maskedPhone}，重发间隔 ${c.intervalSeconds}s');
        stdout.writeln('→ 下一步: dart run tool/sms_flow_dart.dart check <验证码>');

      case 'check':
        final code = args.length > 1 ? args[1] : '';
        await session.completeSmsVerification(code);
        await session.saveState();
        stdout.writeln('★ 验证通过，JSESSIONID='
            '${session.hasCookie('JSESSIONID')}');
        final sems = await session.withApi((a) => a.semesters());
        stdout.writeln('API 冒烟: 学期数=${(sems['semesters'] as List).length} '
            '当前=${sems['current']}');
        final table = await session.withApi((a) => a.courseTable());
        stdout.writeln('课表: ${table['course_count']} 门课');
        stdout.writeln('=== Dart 短信增强认证全链路 OK ===');

      default:
        stderr.writeln('用法: send | check <code>');
        exitCode = 2;
    }
  } on NeedSecondaryAuthError catch (e) {
    stderr.writeln('!! 仍处于风控: ${e.message}');
    exitCode = 1;
  } on PortalError catch (e) {
    stderr.writeln('!! ${e.runtimeType}: ${e.message}');
    exitCode = 1;
  } on CrawlerException catch (e) {
    stderr.writeln('!! ${e.runtimeType}: ${e.message}');
    exitCode = 1;
  } finally {
    session.dispose();
  }
}
