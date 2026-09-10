/// URP 页面 JS 字面量解析工具（对应 grabber/api/base.py 的静态工具）。
///
/// URP 大量数据嵌在页面 JS 里（单引号字符串、无引号键），如：
/// `var lessonJSONs = [{id:123,name:'高数',...}]`
/// `window.lessonId2Counts = {'456':{sc:30,lc:60}}`
library;

import 'dart:convert';

/// 按顶层逗号拆分 JS 实参（尊重引号与括号）。
List<String> splitJsArgs(String s) {
  final args = <String>[];
  final buf = StringBuffer();
  var depth = 0;
  String? inStr;
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    if (inStr != null) {
      buf.write(ch);
      if (ch == inStr) inStr = null;
      continue;
    }
    if (ch == "'" || ch == '"') {
      inStr = ch;
      buf.write(ch);
    } else if (ch == '(' || ch == '[' || ch == '{') {
      depth++;
      buf.write(ch);
    } else if (ch == ')' || ch == ']' || ch == '}') {
      depth--;
      buf.write(ch);
    } else if (ch == ',' && depth == 0) {
      args.add(buf.toString().trim());
      buf.clear();
    } else {
      buf.write(ch);
    }
  }
  if (buf.isNotEmpty) args.add(buf.toString().trim());
  return args;
}

/// 从 [text] 开头提取首个配平的 `{...}` 或 `[...]` 字面量。
///
/// [openCh] 为 '{' 或 '['。找不到或不配平抛 [FormatException]。
String extractBalanced(String text, String openCh) {
  final closeCh = openCh == '[' ? ']' : '}';
  final start = text.indexOf(openCh);
  if (start < 0) {
    throw const FormatException('未找到起始符');
  }
  var depth = 0;
  String? inStr;
  for (var i = start; i < text.length; i++) {
    final ch = text[i];
    if (inStr != null) {
      if (ch == inStr) inStr = null;
      continue;
    }
    if (ch == "'" || ch == '"') {
      inStr = ch;
    } else if (ch == openCh) {
      depth++;
    } else if (ch == closeCh) {
      depth--;
      if (depth == 0) return text.substring(start, i + 1);
    }
  }
  throw const FormatException('括号不配平');
}

/// URP 页面 JS 字面量 → Dart 原生对象（Map/List/String/num/bool/null）。
///
/// 步骤（对标 js_to_py）：
/// 1. 无引号键加引号：`{id:1` → `{"id":1`
/// 2. 单引号替换为双引号
/// 3. jsonDecode
Object? jsLiteralToDart(String s) {
  final quoted = s.replaceAllMapped(
    RegExp(r'([{,\[]\s*)([A-Za-z_$][\w$]*)\s*:'),
    (m) => '${m.group(1)}"${m.group(2)}":',
  );
  return jsonDecode(quoted.replaceAll("'", '"'));
}
