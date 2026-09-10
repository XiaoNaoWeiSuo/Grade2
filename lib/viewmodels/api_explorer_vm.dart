/// API 调试探索 ViewModel —— 工程期把 EamsApi 全部能力逐一按键触发。
///
/// 每个按钮 → `session.withApi(...)` → 结果 JsonMap 存入 [ApiExplorerState.results]，
/// 页面以缩进 JSON 展示。正式 UI 重写时本文件可整体删除，不影响内核。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/crawler/crawler_exceptions.dart';
import '../core/crawler/models/semester_table.dart';
import '../core/crawler/session/crawler_session.dart';
import 'providers.dart';
import 'semester_vm.dart';

class ApiExplorerState {
  const ApiExplorerState({
    this.running,
    this.results = const {},
    this.error,
  });

  /// 正在运行的动作名（页面据此显示局部 loading）。
  final String? running;

  /// 动作名 → 结果（原生 JsonMap 或 List 包装成 JsonMap）。
  final Map<String, Object?> results;

  /// 最近一次错误。
  final String? error;

  ApiExplorerState copyWith({
    String? running,
    bool clearRunning = false,
    Map<String, Object?>? results,
    String? error,
    bool clearError = false,
  }) =>
      ApiExplorerState(
        running: clearRunning ? null : (running ?? this.running),
        results: results ?? this.results,
        error: clearError ? null : (error ?? this.error),
      );
}

class ApiExplorerController extends Notifier<ApiExplorerState> {
  @override
  ApiExplorerState build() => const ApiExplorerState();

  /// 可触发的动作清单（MorePage 按此渲染按钮）。
  static const actions = <String, String>{
    'welcome': '欢迎页',
    'stdDetail': '学籍信息',
    'semesters': '学期列表',
    'grades': '个人成绩(当前学期)',
    'examBatches': '考试批次',
    'examTable': '考试安排(第1批次)',
    'otherExams': '资格考试报名',
    'midterm': '中期考核',
    'planCompletion': '培养计划完成度',
    'planByMajor': '我的专业培养计划',
    'majorPlan': '专业培养方案',
    'stdApply': '转专业申请',
    'messages': '系统消息',
    'evaluate': '教学评价任务',
    'electiveProfiles': '选课轮次',
  };

  /// 运行指定动作。
  Future<void> run(String name) async {
    final session = ref.read(crawlerSessionProvider);
    if (session == null) {
      state = state.copyWith(error: '未登录');
      return;
    }
    state = state.copyWith(running: name, clearError: true);
    try {
      final result = await _dispatch(session, name);
      state = state.copyWith(
        clearRunning: true,
        results: {...state.results, name: result},
      );
    } on CrawlerException catch (e) {
      state = state.copyWith(clearRunning: true, error: e.message);
    } catch (e) {
      state = state.copyWith(clearRunning: true, error: '$e');
    }
  }

  // ⚠ session 必须静态类型（dynamic 接收者会让 withApi 闭包运行时签名检查失败）
  Future<Object?> _dispatch(CrawlerSession session, String name) async {
    switch (name) {
      case 'welcome':
        return session.withApi((api) => api.welcome());
      case 'stdDetail':
        return session.withApi((api) => api.stdDetail());
      case 'semesters':
        final r = await session.withApi((api) => api.semesters());
        // 权威校正：学期列表与当前学期写入 meta，供全局选择器/课表/成绩使用
        final cache = ref.read(localCacheProvider).requireValue;
        String label = '';
        for (final s
            in (r['semesters'] as List? ?? const []).cast<Object?>()) {
          if (s is Map && s['id'] == r['current']) {
            label = s['label'] as String? ?? '';
          }
        }
        await cache.write(
            'meta', 'current_semester', {'id': r['current'], 'label': label});
        await cache.write('meta', 'semester_list', r['semesters']);
        ref.invalidate(semesterSelectionProvider);
        return r;
      case 'grades':
        final semId = await _currentSemesterId();
        return session.withApi((api) =>
            api.grades(semId ?? SemesterTable.currentSemesterId()));
      case 'examBatches':
        final r = await session.withApi((api) => api.examBatches());
        return {'batches': r};
      case 'examTable':
        final prev = state.results['examBatches'];
        final batches =
            prev is Map ? (prev['batches'] as List? ?? const []) : const [];
        if (batches.isEmpty) {
          throw const SessionLost('请先运行“考试批次”');
        }
        final batchId =
            (batches.first as Map)['id'] as int? ?? (throw const SessionLost('批次解析失败'));
        return session.withApi((api) => api.examTable(batchId));
      case 'otherExams':
        return session.withApi((api) => api.otherExams());
      case 'midterm':
        return session.withApi((api) => api.midterm());
      case 'planCompletion':
        return session.withApi((api) => api.planCompletion());
      case 'planByMajor':
        return session.withApi((api) => api.planByMajor());
      case 'majorPlan':
        return session.withApi((api) => api.majorPlan());
      case 'stdApply':
        return session.withApi((api) => api.stdApply());
      case 'messages':
        return session.withApi((api) => api.messages());
      case 'evaluate':
        return session.withApi((api) => api.evaluate());
      case 'electiveProfiles':
        final r = await session.withApi((api) => api.electiveProfiles());
        return {'profiles': r};
      default:
        throw StateError('未知动作: $name');
    }
  }

  Future<int?> _currentSemesterId() async {
    // 全局学期选择优先（用户切换的学期），其次 meta 缓存/本地推算
    final sel = ref.read(semesterSelectionProvider).value;
    if (sel != null) return sel.currentId;
    final cache = ref.read(localCacheProvider).requireValue;
    final meta = await cache.readAs<Map<String, Object?>>(
        'meta', 'current_semester', const {});
    return meta['id'] as int? ?? SemesterTable.currentSemesterId();
  }
}

/// API 探索 Provider（全局保活）。
final apiExplorerProvider =
    NotifierProvider<ApiExplorerController, ApiExplorerState>(
        ApiExplorerController.new);
