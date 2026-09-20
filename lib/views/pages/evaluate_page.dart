/// 教学评价页 —— Cupertino 纯 iOS 风格。
///
/// - 导航栏：trailing 刷新；标题『教学评价』
/// - 主体：下拉刷新 + Group 评价任务列表（点击一条弹出详情 KV）
/// - 数据：evaluateProvider（缓存优先，离线可用）
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
            backgroundColor: p.bar.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => ref.read(evaluateProvider.notifier).refresh(),
              child: const Icon(CupertinoIcons.arrow_clockwise),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(evaluateProvider.notifier).refresh(),
          ),
          AsyncSliver<Map<String, Object?>?>(
            async: ref.watch(evaluateProvider),
            emptyText: l10n.noEvaluate,
            onRetry: () => ref.read(evaluateProvider.notifier).refresh(),
            sliverPadding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
        if (r is Map<String, Object?>) r
    ];

    if (records.isEmpty) {
      return SizedBox(
        height: 200,
        child: CupertinoEmpty(message: context.l10n.noEvaluate),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          header: Text(context.l10n.pendingTasks),
          children: [
            for (final rec in records)
              Tile(
                title: Text(_primary(rec, context)),
                subtitle: _hasLinks(rec) ? Text(context.l10n.clickToView) : null,
                leading: const TileIcon(
                  icon: CupertinoIcons.doc_text_search,
                  color: CupertinoColors.systemOrange,
                ),
                onTap: () => _showDetail(context, rec),
              ),
          ],
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
    final kv = [
      for (final e in rec.entries)
        if (e.key != '_links' && e.key != 'file') (e.key, '${e.value ?? ''}'),
    ];

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        final p = AppThemeScope.of(ctx);
        return BlurView(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: p.separator,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    ctx.l10n.evalDetail,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: p.label,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Group(
                        margin: EdgeInsets.zero,
                        children: [
                          for (final item in kv)
                            KVRow(label: item.$1, value: item.$2),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CupertinoButton(
                    child: Text(ctx.l10n.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
