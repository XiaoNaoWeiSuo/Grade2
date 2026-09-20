/// 主题系统 —— 跟随系统 / 亮色 / 暗色 / 护眼 四模式。
///
/// - [AppThemeMode] 四模式枚举。
/// - [AppPalette] 每模式一组语义色板（背景/卡片/栏/文本/分隔/主色）。
/// - [AppThemeScope] InheritedWidget，页面用 `AppThemeScope.of(context)` 取色板，
///   从而让硬编码颜色也随主题切换（亮/暗/护眼生效）。
/// - [buildTheme] 由色板产出 [CupertinoThemeData] 供 CupertinoApp 使用。
library;

import 'package:flutter/cupertino.dart';

/// 主题模式。
enum AppThemeMode { system, light, dark, eye }

/// 每模式语义色板（页面级取色来源）。
class AppPalette {
  const AppPalette({
    required this.bg,
    required this.card,
    required this.bar,
    required this.label,
    required this.secondary,
    required this.separator,
    required this.primary,
  });

  /// 分组背景（页面底色）。
  final Color bg;

  /// 卡片/分组背景。
  final Color card;

  /// 导航栏背景。
  final Color bar;

  /// 主文本色。
  final Color label;

  /// 次级文本色。
  final Color secondary;

  /// 分隔线色。
  final Color separator;

  /// 主色（强调/按钮/选中）。
  final Color primary;

  /// 任意色的透明度变体。
  Color tint(Color c, double alpha) => c.withValues(alpha: alpha);
}

const _light = AppPalette(
  bg: Color(0xFFF2F2F7),
  card: Color(0xFFFFFFFF),
  bar: Color(0xFFF9F9F9),
  label: Color(0xFF000000),
  secondary: Color(0xFF8E8E93),
  separator: Color(0xFFC6C6C8),
  primary: Color(0xFF007AFF),
);

const _dark = AppPalette(
  bg: Color(0xFF000000),
  card: Color(0xFF1C1C1E),
  bar: Color(0xFF1C1C1E),
  label: Color(0xFFFFFFFF),
  secondary: Color(0xFF8E8E93),
  separator: Color(0xFF38383A),
  primary: Color(0xFF0A84FF),
);

/// 护眼（暖色调、低蓝光）：奶油底 + 鼠尾草绿主色。
const _eye = AppPalette(
  bg: Color(0xFFF3EFE2),
  card: Color(0xFFFCF9EF),
  bar: Color(0xFFF7F3E7),
  label: Color(0xFF3A3931),
  secondary: Color(0xFF8A8472),
  separator: Color(0xFFDCD5C0),
  primary: Color(0xFF6F8F5A),
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
      textStyle: TextStyle(color: labelColor, fontSize: 17),
      actionTextStyle: TextStyle(color: p.primary, fontSize: 17),
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
