// 外观设置（setting.json）：替代旧 MyImagePicker 直写文件 +
// MainPage 直读文件 + ResultObject 回传的组合。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/json_store.dart';
import '../data/models/app_settings.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  final JsonStore _store = JsonStore("setting.json");

  @override
  AppSettings build() => AppSettings.fromJson(const {});

  /// 启动时从 setting.json 加载（旧 MainPage initState 逻辑）
  Future<void> load() async {
    final map = await _store.read();
    if (map.isNotEmpty) {
      state = AppSettings.fromJson(map);
    }
  }

  /// 更新设置并持久化（替代旧 MyImagePicker writeCounter）
  Future<void> update(AppSettings settings) async {
    state = settings;
    await _store.write(settings.toJson());
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
