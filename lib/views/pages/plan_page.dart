/// 培养计划页 —— 顶部 CupertinoSegmentedControl 切四块：完成度 / 我的计划 / 培养方案 / 转专业申请。
///
/// 单 Provider（planProvider）内四块数据并行加载，各子视图用 AsyncSliver 独立渲染；
/// 整页 CustomScrollView + CupertinoSliverRefreshControl 下拉刷新。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/plan_vm.dart';
import '../widgets/cupertino_kit.dart';

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppThemeScope.of(context);
    
    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: const _PlanBody(),
    );
  }
}

class _PlanBody extends ConsumerStatefulWidget {
  const _PlanBody();
  @override
  ConsumerState<_PlanBody> createState() => _PlanBodyState();
}

class _PlanBodyState extends ConsumerState<_PlanBody> {
  int _index = 0;

  Future<void> _refresh() => ref.read(planProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;
    final async = ref.watch(planProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: Text(l10n.plan),
          backgroundColor: p.bar.withValues(alpha: 0.8),
          border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
          stretch: true,
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _refresh,
            child: const Icon(CupertinoIcons.arrow_clockwise),
          ),
        ),
        CupertinoSliverRefreshControl(onRefresh: _refresh),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _index,
              onValueChanged: (v) => setState(() => _index = v ?? 0),
              children: {
                0: _Segment(l10n.tabCompletion),
                1: _Segment(l10n.tabMyPlan),
                2: _Segment(l10n.tabMajorPlan),
                3: _Segment(l10n.tabStdApply),
              },
            ),
          ),
        ),
        _Content(index: _index, async: async),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.index, required this.async});
  final int index;
  final AsyncValue<PlanData> async;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CupertinoActivityIndicator(radius: 12)),
      ),
      error: (e, _) => SliverFillRemaining(
        child: CupertinoEmpty(
          message: '$e',
          icon: CupertinoIcons.exclamationmark_triangle,
        ),
      ),
      data: (data) => _buildData(context, data),
    );
  }

  Widget _buildData(BuildContext context, PlanData data) {
    switch (index) {
      case 0: return _CompletionView(data: data.completion.value ?? const {});
      case 1: return _TableView(data: data.byMajor.value ?? const {}, emptyText: '暂无我的计划数据');
      case 2: return _TableView(data: data.major.value ?? const {}, emptyText: '暂无培养方案数据');
      case 3: return _ApplyView(data: data.stdApply.value ?? const {});
      default: return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.data});
  final Map<String, Object?> data;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final summary = data['summary'];
    if (summary is Map) {
      children.add(Group(
        header: const Text('完成度汇总'),
        children: [
          for (final e in summary.entries)
            KVRow(label: '${e.key}', value: '${e.value}'),
        ],
      ));
    }

    final sections = data['sections'];
    if (sections is List) {
      for (final s in sections) {
        if (s is! Map) continue;
        final groupName = (s['group'] as String?) ?? '课程明细';
        final groupChildren = <Widget>[];
        
        final g = s['summary'];
        if (g is Map) {
          for (final e in g.entries) {
            groupChildren.add(KVRow(label: '${e.key}', value: '${e.value}'));
          }
        }
        
        final recs = s['records'];
        if (recs is List) {
          for (final r in recs) {
            if (r is! Map<String, Object?>) continue;
            for (final e in r.entries) {
              if (e.key.startsWith('_')) continue;
              groupChildren.add(KVRow(label: e.key, value: '${e.value}'));
            }
          }
        }
        
        children.add(Group(
          header: Text(groupName),
          children: groupChildren,
        ));
      }
    }

    if (children.isEmpty) {
      return const SliverFillRemaining(child: CupertinoEmpty(message: '暂无完成情况数据'));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(delegate: SliverChildListDelegate(children)),
    );
  }
}

class _TableView extends StatelessWidget {
  const _TableView({required this.data, required this.emptyText});
  final Map<String, Object?> data;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final t = tables[i] as Map<String, Object?>;
            return _PlanTable(table: t);
          },
          childCount: tables.length,
        ),
      ),
    );
  }
}

class _PlanTable extends StatelessWidget {
  const _PlanTable({required this.table});
  final Map<String, Object?> table;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final title = (table['title'] as String?) ?? '';
    final headers = (table['headers'] as List? ?? const []).map((e) => '$e').toList();
    final records = (table['records'] as List? ?? const []).whereType<Map<String, Object?>>().toList();

    if (headers.isEmpty && records.isEmpty) return const SizedBox.shrink();

    return Group(
      header: title.isNotEmpty ? Text(title) : null,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder(
              horizontalInside: BorderSide(color: p.separator, width: 0.5),
            ),
            children: [
              TableRow(
                children: [
                  for (final h in headers)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(h, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              for (final r in records)
                TableRow(
                  children: [
                    for (var i = 0; i < headers.length; i++)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(_cell(r, i, headers), style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _cell(Map<String, Object?> r, int i, List<String> headers) {
    final key = i < headers.length ? headers[i] : 'col${i + 1}';
    return '${r[key] ?? ''}';
  }
}

class _ApplyView extends StatelessWidget {
  const _ApplyView({required this.data});
  final Map<String, Object?> data;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final children = <Widget>[];
    
    final text = data['text'];
    if (text is String && text.isNotEmpty) {
      children.add(Group(
        header: const Text('说明'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(text, style: TextStyle(fontSize: 14, color: p.secondary)),
          ),
        ],
      ));
    }

    final menus = data['menus'];
    if (menus is List && menus.isNotEmpty) {
      children.add(Group(
        header: const Text('相关入口'),
        children: [
          for (final m in menus)
            if (m is Map)
              Tile(
                title: Text('${m['text'] ?? ''}'),
                subtitle: Text('${m['href'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                leading: const TileIcon(icon: CupertinoIcons.link, color: CupertinoColors.systemGreen),
                onTap: () {}, // 仅展示
              ),
        ],
      ));
    }

    if (children.isEmpty) {
      return const SliverFillRemaining(child: CupertinoEmpty(message: '暂无申请信息'));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(delegate: SliverChildListDelegate(children)),
    );
  }
}
