/// 成绩查询页 —— 现代 iOS 数据卡片 + 绩点学分统计看板。
///
/// 特性：
/// - 学期绩点与学分统计 Hero 看板（平均学分绩点、总学分、修读门数）
/// - 课程成绩卡片流（分数颜色分级、学分胶囊、修读性质）
/// - 快速按课程名称搜索过滤
/// - 单击成绩卡片呼出 iOS 抽屉查看教务完整明细（平时、期末、折算分等）
/// - 保留原始完整表格切换（严格遵循 T14 KeyedSubtree 防断言机制）
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/grades_vm.dart';
import '../../viewmodels/semester_vm.dart';
import '../widgets/cupertino_kit.dart';

class GradesPage extends ConsumerStatefulWidget {
  const GradesPage({super.key});

  @override
  ConsumerState<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends ConsumerState<GradesPage> {
  final _searchCtrl = TextEditingController();
  int _viewMode = 0; // 0=现代卡片 1=完整原始表格

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
            largeTitle: Text(l10n.grades),
            backgroundColor: p.bar.withValues(alpha: 0.82),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                  onPressed: () => ref.read(gradesProvider.notifier).refresh(),
                  child: const Icon(CupertinoIcons.arrow_clockwise, size: 20),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                  onPressed: () => _pickSemester(context, ref),
                  child: const Icon(CupertinoIcons.calendar, size: 20),
                ),
              ],
            ),
          ),
          _GradesBody(
            searchQuery: _searchCtrl.text.trim().toLowerCase(),
            viewMode: _viewMode,
            searchWidget: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  CupertinoSearchTextField(
                    controller: _searchCtrl,
                    placeholder: context.l10n.searchCoursePlaceholder,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Spacer(),
                      SizedBox(
                        width: 160,
                        child: CupertinoSlidingSegmentedControl<int>(
                          groupValue: _viewMode,
                          onValueChanged: (v) {
                            if (v != null) setState(() => _viewMode = v);
                          },
                          children: {
                            0: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(context.l10n.cardFlowView, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            1: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(context.l10n.tableRawView, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSemester(BuildContext context, WidgetRef ref) async {
    final selection = ref.read(semesterSelectionProvider).value;
    if (selection == null) return;

    await showCupertinoModalSheet<void>(
      context: context,
      builder: (ctx) {
        final p = AppThemeScope.of(ctx);
        return CupertinoSheetContainer(
          title: ctx.l10n.switchSemester,
          subtitle: ctx.l10n.historySemesterGrades,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: selection.options.length,
            separatorBuilder: (_, _) => const Sep(indent: 16),
            itemBuilder: (subCtx, index) {
              final opt = selection.options.reversed.toList()[index];
              final isCurrent = opt['id'] == selection.currentId;
              return Tile(
                title: Text(opt['label'] as String? ?? '${opt['id']}'),
                trailing: isCurrent
                    ? Icon(
                        CupertinoIcons.checkmark_alt,
                        color: p.primary,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref.read(semesterSelectionProvider.notifier).select(opt['id'] as int);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _GradesBody extends ConsumerWidget {
  const _GradesBody({
    required this.searchQuery,
    required this.viewMode,
    required this.searchWidget,
  });

  final String searchQuery;
  final int viewMode;
  final Widget searchWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gradesProvider);
    final l10n = context.l10n;

    return AsyncSliver<GradesData?>(
      async: async,
      emptyText: l10n.noGrades,
      onRetry: () => ref.read(gradesProvider.notifier).refresh(),
      builder: (context, data) => _content(context, data!),
    );
  }

  Widget _content(BuildContext context, GradesData data) {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;
    final records = data.records;

    // 计算统计指标
    double totalCredits = 0.0;
    double weightedGpaSum = 0.0;
    double gpaCredits = 0.0;

    for (final r in records) {
      final cred = _findDouble(r, ['学分', 'credit', 'credits']);
      final gpa = _findDouble(r, ['绩点', 'gpa', 'point']);
      if (cred != null && cred > 0) {
        totalCredits += cred;
        if (gpa != null) {
          weightedGpaSum += (cred * gpa);
          gpaCredits += cred;
        }
      }
    }
    final avgGpa = gpaCredits > 0 ? (weightedGpaSum / gpaCredits) : null;

    // 过滤记录
    final filtered = records.where((r) {
      if (searchQuery.isEmpty) return true;
      final text = r.values.map((v) => v?.toString() ?? '').join(' ').toLowerCase();
      return text.contains(searchQuery);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 学期与缓存状态徽章
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Row(
              children: [
                CupertinoPillBadge(
                  text: data.semesterLabel,
                  icon: CupertinoIcons.calendar,
                  color: p.primary.withValues(alpha: 0.12),
                  textColor: p.primary,
                ),
                const SizedBox(width: 8),
                CupertinoPillBadge(
                  text: data.fromCache ? l10n.fromCache : l10n.fromOnline,
                  color: data.fromCache
                      ? p.secondary.withValues(alpha: 0.12)
                      : p.success.withValues(alpha: 0.12),
                  textColor: data.fromCache ? p.secondary : p.success,
                ),
              ],
            ),
          ),

          // 核心学业指标看板
          Row(
            children: [
              Expanded(
                child: CupertinoCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.gpaLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: p.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        avgGpa != null ? avgGpa.toStringAsFixed(2) : '--',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: p.label,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CupertinoCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.totalCreditsLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: p.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        totalCredits > 0 ? totalCredits.toStringAsFixed(1) : l10n.coursesCountSuffix(records.length),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: p.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          searchWidget,

          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: CupertinoEmpty(
                message: records.isEmpty ? l10n.noGrades : l10n.noGradesMatched,
                icon: CupertinoIcons.chart_bar_square,
              ),
            )
          else if (viewMode == 0)
            // 现代化卡片流视图
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) => _GradeCard(
                rec: filtered[index],
                p: p,
                onTap: () => _showRecordSheet(context, filtered[index], p, l10n),
              ),
            )
          else
            // 原始表格视图（KeyedSubtree 严格隔离防 T14 崩溃）
            _buildRawTable(context, data, filtered),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  double? _findDouble(Map<String, Object?> map, List<String> candidates) {
    for (final k in candidates) {
      final v = map[k];
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Widget _buildRawTable(
    BuildContext context,
    GradesData data,
    List<Map<String, Object?>> records,
  ) {
    final p = AppThemeScope.of(context);
    final headers = data.headers;
    if (headers.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: KeyedSubtree(
          key: ValueKey('grades_table_${data.semesterId}'),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              TableRow(
                decoration: BoxDecoration(color: p.secondary.withValues(alpha: 0.05)),
                children: [
                  for (final h in headers)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Text(
                        h,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: p.secondary),
                      ),
                    ),
                ],
              ),
              for (var i = 0; i < records.length; i++)
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: p.border, width: 0.5)),
                  ),
                  children: [
                    for (final h in headers)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showRecordSheet(context, records[i], p, context.l10n),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Text(
                            s(records[i], h),
                            style: TextStyle(fontSize: 13, color: p.label, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordSheet(
    BuildContext context,
    Map<String, Object?> rec,
    AppPalette p,
    AppStrings l10n,
  ) {
    final name = rec['课程名称']?.toString() ?? rec['课程']?.toString() ?? l10n.course;

    showCupertinoModalSheet<void>(
      context: context,
      builder: (ctx) => CupertinoSheetContainer(
        title: name,
        subtitle: l10n.rawGradesDetail,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            for (final e in rec.entries)
              if (!e.key.startsWith('_') && e.value != null && e.value.toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          e.key,
                          style: TextStyle(fontSize: 14, color: p.secondary, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value.toString(),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.label),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.rec,
    required this.p,
    required this.onTap,
  });

  final Map<String, Object?> rec;
  final AppPalette p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = rec['课程名称']?.toString() ?? rec['课程']?.toString() ?? l10n.course;
    final scoreStr = rec['成绩']?.toString() ?? rec['最终成绩']?.toString() ?? rec['分数']?.toString() ?? '--';
    final credit = rec['学分']?.toString() ?? '';
    final gpa = rec['绩点']?.toString() ?? '';
    final nature = rec['课程类别']?.toString() ?? rec['课程性质']?.toString() ?? '';

    // 分数色彩研判
    final scoreNum = double.tryParse(scoreStr);
    Color scoreColor = p.primary;
    if (scoreNum != null) {
      if (scoreNum >= 90) {
        scoreColor = p.success;
      } else if (scoreNum >= 80) {
        scoreColor = p.primary;
      } else if (scoreNum >= 60) {
        scoreColor = p.warning;
      } else {
        scoreColor = p.destructive;
      }
    } else {
      if (scoreStr.contains('优秀') || scoreStr.contains('良好')) {
        scoreColor = p.success;
      } else if (scoreStr.contains('不及格') || scoreStr.contains('未通过')) {
        scoreColor = p.destructive;
      }
    }

    return CupertinoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.label,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (credit.isNotEmpty)
                      CupertinoPillBadge(
                        text: l10n.creditsLabel.replaceFirst('%1', credit),
                        color: p.secondary.withValues(alpha: 0.1),
                        textColor: p.secondary,
                      ),
                    if (gpa.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      CupertinoPillBadge(
                        text: '${l10n.gpa} $gpa',
                        color: p.primary.withValues(alpha: 0.1),
                        textColor: p.primary,
                      ),
                    ],
                    if (nature.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        nature,
                        style: TextStyle(fontSize: 11, color: p.tertiary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  scoreStr,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
