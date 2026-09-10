/// 表格流式挖掘器（对应 grabber/api/clean.py 的 TableMiner 及配套函数）。
///
/// 基于 [HtmlSaxParser]（纯 Dart）实现，容错优于正则配平。
///
/// 数据结构（原生 Map/List）：
/// ```text
/// 单元格 cell = {
///   "tag": "td"|"th", "attrs": {..}, "text": "清洗后文本",
///   "links": [{"href": "..", "text": "..", "col"?: ..}],
///   "images": [{"src","alt","title"}],
///   "span": null|"row"|"col",   // rowspan/colspan 网格展开占位标记
///   "colspan": 1, "rowspan": 1
/// }
/// 表格 table = {
///   "id","class","title","caption",
///   "header_rows": [[cell..]..], "headers": [首行表头文本..],
///   "rows": [[cell..]..], "n_rows", "n_cols", "empty"
/// }
/// ```
library;

import 'clean.dart';
import 'html_sax.dart';

typedef CellMap = Map<String, Object?>;
typedef RowList = List<CellMap>;
typedef TableMap = Map<String, Object?>;

/// 表格挖掘器：`parse(html)` 后从 [tables] 取结果。
class TableMiner {
  final List<TableMap> tables = [];

  final List<_TableState> _tstack = [];
  CellMap? _cell;
  CellMap? _link;
  List<String>? _caption;
  List<String>? _heading; // 待关联到下一张表的前置标题

  late final HtmlSaxParser _parser = HtmlSaxParser(
    onStartTag: _startTag,
    onEndTag: _endTag,
    onData: _data,
  );

  void parse(String html) => _parser.parse(html);

  // ---------------- SAX 事件 ----------------

  void _startTag(String tag, Map<String, String> attrs) {
    if (tag == 'table') {
      var title = '';
      if (_heading != null) {
        // 消费前置标题
        title = cleanWs(_heading!.join());
        _heading = null;
      }
      _tstack.add(_TableState(attrs, title));
      return;
    }
    if (_tstack.isEmpty) {
      // 表外：只关心标题（h1-h4/legend/bold div）
      if (tag == 'h1' || tag == 'h2' || tag == 'h3' || tag == 'h4' || tag == 'legend') {
        _heading = [];
      } else if (tag == 'div' &&
          (attrs['style'] ?? '')
              .replaceAll(' ', '')
              .contains('font-weight:bold')) {
        _heading = [];
      }
      return;
    }
    final t = _tstack.last;
    switch (tag) {
      case 'tr':
        _openRow(t);
      case 'td' || 'th':
        _openCell(t, tag, attrs);
      case 'caption':
        _caption = [];
      case 'thead':
        t.thead = true;
      case 'tbody':
        t.thead = false;
      case 'a':
        if (_cell != null) {
          _link = {'href': attrs['href'] ?? '', 'text': ''};
        }
      case 'img':
        if (_cell != null) {
          // 与 Python setdefault 语义一致：仅出现 img 时才创建 images 键
          (_cell!.putIfAbsent('images', () => <CellMap>[]) as List<CellMap>)
              .add({
            'src': attrs['src'] ?? '',
            'alt': attrs['alt'] ?? '',
            'title': attrs['title'] ?? '',
          });
        }
    }
  }

  void _endTag(String tag) {
    if (tag == 'table' && _tstack.isNotEmpty) {
      _closeTable();
      return;
    }
    if (_tstack.isEmpty) return;
    final t = _tstack.last;
    switch (tag) {
      case 'td' || 'th':
        _closeCell(t);
      case 'tr':
        _closeRow(t);
      case 'thead':
        t.thead = false;
      case 'caption':
        if (_caption != null) {
          t.caption = cleanWs(_caption!.join());
          _caption = null;
        }
      case 'a':
        if (_link != null) {
          if (_cell != null) {
            (_cell!['links'] as List<CellMap>).add(_link!);
          }
          _link = null;
        }
    }
  }

  void _data(String data) {
    _caption?.add(data);
    _link?['text'] = (_link!['text'] as String) + data;
    _cell?['text'] = (_cell!['text'] as String) + data;
    _heading?.add(data);
  }

  // ---------------- 行/单元格/表格收口（1:1 对应 Python 私有方法） ----------------

  void _openRow(_TableState t) {
    _closeCell(t);
    _closeRow(t);
    final row = <CellMap>[];
    t.row = row;
    var col = 0;
    // 跨行占位：继承源值并打标
    while (t.spans.containsKey(col)) {
      final entry = t.spans[col]!;
      final rem = entry[0] as int;
      final cell = entry[1] as CellMap;
      row.add({...cell, 'span': 'row'});
      if (rem - 1 <= 0) {
        t.spans.remove(col);
      } else {
        t.spans[col] = [rem - 1, cell];
      }
      col++;
    }
    t.col = col;
  }

  void _closeRow(_TableState t) {
    final row = t.row;
    t.row = null;
    if (row == null) return;
    t.col = 0;
    if (row.any((c) => (c['text'] as String).isNotEmpty)) {
      (t.thead ? t.headerRows : t.rows).add(row);
    }
  }

  void _openCell(_TableState t, String tag, Map<String, String> attrs) {
    _closeCell(t);
    if (t.row == null) _openRow(t);
    _cell = {
      'tag': tag,
      'attrs': attrs,
      'text': '',
      'links': <CellMap>[],
      'span': null,
      'colspan': _spanOr(attrs['colspan']),
      'rowspan': _spanOr(attrs['rowspan']),
    };
  }

  void _closeCell(_TableState t) {
    final cell = _cell;
    _cell = null;
    if (cell == null) return;
    final row = t.row;
    if (row == null) return;
    cell['text'] = cleanWs(cell['text'] as String);
    row.add(cell);
    final colspan = cell['colspan'] as int;
    for (var k = 0; k < colspan - 1; k++) {
      row.add({...cell, 'span': 'col'}); // 跨列占位
    }
    final rowspan = cell['rowspan'] as int;
    if (rowspan > 1) {
      for (var k = 0; k < colspan; k++) {
        t.spans[t.col + k] = [rowspan - 1, cell]; // 登记跨行
      }
    }
    t.col += colspan;
  }

  void _closeTable() {
    final t = _tstack.removeLast();
    _closeCell(t);
    _closeRow(t);
    tables.add(t.toMap());
  }

  static int _spanOr(String? s) {
    final v = int.tryParse((s ?? '').trim());
    if (v == null || v < 1) return 1;
    return v;
  }
}

/// 解析中的表格状态。
class _TableState {
  _TableState(this.attrs, this.title);

  final Map<String, String> attrs;
  final String title;
  String caption = '';
  final List<RowList> headerRows = [];
  final List<RowList> rows = [];
  bool thead = false;

  RowList? row;
  int col = 0;
  final Map<int, List<Object>> spans = {}; // col → [剩余行数, 源cell]

  TableMap toMap() {
    final all = [...headerRows, ...rows];
    return {
      'id': attrs['id'] ?? '',
      'class': attrs['class'] ?? '',
      'title': title,
      'caption': caption,
      'header_rows': headerRows,
      'headers': headerRows.isNotEmpty
          ? [for (final c in headerRows.first) c['text'] as String]
          : <String>[],
      'rows': rows,
      'n_rows': rows.length,
      'n_cols': all.fold<int>(0, (m, r) => r.length > m ? r.length : m),
      'empty': rows.isEmpty && headerRows.isEmpty,
    };
  }
}

// ---------------- 对外 API（模块级纯函数） ----------------

/// 提取页面全部表格（嵌套表独立产出，顺序 = 收口顺序），过滤空表。
List<TableMap> parseTables(String? html) {
  if (html == null || html.isEmpty) return [];
  final miner = TableMiner()..parse(html);
  return [for (final t in miner.tables) if (t['empty'] != true) t];
}

/// 按 class 关键字/表头/前置标题挑选第一张匹配的表格。
TableMap? pickTable(
  List<TableMap> tables, {
  String classKw = '',
  bool hasHeader = false,
  String titleKw = '',
}) {
  for (final t in tables) {
    if (classKw.isNotEmpty && !(t['class'] as String).contains(classKw)) {
      continue;
    }
    if (hasHeader && (t['headers'] as List).isEmpty) continue;
    if (titleKw.isNotEmpty &&
        !('${t['title']}${t['caption']}').contains(titleKw)) {
      continue;
    }
    return t;
  }
  return null;
}

/// 需要数值化的列名（成绩/学分等）。
final RegExp _numCol = RegExp(r'学分|绩点|成绩|分数|人数|上限|座位|序号|最终');

/// 表格 → 记录列表（`List<Map<String, Object?>>`）。
///
/// - 表头：thead 首行；无 thead 时可用 [headerRow] 指定数据首行为表头
/// - 值：单元格纯文本；列名命中 学分/绩点/成绩 等自动数值化（[autonum]）
/// - 单元格链接 → 记录级 `_links`: [{col, href, text}]
/// - 行内图片 → 记录级 `_images`
/// - 跨列组名行/唯一非空单元格行 → `{"_group": 文本}` 分组行
List<Map<String, Object?>> tableRecords(
  TableMap? table, {
  int? headerRow,
  bool autonum = true,
}) {
  if (table == null) return [];
  final headers = [for (final h in (table['headers'] as List)) h as String];
  var rows = List<RowList>.from(table['rows'] as List);
  if (headers.isEmpty &&
      headerRow != null &&
      rows.isNotEmpty &&
      headerRow >= 0 &&
      headerRow < rows.length) {
    headers.clear();
    headers.addAll([for (final c in rows[headerRow]) c['text'] as String]);
    rows = rows.sublist(headerRow + 1);
  }
  // 双行表头：第二行的子表头（如 1-8 学期数字）并入重复列名
  final hrRows = table['header_rows'] as List? ?? const [];
  final sub = hrRows.length > 1
      ? [for (final c in (hrRows[1] as List)) (c as CellMap)['text'] as String]
      : const <String>[];

  final records = <Map<String, Object?>>[];
  for (final row in rows) {
    final real = [for (final c in row) if (c['span'] == null) c];
    final realTexts = [
      for (final c in real)
        if ((c['text'] as String).isNotEmpty) c['text'] as String
    ];
    final head = row.isNotEmpty ? row.first : null;
    if (head != null &&
        (head['text'] as String).isNotEmpty &&
        (head['colspan'] as int) >= 2) {
      // 分组头行：跨列组名（其后可能带组级汇总，如 必修小计学分）
      final d = <String, Object?>{'_group': head['text']};
      var col = 0;
      for (final c in row) {
        if (identical(c, head)) {
          col += c['colspan'] as int;
          continue;
        }
        if (c['span'] != null) {
          col += 1;
          continue;
        }
        final key = _headerAt(headers, col);
        final text = c['text'] as String;
        if (text.isNotEmpty) {
          d[key] = _cellValue(text, key, autonum);
        }
        col += c['colspan'] as int;
      }
      records.add(d);
      continue;
    }
    if (real.length == 1 && realTexts.isNotEmpty) {
      records.add({'_group': realTexts.first});
      continue;
    }
    final d = <String, Object?>{};
    for (var i = 0; i < row.length; i++) {
      final c = row[i];
      var key = _headerAt(headers, i);
      if (d.containsKey(key)) {
        // 展开产生的重复列名 → 并子表头/加序号
        final s = i < sub.length ? sub[i].trim() : '';
        key = s.isNotEmpty ? '$key$s' : '$key#${i + 1}';
      }
      d[key] = _cellValue(c['text'] as String, key, autonum);
    }
    final links = <CellMap>[];
    for (var i = 0; i < row.length; i++) {
      final col = _headerAt(headers, i);
      for (final l in (row[i]['links'] as List)) {
        final lm = l as CellMap;
        if ((lm['href'] as String?)?.isNotEmpty == true) {
          links.add({...lm, 'col': col});
        }
      }
    }
    if (links.isNotEmpty) d['_links'] = links;
    final images = <CellMap>[
      for (final c in row)
        for (final img in ((c['images'] as List?) ?? const []))
          if (((img as CellMap)['src'] as String?)?.isNotEmpty == true) img
    ];
    if (images.isNotEmpty) d['_images'] = images;
    records.add(d);
  }
  return records;
}

String _headerAt(List<String> headers, int i) =>
    i < headers.length && headers[i].isNotEmpty ? headers[i] : 'col${i + 1}';

Object? _cellValue(String text, String key, bool autonum) =>
    autonum && _numCol.hasMatch(key) ? toNum(text) : text;

/// 页面全部 KV 信息表 → `[{"section": 名称, "kv": {…}}, …]`
///
/// - section 来源：表格前置标题(bold div/h*)、caption、表内 darkColumn 分组行
/// - 键：以冒号结尾的单元格；值：其后相邻单元格文本
/// - 单元格内图片（如学籍照片）→ kv["照片"] = src
List<Map<String, Object?>> kvTables(String html) {
  final out = <Map<String, Object?>>[];
  for (final t in parseTables(html)) {
    var section = ((t['title'] as String).isNotEmpty ? t['title'] : t['caption'])
        as String;
    var kv = <String, Object?>{};
    final allRows = <RowList>[
      ...(t['header_rows'] as List).cast<RowList>(),
      ...(t['rows'] as List).cast<RowList>(),
    ];
    for (final row in allRows) {
      final real = [for (final c in row) if (c['span'] == null) c];
      final realTexts = [
        for (final c in real)
          if ((c['text'] as String).isNotEmpty) c['text'] as String
      ];
      final first = real.isNotEmpty ? real.first : null;
      if (real.length == 1 &&
          first != null &&
          (((first['attrs'] as Map)['class'] as String?) ?? '')
              .contains('darkColumn')) {
        if (kv.isNotEmpty) {
          out.add({'section': section.isEmpty ? '(未命名)' : section, 'kv': kv});
          kv = {};
        }
        if (realTexts.isNotEmpty) section = realTexts.first;
        continue;
      }
      var i = 0;
      while (i + 1 < row.length) {
        final k = row[i]['text'] as String;
        if (k.isNotEmpty && (k.endsWith(':') || k.endsWith('：'))) {
          final v = row[i + 1];
          final key = stripChars(rstripChars(k, ':： '), ' ').trim();
          kv.putIfAbsent(key, () => v['text'] as String? ?? '');
          for (final l in (v['links'] as List)) {
            final lm = l as CellMap;
            if ((lm['href'] as String?)?.isNotEmpty == true) {
              kv.putIfAbsent('${key}_链接', () => lm['href'] as String);
            }
          }
          i += 2;
        } else {
          i += 1;
        }
      }
      // 行内图片（如学籍照片）统一捕获
      for (final c in row) {
        for (final img in ((c['images'] as List?) ?? const [])) {
          final src = (img as CellMap)['src'];
          if (src is String && src.isNotEmpty) {
            kv.putIfAbsent('照片', () => src);
          }
        }
      }
    }
    if (kv.isNotEmpty) {
      out.add({'section': section.isEmpty ? '(未命名)' : section, 'kv': kv});
    }
  }
  return out;
}
