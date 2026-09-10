/// 杂项解析器：学籍/消息/欢迎页/学期/中期考核/教学评价
/// （对应 grabber/api/misc.py 的纯解析部分）。
library;

import 'clean.dart';
import 'html_sax.dart' show decodeHtmlEntities;
import 'table_miner.dart';

/// 学籍 HTML → `{sections, photo, kv}`。
///
/// - sections：`[{section, kv}]`（学籍/联系信息/家庭联系信息等多段）
/// - photo：照片 URL（无则空串）
/// - kv：首段 KV
Map<String, Object?> parseStdDetailHtml(String html) {
  final sections = kvTables(html);
  var photo = '';
  for (final s in sections) {
    final kv = s['kv'] as Map<String, Object?>;
    final p = kv['照片'];
    if (p is String && p.isNotEmpty) photo = p;
  }
  return {
    'sections': sections,
    'photo': photo,
    'kv': sections.isNotEmpty ? sections.first['kv'] : <String, Object?>{},
  };
}

/// 系统消息 HTML → `{records, count}`（发件人/主题/时间全字段）。
Map<String, Object?> parseMessagesHtml(String html) {
  final grid = pickTable(parseTables(html), classKw: 'gridtable');
  final records = tableRecords(grid);
  return {'records': records, 'count': records.length};
}

/// 欢迎页 → `{modules, welcome_text}`（各模块标题 + 正文完整文本）。
Map<String, Object?> parseWelcomeHtml(String html) {
  final modules = <Map<String, Object?>>[];
  for (final m in RegExp(
          r'<h2 class="header">\s*<a[^>]*>([^<]+)</a>\s*</h2>\s*'
          r'<div class="modulebody">(.*?)</div>',
          dotAll: true)
      .allMatches(html)) {
    final body = cleanWs(decodeHtmlEntities(
        m.group(2)!.replaceAll(RegExp(r'<[^>]+>'), ' ')));
    modules.add({'name': m.group(1)!.trim(), 'content': body});
  }
  return {
    'modules': modules,
    'welcome_text': modules.isNotEmpty ? modules.first['content'] : '',
  };
}

/// 学期列表页（dataQuery semesterCalendar 的 JS 响应）
/// → `{semesters, current, year_index}`。
///
/// 响应为 JS 字面量且 yearDom 内嵌 HTML，通用转换不适用，用定向正则。
Map<String, Object?> parseSemestersHtml(String html) {
  final sems = <Map<String, Object?>>[
    for (final m in RegExp(r'\{id:(\d+),schoolYear:"([^"]+)",name:"([^"]+)"\}')
        .allMatches(html))
      {
        'id': int.parse(m.group(1)!),
        'schoolYear': m.group(2)!,
        'name': m.group(3)!,
        'label': '${m.group(2)!}学年 ${m.group(3)!}学期',
      }
  ];
  sems.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
  final cur = RegExp(r'semesterId:"(\d+)"').firstMatch(html);
  final yi = RegExp(r'yearIndex:"(\d+)"').firstMatch(html);
  return {
    'semesters': sems,
    // value 为空时响应不含 semesterId，回退为列表中最新学期
    'current': cur != null
        ? int.parse(cur.group(1)!)
        : (sems.isNotEmpty ? sems.last['id'] : null),
    'year_index': yi?.group(1),
  };
}

/// 中期考核页 → `{message, text}`。
Map<String, Object?> parseMidtermHtml(String html) {
  final m = RegExp(r'<h[1-4][^>]*>(.*?)</h[1-4]>', dotAll: true)
      .firstMatch(html);
  final text = cleanWs(html.replaceAll(RegExp(r'<[^>]+>'), ' '));
  return {
    'message': m != null ? cleanWs(m.group(1)!) : '',
    'text': text.length > 500 ? text.substring(0, 500) : text,
  };
}

/// 教学评价页 → `{records, count}`。
Map<String, Object?> parseEvaluateHtml(String html) {
  final grid = pickTable(parseTables(html), classKw: 'gridtable');
  final records = tableRecords(grid);
  return {'records': records, 'count': records.length};
}
