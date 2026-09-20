/// 教学评价 ViewModel —— 缓存优先 + 在线拉取。
///
/// 数据流：
/// ```text
/// build()
///   ├─ 本地缓存命中(evaluate/evaluate_all) → 直接渲染(离线可用)
///   └─ 未命中/无缓存 → api.evaluate() → 写缓存(去掉 file) → 渲染
/// refresh() 强制在线刷新（绕过缓存，写回后更新状态，失败回落已有数据）
/// ```
/// 交互态：未登录抛 SessionLost，由 UI 层按 CrawlerException.message 提示。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crawler/crawler_exceptions.dart';
import '../core/crawler/session/crawler_session.dart';
import '../core/storage/local_cache.dart';
import 'providers.dart';

class EvaluateController extends AsyncNotifier<Map<String, Object?>?> {
  @override
  Future<Map<String, Object?>?> build() async {
    final cache = await ref.watch(localCacheProvider.future);

    // 1) 缓存优先（离线可用）
    final hit = await cache.read(_ns, _key);
    if (hit is Map<String, Object?>) return hit;

    // 2) 在线拉取
    final session = ref.watch(crawlerSessionProvider);
    if (session == null) {
      throw const SessionLost('未登录且无本地评教缓存');
    }
    return _fetch(cache, session);
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
      state = AsyncData(await _fetch(cache, session));
    } on CrawlerException catch (e) {
      // 回落已有数据（内存态优先于重新读盘）
      if (cur != null) {
        state = AsyncData(cur);
      } else {
        state = AsyncError(e, StackTrace.current);
      }
    }
  }

  // ---------------- 内部 ----------------

  static const _ns = 'evaluate';
  static const _key = 'evaluate_all';

  /// ⚠ session 参数必须是静态类型 CrawlerSession：dynamic 接收者调用泛型
  /// withApi 时闭包被推断为 (dynamic)→dynamic，运行时签名检查失败。
  Future<Map<String, Object?>> _fetch(
      LocalCache cache, CrawlerSession session) async {
    final raw = await session.withApi((api) => api.evaluate());
    raw.remove('file'); // 原始文件路径不入缓存
    await cache.write(_ns, _key, raw);
    return raw;
  }
}

/// 教学评价 Provider（全局保活；随 session 变化自动重建）。
final evaluateProvider =
    AsyncNotifierProvider<EvaluateController, Map<String, Object?>?>(
        EvaluateController.new);