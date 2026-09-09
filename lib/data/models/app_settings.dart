// 新建的 setting.json 类型化设置模型（MVVM 重构）。
// 键名与旧代码读写格式完全一致（lib/tree/pages.dart MyImagePicker、lib/main.dart L1411-1425）：
// 颜色以 Color.value 的 hex 字符串（无 0x 前缀）存储，布尔以 "true"/"false" 字符串存储，保证旧数据兼容。

import 'dart:ui';

/// setting.json 类型化设置模型（键：weekbarcolor/timebarcolor/bgcolor/classimage/itemcolorstate/blur）
class AppSettings {
  /// 日期栏颜色（键 weekbarcolor）
  final Color dateColor;

  /// 时间栏颜色（键 timebarcolor）
  final Color timeColor;

  /// 背景色（键 bgcolor）
  final Color bgColor;

  /// 课程表背景图路径（键 classimage，空字符串表示未设置）
  final String classImage;

  /// 条目颜色开关（键 itemcolorstate）
  final bool itemColorState;

  /// 背景模糊开关（键 blur）
  final bool blur;

  const AppSettings({
    required this.dateColor,
    required this.timeColor,
    required this.bgColor,
    this.classImage = "",
    this.itemColorState = false,
    this.blur = false,
  });

  static const Color _defaultDateColor = Color.fromARGB(255, 0, 0, 0);
  static const Color _defaultTimeColor = Color.fromARGB(255, 2, 32, 45);
  static final Color _defaultBgColor =
      const Color.fromARGB(255, 171, 232, 255).withValues(alpha: 0.6);

  /// 键缺失/非法时使用旧代码的默认值
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    Color parseColor(dynamic raw, Color fallback) {
      if (raw is String && raw.isNotEmpty) {
        final int? value = int.tryParse(raw, radix: 16);
        if (value != null) {
          return Color(value);
        }
      }
      return fallback;
    }

    return AppSettings(
      dateColor: parseColor(json['weekbarcolor'], _defaultDateColor),
      timeColor: parseColor(json['timebarcolor'], _defaultTimeColor),
      bgColor: parseColor(json['bgcolor'], _defaultBgColor),
      classImage: (json['classimage'] as String?) ?? "",
      itemColorState: json['itemcolorstate'] == "true",
      blur: json['blur'] == "true",
    );
  }

  /// 键名与存储格式与旧代码完全一致（hex 字符串 / "true"/"false"）
  Map<String, dynamic> toJson() {
    return {
      'weekbarcolor': dateColor.toARGB32().toRadixString(16),
      'timebarcolor': timeColor.toARGB32().toRadixString(16),
      'bgcolor': bgColor.toARGB32().toRadixString(16),
      'classimage': classImage,
      'itemcolorstate': itemColorState.toString(),
      'blur': blur.toString(),
    };
  }
}
