/// 缓存管理 ViewModel —— LocalCache 的可视化/运维封装。
///
/// 提供命名空间枚举、条目增删改查、统计与清空，供缓存工具页直接绑定。
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/local_cache.dart';
import 'providers.dart';

/// 缓存工具状态。
class CacheState {
  const CacheState({
    this.namespaces = const [],
    this.dumps = const {},
    this.bytes = 0,
    this.entries = 0,
  });

  final List<String> namespaces;

  /// ns → {key → {v, exp}} 原始快照。
  final Map<String, Map<String, Object?>> dumps;
  final int bytes;
  final int entries;

  CacheState copyWith({
    List<String>? namespaces,
    Map<String, Map<String, Object?>>? dumps,
    int? bytes,
    int? entries,
  }) =>
      CacheState(
        namespaces: namespaces ?? this.namespaces,
        dumps: dumps ?? this.dumps,
        bytes: bytes ?? this.bytes,
        entries: entries ?? this.entries,
      );
}

class CacheController extends AsyncNotifier<CacheState> {
  @override
  Future<CacheState> build() => _snapshot();

  /// 重新扫描全部命名空间。
  Future<void> refresh() async {
    state = const AsyncLoading<CacheState>().copyWithPrevious(state);
    state = AsyncData(await _snapshot());
  }

  /// 删除单个键。
  Future<void> deleteKey(String ns, String key) async {
    await _cache().remove(ns, key);
    state = AsyncData(await _snapshot());
  }

  /// 清空命名空间。
  Future<void> clearNs(String ns) async {
    await _cache().clearNs(ns);
    state = AsyncData(await _snapshot());
  }

  /// 清空全部缓存。
  Future<void> clearAll() async {
    await _cache().clearAll();
    state = AsyncData(await _snapshot());
  }

  /// 写入/覆盖一个键（工具页"编辑 JSON"与"新增测试条目"共用）。
  ///
  /// [rawJson] 为 JSON 文本；解析失败返回错误文案（null = 成功）。
  Future<String?> writeJson(String ns, String key, String rawJson,
      {int? ttlSeconds}) async {
    Object? value;
    try {
      value = jsonDecode(rawJson);
    } on FormatException catch (e) {
      return 'JSON 解析失败: ${e.message}';
    }
    await _cache().write(ns, key, value, ttlSeconds: ttlSeconds);
    state = AsyncData(await _snapshot());
    return null;
  }

  /// 写入一个工程期演示条目（验证读写闭环）。
  Future<void> addDemoEntry() async {
    final ns = 'demo';
    final now = DateTime.now();
    await _cache().write(ns, '演示条目_${now.millisecondsSinceEpoch % 10000}', {
      'msg': 'LocalCache 读写闭环正常',
      'at': now.toIso8601String(),
      'list': [1, 2, 3],
    });
    state = AsyncData(await _snapshot());
  }

  // ---------------- 内部 ----------------

  LocalCache _cache() => ref.read(localCacheProvider).requireValue;

  Future<CacheState> _snapshot() async {
    final cache = _cache();
    final nss = await cache.namespaces();
    final dumps = <String, Map<String, Object?>>{};
    var bytes = 0;
    var entries = 0;
    for (final ns in nss) {
      final d = await cache.dump(ns);
      dumps[ns] = d;
      entries += d.length;
    }
    final st = await cache.stats();
    bytes = st['bytes'] as int? ?? 0;
    return CacheState(
        namespaces: nss, dumps: dumps, bytes: bytes, entries: entries);
  }
}

/// 缓存工具 Provider（全局保活）。
final cacheProvider =
    AsyncNotifierProvider<CacheController, CacheState>(CacheController.new);
