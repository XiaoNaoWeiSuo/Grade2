/// 课表解析器（对应 grabber/api/timetable.py 的纯解析部分）。
///
/// 课表数据在页面 JS 里，每个课程块结构（宁重复勿缺，全部捕获）：
/// ```text
/// var teachers  = [{id,name,lab}];           任课教师
/// var actTeachers = [{id,name,lab}];         实际授课教师
/// var assistantName = "";                    助教
/// activity = new TaskActivity(教师ids, 教师names, "教学班号(课程代码)",
///             "课程名(课程代码)", roomId, roomName, 周次位串, null, null,
///             assistantName, "", 实验标记);
/// index = D*unitCount+U;                     星期D(1起) 第U节(1起)
/// ```
library;

import 'clean.dart';
import 'js_literal.dart';

const List<String> _dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

// ---- 热路径正则提为 final（parseCourseHtml 的课程块循环内使用） ----
final RegExp _unitCountRe = RegExp(r'var\s+unitCount\s*=\s*(\d+)');
final RegExp _courseTableRe = RegExp(r'new\s+CourseTable\((\d+)\s*,\s*(\d+)\)');
final RegExp _taskActivityRe =
    RegExp(r'new\s+TaskActivity\s*\((.*?)\)\s*;', dotAll: true);
final RegExp _indexRe = RegExp(r'index\s*=\s*(\d+)\s*\*\s*unitCount\s*\+\s*(\d+)\s*;');
final RegExp _assistantRe = RegExp(r'assistantName\s*=\s*"([^"]*)"');
RegExp _teachersBlockRe(String varName) =>
    RegExp('var\\s+$varName\\s*=\\s*(\\[[^\\]]*\\])');
final RegExp _teacherItemRe = RegExp(
    r'\{[^{}]*?id\s*:\s*(\d+)[^{}]*?name\s*:\s*"([^"]*)"[^{}]*?lab\s*:\s*(true|false)[^{}]*?\}');
final RegExp _splitLabelRe = RegExp(r'^(.*?)\(([\w-]+)\)\s*$');
final RegExp _courseTableIdsRe = RegExp(r'addInput\(form,"ids","(\d+)"\)');

/// 解析 `var teachers = [{id:..,name:"..",lab:false}]` → 列表。
List<Map<String, Object?>> _jsTeachers(String part, String varName) {
  final m = _teachersBlockRe(varName).firstMatch(part);
  if (m == null) return [];
  final out = <Map<String, Object?>>[];
  for (final tm in _teacherItemRe.allMatches(m.group(1)!)) {
    out.add({
      'id': int.parse(tm.group(1)!),
      'name': tm.group(2)!,
      'lab': tm.group(3) == 'true',
    });
  }
  return out;
}

/// `"115251(752764)"` → `{no, code, raw}`。
Map<String, Object?> _splitLabel(String? s) {
  final m = _splitLabelRe.firstMatch(s ?? '');
  if (m != null) {
    return {'no': m.group(1)!, 'code': m.group(2)!, 'raw': s ?? ''};
  }
  return {'no': s ?? '', 'code': '', 'raw': s ?? ''};
}

/// 课表 HTML/JS → 完整结构化数据（纯函数，支持离线自检）。
///
/// 返回 `{unit_count, table_meta, course_count, courses, merged}`：
/// - courses 每条含：教师(id/名称/助教)、教学班号/课程代码/课程名、
///   roomId/roomName、周次(raw/digest/list/count/total)、星期/节次、
///   实验标记、TaskActivity 原始参数(params_raw)
/// - merged 按课程名聚合各上课时段
Map<String, Object?> parseCourseHtml(String html) {
  final unitM = _unitCountRe.firstMatch(html);
  final unitCount = unitM != null ? int.parse(unitM.group(1)!) : null;

  var tableMeta = <String, Object?>{};
  final tm = _courseTableRe.firstMatch(html);
  if (tm != null) {
    tableMeta = {'year': int.parse(tm.group(1)!), 'slots': int.parse(tm.group(2)!)};
  }

  final courses = <Map<String, Object?>>[];
  // 每个课程块以 "var teachers" 开始，块内含 TaskActivity 与 index
  for (final part
      in splitBefore(html, RegExp(r'var\s+teachers\s*='))) {
    final actM = _taskActivityRe.firstMatch(part);
    final idxMatches = _indexRe.allMatches(part).toList();
    if (actM == null || idxMatches.isEmpty) continue;
    final args = splitJsArgs(actM.group(1)!);

    String lit(int i) {
      final s = i < args.length ? args[i].trim() : '';
      if (s.length >= 2 && (s[0] == '"' || s[0] == "'") && s[s.length - 1] == s[0]) {
        return s.substring(1, s.length - 1);
      }
      return '';
    }

    final teachers = _jsTeachers(part, 'teachers');
    final actTeachers = _jsTeachers(part, 'actTeachers');
    final assistantM = _assistantRe.firstMatch(part);
    final assistant = assistantM?.group(1) ?? '';
    final task = _splitLabel(lit(2));
    final name = _splitLabel(lit(3));
    final week = weekParse(lit(6));

    for (final idxM in idxMatches) {
      final idx = int.parse(idxM.group(1)!) * (unitCount ?? 0) + int.parse(idxM.group(2)!);
      final day = unitCount != null && unitCount > 0 ? idx ~/ unitCount + 1 : null;
      final unit = unitCount != null && unitCount > 0 ? idx % unitCount + 1 : null;
      courses.add({
        // 教师
        'teachers': teachers,
        'teacher_names': (actTeachers.isNotEmpty ? actTeachers : teachers)
            .map((t) => t['name'] as String)
            .join(','),
        'act_teachers': actTeachers,
        'assistant': assistant,
        // 课程标识
        'task_no': task['no'],
        'course_code': task['code'],
        'clazz': task['raw'],
        'name': name['no'],
        'name_raw': name['raw'],
        'course_code2': name['code'],
        // 地点
        'room_id': lit(4),
        'room': lit(5),
        // 时间
        'day': day,
        'day_name': day != null && day >= 1 && day <= 7 ? _dayNames[day - 1] : null,
        'unit': unit,
        'weeks': week, // {raw, digest, list, count, total}
        // 其它标记(第 12 参:实验/实践课标记;全部参数原样保留)
        'flag': lit(11),
        'params_raw': args,
      });
    }
  }

  // 按课程名聚合(同一课程多时段)
  final merged = <String, Map<String, Object?>>{};
  for (final c in courses) {
    final key = c['name'] as String?;
    final m = merged.putIfAbsent(key ?? '', () => {
          'name': key ?? '',
          'course_code':
              ((c['course_code'] as String?) ?? '').isNotEmpty
                  ? c['course_code']
                  : c['course_code2'],
          'clazz': c['clazz'],
          'teachers': c['teacher_names'],
          'assistant': c['assistant'],
          'rooms': <String>[],
          'times': <String>[],
          'weeks': <String>[],
          'units': 0,
        });
    final room = c['room'] as String;
    if (room.isNotEmpty && !(m['rooms'] as List).contains(room)) {
      (m['rooms'] as List).add(room);
    }
    if (c['day'] != null && c['unit'] != null) {
      (m['times'] as List).add('${c['day_name']}${c['unit']}节');
    }
    final digest = ((c['weeks'] as Map)['digest'] as String?) ?? '';
    if (digest.isNotEmpty && !(m['weeks'] as List).contains(digest)) {
      (m['weeks'] as List).add(digest);
    }
    m['units'] = (m['units'] as int) + 1;
  }
  return {
    'unit_count': unitCount,
    'table_meta': tableMeta,
    'course_count': courses.length,
    'courses': courses,
    'merged': merged.values.toList(),
  };
}

/// 从课表入口页解析 学生id(std) 与 班级id(class)。
///
/// 返回 `{"std": "1225"?, "class": "1226"?}`（值为字符串）。
Map<String, Object?> parseCourseTableIds(String html) {
  final ids = _courseTableIdsRe
      .allMatches(html)
      .map((m) => m.group(1)!)
      .toList();
  return {
    'std': ids.isNotEmpty ? ids[0] : null,
    'class': ids.length > 1 ? ids[1] : null,
  };
}
