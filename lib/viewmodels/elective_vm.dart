/// 选课 ViewModel —— 跨接口编排的核心。
///
/// 数据流（都在本 Controller 内串 API，UI 不散落）：
/// ```text
/// build()            → 未登录抛 SessionLost，否则 electiveProfiles() 拉轮次列表
/// openProfile(p)     → electiveContext(id) → electiveLessons(id)
///                      → electiveCounts(projectId, semesterId) → 合并出 merged
/// refreshProfile()   → 复拉当前轮次的 context/lessons/counts（下拉刷新）
/// operate(id, elect) → ⚠写操作 electiveOperate(...) → 成功后重拉 counts+lessons
/// ```
/// `merged` 每项 = { lesson: lesson, sc: 已选(可空), lc: 上限(可空) }。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crawler/crawler_exceptions.dart';
import '../core/crawler/session/crawler_session.dart';
import 'providers.dart';

/// 选课状态（含轮次列表 + 当前进入轮次的课程详情）。
class ElectiveState {
  const ElectiveState({
    this.profiles = const [],
    this.selectedProfile,
    this.lessons = const [],
    this.merged = const [],
    this.myElect = const {},
    this.ttCodes = const {},
    this.projectId = 1,
    this.semesterId,
    this.operatingLessonId,
    this.detailLoading = false,
    this.error,
  });

  /// 选课轮次列表（parseProfilesHtml 输出）。
  final List<Map<String, Object?>> profiles;

  /// 当前进入的轮次（原样复制自 profiles 的一项）。
  final Map<String, Object?>? selectedProfile;

  /// 当前轮次的课程列表（parseLessonsHtml 输出）。
  final List<Map<String, Object?>> lessons;

  /// 合并余量后的展示列表：{ lesson, sc, lc }。
  final List<Map<String, Object?>> merged;

  /// 我(当前学生)在本轮已选的课程 id 集合（字符串，持久化）。
  ///
  /// ⚠ `merged[].sc` 是"全站已选总人数"，不能用来判断"我是否已选"；
  /// 这里由 App 本地持久化的选/退操作记录来准确表达"我的已选"，
  /// 供"已选"标签筛选与退课按钮判定使用。
  final Set<String> myElect;

  /// 当前学期课表内出现的课程号集合（course_code2/course_code 清洗后）。
  ///
  /// 用于与选课列表按"课程号"交叉匹配：若某课的 `code` 已在课表里，
  /// 则认为该课程已被本人修读（可能在网页端选的，App 无记录）。
  /// 与 [myElect] 一起构成"我的已选"判定（本地精确 + 课表拓补）。
  final Set<String> ttCodes;

  /// electiveContext 解析出的 projectId（选课人数余量查询用）。
  final int projectId;

  /// electiveContext 解析出的 semesterId。
  final int? semesterId;

  /// 正在执行选/退操作的课程 id（局部禁用该课的按钮，防重复提交）。
  final int? operatingLessonId;

  /// true = 正在拉取当前轮次详情（context/lessons/counts）。
  final bool detailLoading;

  /// 跨接口编排或写操作失败的人类可读错误（仅详情态使用）。
  final String? error;

  static const _unset = Object();

  ElectiveState copyWith({
    List<Map<String, Object?>>? profiles,
    Object? selectedProfile = _unset,
    List<Map<String, Object?>>? lessons,
    List<Map<String, Object?>>? merged,
    Object? myElect = _unset,
    Object? ttCodes = _unset,
    int? projectId,
    Object? semesterId = _unset,
    Object? operatingLessonId = _unset,
    bool? detailLoading,
    Object? error = _unset,
  }) {
    return ElectiveState(
      profiles: profiles ?? this.profiles,
      selectedProfile: identical(selectedProfile, _unset)
          ? this.selectedProfile
          : selectedProfile as Map<String, Object?>?,
      lessons: lessons ?? this.lessons,
      merged: merged ?? this.merged,
      myElect: identical(myElect, _unset) ? this.myElect : myElect as Set<String>,
      ttCodes: identical(ttCodes, _unset) ? this.ttCodes : ttCodes as Set<String>,
      projectId: projectId ?? this.projectId,
      semesterId:
          identical(semesterId, _unset) ? this.semesterId : semesterId as int?,
      operatingLessonId: identical(operatingLessonId, _unset)
          ? this.operatingLessonId
          : operatingLessonId as int?,
      detailLoading: detailLoading ?? this.detailLoading,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class ElectiveController extends AsyncNotifier<ElectiveState> {
  ElectiveState get _cur => state.value ?? const ElectiveState();

  @override
  Future<ElectiveState> build() async {
    final session = ref.watch(crawlerSessionProvider);
    if (session == null) {
      throw const SessionLost('未登录');
    }
    final profiles = await session.withApi((api) => api.electiveProfiles());
    final ttCodes = await _loadTimetableCodes(session);
    return ElectiveState(profiles: profiles, ttCodes: ttCodes);
  }

  /// 拉取当前学期课表的"课程号"集合，用于与选课列表交叉判断"我是否已选"。
  ///
  /// 课表失败（非登录季无课/接口异常）时返回空集，退化为仅本地 myElect 判定。
  Future<Set<String>> _loadTimetableCodes(CrawlerSession session) async {
    try {
      final r = await session.withApi((api) => api.courseTable(kind: 'std'));
      final out = <String>{};
      for (final c in (r['courses'] as List? ?? const []).cast<Object?>()) {
        if (c is! Map) continue;
        final code2 = c['course_code2'];
        if (code2 is String && code2.isNotEmpty) out.add(code2);
        final code = c['course_code'];
        if (code is String && code.isNotEmpty) out.add(code);
      }
      return out;
    } on CrawlerException {
      return const {};
    }
  }

  /// （下拉刷新）重新拉取轮次列表。失败仅在状态里留 error，不抛。
  Future<void> loadProfiles() async {
    final session = ref.read(crawlerSessionProvider);
    if (session == null) {
      state = AsyncData(_cur.copyWith(error: '未登录'));
      return;
    }
    try {
      final profiles = await session.withApi((api) => api.electiveProfiles());
      state = AsyncData(_cur.copyWith(profiles: profiles, error: null));
    } on CrawlerException catch (e) {
      state = AsyncData(_cur.copyWith(error: e.message));
    }
  }

  /// 进入某轮次：拉 context → lessons → counts → 合并出 merged。
  Future<void> openProfile(Map<String, Object?> profile) async {
    final session = ref.read(crawlerSessionProvider);
    if (session == null) {
      state = AsyncData(_cur.copyWith(
          selectedProfile: profile, detailLoading: false, error: '未登录'));
      return;
    }
    state = AsyncData(_cur.copyWith(
      selectedProfile: profile,
      detailLoading: true,
      merged: const [],
      lessons: const [],
      error: null,
    ));
    try {
      final d = await _assemble(session, profile);
      final pid = _profileId(profile);
      final myElect = await _loadMyElect(pid);
      state = AsyncData(_cur.copyWith(
        selectedProfile: profile,
        lessons: d.lessons,
        merged: d.merged,
        myElect: myElect,
        projectId: d.projectId,
        semesterId: d.semesterId,
        detailLoading: false,
        error: null,
      ));
    } on CrawlerException catch (e) {
      state = AsyncData(_cur.copyWith(detailLoading: false, error: e.message));
    }
  }

  /// 下拉刷新：复拉当前轮次的详情（保持已选轮次不变）。
  Future<void> refreshProfile() async {
    final session = ref.read(crawlerSessionProvider);
    final profile = _cur.selectedProfile;
    if (session == null) {
      state = AsyncData(_cur.copyWith(error: '未登录'));
      return;
    }
    if (profile == null) return;
    state = AsyncData(_cur.copyWith(detailLoading: true, error: null));
    try {
      final d = await _assemble(session, profile);
      final pid = _profileId(profile);
      final myElect = await _loadMyElect(pid);
      state = AsyncData(_cur.copyWith(
        lessons: d.lessons,
        merged: d.merged,
        myElect: myElect,
        projectId: d.projectId,
        semesterId: d.semesterId,
        detailLoading: false,
        error: null,
      ));
    } on CrawlerException catch (e) {
      state = AsyncData(_cur.copyWith(detailLoading: false, error: e.message));
    }
  }

  /// 选课([elect]=true) / 退课([elect]=false)。⚠写操作，二次确认放 UI。
  ///
  /// 返回结果 message（成功/失败均返回文案，供 UI toast）；失败时内部已
  /// 恢复按钮交互态（operatingLessonId 置空）。成功后会重拉 counts+lessons。
  Future<String?> operate(int lessonId, bool elect) async {
    final session = ref.read(crawlerSessionProvider);
    final profile = _cur.selectedProfile;
    if (session == null) return '未登录';
    final pid = profile?['id'];
    if (pid is! int) return '轮次无效';
    state = AsyncData(_cur.copyWith(operatingLessonId: lessonId));
    try {
      final res = await session
          .withApi((api) => api.electiveOperate(profileId: pid, lessonId: lessonId, elect: elect));
      // 成功后在本地"我的已选"集合中登记/移除并落盘（准确表达我的选课状态）
      final mine = {..._cur.myElect};
      final key = '$lessonId';
      if (elect) {
        mine.add(key);
      } else {
        mine.remove(key);
      }
      await _saveMyElect(pid, mine);
      // 重拉 counts + lessons，刷新余量与可退状态
      final d = await _assemble(session, profile!);
      state = AsyncData(_cur.copyWith(
        lessons: d.lessons,
        merged: d.merged,
        myElect: mine,
        projectId: d.projectId,
        semesterId: d.semesterId,
        detailLoading: false,
        operatingLessonId: null,
        error: null,
      ));
      final msg = res['message'];
      final text = msg is String && msg.isNotEmpty
          ? msg
          : (elect ? '选课成功' : '退课成功');
      return text;
    } on CrawlerException catch (e) {
      state = AsyncData(_cur.copyWith(operatingLessonId: null, error: e.message));
      return e.message;
    }
  }

  // --------------- 我的选课（本地持久化） ---------------

  static const _nsElect = 'elective';

  int _profileId(Map<String, Object?> profile) {
    final v = profile['id'];
    return v is int ? v : 1;
  }

  Future<Set<String>> _loadMyElect(int profileId) async {
    try {
      final cache = await ref.read(localCacheProvider.future);
      final list = await cache.readAs<List<Object?>>(
          _nsElect, 'my_elect_$profileId', const []);
      return {for (final e in list) '$e'};
    } on Exception {
      return const {};
    }
  }

  Future<void> _saveMyElect(int profileId, Set<String> mine) async {
    try {
      final cache = await ref.read(localCacheProvider.future);
      await cache.write(_nsElect, 'my_elect_$profileId', mine.toList()..sort());
    } on Exception {
      // 尽力而为，不阻塞主流程
    }
  }

  // --------------- 内部 ---------------

  /// 跨接口编排：context → lessons → counts → merged。
  ///
  /// ⚠ session 必须是静态类型 CrawlerSession（dynamic 会破坏 withApi 的
  /// 闭包泛型推断，运行时签名检查失败）。
  Future<({List<Map<String, Object?>> lessons, List<Map<String, Object?>> merged,
      int projectId, int? semesterId})> _assemble(
      CrawlerSession session, Map<String, Object?> profile) async {
    final rawId = profile['id'];
    final pid = rawId is int ? rawId : 1;
    final ctx = await session.withApi((api) => api.electiveContext(pid));
    final projectId = (ctx['project_id'] as num?)?.toInt() ?? 1;
    final semesterId = (ctx['semester_id'] as num?)?.toInt();
    final lessons = await session.withApi((api) => api.electiveLessons(pid));
    final counts = await session.withApi(
        (api) => api.electiveCounts(projectId: projectId, semesterId: semesterId));
    final merged = <Map<String, Object?>>[];
    for (final lesson in lessons) {
      final lid = lesson['id'];
      final count = lid != null ? counts[lid.toString()] : null;
      int? sc;
      int? lc;
      if (count is Map) {
        final s = count['sc'];
        final l = count['lc'];
        if (s is num) sc = s.toInt();
        if (l is num) lc = l.toInt();
      }
      merged.add({'lesson': lesson, 'sc': sc, 'lc': lc});
    }
    return (
      lessons: lessons,
      merged: merged,
      projectId: projectId,
      semesterId: semesterId,
    );
  }
}

/// 选课 Provider（随登录/登出 session 变化自动重建）。
final electiveProvider =
    AsyncNotifierProvider<ElectiveController, ElectiveState>(
        ElectiveController.new);