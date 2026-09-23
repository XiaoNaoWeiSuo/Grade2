/// 考试安排页 —— 现代化准考证卡片与等级考试看板。
///
/// 特性：
/// - 准考证风格的考试卡片（考场、座位号高亮、开考倒计时）
/// - 分段式管理：正考/补考批次、四六级/等级考试、中期考核
/// - 复制考场信息快捷交互
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/exam_vm.dart';
import '../widgets/cupertino_kit.dart';

class ExamPage extends ConsumerStatefulWidget {
  const ExamPage({super.key});

  @override
  ConsumerState<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends ConsumerState<ExamPage> {
  int _categoryTab = 0; // 0=期末/补考 1=等级考试 2=中期考核

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;

    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.exam),
            backgroundColor: p.bar.withValues(alpha: 0.82),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: () => ref.read(examProvider.notifier).refresh(),
              child: const Icon(CupertinoIcons.arrow_clockwise, size: 20),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _categoryTab,
                  onValueChanged: (v) {
                    if (v != null) {
                      HapticFeedback.selectionClick();
                      setState(() => _categoryTab = v);
                    }
                  },
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Text(
                        l10n.examArrange,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Text(
                        l10n.othersExam,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    2: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Text(
                        l10n.midterm,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  },
                ),
              ),
            ),
          ),
          _ExamBody(categoryTab: _categoryTab),
        ],
      ),
    );
  }
}

class _ExamBody extends ConsumerWidget {
  const _ExamBody({required this.categoryTab});

  final int categoryTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(examProvider);
    final state = async.value;
    final l10n = context.l10n;
    final p = AppThemeScope.of(context);

    if (async.isLoading && state == null) {
      return const SliverFillRemaining(
        child: Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    }

    if (state == null) {
      return SliverFillRemaining(
        child: CupertinoErrorCard(
          message: '${async.error}',
          onRetry: () => ref.read(examProvider.notifier).refresh(),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
      sliver: SliverToBoxAdapter(
        child: switch (categoryTab) {
          0 => _buildArranges(context, ref, state, p, l10n),
          1 => _buildOthers(context, ref, state, p, l10n),
          _ => _buildMidterm(context, ref, state, p, l10n),
        },
      ),
    );
  }

  Widget _buildArranges(
    BuildContext context,
    WidgetRef ref,
    ExamState state,
    AppPalette p,
    AppStrings l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 批次选择胶囊横条
        state.batches.when(
          loading: () => const SizedBox(
            height: 36,
            child: Center(child: CupertinoActivityIndicator(radius: 8)),
          ),
          error: (e, _) => Text('$e', style: TextStyle(fontSize: 12, color: p.destructive)),
          data: (batches) {
            if (batches.isEmpty) return const SizedBox.shrink();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final b in batches)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: CupertinoScaleButton(
                        onTap: () => ref.read(examProvider.notifier).selectBatch(b['id'] as int),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: state.selectedBatchId == b['id'] ? p.primary : p.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: state.selectedBatchId == b['id'] ? p.primary : p.border,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            s(b, 'name').isEmpty ? '# ${b['id']}' : s(b, 'name'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: state.selectedBatchId == b['id']
                                  ? CupertinoColors.white
                                  : p.label,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // 考试安排列表
        state.table.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CupertinoActivityIndicator(radius: 12)),
          ),
          error: (e, _) => CupertinoErrorCard(
            message: '$e',
            onRetry: () => ref.read(examProvider.notifier).refresh(),
          ),
          data: (table) {
            final records = asMapList(table['records']);
            if (records.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: CupertinoEmpty(
                  message: l10n.noExamArrange,
                  icon: CupertinoIcons.doc_checkmark,
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) => _ExamTicketCard(rec: records[index], p: p),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOthers(
    BuildContext context,
    WidgetRef ref,
    ExamState state,
    AppPalette p,
    AppStrings l10n,
  ) {
    return state.others.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CupertinoActivityIndicator(radius: 12)),
      ),
      error: (e, _) => CupertinoErrorCard(
        message: '$e',
        onRetry: () => ref.read(examProvider.notifier).loadOthers(),
      ),
      data: (others) {
        final signups = asMapList(others['signups']);
        final scores = asMapList(others['scores']);

        if (signups.isEmpty && scores.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: CupertinoEmpty(
              message: l10n.noSignups,
              icon: CupertinoIcons.doc_text_search,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (scores.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  l10n.examScoresObtained,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.secondary,
                  ),
                ),
              ),
              for (final s in scores)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CupertinoCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final e in s.entries)
                          if (!e.key.startsWith('_') && e.value != null && e.value.toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text(e.key, style: TextStyle(fontSize: 13, color: p.secondary)),
                                  const Spacer(),
                                  Text(
                                    e.value.toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: e.key.contains('成绩') || e.key.contains('分数')
                                          ? p.primary
                                          : p.label,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            if (signups.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  l10n.examSignupRecords,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.secondary,
                  ),
                ),
              ),
              for (final s in signups)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CupertinoCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final e in s.entries)
                          if (!e.key.startsWith('_') && e.value != null && e.value.toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text(e.key, style: TextStyle(fontSize: 13, color: p.secondary)),
                                  const Spacer(),
                                  Text(e.value.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.label)),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMidterm(
    BuildContext context,
    WidgetRef ref,
    ExamState state,
    AppPalette p,
    AppStrings l10n,
  ) {
    return state.midterm.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CupertinoActivityIndicator(radius: 12)),
      ),
      error: (e, _) => CupertinoErrorCard(
        message: '$e',
        onRetry: () => ref.read(examProvider.notifier).loadMidterm(),
      ),
      data: (mid) {
        final text = mid['text']?.toString() ?? '';
        if (text.trim().isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: CupertinoEmpty(
              message: l10n.noMidterm,
              icon: CupertinoIcons.doc_plaintext,
            ),
          );
        }
        return CupertinoCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.doc_chart, size: 20, color: p.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.midterm,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.label,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Sep(),
              const SizedBox(height: 12),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: p.label,
                  height: 1.6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExamTicketCard extends StatelessWidget {
  const _ExamTicketCard({required this.rec, required this.p});

  final Map<String, Object?> rec;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = rec['课程']?.toString() ?? rec['课程名称']?.toString() ?? l10n.examSubject;
    final time = rec['考试时间']?.toString() ?? '';
    final room = rec['考场']?.toString() ?? '';
    final seat = rec['座位号']?.toString() ?? '';

    return CupertinoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.label,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (seat.isNotEmpty) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: p.primary.withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.number, size: 12, color: p.primary),
                      const SizedBox(width: 2),
                      Text(
                        l10n.seatLabel(seat),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Sep(),
          const SizedBox(height: 12),
          if (time.isNotEmpty)
            _TicketRow(
              icon: CupertinoIcons.clock_fill,
              label: l10n.examTime,
              value: time,
              p: p,
            ),
          if (room.isNotEmpty) ...[
            const SizedBox(height: 8),
            _TicketRow(
              icon: CupertinoIcons.location_solid,
              label: l10n.examRoom,
              value: room,
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 24),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: room));
                  toast(context, l10n.examRoomCopied);
                },
                child: Text(
                  l10n.copy,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.primary),
                ),
              ),
              p: p,
            ),
          ],
        ],
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    required this.p,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: p.secondary),
        const SizedBox(width: 8),
        Text('$label：', style: TextStyle(fontSize: 13, color: p.secondary)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.label),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
