/// 考试模块 ViewModel —— 批次选择 + 考试安排联动 + 课外考试(四六级) + 中期考核。
///
/// 结构：单 [AsyncNotifier]，state 内四个子 AsyncValue 分别承载
/// 批次/安排/其他/中期，彼此独立渲染各自 async 状态（错误互不影响）。
/// 请求均在同一 session 下以 withApi 顺序 await（降低触发频率）。
///
/// 数据流：
/// ```text
/// build()
///   ├─ examBatches()   → 批次列表（默认选中 selected==true 那个）
///   ├─ examTable(id)   → 当前批次考试安排（随批次切换联动重取）
///   ├─ otherExams()    → 报名/成绩两段
///   └─ midterm()       → 中期考核文本
/// refresh() 整体重取；selectBatch(id) 只联动重取安排；loadOthers/loadMidterm 单段刷新。
/// ```
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crawler/crawler_exceptions.dart';
import '../core/crawler/models/data_models.dart';
import '../core/crawler/session/crawler_session.dart';
import 'providers.dart';

import 'semester_vm.dart';

/// 考试模块状态（不可变）。
class ExamState {
  const ExamState({
    this.batches = const AsyncLoading(),
    this.selectedBatchId,
    this.table = const AsyncLoading(),
    this.others = const AsyncLoading(),
    this.midterm = const AsyncLoading(),
    this.semesterId,
  });

  /// 批次列表（JsonMap：{id, name, selected}）。
  final AsyncValue<List<JsonMap>> batches;
  final int? selectedBatchId;

  /// 当前批次考试安排（{batch_id, headers, records, count, file}）。
  final AsyncValue<JsonMap> table;

  /// 课外资格考试（{signups, scores, signup_count, score_count, file}）。
  final AsyncValue<JsonMap> others;

  /// 中期考核文本（{message, text, file} 的 text 字段）。
  final AsyncValue<JsonMap> midterm;

  /// 关联的学期 ID。
  final int? semesterId;

  ExamState copyWith({
    AsyncValue<List<JsonMap>>? batches,
    int? Function()? selectedBatchId,
    AsyncValue<JsonMap>? table,
    AsyncValue<JsonMap>? others,
    AsyncValue<JsonMap>? midterm,
    int? semesterId,
  }) {
    return ExamState(
      batches: batches ?? this.batches,
      selectedBatchId:
          selectedBatchId != null ? selectedBatchId() : this.selectedBatchId,
      table: table ?? this.table,
      others: others ?? this.others,
      midterm: midterm ?? this.midterm,
      semesterId: semesterId ?? this.semesterId,
    );
  }
}

class ExamController extends AsyncNotifier<ExamState> {
  @override
  Future<ExamState> build() async {
    final session = ref.watch(crawlerSessionProvider);
    if (session == null) {
      throw const SessionLost('未登录，无法加载考试数据');
    }
    // 监听全局学期选择，切换学期时自动重建
    final selection = await ref.watch(semesterSelectionProvider.future);
    return _loadAll(session, semesterId: selection.currentId);
  }

  /// 整页下拉刷新：全部重取（保留当前所选批次）。
  Future<void> refresh() async {
    final session = ref.read(crawlerSessionProvider);
    if (session == null) {
      final err = const SessionLost('未登录，无法刷新考试数据');
      state = AsyncError(err, StackTrace.current);
      return;
    }
    final kept = state.value;
    state = AsyncLoading<ExamState>().copyWithPrevious(state);
    try {
      final semId = kept?.semesterId ?? (await ref.read(semesterSelectionProvider.future)).currentId;
      state = AsyncData(await _loadAll(session, keepId: kept?.selectedBatchId, semesterId: semId));
    } on CrawlerException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// 切换批次：只联动重取「考试安排」。
  Future<void> selectBatch(int id) async {
    final cur = state.value;
    if (cur == null || id == cur.selectedBatchId) return;
    state = AsyncData(cur.copyWith(
      selectedBatchId: () => id,
      table: const AsyncLoading<JsonMap>(),
    ));
    final session = ref.read(crawlerSessionProvider);
    if (session == null) {
      state = AsyncData(cur.copyWith(
        selectedBatchId: () => id,
        table: AsyncError<JsonMap>(
            const SessionLost('未登录'), StackTrace.current),
      ));
      return;
    }
    try {
      final table = await session.withApi((api) => api.examTable(id));
      state = AsyncData(state.value!.copyWith(table: AsyncData(table)));
    } on CrawlerException catch (e) {
      state = AsyncData(state.value!.copyWith(
        selectedBatchId: () => id,
        table: AsyncError(e, StackTrace.current),
      ));
    }
  }

  /// 仅重取课外考试（四六级）。
  Future<void> loadOthers() async {
    final cur = state.value;
    if (cur == null) return;
    state = AsyncData(
        cur.copyWith(others: const AsyncLoading<JsonMap>()));
    final session = ref.read(crawlerSessionProvider);
    if (session == null) {
      state = AsyncData(cur.copyWith(
          others: AsyncError<JsonMap>(
              const SessionLost('未登录'), StackTrace.current)));
      return;
    }
    try {
      final others = await session.withApi((api) => api.otherExams());
      state = AsyncData(state.value!.copyWith(others: AsyncData(others)));
    } on CrawlerException catch (e) {
      state = AsyncData(state.value!
          .copyWith(others: AsyncError(e, StackTrace.current)));
    }
  }

  /// 仅重取中期考核。
  Future<void> loadMidterm() async {
    final cur = state.value;
    if (cur == null) return;
    state =
        AsyncData(cur.copyWith(midterm: const AsyncLoading<JsonMap>()));
    final session = ref.read(crawlerSessionProvider);
    if (session == null) {
      state = AsyncData(cur.copyWith(
          midterm: AsyncError<JsonMap>(
              const SessionLost('未登录'), StackTrace.current)));
      return;
    }
    try {
      final midterm = await session.withApi((api) => api.midterm(semesterId: cur.semesterId));
      state = AsyncData(state.value!.copyWith(midterm: AsyncData(midterm)));
    } on CrawlerException catch (e) {
      state = AsyncData(state.value!.copyWith(
          midterm: AsyncError(e, StackTrace.current)));
    }
  }

  // ---------------- 内部 ----------------

  /// 顺序加载四段（同一 session，withApi 各自独立调用）。
  Future<ExamState> _loadAll(CrawlerSession session, {int? keepId, int? semesterId}) async {
    // 1) 批次
    AsyncValue<List<JsonMap>> batchesV;
    int? selectedId = keepId;
    try {
      final b = await session.withApi((api) => api.examBatches());
      batchesV = AsyncData(b);
      if (selectedId == null || !b.any((x) => x['id'] == selectedId)) {
        final sel =
            b.where((x) => x['selected'] == true).firstOrNull ?? b.firstOrNull;
        selectedId = sel?['id'] as int?;
      }
    } on CrawlerException catch (e) {
      batchesV = AsyncError(e, StackTrace.current);
    }

    // 2) 当前批次安排（有批次才拉）
    AsyncValue<JsonMap> tableV;
    final batchId = selectedId;
    if (batchId != null) {
      try {
        final t = await session.withApi((api) => api.examTable(batchId));
        tableV = AsyncData(t);
      } on CrawlerException catch (e) {
        tableV = AsyncError(e, StackTrace.current);
      }
    } else {
      tableV = const AsyncLoading<JsonMap>();
    }

    // 3) 课外资格考试（四六级）
    AsyncValue<JsonMap> othersV;
    try {
      final o = await session.withApi((api) => api.otherExams());
      othersV = AsyncData(o);
    } on CrawlerException catch (e) {
      othersV = AsyncError(e, StackTrace.current);
    }

    // 4) 中期考核
    AsyncValue<JsonMap> midtermV;
    try {
      final m = await session.withApi((api) => api.midterm(semesterId: semesterId));
      midtermV = AsyncData(m);
    } on CrawlerException catch (e) {
      midtermV = AsyncError(e, StackTrace.current);
    }

    return ExamState(
      batches: batchesV,
      selectedBatchId: selectedId,
      table: tableV,
      others: othersV,
      midterm: midtermV,
      semesterId: semesterId,
    );
  }
}


/// 考试模块 Provider。
final examProvider = AsyncNotifierProvider<ExamController, ExamState>(
    ExamController.new);

/// 便捷：提取原生 JsonMap 列表（Records）。
List<Map<String, Object?>> asMapList(Object? raw) => [
      for (final e in (raw as List? ?? const []))
        if (e is Map<String, Object?>) e,
    ];