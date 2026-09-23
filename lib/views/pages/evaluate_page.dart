/// 教学评价页 —— 期末教师评教任务看板。
/// 采用 iOS 任务清单风格呈现与抽屉详情。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/evaluate_vm.dart';
import '../widgets/cupertino_kit.dart';

class EvaluatePage extends ConsumerWidget {
  const EvaluatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;

    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.evaluate),
            backgroundColor: p.bar.withValues(alpha: 0.82),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: () => ref.read(evaluateProvider.notifier).refresh(),
              child: const Icon(CupertinoIcons.arrow_clockwise, size: 20),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(evaluateProvider.notifier).refresh(),
          ),
          AsyncSliver<Map<String, Object?>?>(
            async: ref.watch(evaluateProvider),
            emptyText: l10n.noEvaluate,
            onRetry: () => ref.read(evaluateProvider.notifier).refresh(),
            sliverPadding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
            builder: (context, data) => _EvaluateContent(data: data ?? const {}),
          ),
        ],
      ),
    );
  }
}

class _EvaluateContent extends StatelessWidget {
  const _EvaluateContent({required this.data});
  final Map<String, Object?> data;

  @override
  Widget build(BuildContext context) {
    final records = [
      for (final r in (data['records'] as List? ?? const []))
        if (r is Map<String, Object?>) r,
    ];

    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: CupertinoEmpty(
          message: context.l10n.noEvaluate,
          description: context.l10n.evaluateClosed,
          icon: CupertinoIcons.checkmark_seal_fill,
        ),
      );
    }

    return Group(
      header: Text(context.l10n.pendingTasks),
      children: [
        for (final rec in records)
          Tile(
            leading: const TileIcon(
              icon: CupertinoIcons.doc_checkmark_fill,
              color: CupertinoColors.systemYellow,
            ),
            title: Text(
              _primary(rec, context),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: _hasLinks(rec) ? Text(context.l10n.clickToView) : null,
            onTap: () => _showDetail(context, rec),
          ),
      ],
    );
  }

  bool _hasLinks(Map<String, Object?> rec) {
    final links = rec['_links'];
    return links is List && links.isNotEmpty;
  }

  String _primary(Map<String, Object?> rec, BuildContext context) {
    for (final e in rec.entries) {
      if (e.key == '_links' || e.key == 'file') continue;
      final v = e.value;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return context.l10n.unnamedTask;
  }

  void _showDetail(BuildContext context, Map<String, Object?> rec) {
    final title = _primary(rec, context);
    final p = AppThemeScope.of(context);
    final kv = [
      for (final e in rec.entries)
        if (e.key != '_links' && e.key != 'file' && e.value != null && e.value.toString().isNotEmpty)
          (e.key, '${e.value}'),
    ];

    showCupertinoModalSheet<void>(
      context: context,
      builder: (ctx) => CupertinoSheetContainer(
        title: title,
        subtitle: ctx.l10n.evalDetail,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            for (final item in kv)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        item.$1,
                        style: TextStyle(
                          fontSize: 13,
                          color: p.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: p.label,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
