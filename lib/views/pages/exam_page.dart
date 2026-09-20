/// 考试页。采用现代化的 Cupertino 设计，优化批次切换与考试卡片展示。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/crawler/models/data_models.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/exam_vm.dart';
import '../widgets/cupertino_kit.dart';

class ExamPage extends ConsumerWidget {
  const ExamPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;
    
    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.exam),
            backgroundColor: p.bar.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
          ),
          const _ExamBody(),
        ],
      ),
    );
  }
}

class _ExamBody extends ConsumerStatefulWidget {
  const _ExamBody();
  @override
  ConsumerState<_ExamBody> createState() => _ExamBodyState();
}

class _ExamBodyState extends ConsumerState<_ExamBody> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(examProvider);
    final state = async.value;
    final l10n = context.l10n;
    final p = AppThemeScope.of(context);

    if (async.isLoading && state == null) {
      return const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator(radius: 12)));
    }
    
    if (state == null) {
      return SliverFillRemaining(child: CupertinoEmpty(message: '${async.error}', icon: CupertinoIcons.exclamationmark_circle));
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 40),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 10),
          
          // --- 批次切换 ---
          _BatchBar(
            batches: state.batches,
            selectedId: state.selectedBatchId,
            onSelected: (id) => ref.read(examProvider.notifier).selectBatch(id),
          ),
          
          // --- 考试安排 ---
          Group(
            header: Text(l10n.examArrange),
            children: [
              AsyncSliverWrapper<JsonMap>(
                async: state.table,
                onRetry: () => state.selectedBatchId == null ? null : ref.read(examProvider.notifier).refresh(),
                emptyText: l10n.noExamArrange,
                builder: (ctx, table) {
                  final records = asMapList(table['records']);
                  if (records.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      for (var i = 0; i < records.length; i++) ...[
                        if (i > 0) Sep(indent: 16, endIndent: 16),
                        _ExamRecordTile(rec: records[i]),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),

          // --- 其他考试 (四六级等) ---
          Group(
            header: Text(l10n.othersExam),
            children: [
              AsyncSliverWrapper<JsonMap>(
                async: state.others,
                onRetry: () => ref.read(examProvider.notifier).loadOthers(),
                builder: (ctx, others) {
                  final signups = asMapList(others['signups']);
                  final scores = asMapList(others['scores']);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (signups.isNotEmpty) ...[
                        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text(l10n.signup, style: TextStyle(fontSize: 13, color: p.secondary, fontWeight: FontWeight.bold))),
                        for (final s in signups) _SimpleKVList(rec: s),
                      ],
                      if (scores.isNotEmpty) ...[
                        if (signups.isNotEmpty) Sep(indent: 16, endIndent: 16),
                        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text(l10n.scores, style: TextStyle(fontSize: 13, color: p.secondary, fontWeight: FontWeight.bold))),
                        for (final s in scores) _SimpleKVList(rec: s),
                      ],
                      if (signups.isEmpty && scores.isEmpty)
                        Padding(padding: const EdgeInsets.all(16), child: Center(child: Text(l10n.noSignups, style: TextStyle(color: p.secondary, fontSize: 14)))),
                    ],
                  );
                },
              ),
            ],
          ),

          // --- 中期考核 ---
          Group(
            header: Text(l10n.midterm),
            children: [
              AsyncSliverWrapper<JsonMap>(
                async: state.midterm,
                onRetry: () => ref.read(examProvider.notifier).loadMidterm(),
                builder: (ctx, mid) {
                  final text = mid['text']?.toString() ?? '';
                  if (text.trim().isEmpty) return Padding(padding: const EdgeInsets.all(16), child: Center(child: Text(l10n.noMidterm, style: TextStyle(color: p.secondary, fontSize: 14))));
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(text, style: TextStyle(fontSize: 14, color: p.label, height: 1.5)),
                  );
                },
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

/// 辅助包装：将 AsyncValue 转为非 Sliver 的 Widget，方便在 Group 内部使用。
class AsyncSliverWrapper<T> extends StatelessWidget {
  const AsyncSliverWrapper({super.key, required this.async, required this.builder, this.onRetry, this.emptyText});
  final AsyncValue<T> async;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Padding(padding: EdgeInsets.all(20), child: Center(child: CupertinoActivityIndicator())),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('$e', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemRed)),
            if (onRetry != null) CupertinoButton(onPressed: onRetry, child: Text(context.l10n.retry, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
      data: (data) {
        if (data == null || (data is List && data.isEmpty)) {
          return Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(emptyText ?? context.l10n.emptyDefault, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 14))));
        }
        return builder(context, data);
      },
    );
  }
}

class _BatchBar extends StatelessWidget {
  const _BatchBar({required this.batches, required this.selectedId, required this.onSelected});
  final AsyncValue<List<JsonMap>> batches;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: batches.when(
        loading: () => const SizedBox(height: 32, child: Center(child: CupertinoActivityIndicator(radius: 8))),
        error: (e, _) => Text('$e', style: TextStyle(fontSize: 12, color: p.secondary)),
        data: (list) {
          if (list.isEmpty) return const SizedBox.shrink();
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final b in list)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onSelected(b['id'] as int),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selectedId == b['id'] ? p.primary : p.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selectedId == b['id'] ? p.primary : p.separator),
                        ),
                        child: Text(
                          s(b, 'name').isEmpty ? '# ${b['id']}' : s(b, 'name'),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selectedId == b['id'] ? CupertinoColors.white : p.label),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ExamRecordTile extends StatelessWidget {
  const _ExamRecordTile({required this.rec});
  final Map<String, Object?> rec;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final name = rec['课程']?.toString() ?? rec['课程名称']?.toString() ?? '未知课程';
    final time = rec['考试时间']?.toString() ?? '';
    final room = rec['考场']?.toString() ?? '';
    final seat = rec['座位号']?.toString() ?? '';
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (time.isNotEmpty) _row(CupertinoIcons.time, time, p),
          if (room.isNotEmpty) _row(CupertinoIcons.location, room, p),
          if (seat.isNotEmpty) _row(CupertinoIcons.number, '座位号：$seat', p),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, AppPalette p) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Icon(icon, size: 14, color: p.secondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: p.secondary, fontWeight: FontWeight.w500))),
      ],
    ),
  );
}

class _SimpleKVList extends StatelessWidget {
  const _SimpleKVList({required this.rec});
  final Map<String, Object?> rec;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final e in rec.entries)
          if (!e.key.startsWith('_') && e.value != null && e.value.toString().trim().isNotEmpty)
            KVRow(label: e.key, value: e.value.toString()),
      ],
    );
  }
}
