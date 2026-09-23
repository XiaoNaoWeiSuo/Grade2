/// 数据清洗工具（对应 grabber/api/clean.py 的纯函数部分）。
///
/// 原则：宁重复勿缺 —— 数值化失败回退原文，绝不丢信息。
library;

import 'html_sax.dart' show decodeHtmlEntities;

// ---- 热路径正则统一提为 final（cleanWs 每单元格调用，避免重复编译） ----
final RegExp _wsRe = RegExp(r'\s+');
final RegExp _tagRe = RegExp(r'<[^>]+>');
final RegExp _tagGreedyRe = RegExp(r'<[^>]*>');
final RegExp _numRe = RegExp(r'^-?\d+(?:\.\d+)?$');

/// 压缩空白（含 &nbsp;/\xa0 → 空格，多空白合一，去首尾）。
String cleanWs(String? s) {
  if (s == null || s.isEmpty) return '';
  final t = s.contains('\u00a0') ? s.replaceAll('\u00a0', ' ') : s;
  return t.replaceAll(_wsRe, ' ').trim();
}

/// 去标签 + &nbsp; 处理 + 压缩空白（不解码其它实体；对应 base.py strip_tags）。
String stripTags(String? s) {
  if (s == null || s.isEmpty) return '';
  final noTags = s.replaceAll(_tagRe, ' ');
  return noTags
      .replaceAll('&nbsp;', ' ')
      .replaceAll(_wsRe, ' ')
      .trim();
}

/// 去标签 + 解码实体 + 压缩空白（兜底工具）。
String stripAll(String? s) {
  if (s == null || s.isEmpty) return '';
  final noTags = s.replaceAll('&nbsp;', ' ').replaceAll(_tagGreedyRe, ' ');
  return cleanWs(decodeHtmlEntities(noTags));
}

/// 文本 → 数值：整串为数字（可带小数）才数值化，否则原样返回。
///
/// 时间 '14:00~15:50' 等不误伤。空串返回 null。
Object? toNum(String? s) {
  final t = cleanWs(s ?? '');
  if (t.isEmpty) return null;
  if (!_numRe.hasMatch(t)) return t;
  final v = double.tryParse(t);
  if (v == null) return t;
  return v == v.truncateToDouble() ? v.toInt() : v;
}

/// 周次位串（URP 53/56 位串 '0111100…'）→ `{raw, digest, list, count, total}`。
///
/// 长江大学教务系统 (URP) 使用 53/56 位学年周次位串：
/// 索引 0 为占位符（非教学周），索引 1 对应第 1 周，索引 2 对应第 2 周……即 index i 对应第 i 周。
/// TaskActivity.js 中 table0.marshalTable(2, 1, 20) 计算周次为 index - from + 2 = index (当 from=2)。
Map<String, Object?> weekParse(String? bits) {
  bits = bits ?? '';
  final weeks = <int>[];
  if (bits.isNotEmpty) {
    if (bits.length >= 20) {
      // URP 53 位位串：从索引 1 开始，index i 即为第 i 周
      for (var i = 1; i < bits.length; i++) {
        if (bits[i] == '1') weeks.add(i);
      }
    } else {
      // 兼容简写或自定义测试短位串
      for (var i = 0; i < bits.length; i++) {
        if (bits[i] == '1') weeks.add(i + 1);
      }
    }
  }
  return {
    'raw': bits,
    'digest': weekDigest(weeks),
    'list': weeks,
    'count': weeks.length,
    'total': bits.length >= 20 ? bits.length - 1 : bits.length,
  };
}

/// 周列表 → '1-9' / '单3-15' / '双2-16' 形式摘要（对应 URP TaskActivity.js 与 base.py）。
String weekDigest(List<int> weeks) {
  if (weeks.isEmpty) return '';
  final wset = weeks.toSet();
  final runs = <String>[];
  var i = 0;
  while (i < weeks.length) {
    // 1) 连续周（步长 1）
    var j = i;
    while (j + 1 < weeks.length && weeks[j + 1] == weeks[j] + 1) {
      j++;
    }
    if (j > i) {
      runs.add('${weeks[i]}-${weeks[j]}');
      i = j + 1;
      continue;
    }

    // 2) 单双周（步长 2，后续元素不能是连续周的起点）
    var k = i;
    while (k + 1 < weeks.length &&
        weeks[k + 1] == weeks[k] + 2 &&
        !wset.contains(weeks[k + 1] + 1)) {
      k++;
    }
    if (k > i) {
      final prefix = (weeks[i] % 2 == 0) ? '双' : '单';
      runs.add('$prefix${weeks[i]}-${weeks[k]}');
      i = k + 1;
      continue;
    }

    // 3) 单独单周
    runs.add('${weeks[i]}');
    i++;
  }
  return runs.join(',');
}

/// 周位串直转摘要（'000011110000' → '5-8'）。
String weekDigestFromBits(String state) {
  return weekParse(state)['digest'] as String? ?? '';
}

/// 去除字符串两端出现在 [chars] 中的字符（Python str.strip(chars)）。
String stripChars(String s, String chars) {
  var start = 0, end = s.length;
  while (start < end && chars.contains(s[start])) {
    start++;
  }
  while (end > start && chars.contains(s[end - 1])) {
    end--;
  }
  return s.substring(start, end);
}

/// 仅去除右端出现在 [chars] 中的字符（Python str.rstrip(chars)）。
String rstripChars(String s, String chars) {
  var end = s.length;
  while (end > 0 && chars.contains(s[end - 1])) {
    end--;
  }
  return s.substring(0, end);
}

/// 在每个正则匹配起点切分（对标 Python `re.split(r'(?=...)')[1:]` 语义）。
///
/// 返回以匹配开头的块列表；首个匹配之前的内容被丢弃。
List<String> splitBefore(String s, RegExp pattern) {
  final out = <String>[];
  final matches = pattern.allMatches(s).toList();
  for (var i = 0; i < matches.length; i++) {
    final end = i + 1 < matches.length ? matches[i + 1].start : s.length;
    out.add(s.substring(matches[i].start, end));
  }
  return out;
}
