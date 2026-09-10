// 复现 App 登录序列：首次登录落盘 → 第二次加载持久化状态重登。
// 运行: /Users/lin/develop/flutter/bin/dart run tool/relogin_diag.dart
import 'dart:convert';
import 'dart:io';

import 'package:grade2/core/crawler/crawler_exceptions.dart';
import 'package:grade2/core/crawler/models/config_models.dart';
import 'package:grade2/core/crawler/session/crawler_session.dart';
import 'package:grade2/core/crawler/session/state_store.dart';

const u = '2022007923';
const p = 'changjiangdaxue@923';
const storePath = '/tmp/relogin_state.json';

Future<void> loginOnce(String tag) async {
  final s = CrawlerSession(
    config: const GrabberConfig(),
    credentials: const CrawlerCredentials(username: u, password: p),
    stateStore: FileSessionStateStore(storePath),
    onLog: (m) => stdout.writeln('[$tag] $m'),
  );
  try {
    await s.ensureApi(forceRelogin: true);
    stdout.writeln('[$tag] 登录成功, cookies=${s.http.cookies.length}条');
    // 打印门户域相关 cookie 名单（排查新旧 sid 并存）
    final names = [
      for (final c in s.http.cookies.toJson())
        '${c['domain']}|${c['name']}'
    ]..sort();
    stdout.writeln('[$tag] cookie清单: ${names.join(', ')}');
  } on CrawlerException catch (e) {
    stderr.writeln('[$tag] 失败: ${e.runtimeType}: ${e.message}');
    exitCode = 1;
  } finally {
    s.dispose(); // 不 reset，模拟 app 进程退出后状态留盘
  }
}

Future<void> main() async {
  await File(storePath).delete().catchError((_) => File(storePath));
  stdout.writeln('=== 第一次登录（全新） ===');
  await loginOnce('A');
  stdout.writeln('=== 第二次登录（加载持久化状态重登，模拟 App 内再次登录） ===');
  await loginOnce('B');
  stdout.writeln('=== 状态文件内容概要 ===');
  if (await File(storePath).exists()) {
    final data = jsonDecode(await File(storePath).readAsString())
        as Map<String, Object?>;
    final cookies = data['cookies'] as List;
    stdout.writeln('cookies ${cookies.length} 条: '
        '${[for (final c in cookies) '${c['domain']}|${c['name']}'].join(', ')}');
  }
}
