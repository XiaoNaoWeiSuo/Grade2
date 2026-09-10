// semesters 原始响应诊断（不入内核）。
// 运行: /Users/lin/develop/flutter/bin/dart run tool/sem_diag.dart
import 'dart:io';

import 'package:grade2/core/crawler/api/eams_api.dart';
import 'package:grade2/core/crawler/models/config_models.dart';
import 'package:grade2/core/crawler/session/crawler_session.dart';
import 'package:grade2/core/crawler/session/state_store.dart';

Future<void> main() async {
  final outDir = '/tmp/semdiag';
  final session = CrawlerSession(
    config: const GrabberConfig(),
    credentials: const CrawlerCredentials(
        username: '2022007923', password: 'changjiangdaxue@923'),
    stateStore: MemorySessionStateStore(),
  );
  try {
    await session.ensureApi();
    final api = EamsApi(
        http: session.http,
        config: const GrabberConfig(),
        rawSink: DirectoryRawSink(outDir));
    final r = await api.semesters();
    stdout.writeln('current=${r['current']} year_index=${r['year_index']} '
        'sems=${(r['semesters'] as List).length}');
    final raw = File('$outDir/semesters_raw.txt').readAsStringSync();
    stdout.writeln('--- raw head 600 ---');
    stdout.writeln(raw.substring(0, raw.length > 600 ? 600 : raw.length));
  } finally {
    await session.reset();
    session.dispose();
  }
}
