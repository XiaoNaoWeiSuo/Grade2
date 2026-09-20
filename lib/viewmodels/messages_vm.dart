/// 系统消息 ViewModel —— 缓存优先（离线可用）+ 在线拉取。
///
/// 数据流：
/// ```text
/// build()
///   ├─ 本地缓存命中(messages/list) → 直接渲染(离线可用)
///   └─ 未命中 → session.withApi(messages) → 写缓存 → 渲染
/// refresh() 强制在线刷新（绕过缓存，写回后更新；失败回落已有数据）
/// ```
/// 记录常见键：『发件人』『主题』『时间』（可能含 _links），取值时容错空。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crawler/crawler_exceptions.dart';
import '../core/storage/local_cache.dart';
import 'providers.dart';

class MessagesController extends AsyncNotifier<Map<String, Object?>?> {
  static const _ns = 'messages';
  static const _key = 'list';

  @override
  Future<Map<String, Object?>?> build() async {
    final cache = await ref.watch(localCacheProvider.future);

    // 1) 缓存优先（离线可用）
    final hit = await cache.read(_ns, _key);
    if (hit is Map<String, Object?>) return hit;

    // 2) 在线拉取
    final session = ref.watch(crawlerSessionProvider);
    if (session == null) throw const SessionLost('未登录且无本地消息缓存');
    final raw = await session.withApi((api) => api.messages());
    await _persist(cache, raw);
    return raw;
  }

  /// 强制在线刷新（绕过缓存）；失败回落已有数据。
  Future<void> refresh() async {
    final cache = await ref.read(localCacheProvider.future);
    final session = ref.read(crawlerSessionProvider);
    if (session == null) {
      state = AsyncError(const SessionLost('未登录'), StackTrace.current);
      return;
    }
    final cur = state.value;
    state = const AsyncLoading<Map<String, Object?>?>()
        .copyWithPrevious(state);
    try {
      final raw = await session.withApi((api) => api.messages());
      await _persist(cache, raw);
      state = AsyncData(raw);
    } on CrawlerException catch (e) {
      state = cur != null
          ? AsyncData(cur)
          : AsyncError(e, StackTrace.current);
    }
  }

  // ---------------- 内部 ----------------

  Future<void> _persist(LocalCache cache, Map<String, Object?> raw) async {
    raw.remove('file'); // 原始文件路径不入缓存
    await cache.write(_ns, _key, raw);
  }
}

/// 系统消息 Provider（登录/登出随 session 变化自动重建）。
final messagesProvider =
    AsyncNotifierProvider<MessagesController, Map<String, Object?>?>(
        MessagesController.new);