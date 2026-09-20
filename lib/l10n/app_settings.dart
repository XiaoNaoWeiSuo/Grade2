/// 应用设置 —— 语言 + 主题模式（持久化到 LocalCache ns=meta）。
///
/// - [settingsControllerProvider]：Notifier of [AppSettings]，`load()` 启动时从缓存
///   读取，`setTheme`/`setLocale` 更新并落盘。
/// - main 通过 [appSettingsProvider] 读取生效值。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/providers.dart';
import 'app_strings.dart';
import 'app_theme.dart';

class AppSettings {
  const AppSettings({
    this.theme = AppThemeMode.system,
    this.locale = const AppLocale('zh-Hans', '简体中文'),
  });

  final AppThemeMode theme;
  final AppLocale locale;

  AppSettings copyWith({AppThemeMode? theme, AppLocale? locale}) =>
      AppSettings(theme: theme ?? this.theme, locale: locale ?? this.locale);
}

class SettingsController extends Notifier<AppSettings> {
  static const _ns = 'meta';
  static const _keyTheme = 'theme';
  static const _keyLocale = 'locale';

  @override
  AppSettings build() => const AppSettings();

  /// 从本地缓存载入持久化的语言/主题（幂等，main 启动时调用）。
  Future<void> load() async {
    final cache = await ref.read(localCacheProvider.future);
    final themeName = await cache.readAs<String>(_ns, _keyTheme, '');
    final localeCode = await cache.readAs<String>(_ns, _keyLocale, '');
    final theme = AppThemeMode.values.asNameMap()[themeName];
    AppLocale? locale;
    for (final l in supportedAppLocales) {
      if (l.code == localeCode) {
        locale = l;
        break;
      }
    }
    if (theme != null || locale != null) {
      state = AppSettings(
        theme: theme ?? state.theme,
        locale: locale ?? state.locale,
      );
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = state.copyWith(theme: mode);
    final cache = await ref.read(localCacheProvider.future);
    await cache.write(_ns, _keyTheme, mode.name);
  }

  Future<void> setLocale(AppLocale locale) async {
    state = state.copyWith(locale: locale);
    final cache = await ref.read(localCacheProvider.future);
    await cache.write(_ns, _keyLocale, locale.code);
  }
}

/// 应用设置 Provider（全局）。
final appSettingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
