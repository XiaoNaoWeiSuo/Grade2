/// 欢迎页 ViewModel —— 教务首页（公告/新闻模块）。
///
/// 数据：EamsApi.welcome() → {modules:[{name, content}], welcome_text, file}。
/// 只读，缓存支持离线；提供 refresh() 强制在线。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crawler/crawler_exceptions.dart';
import '../core/crawler/session/crawler_session.dart';
import '../core/storage/local_cache.dart';
import 'providers.dart';

class WelcomeController extends AsyncNotifier<Map<String, Object?>> {
  static const _ns = 'welcome';
  static const _key = 'welcome';

  @override
  Future<Map<String, Object?>> build() async {
    final cache = await ref.watch(localCacheProvider.future);
    final hit = await cache.read(_ns, _key);
    if (hit is Map<String, Object?>) return hit;
    final session = ref.read(crawlerSessionProvider);
    if (session == null) throw const SessionLost('未登录且无本地欢迎页缓存');
    return _fetch(cache, session);
  }

  /// 强制在线刷新（绕过缓存；失败回落已有数据）。
  Future<void> refresh() async {
    final cur = state.value;
    state = const AsyncLoading<Map<String, Object?>>().copyWithPrevious(state);
    final cache = await ref.read(localCacheProvider.future);
    final session = ref.read(crawlerSessionProvider);
    if (session == null) {
      state = AsyncError(const SessionLost('未登录'), StackTrace.current);
      return;
    }
    try {
      state = AsyncData(await _fetch(cache, session));
    } on CrawlerException catch (e) {
      state = cur != null
          ? AsyncData(cur)
          : AsyncError(e, StackTrace.current);
    }
  }

  // ⚠ session 静态类型（dynamic 接收者会让 withApi 运行时签名检查失败）
  Future<Map<String, Object?>> _fetch(
      LocalCache cache, CrawlerSession session) async {
    final raw = await session.withApi((api) => api.welcome());
    raw.remove('file');
    await cache.write(_ns, _key, raw);
    return raw;
  }
}

/// 欢迎页 Provider。
final welcomeProvider =
    AsyncNotifierProvider<WelcomeController, Map<String, Object?>>(
        WelcomeController.new);
