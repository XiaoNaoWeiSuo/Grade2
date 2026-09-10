/// 选课解析器（对应 grabber/api/elective.py 的纯解析部分）。
library;

import 'clean.dart';
import 'html_sax.dart' show decodeHtmlEntities;
import 'js_literal.dart';

/// 选课入口页 → 轮次列表（名称/轮次号/开放时间/退课时间/限制/注意事项）。
List<Map<String, Object?>> parseProfilesHtml(String html) {
  final out = <Map<String, Object?>>[];
  for (final block in splitBefore(html, RegExp(r'<h2'))) {
    final m = RegExp(r'electionProfile\.id=(\d+)').firstMatch(block);
    if (m == null) continue;
    final h2 = RegExp(r'<h2[^>]*>(.*?)</h2>', dotAll: true).firstMatch(block);
    final text = cleanWs(decodeHtmlEntities(
        block.replaceAll(RegExp(r'<[^>]+>'), ' ')));
    final roundM = RegExp(r'选课轮次\s*(\d+)').firstMatch(text);
    // 范围分隔符为 " - "（两侧空格），与日期内部的 "-" 区分
    final openM = RegExp(r'选课开放时间[:：]?\s*([\d\-: ]+?)\s+-\s+([\d\-: ]+)')
        .firstMatch(text);
    final wdM = RegExp(r'退课开放时间[:：]?\s*([\d\-: ]+?)\s+-\s+([\d\-: ]+)')
        .firstMatch(text);
    final limits = <String>[];
    var notice = '';
    final limM = RegExp(r'选课限制(.*?)注意事项').firstMatch(text);
    if (limM != null) {
      limits.addAll([
        for (final x in limM.group(1)!.split(','))
          if (stripChars(x, ' ,、').isNotEmpty) stripChars(x, ' ,、')
      ]);
    }
    final ntM = RegExp(r'注意事项(.*?)(?:进入选课|$)').firstMatch(text);
    if (ntM != null) notice = ntM.group(1)!.trim();
    out.add({
      'id': int.parse(m.group(1)!),
      'name': h2 != null ? cleanWs(h2.group(1)!) : '',
      'round': roundM != null ? int.parse(roundM.group(1)!) : null,
      'elect_open': openM != null
          ? '${openM.group(1)!.trim()} ~ ${openM.group(2)!.trim()}'
          : '',
      'withdraw_open': wdM != null
          ? '${wdM.group(1)!.trim()} ~ ${wdM.group(2)!.trim()}'
          : '',
      'limits': limits,
      'notice': notice,
      'link': m.group(0)!,
    });
  }
  return out;
}

/// 进入选课轮次页 → `{profile_id, project_id, semester_id}`。
Map<String, Object?> parseElectiveContextHtml(String html, int profileId) {
  final m = RegExp(r'queryStdCount\.action\?projectId=(\d+)&semesterId=(\d+)')
      .firstMatch(html);
  return {
    'profile_id': profileId,
    'project_id': m != null ? int.parse(m.group(1)!) : 1,
    'semester_id': m != null ? int.parse(m.group(2)!) : null,
  };
}

/// 选课课程列表页（var lessonJSONs = [...]）→ 课程列表。
///
/// 解析失败返回空列表（纯函数，不抛异常）。
List<Map<String, Object?>> parseLessonsHtml(String html) {
  final key = RegExp(r'var\s+lessonJSONs\s*=').firstMatch(html);
  if (key == null) return [];
  try {
    final arr = extractBalanced(html.substring(key.end), '[');
    final obj = jsLiteralToDart(arr);
    if (obj is List) {
      return [for (final e in obj) if (e is Map<String, Object?>) e];
    }
    return [];
  } on FormatException {
    return [];
  }
}

/// 选课人数余量页（window.lessonId2Counts = {...}）
/// → `{lesson_id: {"sc": 已选人数, "lc": 人数上限}}`。
Map<String, Object?> parseCountsHtml(String html) {
  final key = RegExp(r'lessonId2Counts\s*=\s*').firstMatch(html);
  if (key == null) return {};
  try {
    final obj = jsLiteralToDart(extractBalanced(html.substring(key.end), '{'));
    if (obj is Map<String, Object?>) return obj;
    return {};
  } on FormatException {
    return {};
  }
}

/// 选课/退课操作结果页 → `{success, message, lesson_id}`。
Map<String, Object?> parseOperateResultHtml(
    String html, int lessonId, bool elect) {
  final red = RegExp(r'color:\s*red;[^"]*">(.*?)</div>', dotAll: true)
      .firstMatch(html);
  if (red != null) {
    return {
      'success': false,
      // 与 Python 一致：strip_tags（不解码实体，仅 &nbsp;）
      'message': stripTags(red.group(1)!),
      'lesson_id': lessonId,
    };
  }
  final m = RegExp(r'elected\s*:\s*(true|false)').firstMatch(html);
  final elected = m != null && m.group(1) == 'true';
  if (elect) {
    return {
      'success': elected,
      'message': elected ? '选课成功' : '选课未生效(结果未确认)',
      'lesson_id': lessonId,
    };
  }
  return {
    'success': !elected,
    'message': !elected ? '退课成功' : '退课未生效(结果未确认)',
    'lesson_id': lessonId,
  };
}
