/// 考试解析器（对应 grabber/api/exam.py 的纯解析部分）。
library;

import 'clean.dart';
import 'table_miner.dart';

/// 考试安排 HTML → `{headers, records, count}`（含座位表下载链接与考场 id）。
///
/// 记录中链接若含 `examRoom.id=N`，额外注入 `exam_room_id`。
Map<String, Object?> parseExamHtml(String html) {
  final tables = parseTables(html);
  final grid = pickTable(tables, classKw: 'gridtable') ??
      (tables.isNotEmpty ? tables.first : null);
  final records = tableRecords(grid);
  for (final r in records) {
    final links = r['_links'];
    if (links is! List) continue;
    for (final l in links) {
      final href = (l as Map)['href'];
      if (href is String) {
        final m = RegExp(r'examRoom\.id=(\d+)').firstMatch(href);
        if (m != null) r['exam_room_id'] = int.parse(m.group(1)!);
      }
    }
  }
  return {
    'headers': grid != null ? grid['headers'] : <String>[],
    'records': records,
    'count': records.length,
  };
}

/// 课外资格考试页 → `{signups, scores, signup_count, score_count}`
/// （按表格前置标题"报名"分流）。
Map<String, Object?> parseOtherExamsHtml(String html) {
  final signups = <Map<String, Object?>>[];
  final scores = <Map<String, Object?>>[];
  for (final t in parseTables(html)) {
    final recs = tableRecords(t);
    final title = '${t['title']}${t['caption']}';
    if (title.contains('报名')) {
      signups.addAll(recs);
    } else {
      scores.addAll(recs);
    }
  }
  return {
    'signups': signups,
    'scores': scores,
    'signup_count': signups.length,
    'score_count': scores.length,
  };
}

/// 考试批次下拉框 → `[{id, name, selected}]`。
List<Map<String, Object?>> parseExamBatchesHtml(String html) {
  final m = RegExp(r'<select[^>]*name="examBatch\.id"[^>]*>(.*?)</select>',
          dotAll: true)
      .firstMatch(html);
  if (m == null) return [];
  final out = <Map<String, Object?>>[];
  for (final opt in RegExp(
          r'<option value="(\d+)"(\s+selected)?[^>]*>(.*?)</option>',
          dotAll: true)
      .allMatches(m.group(1)!)) {
    out.add({
      'id': int.parse(opt.group(1)!),
      'selected': opt.group(2) != null,
      'name': cleanWs(opt.group(3)!),
    });
  }
  return out;
}
