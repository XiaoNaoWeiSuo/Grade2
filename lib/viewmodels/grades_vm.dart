/// 成绩 ViewModel —— 缓存优先 + 跟随全局学期选择 + 在线拉取。
///
/// 数据流：
/// ```text
/// build()
///   ├─ 学期 = semesterSelectionProvider.currentId（成绩跟随全局选择）
///   ├─ 本地缓存命中(grades/grades_<semesterId>) → 直接渲染(离线可用)
///   └─ 未命中 → api.grades(semesterId) → 写缓存 → 渲染
/// refresh() 强制在线刷新（绕过缓存，写回后更新状态，失败回落已有数据）
/// ```
/// 学期切换（semester_vm.select）会令本 Provider 失效重取，成绩随之切学期。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crawler/crawler_exceptions.dart';
import '../core/crawler/models/semester_table.dart';
import '../core/crawler/session/crawler_session.dart';
import '../core/storage/local_cache.dart';
import 'auth_vm.dart';
import 'providers.dart';
import 'semester_vm.dart';

/// 成绩数据（成绩解析器输出的 headers + records + 渲染辅助字段）。
class GradesData {
  const GradesData({
    required this.headers,
    required this.records,
    required this.semesterId,
    required this.semesterLabel,
    required this.fromCache,
    this.fallbackError,
  });

  /// 列名（与 records 元素键对齐，用于表格横向表头）。
  final List<String> headers;

  /// 成绩记录：{列名→值}（学分/绩点/总评成绩等已自动化数值）。
  final List<Map<String, Object?>> records;

  /// 学期 id。
  final int? semesterId;
  final String semesterLabel;

  /// true = 来自本地缓存（离线/未刷新）。
  final bool fromCache;

  /// 在线刷新失败但回落到缓存时的提示。
  final String? fallbackError;
}

class GradesController extends AsyncNotifier<GradesData?> {
  @override
  Future<GradesData?> build() async {
    final cache = await ref.watch(localCacheProvider.future);
    final session = ref.watch(crawlerSessionProvider);

    // 1) 学期 = 全局学期选择（成绩跟随课表/全局切换）
    final selection = await ref.watch(semesterSelectionProvider.future);
    final semId = selection.currentId;
    final semLabel = selection.label;
    final username = ref.watch(authProvider).value?.username ?? '';

    // 2) 成绩缓存优先（支持按账号隔离，兼顾向下兼容）
    Object? hit;
    if (username.isNotEmpty) {
      hit = await cache.read(_ns, 'grades_${username}_$semId');
    }
    hit ??= await cache.read(_ns, _key(semId));

    // 离线/免登模式兜底：若当前学期无缓存，自动载入该账号最近可用成绩
    if (hit == null && session == null) {
      final allKeys = await cache.keys(_ns);
      final fallbackKey = allKeys.cast<String?>().firstWhere(
        (k) => username.isNotEmpty && k!.startsWith('grades_${username}_'),
        orElse: () => allKeys.cast<String?>().firstWhere(
          (k) => k!.startsWith('grades_'),
          orElse: () => null,
        ),
      );
      if (fallbackKey != null) {
        hit = await cache.read(_ns, fallbackKey);
      }
    }

    if (hit is Map<String, Object?>) {
      return _fromRaw(hit, semId, semLabel, true, null);
    }

    // 3) 在线拉取
    if (session == null) {
      throw const SessionLost('未登录且无本地成绩缓存');
    }
    return _fetch(cache, session, semId, semLabel, username);
  }

  /// 强制在线刷新（绕过成绩缓存）；失败回落已有数据。
  Future<void> refresh() async {
    final cache = await ref.read(localCacheProvider.future);
    final session = ref.read(crawlerSessionProvider);
    if (session == null) {
      state = AsyncError(const SessionLost('未登录'), StackTrace.current);
      return;
    }
    final cur = state.value;
    state = const AsyncLoading<GradesData?>().copyWithPrevious(state);
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
        state = AsyncData(GradesData(
          headers: cur.headers,
          records: cur.records,
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

  static const _ns = 'grades';
  static String _key(int id) => 'grades_$id';

  /// ⚠ session 参数必须是静态类型 CrawlerSession：dynamic 接收者调用泛型
  /// withApi 时闭包被推断为 (dynamic)→dynamic，运行时签名检查失败。
  Future<GradesData> _fetch(
      LocalCache cache, CrawlerSession session, int semId, String label, String username) async {
    final raw = await session.withApi((api) => api.grades(semId));
    raw.remove('file'); // 原始文件路径不入缓存
    await cache.write(_ns, _key(semId), raw);
    if (username.isNotEmpty) {
      await cache.write(_ns, 'grades_${username}_$semId', raw);
    }
    return _fromRaw(raw, semId, label, false, null);
  }

  GradesData _fromRaw(Map<String, Object?> raw, int? semId, String label,
      bool fromCache, String? fallbackError) {
    final headers = [
      for (final h in (raw['headers'] as List? ?? const []).cast<Object?>())
        '${h ?? ''}',
    ];
    final records = [
      for (final r in (raw['records'] as List? ?? const []).cast<Object?>())
        if (r is Map<String, Object?>) r
    ];
    return GradesData(
      headers: headers,
      records: records,
      semesterId: semId,
      semesterLabel: label,
      fromCache: fromCache,
      fallbackError: fallbackError,
    );
  }
}

/// 成绩 Provider（全局保活；随全局学期 / session 变化自动重建）。
final gradesProvider =
    AsyncNotifierProvider<GradesController, GradesData?>(
        GradesController.new);