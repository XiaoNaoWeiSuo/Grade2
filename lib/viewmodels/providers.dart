/// 全局 Provider 组装层（MVVM 的"组装根"）。
///
/// 依赖注入约定：
/// - 文件路径只在组装层定位（path_provider），内核层零 Flutter 依赖
/// - 业务 Viewmodel 一律不直接 new 内核对象，而是从本文件读取
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../core/crawler/models/config_models.dart';
import '../core/crawler/session/crawler_session.dart';
import '../core/storage/local_cache.dart';
import 'auth_vm.dart';

/// 密码安全存储（Keychain / Android Keystore）。账号簿密码不再明文落盘。
final secureStorageProvider = Provider<FlutterSecureStorage>(
    (ref) => const FlutterSecureStorage());

/// 本地缓存（LocalCache 单例）。
final localCacheProvider = FutureProvider<LocalCache>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return LocalCache(baseDir: '${dir.path}/grade2_cache');
});

/// 爬虫会话状态落盘路径（cookie/令牌，与业务缓存分开）。
final sessionStatePathProvider = FutureProvider<String>((ref) async {
  final dir = await getApplicationSupportDirectory();
  return '${dir.path}/crawler_state.json';
});

/// 当前已建立的爬虫会话（未登录为 null）。
///
/// 从 auth 状态中提取，避免各业务 Viewmodel 依赖整个 AuthState。
final crawlerSessionProvider = Provider<CrawlerSession?>((ref) {
  return ref.watch(authProvider).value?.session;
});

/// 爬虫全局配置（工程期固定默认值；正式版可改为从设置页读取）。
final grabberConfigProvider =
    Provider<GrabberConfig>((ref) => const GrabberConfig());

/// 任意对象 → 缩进 JSON 文本（调试/工具页展示用）。
String prettyJson(Object? v) =>
    const JsonEncoder.withIndent('  ').convert(v);
