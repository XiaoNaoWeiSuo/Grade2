// Dart 内核短信增强认证冒烟：加载 Python 落盘的同构状态文件复用会话。
// 运行: /Users/lin/develop/flutter/bin/dart run tool/dart_sms_smoke.dart
import 'dart:io';

import 'package:grade2/core/crawler/crawler_exceptions.dart';
import 'package:grade2/core/crawler/models/config_models.dart';
import 'package:grade2/core/crawler/session/crawler_session.dart';
import 'package:grade2/core/crawler/session/state_store.dart';

Future<void> main() async {
  final session = CrawlerSession(
    config: const GrabberConfig(),
    credentials: const CrawlerCredentials(
        username: '2022007923', password: 'changjiangdaxue@923'),
    stateStore: FileSessionStateStore(
        '/Users/lin/Desktop/x/Grade2/grabber/.session/state.json'),
    onLog: (m) => stdout.writeln('[LOG] $m'),
  );
  try {
    await session.ensureApi();
    stdout.writeln('★ 会话复用成功（缓存或快路径），JSESSIONID='
        '${session.hasCookie('JSESSIONID')}');
    final r = await session.withApi((a) => a.semesters());
    stdout.writeln('学期数=${(r['semesters'] as List).length} '
        '当前=${r['current']}');
  } on NeedSecondaryAuthError catch (e) {
    stdout.writeln('◆ 触发风控（预期内，sid 已过期）: ${e.message}');
    stdout.writeln('→ Dart 内核已正确识别为 NeedSecondaryAuthError');
  } on CrawlerException catch (e) {
    stderr.writeln('!! ${e.runtimeType}: ${e.message}');
    exitCode = 1;
  } finally {
    // 不 reset —— 保留状态供 App 直接复用
    session.dispose();
  }
}
