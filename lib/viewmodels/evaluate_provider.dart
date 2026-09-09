// 量化评教：替代旧 updatePage 直接调 Requests.GetEvaluate +
// EvaluatePage 直接改 widget.evaluatedata 的模式。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/evaluate.dart';
import '../data/repositories/evaluate_repository.dart';
import 'session_provider.dart';

class EvaluateNotifier extends AsyncNotifier<List<Evaluate>> {
  EvaluateRepository _repo() {
    final client = ref.read(sessionProvider).client;
    if (client == null) {
      throw StateError("Grade当前为离线模式，无法使用");
    }
    return EvaluateRepository(client);
  }

  @override
  Future<List<Evaluate>> build() async => [];

  /// 进入评教页前加载列表（旧 updatePage 点击入口时的 GetEvaluate）
  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo().getEvaluates());
  }

  /// 提交单条评教后刷新（旧 EvaluatePage "好评"按钮）
  Future<void> submitOne(Evaluate item) async {
    final repo = _repo();
    final semester = ref.read(currentSemesterProvider);
    await repo.pushEvaluate(semester, item.id, item.type);
    state = await AsyncValue.guard(() => repo.getEvaluates());
  }

  /// 把所有未完成评教提交为"非常满意"（旧 EvaluatePage "全部非常满意"按钮）。
  /// 与旧逻辑一致：每提交一条即刷新一次列表。
  Future<void> submitAll() async {
    final repo = _repo();
    final semester = ref.read(currentSemesterProvider);
    final current = state.value ?? [];
    for (final item in current) {
      if (!item.state) {
        await repo.pushEvaluate(semester, item.id, item.type);
        state = await AsyncValue.guard(() => repo.getEvaluates());
      }
    }
  }
}

final evaluateProvider =
    AsyncNotifierProvider<EvaluateNotifier, List<Evaluate>>(EvaluateNotifier.new);
