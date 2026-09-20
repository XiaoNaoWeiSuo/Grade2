/// 系统消息页 —— 展示一组系统通知（主题 / 发件人 / 时间）。
///
/// 单 Provider（messagesProvider）缓存优先渲染；整页 CustomScrollView +
/// CupertinoSliverRefreshControl 下拉刷新，导航栏右上角"刷新"按钮强制在线刷新；
/// 点击单条消息弹底部详情（列出除 _links/file 外的全部 KV）。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/messages_vm.dart';
import '../widgets/cupertino_kit.dart';

class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

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
            largeTitle: Text(l10n.messages),
            backgroundColor: p.bar.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => ref.read(messagesProvider.notifier).refresh(),
              child: const Icon(CupertinoIcons.arrow_clockwise),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(messagesProvider.notifier).refresh(),
          ),
          AsyncSliver<Map<String, Object?>?>(
            async: ref.watch(messagesProvider),
            onRetry: () => ref.read(messagesProvider.notifier).refresh(),
            emptyText: l10n.noMessages,
            sliverPadding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            builder: (context, data) => _MessagesContent(data: data),
          ),
        ],
      ),
    );
  }
}

class _MessagesContent extends StatelessWidget {
  const _MessagesContent({this.data});
  final Map<String, Object?>? data;

  @override
  Widget build(BuildContext context) {
    final records = [
      for (final r in (data?['records'] as List? ?? const []))
        if (r is Map<String, Object?>) r,
    ];

    if (records.isEmpty) {
      return SizedBox(
        height: 200,
        child: CupertinoEmpty(message: context.l10n.noMessages),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          children: [
            for (final m in records)
              Tile(
                title: Text(
                  s(m, '主题').isEmpty ? context.l10n.noSubject : s(m, '主题'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    if (s(m, '发件人').isNotEmpty) s(m, '发件人'),
                    if (s(m, '时间').isNotEmpty) s(m, '时间'),
                  ].join('  ·  '),
                ),
                leading: const TileIcon(
                  icon: CupertinoIcons.mail,
                  color: CupertinoColors.systemBlue,
                ),
                onTap: () => _showDetail(context, m),
              ),
          ],
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, Map<String, Object?> m) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => _DetailSheet(record: m),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.record});
  final Map<String, Object?> record;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final kv = [
      for (final e in record.entries)
        if (e.key != '_links' && e.key != 'file') (e.key, '${e.value ?? ''}'),
    ];

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
                s(record, '主题').isEmpty ? context.l10n.msgDetail : s(record, '主题'),
                textAlign: TextAlign.center,
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
                    children: kv.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(context.l10n.noDetail,
                                  style: TextStyle(color: p.secondary)),
                            ),
                          ]
                        : [
                            for (final item in kv)
                              KVRow(label: item.$1, value: item.$2),
                          ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CupertinoButton(
                child: Text(context.l10n.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
