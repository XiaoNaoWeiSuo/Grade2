/// 全局学期选择 ViewModel —— 课表/成绩等所有"当前学期"消费方的单一数据源。
///
/// 选择优先级：用户选择（落盘 meta.current_semester）> 网络权威校正 >
/// SemesterTable 本地推算（锚点 409=2026-2027-1，+20/学期外推）。
/// 选项列表：本地常量表 63 学期（服务端 semesters() 校正后替换为网络列表）。
/// 切换学期即失效 [timetableProvider]，课表按新学期重取（旧学期缓存仍有效）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crawler/crawler_exceptions.dart';
import '../core/crawler/models/semester_table.dart';
import 'providers.dart';
import 'timetable_vm.dart';

/// 学期选择状态（不可变）。
class SemesterSelection {
  const SemesterSelection({
    required this.currentId,
    required this.label,
    required this.options,
    this.fromNetwork = false,
  });

  final int currentId;
  final String label;

  /// 可选学期列表（与 API semesters 输出同形：{id, schoolYear, name, label}）。
  final List<Map<String, Object?>> options;

  /// 列表是否来自网络权威数据（false = 本地常量表）。
  final bool fromNetwork;

  SemesterSelection copyWith({int? currentId, String? label}) =>
      SemesterSelection(
        currentId: currentId ?? this.currentId,
        label: label ?? this.label,
        options: options,
        fromNetwork: fromNetwork,
      );
}

class SemesterSelectionController extends AsyncNotifier<SemesterSelection> {
  @override
  Future<SemesterSelection> build() async {
    final cache = await ref.watch(localCacheProvider.future);

    // 当前学期：meta 缓存（用户选择/网络校正）→ 本地推算
    final meta = await cache.readAs<Map<String, Object?>>(
        _nsMeta, _keySemester, const {});
    final id = meta['id'] as int? ?? SemesterTable.currentSemesterId();

    // 选项列表：网络列表缓存 → 本地常量表
    final netList = await cache.readAs<List<Object?>>(
        _nsMeta, _keySemesterList, const []);
    final options = [
      for (final e in netList)
        if (e is Map<String, Object?>) e,
    ];
    if (options.isNotEmpty) {
      return SemesterSelection(
        currentId: id,
        label: meta['label'] as String? ?? SemesterTable.labelFor(id),
        options: options,
        fromNetwork: true,
      );
    }
    return SemesterSelection(
      currentId: id,
      label: meta['label'] as String? ?? SemesterTable.labelFor(id),
      options: SemesterTable.allAsMaps(),
    );
  }

  /// 切换学期（全局生效：课表立即重取，成绩等后续走 meta 缓存）。
  Future<String?> select(int semesterId) async {
    final cur = state.value;
    if (cur == null || semesterId == cur.currentId) return null;
    final cache = await ref.read(localCacheProvider.future);
    final label = SemesterTable.labelFor(semesterId);
    await cache.write(_nsMeta, _keySemester,
        {'id': semesterId, 'label': label, 'source': 'user'});
    state = AsyncData(cur.copyWith(currentId: semesterId, label: label));
    // 课表随选择立即重取（缓存优先）；当前学期定位到真实当前周，历史学期从第 1 周开始
    final isCur = (semesterId == SemesterTable.currentSemesterId());
    ref.read(weekIndexProvider.notifier).state =
        isCur ? SemesterTable.calculateCurrentWeek(semesterId) : 1;
    ref.invalidate(timetableProvider);
    return null;
  }

  /// 网络权威校正：拉取服务端学期列表与当前学期，落盘并刷新选项。
  Future<String?> refreshFromNetwork() async {
    final session = ref.read(crawlerSessionProvider);
    if (session == null) return '未登录';
    final cur = state.value;
    if (cur != null) {
      state = const AsyncLoading<SemesterSelection>().copyWithPrevious(state);
    }
    try {
      final r = await session.withApi((api) => api.semesters());
      final sems = [
        for (final s in (r['semesters'] as List? ?? const []).cast<Object?>())
          if (s is Map<String, Object?>) s
      ];
      final netCurrent = r['current'] as int?;
      final cache = await ref.read(localCacheProvider.future);
      await cache.write(_nsMeta, _keySemesterList, sems);
      final id = netCurrent ?? cur?.currentId ?? SemesterTable.currentSemesterId();
      final label = sems
          .cast<Map<String, Object?>?>()
          .firstWhere((s) => s?['id'] == id,
              orElse: () => null)
          ?['label'] as String? ??
          SemesterTable.labelFor(id);
      await cache.write(_nsMeta, _keySemester,
          {'id': id, 'label': label, 'source': 'network'});
      state = AsyncData(SemesterSelection(
        currentId: id,
        label: label,
        options: sems,
        fromNetwork: true,
      ));
      ref.invalidate(timetableProvider);
      return null;
    } on CrawlerException catch (e) {
      state = AsyncData((state.value ?? cur ??
              const SemesterSelection(
                  currentId: 409, label: '', options: []))
          .copyWith());
      return e.message;
    }
  }

  // ---------------- 内部 ----------------

  static const _nsMeta = 'meta';
  static const _keySemester = 'current_semester';
  static const _keySemesterList = 'semester_list';
}

/// 全局学期选择 Provider（全局保活）。
final semesterSelectionProvider =
    AsyncNotifierProvider<SemesterSelectionController, SemesterSelection>(
        SemesterSelectionController.new);
