/// 课程表 ViewModel —— 缓存优先 + 全局学期选择 + 在线拉取 + 周次翻页。
///
/// 数据流：
/// ```text
/// build()
///   ├─ 学期 = semesterSelectionProvider（用户选择 > 网络校正 > 本地推算）
///   ├─ 本地缓存命中(timetable.table_std_<id>) → 直接渲染(离线可用)
///   └─ 未命中 → courseTable(std, semesterId) → 写缓存 → 渲染
/// refresh() 强制在线刷新（绕过缓存，写回后更新状态）
/// ```
/// 学期切换（semester_vm.select）会令本 Provider 失效重取；周次翻页只改
/// [weekIndexProvider]，不触发网络。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crawler/crawler_exceptions.dart';
import '../core/crawler/models/semester_table.dart';
import '../core/crawler/parsers/clean.dart';
import '../core/crawler/session/crawler_session.dart';
import '../core/storage/local_cache.dart';
import 'auth_vm.dart';
import 'providers.dart';
import 'semester_vm.dart';

/// 课表数据（解析器输出的原生 Map 列表 + 渲染辅助字段）。
class TimetableData {
  const TimetableData({
    required this.courses,
    required this.unitCount,
    required this.totalWeeks,
    required this.semesterId,
    required this.semesterLabel,
    required this.fromCache,
    this.fallbackError,
  });

  /// parseCourseHtml 的 courses（字段见 data_models.dart CourseRecord）。
  final List<Map<String, Object?>> courses;
  final int unitCount;
  final int totalWeeks;
  final int? semesterId;
  final String semesterLabel;

  /// true = 来自本地缓存（离线/未刷新）。
  final bool fromCache;

  /// 在线刷新失败但回落到缓存时的提示。
  final String? fallbackError;
}

class TimetableController extends AsyncNotifier<TimetableData?> {
  @override
  Future<TimetableData?> build() async {
    final cache = await ref.watch(localCacheProvider.future);
    final session = ref.watch(crawlerSessionProvider);

    // 1) 学期 = 全局学期选择（用户选择 > 网络校正 > 本地推算）
    final selection = await ref.watch(semesterSelectionProvider.future);
    final semId = selection.currentId;
    final semLabel = selection.label;
    final username = ref.watch(authProvider).value?.username ?? '';

    // 2) 课表缓存优先（支持按账号隔离，兼顾向下兼容）
    Object? hit;
    if (username.isNotEmpty) {
      hit = await cache.read(_nsTable, 'table_std_${username}_$semId');
    }
    hit ??= await cache.read(_nsTable, 'table_std_$semId');

    // 离线/免登模式兜底：若当前学期无缓存，自动载入该账号最近可用课表
    if (hit == null && session == null) {
      final allKeys = await cache.keys(_nsTable);
      final fallbackKey = allKeys.cast<String?>().firstWhere(
        (k) => username.isNotEmpty && k!.startsWith('table_std_${username}_'),
        orElse: () => allKeys.cast<String?>().firstWhere(
          (k) => k!.startsWith('table_std_'),
          orElse: () => null,
        ),
      );
      if (fallbackKey != null) {
        hit = await cache.read(_nsTable, fallbackKey);
      }
    }

    if (hit is Map<String, Object?>) {
      return _fromRaw(hit, semId, semLabel, true, null);
    }

    // 3) 在线拉取
    if (session == null) {
      throw const SessionLost('未登录且无本地课表缓存');
    }
    return _fetch(cache, session, semId, semLabel, username);
  }

  /// 强制在线刷新（绕过课表缓存）。
  Future<void> refresh() async {
    final cache = await ref.read(localCacheProvider.future);
    final session = ref.read(crawlerSessionProvider);
    if (session == null) {
      state = AsyncError(const SessionLost('未登录'), StackTrace.current);
      return;
    }
    final cur = state.value;
    state = const AsyncLoading<TimetableData?>().copyWithPrevious(state);
    try {
      final semId = cur?.semesterId ??
          (await ref.read(semesterSelectionProvider.future)).currentId;
      final label = SemesterTable.labelFor(semId);
      final username = ref.read(authProvider).value?.username ?? '';
      final data = await _fetch(cache, session, semId, label, username);
      state = AsyncData(data);
    } on CrawlerException catch (e) {
      // 回落到已有缓存（内存态优先于重新读盘）
      if (cur != null) {
        state = AsyncData(TimetableData(
          courses: cur.courses,
          unitCount: cur.unitCount,
          totalWeeks: cur.totalWeeks,
          semesterId: cur.semesterId,
          semesterLabel: cur.semesterLabel,
          fromCache: true,
          fallbackError: '刷新失败，已显示本地缓存：${e.message}',
        ));
      } else {
        state = AsyncError(e, StackTrace.current);
      }
    }
  }

  // ---------------- 内部 ----------------

  static const _nsTable = 'timetable';

  // ⚠ session 参数必须是静态类型 CrawlerSession：dynamic 接收者调用泛型
  // withApi 时闭包被推断为 (dynamic)→dynamic，运行时签名检查失败
  // （"type '(dynamic) => dynamic' is not a subtype of ..."）
  Future<TimetableData> _fetch(
      LocalCache cache, CrawlerSession session, int semId, String label, String username) async {
    final raw = await session
        .withApi((api) => api.courseTable(kind: 'std', semesterId: semId));
    raw.remove('file'); // 原始文件路径不入缓存
    await cache.write(_nsTable, 'table_std_$semId', raw);
    if (username.isNotEmpty) {
      await cache.write(_nsTable, 'table_std_${username}_$semId', raw);
    }
    return _fromRaw(raw, semId, label, false, null);
  }

  TimetableData _fromRaw(Map<String, Object?> raw, int? semId, String label,
      bool fromCache, String? fallbackError) {
    final courses = <Map<String, Object?>>[];
    for (final item in (raw['courses'] as List? ?? const []).cast<Object?>()) {
      if (item is Map) {
        final c = Map<String, Object?>.from(item);
        final weeks = c['weeks'];
        final rawBits = weeks is Map
            ? (weeks['raw'] as String?)
            : (weeks is String ? weeks : null);
        if (rawBits != null && rawBits.isNotEmpty) {
          c['weeks'] = weekParse(rawBits);
        }
        courses.add(c);
      }
    }
    var totalWeeks = 0;
    for (final c in courses) {
      final weeks = c['weeks'];
      final t = weeks is Map ? weeks['total'] : null;
      if (t is int && t > totalWeeks) totalWeeks = t;
    }
    if (totalWeeks == 0) totalWeeks = 25; // 位串缺失时的兜底
    final uc = raw['unit_count'] as int?;
    return TimetableData(
      courses: courses,
      unitCount: (uc == null || uc <= 0) ? 12 : uc,
      totalWeeks: totalWeeks,
      semesterId: semId,
      semesterLabel: label,
      fromCache: fromCache,
      fallbackError: fallbackError,
    );
  }
}

/// 课表 Provider（全局保活；登录/登出随 session 变化自动重建）。
final timetableProvider =
    AsyncNotifierProvider<TimetableController, TimetableData?>(
        TimetableController.new);

/// 当前真实教学周（自动按开学日期与周一推算，如秋学期 9.1 所在周为第 1 周）。
final actualCurrentWeekProvider = Provider<int>((ref) {
  final selection = ref.watch(semesterSelectionProvider).value;
  final semId = selection?.currentId ?? SemesterTable.currentSemesterId();
  final timetable = ref.watch(timetableProvider).value;
  final maxWeeks = timetable?.totalWeeks ?? 25;
  return SemesterTable.calculateCurrentWeek(semId, null, maxWeeks);
});

/// 当前查看的教学周（1 起）。当前学期初始化为真实当前周，历史学期初始化为第 1 周。翻页只改它，不触发网络。
final weekIndexProvider = StateProvider<int>((ref) {
  final selection = ref.watch(semesterSelectionProvider).value;
  final semId = selection?.currentId ?? SemesterTable.currentSemesterId();
  final isCur = (semId == SemesterTable.currentSemesterId());
  return isCur ? SemesterTable.calculateCurrentWeek(semId) : 1;
});
