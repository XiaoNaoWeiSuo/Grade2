/// 培养计划解析器（对应 grabber/api/plan.py 的纯解析部分）。
library;

import 'clean.dart';
import 'table_miner.dart';

/// 平铺记录(含 `_group` 行) → `[{group, summary, records}]` 分组结构。
List<Map<String, Object?>> _sectionsFromRecords(
    List<Map<String, Object?>> records) {
  final sections = <Map<String, Object?>>[];
  Map<String, Object?>? cur;
  for (final r in List.of(records)) {
    if (r.containsKey('_group')) {
      final group = r.remove('_group');
      final summary = <String, Object?>{}..addAll(r);
      cur = {'group': group, 'summary': summary, 'records': <Map<String, Object?>>[]};
      sections.add(cur);
    } else {
      if (cur == null) {
        cur = {'group': '(未分组)', 'summary': <String, Object?>{}, 'records': <Map<String, Object?>>[]};
        sections.add(cur);
      }
      (cur['records'] as List).add(r);
    }
  }
  return sections;
}

/// 计划完成情况 HTML → `{summary, sections, records, count}`。
///
/// - summary：头部 KV
/// - sections：分组课程明细 `[{group, summary, records}]`
/// - records：平铺（每条附加 group 字段）
Map<String, Object?> parsePlanCompletionHtml(String html) {
  final kvs = kvTables(html);
  final tables = parseTables(html);
  final form = pickTable(tables, classKw: 'formTable');
  final records = tableRecords(form, headerRow: 0);
  final sections = _sectionsFromRecords(records);
  final flat = <Map<String, Object?>>[];
  for (final s in sections) {
    for (final r in (s['records'] as List)) {
      flat.add({'group': s['group'], ...(r as Map<String, Object?>)});
    }
  }
  return {
    'summary': kvs.isNotEmpty ? kvs.first['kv'] : <String, Object?>{},
    'sections': sections,
    'records': flat,
    'count': flat.length,
  };
}

/// 培养方案/专业计划页 → 全部表格（嵌套内层表独立，含表头与记录）。
///
/// `[{class, title, headers, header_rows, records}]`
List<Map<String, Object?>> parsePlanTablesHtml(String html) {
  final out = <Map<String, Object?>>[];
  for (final t in parseTables(html)) {
    if ((t['n_rows'] as int) == 0 && (t['header_rows'] as List).isEmpty) {
      continue;
    }
    out.add({
      'class': t['class'],
      'title': ((t['title'] as String).isNotEmpty
          ? t['title']
          : t['caption']),
      'headers': t['headers'],
      'header_rows': t['n_rows'],
      'records': tableRecords(t),
    });
  }
  return out;
}

/// 转专业申请页 → `{message, menus, text}`。
Map<String, Object?> parseStdApplyHtml(String html) {
  final msg = RegExp(r'<h[2-4][^>]*>([^<]+)</h[2-4]>').firstMatch(html);
  final menus = <Map<String, Object?>>[];
  for (final m
      in RegExp(r'<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>', dotAll: true)
          .allMatches(html)) {
    menus.add({'text': cleanWs(m.group(2)!), 'href': m.group(1)!});
  }
  return {
    'message': msg != null ? cleanWs(msg.group(1)!) : '',
    'menus': menus,
    // 与 Python 一致：仅去标签 + clean_ws，不解码实体
    'text': _clip(cleanWs(html.replaceAll(RegExp(r'<[^>]+>'), ' ')), 300),
  };
}

String _clip(String s, int n) => s.length > n ? s.substring(0, n) : s;
