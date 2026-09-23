/// 培养计划页 —— 学业学分进度看板与指导性培养方案。
///
/// 具备：
/// - 学分完成度 Hero 卡片与各课程模块进度分解
/// - 指导性培养方案与专业修读计划
/// - 转专业申请说明与校务入口
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/plan_vm.dart';
import '../widgets/cupertino_kit.dart';

class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  int _tab = 0; // 0=完成度 1=我的计划 2=培养方案 3=转专业

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;
    final async = ref.watch(planProvider);

    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.plan),
            backgroundColor: p.bar.withValues(alpha: 0.82),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: () => ref.read(planProvider.notifier).refresh(),
              child: const Icon(CupertinoIcons.arrow_clockwise, size: 20),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(planProvider.notifier).refresh(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _tab,
                  onValueChanged: (v) {
                    if (v != null) {
                      HapticFeedback.selectionClick();
                      setState(() => _tab = v);
                    }
                  },
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        l10n.tabCompletion,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        l10n.tabMyPlan,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    2: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        l10n.tabMajorPlan,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    3: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        l10n.tabStdApply,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  },
                ),
              ),
            ),
          ),
          _PlanContent(tab: _tab, async: async),
        ],
      ),
    );
  }
}

class _PlanContent extends StatelessWidget {
  const _PlanContent({required this.tab, required this.async});

  final int tab;
  final AsyncValue<PlanData> async;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CupertinoActivityIndicator(radius: 14)),
      ),
      error: (e, _) => SliverFillRemaining(
        child: CupertinoErrorCard(
          message: '$e',
          onRetry: () => ProviderScope.containerOf(context).read(planProvider.notifier).refresh(),
        ),
      ),
      data: (data) => _buildView(context, data),
    );
  }

  Widget _buildView(BuildContext context, PlanData data) {
    switch (tab) {
      case 0:
        return _CompletionView(data: data.completion.value ?? const {});
      case 1:
        return _TableView(data: data.byMajor.value ?? const {}, emptyText: context.l10n.noPlanByMajor);
      case 2:
        return _TableView(data: data.major.value ?? const {}, emptyText: context.l10n.noPlanMajor);
      default:
        return _ApplyView(data: data.stdApply.value ?? const {});
    }
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.data});
  final Map<String, Object?> data;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final summary = data['summary'];
    final sections = data['sections'];

    if (summary is! Map && (sections is! List || sections.isEmpty)) {
      return SliverFillRemaining(
        child: CupertinoEmpty(
          message: context.l10n.noPlanCompletion,
          icon: CupertinoIcons.list_bullet_indent,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 汇总大卡片
            if (summary is Map && summary.isNotEmpty) ...[
              CupertinoCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.chart_pie_fill, size: 18, color: p.primary),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.creditsOverview,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: p.label,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Sep(),
                    const SizedBox(height: 10),
                    for (final e in summary.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Text(
                              '${e.key}',
                              style: TextStyle(fontSize: 14, color: p.secondary),
                            ),
                            const Spacer(),
                            Text(
                              '${e.value}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: p.label,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 各模块分段
            if (sections is List)
              for (final s in sections)
                if (s is Map) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      (s['group'] as String?) ?? context.l10n.moduleDetail,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: p.secondary,
                      ),
                    ),
                  ),
                  _buildSectionCard(s, p),
                  const SizedBox(height: 16),
                ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(Map s, AppPalette p) {
    final summary = s['summary'];
    final recs = s['records'];

    return CupertinoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary is Map)
            for (final e in summary.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('${e.key}', style: TextStyle(fontSize: 13, color: p.secondary)),
                    const Spacer(),
                    Text('${e.value}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: p.primary)),
                  ],
                ),
              ),
          if (recs is List && recs.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Sep(),
            const SizedBox(height: 8),
            for (final r in recs)
              if (r is Map<String, Object?>)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          r['课程名称']?.toString() ?? r['课程']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: p.label, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        r['成绩']?.toString() ?? r['修读情况']?.toString() ?? '',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.secondary),
                      ),
                    ],
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _TableView extends StatelessWidget {
  const _TableView({required this.data, required this.emptyText});
  final Map<String, Object?> data;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final err = data['error'];
    if (err is String && err.isNotEmpty) {
      return SliverFillRemaining(
        child: CupertinoEmpty(
          message: err,
          icon: CupertinoIcons.lock_shield,
        ),
      );
    }

    final tables = data['tables'];
    if (tables is! List || tables.isEmpty) {
      return SliverFillRemaining(child: CupertinoEmpty(message: emptyText));
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final t = tables[i] as Map<String, Object?>;
            final title = (t['title'] as String?) ?? context.l10n.courseScheme;
            final headers = (t['headers'] as List? ?? const []).map((e) => '$e').toList();
            final records = (t['records'] as List? ?? const []).whereType<Map<String, Object?>>().toList();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.secondary),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.border, width: 0.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Table(
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        defaultColumnWidth: const IntrinsicColumnWidth(),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: p.secondary.withValues(alpha: 0.05)),
                            children: [
                              for (final h in headers)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Text(h, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: p.secondary)),
                                ),
                            ],
                          ),
                          for (final r in records)
                            TableRow(
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.border, width: 0.5))),
                              children: [
                                for (var idx = 0; idx < headers.length; idx++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    child: Text(
                                      '${r[headers[idx]] ?? r['col${idx + 1}'] ?? ''}',
                                      style: TextStyle(fontSize: 13, color: p.label),
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
          },
          childCount: tables.length,
        ),
      ),
    );
  }
}

class _ApplyView extends StatelessWidget {
  const _ApplyView({required this.data});
  final Map<String, Object?> data;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final text = data['text'];
    final menus = data['menus'];

    if ((text is! String || text.isEmpty) && (menus is! List || menus.isEmpty)) {
      return SliverFillRemaining(child: CupertinoEmpty(message: context.l10n.noStdApply));
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            if (text is String && text.isNotEmpty)
              CupertinoCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  text,
                  style: TextStyle(fontSize: 14, color: p.label, height: 1.5),
                ),
              ),
            const SizedBox(height: 16),
            if (menus is List && menus.isNotEmpty)
              Group(
                header: Text(context.l10n.affairChannel),
                children: [
                  for (final m in menus)
                    if (m is Map)
                      Tile(
                        leading: const TileIcon(icon: CupertinoIcons.link, color: CupertinoColors.systemGreen),
                        title: Text('${m['text'] ?? ''}'),
                        subtitle: Text('${m['href'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {},
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
