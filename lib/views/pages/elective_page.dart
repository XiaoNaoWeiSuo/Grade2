/// 选课入口页：轮次列表。采用现代化的 Inset Grouped 列表与大标题导航栏。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/elective_vm.dart';
import '../widgets/cupertino_kit.dart';
import 'elective_lessons_page.dart';

class ElectivePage extends ConsumerWidget {
  const ElectivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;
    
    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.elective),
            backgroundColor: p.bar.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
          ),
          const _ProfilesBody(),
        ],
      ),
    );
  }
}

class _ProfilesBody extends ConsumerWidget {
  const _ProfilesBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(electiveProvider);
    final l10n = context.l10n;
    
    return AsyncSliver<ElectiveState>(
      async: async,
      onRetry: () => ref.read(electiveProvider.notifier).loadProfiles(),
      emptyText: l10n.noProfiles,
      builder: (context, data) {
        final profiles = data.profiles;
        return SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Group(
                header: Text(l10n.electiveProfiles),
                children: [
                  for (final profile in profiles)
                    _ProfileTile(
                      profile: profile,
                      onTap: () => pushPage(context, ElectiveLessonsPage(profile: profile)),
                    ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.profile, required this.onTap});
  final Map<String, Object?> profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;
    final name = s(profile, 'name');
    final round = i(profile, 'round');
    final electOpen = s(profile, 'elect_open').isNotEmpty;
    final withdrawOpen = s(profile, 'withdraw_open').isNotEmpty;
    final limits = profile['limits'] as List? ?? const [];

    return Tile(
      onTap: onTap,
      title: Text(
        round != null ? l10n.roundLabel.replaceFirst('%1', name).replaceFirst('%2', '$round') : name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Row(
            children: [
              _StatusBadge(open: electOpen, openText: l10n.electOpen, closedText: l10n.electClosed),
              const SizedBox(width: 8),
              _StatusBadge(open: withdrawOpen, openText: l10n.withdrawOpen, closedText: l10n.withdrawClosed),
            ],
          ),
          if (limits.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final limit in limits)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('· $limit', style: TextStyle(fontSize: 12, color: p.secondary)),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.open, required this.openText, required this.closedText});
  final bool open;
  final String openText;
  final String closedText;

  @override
  Widget build(BuildContext context) {
    final color = open ? CupertinoColors.systemGreen : CupertinoColors.systemGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.circle_fill, size: 6, color: color),
          const SizedBox(width: 4),
          Text(open ? openText : closedText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
