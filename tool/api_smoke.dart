// 第④步 EamsApi 实网冒烟（不入内核）。
// 运行: /Users/lin/develop/flutter/bin/dart run tool/api_smoke.dart
import 'dart:io';

import 'package:grade2/core/crawler/crawler_exceptions.dart';
import 'package:grade2/core/crawler/models/config_models.dart';
import 'package:grade2/core/crawler/session/crawler_session.dart';
import 'package:grade2/core/crawler/session/state_store.dart';

const username = '2022007923';
const password = 'changjiangdaxue@923';

void show(String name, Object? v) {
  final s = v.toString().replaceAll('\n', ' ');
  stdout.writeln('$name: ${s.length > 220 ? s.substring(0, 220) : s}');
}

Future<void> main() async {
  final session = CrawlerSession(
    config: const GrabberConfig(),
    credentials: const CrawlerCredentials(username: username, password: password),
    stateStore: MemorySessionStateStore(),
    onLog: (m) => stdout.writeln('[LOG] $m'),
  );
  try {
    final api = await session.ensureApi(forceRelogin: true);
    show('welcome', await session.withApi((_) => api.welcome()));
    show('semesters.current',
        (await session.withApi((_) => api.semesters()))['current']);
    show('courseTable.course_count',
        (await session.withApi((_) => api.courseTable()))['course_count']);
    show('grades(369).count',
        (await session.withApi((_) => api.grades(369)))['count']);
    show('examBatches', await session.withApi((_) => api.examBatches()));
    stdout.writeln('=== API 冒烟 OK ===');
  } on CrawlerException catch (e) {
    stderr.writeln('!! ${e.runtimeType}: ${e.message}');
    exitCode = 1;
  } finally {
    await session.reset();
    session.dispose();
  }
}
