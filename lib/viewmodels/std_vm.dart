/// 学籍信息 ViewModel —— 拉取学籍详细（多 section 分段 KV + 照片 URL）。
///
/// 数据形状（来自 [EamsApi.stdDetail]）：
/// ```text
/// stdDetailProvider (AsyncNotifier<Map<String,Object?>?>)
///   → {sections:[{section, kv}], photo:String(可空), kv:JsonMap, file}
/// ```
/// 未登录时 build() 抛 [SessionLost]（AsyncError 展示）。下拉/按钮刷新走 [refresh]
/// （copyWithPrevious 保留旧值平滑刷新）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crawler/crawler_exceptions.dart';
import 'providers.dart';

class StdDetailController extends AsyncNotifier<Map<String, Object?>?> {
  @override
  Future<Map<String, Object?>?> build() => _load();

  /// 下拉刷新 / 导航栏刷新按钮：保留旧值重拉。
  Future<void> refresh() async {
    state = const AsyncLoading<Map<String, Object?>?>()
        .copyWithPrevious(state);
    try {
      state = AsyncData(await _load());
    } on CrawlerException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<Map<String, Object?>?> _load() async {
    final session = ref.read(crawlerSessionProvider);
    if (session == null) {
      throw const SessionLost('未登录');
    }
    // ⚠ session 必须静态类型（dynamic 会使 withApi 闭包运行时签名检查失败）
    return session.withApi((api) => api.stdDetail());
  }
}

/// 学籍信息 Provider。
final stdDetailProvider =
    AsyncNotifierProvider<StdDetailController, Map<String, Object?>?>(
        StdDetailController.new);