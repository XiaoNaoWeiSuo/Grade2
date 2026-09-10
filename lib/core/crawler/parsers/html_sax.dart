/// 纯 Dart 的 SAX 式 HTML 流式解析器
/// （对标 Python 标准库 html.parser.HTMLParser，内核无第三方依赖）。
///
/// 能力与约束（按 URP 页面实际需要裁剪，容错优先）：
/// - 事件流：onStartTag(tag, attrs) / onEndTag(tag) / onData(text)
/// - 标签名与属性名统一小写；属性值做实体解码
/// - 文本数据自动做实体解码（对标 convert_charrefs=True）
/// - `<script>`/`<style>` 原文透传为 data（内部 `<` 不误判为标签）
/// - 自闭合 `/>` 与 void 元素（br/img/input/meta/link...）自动补发 endTag
/// - 跳过注释 / DOCTYPE / 处理指令 / CDATA（CDATA 内容作为 data 透传）
library;

/// HTML 实体解码（命名实体 + 十进制/十六进制数字实体）。
///
/// 覆盖 Python html.unescape 在 URP 页面上的实际使用集。
String decodeHtmlEntities(String s) {
  if (!s.contains('&')) return s;
  return s.replaceAllMapped(_entityRe, (m) {
    final ent = m[1]!;
    final numeric = m[2]; // m[2] 对未参与匹配的组返回 null（不抛异常）
    if (numeric != null) {
      final code = numeric.startsWith('x') || numeric.startsWith('X')
          ? int.tryParse(numeric.substring(1), radix: 16)
          : int.tryParse(numeric);
      if (code == null || code < 0 || code > 0x10FFFF) return m.group(0)!;
      return String.fromCharCode(code);
    }
    return _namedEntities[ent] ?? m.group(0)!;
  });
}

final RegExp _entityRe =
    RegExp(r'&(#(x?[0-9A-Fa-f]+)|[A-Za-z][A-Za-z0-9]*);');

/// 常用命名实体表（nbsp 保留为 U+00A0，由 clean_ws 统一压缩）。
const Map<String, String> _namedEntities = {
  'nbsp': '\u00a0', 'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"',
  'apos': "'", 'copy': '©', 'reg': '®', 'trade': '™', 'hellip': '…',
  'mdash': '—', 'ndash': '–', 'lsquo': '\u2018', 'rsquo': '\u2019',
  'ldquo': '\u201c', 'rdquo': '\u201d', 'bull': '•', 'dagger': '†',
  'permil': '‰', 'prime': '′', 'Prime': '″', 'times': '×', 'divide': '÷',
  'plusmn': '±', 'deg': '°', 'micro': 'µ', 'para': '¶', 'middot': '·',
  'cent': '¢', 'pound': '£', 'yen': '¥', 'euro': '€', 'sect': '§',
  'laquo': '«', 'raquo': '»', 'frac12': '½', 'frac14': '¼', 'frac34': '¾',
  'sup1': '¹', 'sup2': '²', 'sup3': '³', 'alpha': 'α', 'beta': 'β',
  'gamma': 'γ', 'delta': 'δ', 'pi': 'π', 'mu': 'μ', 'sigma': 'σ',
  'larr': '←', 'uarr': '↑', 'rarr': '→', 'darr': '↓', 'harr': '↔',
  'ne': '≠', 'le': '≤', 'ge': '≥', 'infin': '∞', 'sum': '∑', 'radic': '√',
  'ensp': '\u2002', 'emsp': '\u2003', 'thinsp': '\u2009', 'zwnj': '\u200c',
  'zwj': '\u200d', 'lrm': '\u200e', 'rlm': '\u200f',
};

/// Void 元素（无闭合标签）。
const Set<String> _voidElements = {
  'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link',
  'meta', 'param', 'source', 'track', 'wbr',
};

/// 原文透传元素（内部不解析标签）。
const Set<String> _rawTextElements = {'script', 'style'};

class HtmlSaxParser {
  /// 事件回调。
  final void Function(String tag, Map<String, String> attrs) onStartTag;
  final void Function(String tag) onEndTag;
  final void Function(String text) onData;

  HtmlSaxParser({
    required this.onStartTag,
    required this.onEndTag,
    required this.onData,
  });

  /// 解析整份文档（一次性喂入；URP 页面尺寸在 MB 级，可承受）。
  void parse(String html) {
    var i = 0;
    final n = html.length;
    final text = StringBuffer();

    void flushText() {
      if (text.isNotEmpty) {
        onData(decodeHtmlEntities(text.toString()));
        text.clear();
      }
    }

    while (i < n) {
      final lt = html.indexOf('<', i);
      if (lt < 0) {
        text.write(html.substring(i));
        break;
      }
      if (lt > i) text.write(html.substring(i, lt));

      // <!-- 注释 -->
      if (html.startsWith('<!--', lt)) {
        flushText();
        final end = html.indexOf('-->', lt + 4);
        i = end < 0 ? n : end + 3;
        continue;
      }
      // <![CDATA[ ... ]]>（内容作为 data）
      if (html.startsWith('<![CDATA[', lt)) {
        final end = html.indexOf(']]>', lt + 9);
        final chunk = end < 0
            ? html.substring(lt + 9)
            : html.substring(lt + 9, end);
        text.write(chunk);
        i = end < 0 ? n : end + 3;
        continue;
      }
      // <!DOCTYPE ...> / <?...?>
      if (lt + 1 < n && (html[lt + 1] == '!' || html[lt + 1] == '?')) {
        flushText();
        final end = html.indexOf('>', lt + 2);
        i = end < 0 ? n : end + 1;
        continue;
      }
      // </close>
      if (lt + 1 < n && html[lt + 1] == '/') {
        flushText();
        final end = html.indexOf('>', lt + 2);
        if (end < 0) break;
        final name = html
            .substring(lt + 2, end)
            .trim()
            .toLowerCase();
        if (name.isNotEmpty) onEndTag(name);
        i = end + 1;
        continue;
      }
      // <tag attrs...> 或 <tag attrs.../>
      final tagMatch = _tagStartRe.matchAsPrefix(html, lt);
      if (tagMatch == null) {
        // 形如 "a < b" 的孤立 '<'，按文本处理
        text.write('<');
        i = lt + 1;
        continue;
      }
      flushText();
      final tag = tagMatch.group(1)!.toLowerCase();
      final afterName = lt + tagMatch.group(0)!.length;
      // 找标签结尾（尊重引号内的 '>'）
      final (closeIdx, selfClosing) = _findTagEnd(html, afterName);
      if (closeIdx < 0) {
        onStartTag(tag, const {});
        onEndTag(tag);
        break;
      }
      final attrStr = html.substring(afterName, closeIdx).trim();
      final attrs = _parseAttrs(attrStr);
      onStartTag(tag, attrs);
      i = closeIdx + 1;

      if (_rawTextElements.contains(tag)) {
        // 原文透传直到匹配的闭合标签
        final close = _findRawClose(html, i, tag);
        final chunk = html.substring(i, close);
        if (chunk.isNotEmpty) onData(chunk);
        onEndTag(tag);
        // 定位闭合标签的 '>' 之后（兼容 </tag > 等空白变体）
        final gt = html.indexOf('>', close);
        i = gt < 0 ? n : gt + 1;
        continue;
      }
      if (selfClosing || _voidElements.contains(tag)) {
        onEndTag(tag);
      }
    }
    flushText();
  }

  static final RegExp _tagStartRe = RegExp(r'<([A-Za-z][A-Za-z0-9:-]*)');

  /// 返回 (内容结束索引 即 '>' 位置, 是否自闭合)。
  static (int, bool) _findTagEnd(String html, int from) {
    var quote = '\x00'; // 当前引号字符
    for (var i = from; i < html.length; i++) {
      final c = html[i];
      if (quote != '\x00') {
        if (c == quote) quote = '\x00';
      } else if (c == '"' || c == '\'') {
        quote = c;
      } else if (c == '>') {
        final selfClosing = i > from && html[i - 1] == '/';
        return (i, selfClosing);
      }
    }
    return (-1, false);
  }

  /// 解析属性串：`name` / `name=value` / `name="v a l"` / `name='v'`。
  static Map<String, String> _parseAttrs(String s) {
    final attrs = <String, String>{};
    var i = 0;
    final n = s.length;
    while (i < n) {
      // 跳过空白与残留的 '/'
      while (i < n && (s.codeUnitAt(i) == 0x20 || s[i] == '\t' || s[i] == '\n' || s[i] == '\r' || s[i] == '/')) {
        i++;
      }
      if (i >= n) break;
      final nameStart = i;
      while (i < n &&
          s[i] != '=' &&
          s.codeUnitAt(i) != 0x20 &&
          s[i] != '\t' &&
          s[i] != '\n' &&
          s[i] != '\r' &&
          s[i] != '/') {
        i++;
      }
      if (i == nameStart) {
        i++;
        continue;
      }
      final name = s.substring(nameStart, i).toLowerCase();
      // 跳过空白
      while (i < n && (s.codeUnitAt(i) == 0x20 || s[i] == '\t' || s[i] == '\n' || s[i] == '\r')) {
        i++;
      }
      var value = '';
      if (i < n && s[i] == '=') {
        i++;
        while (i < n && (s.codeUnitAt(i) == 0x20 || s[i] == '\t' || s[i] == '\n' || s[i] == '\r')) {
          i++;
        }
        if (i < n && (s[i] == '"' || s[i] == '\'')) {
          final q = s[i++];
          final vStart = i;
          while (i < n && s[i] != q) {
            i++;
          }
          value = s.substring(vStart, i);
          if (i < n) i++; // 吃掉闭合引号
        } else {
          final vStart = i;
          while (i < n &&
              s.codeUnitAt(i) != 0x20 &&
              s[i] != '\t' &&
              s[i] != '\n' &&
              s[i] != '\r') {
            i++;
          }
          value = s.substring(vStart, i);
        }
      }
      attrs[name] = decodeHtmlEntities(value);
    }
    return attrs;
  }

  /// 查找原文元素的闭合标签位置（`</tag` 的 '<' 位置）。
  ///
  /// 用 indexOf 而非正则+substring：避免每个 script/style 块拷贝一次
  /// 文档剩余部分（MB 级页面 × 多脚本块时是 O(n·k) 拷贝）。
  /// 大小写：URP 页面闭合标签恒为小写；找不到小写形式时再做不区分
  /// 大小写的正则兜底（罕见路径）。
  static int _findRawClose(String html, int from, String tag) {
    var idx = html.indexOf('</$tag', from);
    if (idx >= 0) return idx;
    final m = RegExp('</$tag\\s*>', caseSensitive: false)
        .firstMatch(html.substring(from));
    return m == null ? html.length : from + m.start;
  }
}
