/// 选课入口页：轮次列表。
/// 采用现代 iOS 状态卡片展示选课轮次、开放期、限额与规则。
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
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.elective),
            backgroundColor: p.bar.withValues(alpha: 0.82),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: () => ref.read(electiveProvider.notifier).loadProfiles(),
              child: const Icon(CupertinoIcons.arrow_clockwise, size: 20),
            ),
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
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  l10n.electiveProfiles,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppThemeScope.of(context).secondary,
                  ),
                ),
              ),
              for (final profile in profiles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProfileCard(
                    profile: profile,
                    onTap: () => pushPage(context, ElectiveLessonsPage(profile: profile)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onTap});

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
    final notice = s(profile, 'notice');

    final title = round != null
        ? l10n.roundLabel.replaceFirst('%1', name).replaceFirst('%2', '$round')
        : name;

    return CupertinoCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.label,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Icon(CupertinoIcons.chevron_right, size: 16, color: p.tertiary),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CupertinoPillBadge(
                text: electOpen ? l10n.electOpen : l10n.electClosed,
                icon: electOpen ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.xmark_circle_fill,
                color: electOpen
                    ? p.success.withValues(alpha: 0.12)
                    : p.secondary.withValues(alpha: 0.12),
                textColor: electOpen ? p.success : p.secondary,
              ),
              const SizedBox(width: 8),
              CupertinoPillBadge(
                text: withdrawOpen ? l10n.withdrawOpen : l10n.withdrawClosed,
                icon: withdrawOpen ? CupertinoIcons.arrow_uturn_left_circle_fill : CupertinoIcons.slash_circle_fill,
                color: withdrawOpen
                    ? p.primary.withValues(alpha: 0.12)
                    : p.secondary.withValues(alpha: 0.12),
                textColor: withdrawOpen ? p.primary : p.secondary,
              ),
            ],
          ),
          if (limits.isNotEmpty || notice.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Sep(),
            const SizedBox(height: 10),
            if (notice.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  notice,
                  style: TextStyle(fontSize: 12, color: p.secondary, height: 1.3),
                ),
              ),
            for (final limit in limits)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $limit',
                  style: TextStyle(fontSize: 12, color: p.secondary),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
