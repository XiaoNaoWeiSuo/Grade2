import 'package:flutter/widgets.dart';

/// 日文排版风格的垂直文字组件（縦書き · Tategaki）。
///
/// 特性：
/// 1. 文字由上至下书写（纵向）。
/// 2. 多列文字依照传统东方/日文排版规范从右至左推进（[TextDirection.rtl]）。
/// 3. 自动将横排括号、书名号映射为正统 CJK 竖排专用字形（如 `(` 映射为 `︵`，`)` 映射为 `︶`）。
/// 4. 紧凑排印，提升竖直长方形卡片的信息密度与可读性。
class TategakiText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int maxCharsPerColumn;
  final int maxColumns;
  final double columnSpacing;

  const TategakiText({
    super.key,
    required this.text,
    required this.style,
    this.maxCharsPerColumn = 6,
    this.maxColumns = 3,
    this.columnSpacing = 2.0,
  });

  /// 将横排标点符号转换为标准 CJK 竖排表示形式 (Unicode 竖排标点区 \uFE30-\uFE4F)
  static String convertToVerticalGlyphs(String input) {
    final sb = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      switch (char) {
        case '(':
        case '（':
          sb.write('\uFE35'); // ︵
          break;
        case ')':
        case '）':
          sb.write('\uFE36'); // ︶
          break;
        case '[':
        case '【':
          sb.write('\uFE3F'); // ︻
          break;
        case ']':
        case '】':
          sb.write('\uFE40'); // ︼
          break;
        case '{':
        case '｛':
          sb.write('\uFE37'); // ︷
          break;
        case '}':
        case '｝':
          sb.write('\uFE38'); // ︸
          break;
        case '<':
        case '《':
          sb.write('\uFE3D'); // ︽
          break;
        case '>':
        case '》':
          sb.write('\uFE3E'); // ︾
          break;
        case '—':
        case '一':
          // 破折号在竖排中为垂直贯穿线
          sb.write(char == '—' ? '\uFE31' : char);
          break;
        case '…':
          sb.write('\uFE19'); // ︙
          break;
        default:
          sb.write(char);
      }
    }
    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    final clean = convertToVerticalGlyphs(text.trim());
    if (clean.isEmpty) return const SizedBox.shrink();

    // 智能分列算法：平衡各列字符数，避免末列仅留单字
    final totalLen = clean.length;
    final int charsPerCol;
    if (totalLen <= maxCharsPerColumn) {
      charsPerCol = totalLen;
    } else {
      // 若总长超出，尽量均匀分摊在 2 或 3 列
      final neededCols = (totalLen / maxCharsPerColumn).ceil().clamp(1, maxColumns);
      charsPerCol = (totalLen / neededCols).ceil().clamp(3, maxCharsPerColumn);
    }

    final columns = <List<String>>[];
    var start = 0;
    while (start < clean.length && columns.length < maxColumns) {
      var end = (start + charsPerCol).clamp(0, clean.length);
      // 若为最后一列且剩余字符过多，末尾截断以省号替代
      if (columns.length == maxColumns - 1 && end < clean.length) {
        final sub = '${clean.substring(start, end - 1)}…';
        columns.add(sub.runes.map((r) => String.fromCharCode(r)).toList());
        break;
      }
      final sub = clean.substring(start, end);
      columns.add(sub.runes.map((r) => String.fromCharCode(r)).toList());
      start = end;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl, // 关键：日文与东方排版行进方向为由右至左
      children: [
        for (var cIdx = 0; cIdx < columns.length; cIdx++) ...[
          if (cIdx > 0) SizedBox(width: columnSpacing),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final char in columns[cIdx])
                Text(
                  char,
                  style: style,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
