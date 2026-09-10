/// 成绩解析器（对应 grabber/api/grade.py 的纯解析部分）。
library;

import 'table_miner.dart';

/// 成绩 HTML → `{headers, records, rows, count}`（纯函数）。
///
/// - records：表头命名 + 数值化的记录列表
/// - rows：原始文本行（`List<List<String>>`）
Map<String, Object?> parseGradesHtml(String html) {
  final tables = parseTables(html);
  final grid = pickTable(tables, classKw: 'gridtable') ??
      (tables.isNotEmpty ? tables.first : null);
  final records = tableRecords(grid);
  final rows = [
    for (final r in (grid?['rows'] as List? ?? const []))
      [for (final c in (r as List)) c['text'] as String]
  ];
  return {
    'headers': grid != null ? grid['headers'] : <String>[],
    'records': records,
    'count': records.length,
    'rows': rows,
  };
}
