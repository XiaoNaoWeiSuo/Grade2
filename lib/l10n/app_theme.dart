/// 主题系统 —— 跟随系统 / 亮色 / 暗色 / 护眼 四模式。
///
/// - [AppThemeMode] 四模式枚举。
/// - [AppPalette] 每模式一组语义色板（背景/卡片/栏/文本/分隔/主色/辅助色）。
/// - [AppThemeScope] InheritedWidget，页面用 `AppThemeScope.of(context)` 取色板，
///   从而让硬编码颜色也随主题切换（亮/暗/护眼生效）。
/// - [buildTheme] 由色板产出 [CupertinoThemeData] 供 CupertinoApp 使用。
library;

import 'package:flutter/cupertino.dart';

/// 主题模式。
enum AppThemeMode { system, light, dark, eye }

/// 课程卡片专属配色代币（随主题模式自适应）。
class CourseColorToken {
  const CourseColorToken({
    required this.bg,
    required this.accent,
    required this.text,
  });

  /// 卡片背景色。
  final Color bg;

  /// 左侧边条/高亮强调色。
  final Color accent;

  /// 文字主色。
  final Color text;
}

/// 每模式语义色板（页面级取色来源）。
class AppPalette {
  const AppPalette({
    required this.bg,
    required this.card,
    required this.cardElevated,
    required this.bar,
    required this.label,
    required this.secondary,
    required this.tertiary,
    required this.separator,
    required this.border,
    required this.primary,
    required this.success,
    required this.warning,
    required this.destructive,
    required this.courseColors,
    required this.isDark,
  });

  /// 分组背景（页面底色）。
  final Color bg;

  /// 卡片/分组背景。
  final Color card;

  /// 浮层/弹窗卡片背景。
  final Color cardElevated;

  /// 导航栏背景。
  final Color bar;

  /// 主文本色。
  final Color label;

  /// 次级文本色。
  final Color secondary;

  /// 三级辅助文本/提示色。
  final Color tertiary;

  /// 分隔线色。
  final Color separator;

  /// 微弱边框色。
  final Color border;

  /// 主色（强调/按钮/选中）。
  final Color primary;

  /// 成功色（绿）。
  final Color success;

  /// 警示色（橙）。
  final Color warning;

  /// 危险/删除色（红）。
  final Color destructive;

  /// 课表格子颜色池。
  final List<CourseColorToken> courseColors;

  /// 是否为暗色环境。
  final bool isDark;

  /// 任意色的透明度变体。
  Color tint(Color c, double alpha) => c.withValues(alpha: alpha);

  /// 根据哈希取稳定的课程卡片配色。
  CourseColorToken courseTokenFor(int hash) {
    final idx = hash.abs() % courseColors.length;
    return courseColors[idx];
  }
}

const _lightCourseColors = [
  CourseColorToken(bg: Color(0xFFE8F1FC), accent: Color(0xFF007AFF), text: Color(0xFF0D47A1)),
  CourseColorToken(bg: Color(0xFFEDF7ED), accent: Color(0xFF34C759), text: Color(0xFF1B5E20)),
  CourseColorToken(bg: Color(0xFFFFF4E5), accent: Color(0xFFFF9500), text: Color(0xFFE65100)),
  CourseColorToken(bg: Color(0xFFF8EAF6), accent: Color(0xFFAF52DE), text: Color(0xFF4A148C)),
  CourseColorToken(bg: Color(0xFFE0F7FA), accent: Color(0xFF00BCD4), text: Color(0xFF006064)),
  CourseColorToken(bg: Color(0xFFFFEBEE), accent: Color(0xFFFF2D55), text: Color(0xFFB71C1C)),
  CourseColorToken(bg: Color(0xFFEDE7F6), accent: Color(0xFF5856D6), text: Color(0xFF311B92)),
  CourseColorToken(bg: Color(0xFFF1F8E9), accent: Color(0xFF8BC34A), text: Color(0xFF33691E)),
];

const _darkCourseColors = [
  CourseColorToken(bg: Color(0xFF102847), accent: Color(0xFF0A84FF), text: Color(0xFFE3F2FD)),
  CourseColorToken(bg: Color(0xFF14301B), accent: Color(0xFF30D158), text: Color(0xFFE8F5E9)),
  CourseColorToken(bg: Color(0xFF38230D), accent: Color(0xFFFF9F0A), text: Color(0xFFFFF3E0)),
  CourseColorToken(bg: Color(0xFF301533), accent: Color(0xFFBF5AF2), text: Color(0xFFF3E5F5)),
  CourseColorToken(bg: Color(0xFF0E2E33), accent: Color(0xFF64D2FF), text: Color(0xFFE0F7FA)),
  CourseColorToken(bg: Color(0xFF3B151A), accent: Color(0xFFFF375F), text: Color(0xFFFFEBEE)),
  CourseColorToken(bg: Color(0xFF231A3D), accent: Color(0xFF5E5CE6), text: Color(0xFFEDE7F6)),
  CourseColorToken(bg: Color(0xFF1F2B14), accent: Color(0xFF98E244), text: Color(0xFFF1F8E9)),
];

const _eyeCourseColors = [
  CourseColorToken(bg: Color(0xFFE4EDE0), accent: Color(0xFF6F8F5A), text: Color(0xFF2C451D)),
  CourseColorToken(bg: Color(0xFFF0E8D5), accent: Color(0xFFBA8E48), text: Color(0xFF594017)),
  CourseColorToken(bg: Color(0xFFE2E7ED), accent: Color(0xFF628099), text: Color(0xFF203B52)),
  CourseColorToken(bg: Color(0xFFEFE2DC), accent: Color(0xFFB37365), text: Color(0xFF5C2920)),
  CourseColorToken(bg: Color(0xFFE8E5DA), accent: Color(0xFF8C866D), text: Color(0xFF3F3A27)),
  CourseColorToken(bg: Color(0xFFDFEAE8), accent: Color(0xFF5A8E89), text: Color(0xFF1E4844)),
  CourseColorToken(bg: Color(0xFFEAE3EB), accent: Color(0xFF967699), text: Color(0xFF4C2F4F)),
  CourseColorToken(bg: Color(0xFFE8EBDF), accent: Color(0xFF7E8A5E), text: Color(0xFF37401F)),
];

const _light = AppPalette(
  bg: Color(0xFFF2F2F7),
  card: Color(0xFFFFFFFF),
  cardElevated: Color(0xFFFFFFFF),
  bar: Color(0xF0F9F9F9),
  label: Color(0xFF000000),
  secondary: Color(0xFF8E8E93),
  tertiary: Color(0xFFC7C7CC),
  separator: Color(0xFFC6C6C8),
  border: Color(0x1F000000),
  primary: Color(0xFF007AFF),
  success: Color(0xFF34C759),
  warning: Color(0xFFFF9500),
  destructive: Color(0xFFFF3B30),
  courseColors: _lightCourseColors,
  isDark: false,
);

const _dark = AppPalette(
  bg: Color(0xFF000000),
  card: Color(0xFF1C1C1E),
  cardElevated: Color(0xFF2C2C2E),
  bar: Color(0xF01C1C1E),
  label: Color(0xFFFFFFFF),
  secondary: Color(0xFF8E8E93),
  tertiary: Color(0xFF48484A),
  separator: Color(0xFF38383A),
  border: Color(0x28FFFFFF),
  primary: Color(0xFF0A84FF),
  success: Color(0xFF30D158),
  warning: Color(0xFFFF9F0A),
  destructive: Color(0xFFFF453A),
  courseColors: _darkCourseColors,
  isDark: true,
);

/// 护眼（暖色调、低蓝光）：奶油底 + 鼠尾草绿主色。
const _eye = AppPalette(
  bg: Color(0xFFF3EFE2),
  card: Color(0xFFFCF9EF),
  cardElevated: Color(0xFFFFFFFF),
  bar: Color(0xF0F7F3E7),
  label: Color(0xFF3A3931),
  secondary: Color(0xFF8A8472),
  tertiary: Color(0xFFB5AE9C),
  separator: Color(0xFFDCD5C0),
  border: Color(0x1F3A3931),
  primary: Color(0xFF6F8F5A),
  success: Color(0xFF5A8E5C),
  warning: Color(0xFFC77B39),
  destructive: Color(0xFFC9544E),
  courseColors: _eyeCourseColors,
  isDark: false,
);

/// 取当前模式色板（system 依平台亮度落到亮/暗）。
AppPalette paletteFor(AppThemeMode mode, Brightness platform) {
  switch (mode) {
    case AppThemeMode.system:
      return platform == Brightness.dark ? _dark : _light;
    case AppThemeMode.light:
      return _light;
    case AppThemeMode.dark:
      return _dark;
    case AppThemeMode.eye:
      return _eye;
  }
}

Brightness brightnessFor(AppThemeMode mode, Brightness platform) {
  switch (mode) {
    case AppThemeMode.system:
      return platform;
    case AppThemeMode.light:
    case AppThemeMode.eye:
      return Brightness.light;
    case AppThemeMode.dark:
      return Brightness.dark;
  }
}

/// 由色板产出 Cupertino 主题。
CupertinoThemeData buildTheme(AppPalette p, Brightness brightness) {
  final labelColor = p.label;
  return CupertinoThemeData(
    brightness: brightness,
    primaryColor: p.primary,
    primaryContrastingColor: CupertinoColors.white,
    scaffoldBackgroundColor: p.bg,
    barBackgroundColor: p.bar,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(
        color: labelColor,
        fontSize: 17,
        letterSpacing: -0.4,
      ),
      actionTextStyle: TextStyle(
        color: p.primary,
        fontSize: 17,
        letterSpacing: -0.4,
        fontWeight: FontWeight.w600,
      ),
      navTitleTextStyle: TextStyle(
        color: labelColor,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      navLargeTitleTextStyle: TextStyle(
        color: labelColor,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      primaryColor: p.primary,
    ),
  );
}

/// 主题作用域：向下提供色板，供任意页面取色。
class AppThemeScope extends InheritedWidget {
  const AppThemeScope({super.key, required this.palette, required super.child});

  final AppPalette palette;

  static AppPalette of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppThemeScope>()!.palette;

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) =>
      oldWidget.palette != palette;
}
