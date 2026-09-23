/// 系统消息页 —— 教务系统通知与邮件列表。
/// 采用 iOS 邮箱质感的列表呈现与抽屉详情。
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
            backgroundColor: p.bar.withValues(alpha: 0.82),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: () => ref.read(messagesProvider.notifier).refresh(),
              child: const Icon(CupertinoIcons.arrow_clockwise, size: 20),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(messagesProvider.notifier).refresh(),
          ),
          AsyncSliver<Map<String, Object?>?>(
            async: ref.watch(messagesProvider),
            onRetry: () => ref.read(messagesProvider.notifier).refresh(),
            emptyText: l10n.noMessages,
            sliverPadding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: CupertinoEmpty(
          message: context.l10n.noMessages,
          icon: CupertinoIcons.envelope_badge,
        ),
      );
    }

    return Group(
      margin: EdgeInsets.zero,
      children: [
        for (final m in records)
          Tile(
            leading: const TileIcon(
              icon: CupertinoIcons.mail_solid,
              color: CupertinoColors.systemRed,
            ),
            title: Text(
              s(m, '主题').isEmpty ? context.l10n.noSubject : s(m, '主题'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              [
                if (s(m, '发件人').isNotEmpty) s(m, '发件人'),
                if (s(m, '时间').isNotEmpty) s(m, '时间'),
              ].join(' · '),
            ),
            onTap: () => _showDetail(context, m),
          ),
      ],
    );
  }

  void _showDetail(BuildContext context, Map<String, Object?> m) {
    final title = s(m, '主题').isEmpty ? context.l10n.msgDetail : s(m, '主题');
    final p = AppThemeScope.of(context);
    final kv = [
      for (final e in m.entries)
        if (e.key != '_links' && e.key != 'file' && e.value != null && e.value.toString().isNotEmpty)
          (e.key, '${e.value}'),
    ];

    showCupertinoModalSheet<void>(
      context: context,
      builder: (ctx) => CupertinoSheetContainer(
        title: title,
        subtitle: s(m, '时间'),
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
