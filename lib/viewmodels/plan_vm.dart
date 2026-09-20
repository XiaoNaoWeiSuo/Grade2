/// 培养计划 ViewModel —— 并行拉取四块数据并在单个 Provider 内按子视图分装。
///
/// 数据：
/// ```text
/// planProvider (AsyncNotifier<PlanData>)
///   ├─ 完成度   planCompletion()  → {summary, sections, records, count, file}
///   ├─ 我的计划  planByMajor()    → {tables, file}
///   ├─ 培养方案  majorPlan()      → {tables,file} 或 {error,file}（无权限）
///   └─ 转专业    stdApply()       → {message, menus, text, file}
/// ```
/// build() 内用 Future.wait 并行拉取；每条独立捕 on CrawlerException 转为
/// AsyncError，互不拖垮对方。未登录时四块统一 AsyncError(SessionLost)。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crawler/api/eams_api.dart';
import '../core/crawler/crawler_exceptions.dart';
import '../core/crawler/session/crawler_session.dart';
import 'providers.dart';

/// 培养计划四块数据容器（每块独立异步状态，便于各子视图用 AsyncSliver 渲染）。
class PlanData {
  const PlanData({
    required this.completion,
    required this.byMajor,
    required this.major,
    required this.stdApply,
  });

  /// 完成度：`{summary, sections, records, count}`。
  final AsyncValue<Map<String, Object?>> completion;

  /// 我的计划：`{tables}`。
  final AsyncValue<Map<String, Object?>> byMajor;

  /// 培养方案：`{tables}` 或 `{error}`（无权限）。
  final AsyncValue<Map<String, Object?>> major;

  /// 转专业申请：`{message, menus, text}`。
  final AsyncValue<Map<String, Object?>> stdApply;
}

class PlanController extends AsyncNotifier<PlanData> {
  @override
  Future<PlanData> build() => _load();

  /// 整页下拉刷新：并联重拉四块。
  Future<void> refresh() async {
    state = const AsyncLoading<PlanData>().copyWithPrevious(state);
    try {
      state = AsyncData(await _load());
    } on CrawlerException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  // ---------------- 内部 ----------------

  Future<PlanData> _load() async {
    final session = ref.watch(crawlerSessionProvider);
    if (session == null) {
      return _errorAll(const SessionLost('未登录'));
    }
    // 并行拉取四块；单块失败不影响其余
    final results = await Future.wait([
      _fetch(session, (api) => api.planCompletion()),
      _fetch(session, (api) => api.planByMajor()),
      _fetch(session, (api) => api.majorPlan()),
      _fetch(session, (api) => api.stdApply()),
    ]);
    return PlanData(
      completion: results[0],
      byMajor: results[1],
      major: results[2],
      stdApply: results[3],
    );
  }

  Future<AsyncValue<Map<String, Object?>>> _fetch(
    CrawlerSession session,
    Future<Map<String, Object?>> Function(EamsApi api) fn,
  ) async {
    try {
      return AsyncData(await session.withApi(fn));
    } on CrawlerException catch (e) {
      return AsyncError<Map<String, Object?>>(e, StackTrace.current);
    }
  }

  PlanData _errorAll(CrawlerException e) {
    final er = AsyncError<Map<String, Object?>>(e, StackTrace.current);
    return PlanData(completion: er, byMajor: er, major: er, stdApply: er);
  }
}

/// 培养计划 Provider（登录/登出随 session 变化自动重建）。
final planProvider =
    AsyncNotifierProvider<PlanController, PlanData>(PlanController.new);