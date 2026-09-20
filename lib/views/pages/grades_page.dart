/// 成绩页。采用现代化的 Cupertino 设计，引入更细腻的表格展示与磨砂玻璃质感。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/grades_vm.dart';
import '../../viewmodels/semester_vm.dart';
import '../widgets/cupertino_kit.dart';

class GradesPage extends ConsumerWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;
    
    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.grades),
            backgroundColor: p.bar.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => ref.read(gradesProvider.notifier).refresh(),
                  child: const Icon(CupertinoIcons.arrow_clockwise),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _pickSemester(context, ref),
                  child: const Icon(CupertinoIcons.calendar),
                ),
              ],
            ),
          ),
          const _GradesBody(),
        ],
      ),
    );
  }

  Future<void> _pickSemester(BuildContext context, WidgetRef ref) async {
    final selection = ref.read(semesterSelectionProvider).value;
    if (selection == null) return;
    
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        final p = AppThemeScope.of(ctx);
        return BlurView(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(width: 36, height: 5, decoration: BoxDecoration(color: p.separator, borderRadius: BorderRadius.circular(2.5))),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(ctx.l10n.switchSemester, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: selection.options.length,
                    separatorBuilder: (_, __) => Sep(indent: 16, endIndent: 16),
                    itemBuilder: (ctx, index) {
                      final opt = selection.options.reversed.toList()[index];
                      final isCurrent = opt['id'] == selection.currentId;
                      return Tile(
                        title: Text(opt['label'] as String? ?? '${opt['id']}'),
                        trailing: isCurrent ? Icon(CupertinoIcons.check_mark, color: p.primary, size: 18) : null,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          ref.read(semesterSelectionProvider.notifier).select(opt['id'] as int);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GradesBody extends ConsumerWidget {
  const _GradesBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gradesProvider);
    final l10n = context.l10n;
    
    return AsyncSliver<GradesData?>(
      async: async,
      emptyText: l10n.noGrades,
      onRetry: () => ref.read(gradesProvider.notifier).refresh(),
      builder: (context, data) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _content(context, data!),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, GradesData data) {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.fallbackError != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: CupertinoColors.systemRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(data.fallbackError!, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemRed, fontWeight: FontWeight.w500)),
          ),
          
        BlurView(
          borderRadius: BorderRadius.circular(12),
          color: p.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(CupertinoIcons.doc_text_fill, size: 18, color: p.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(data.semesterLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Text(data.fromCache ? l10n.fromCache : l10n.fromOnline, style: TextStyle(fontSize: 12, color: p.secondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        if (data.records.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 60), child: CupertinoEmpty(message: l10n.noGrades))
        else
          _buildTable(context, data),
          
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTable(BuildContext context, GradesData data) {
    final p = AppThemeScope.of(context);
    final headers = data.headers;
    if (headers.isEmpty) return CupertinoEmpty(message: context.l10n.noGrades, icon: CupertinoIcons.doc_text);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(context.l10n.gradesDetail, style: TextStyle(fontSize: 13, color: p.secondary, fontWeight: FontWeight.bold)),
        ),
        Container(
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: p.separator.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: KeyedSubtree(
              key: ValueKey('grades_table_${data.semesterId}'),
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: p.secondary.withValues(alpha: 0.05)),
                    children: [for (final h in headers) _cellText(context, h, bold: true)],
                  ),
                  for (var i = 0; i < data.records.length; i++)
                    TableRow(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.separator, width: 0.5))),
                      children: [
                        for (final h in headers)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _showRecord(context, data.records[i]),
                            child: _cellText(context, s(data.records[i], h)),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cellText(BuildContext context, String text, {bool bold = false}) {
    final p = AppThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(text, style: TextStyle(fontSize: 14, color: p.label, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
    );
  }

  void _showRecord(BuildContext context, Map<String, Object?> rec) {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;
    
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => BlurView(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 5, decoration: BoxDecoration(color: p.separator, borderRadius: BorderRadius.circular(2.5))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.recordDetail, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final e in rec.entries)
                      KVRow(label: e.key, value: e.value?.toString() ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CupertinoButton(child: Text(l10n.close, style: const TextStyle(fontWeight: FontWeight.bold)), onPressed: () => Navigator.of(ctx).pop()),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
