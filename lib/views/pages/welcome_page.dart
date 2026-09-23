/// 欢迎与公告页 —— 校园教务通知公告与新闻资讯。
/// 采用现代 iOS 卡片式排版与大标题导航栏。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/welcome_vm.dart';
import '../widgets/cupertino_kit.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = AppThemeScope.of(context);

    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.welcome),
            backgroundColor: p.bar.withValues(alpha: 0.82),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: () => ref.read(welcomeProvider.notifier).refresh(),
              child: const Icon(CupertinoIcons.arrow_clockwise, size: 20),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(welcomeProvider.notifier).refresh(),
          ),
          AsyncSliver<Map<String, Object?>>(
            async: ref.watch(welcomeProvider),
            onRetry: () => ref.invalidate(welcomeProvider),
            emptyText: l10n.noAnnounce,
            sliverPadding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
            builder: (context, data) => _WelcomeContent(data: data),
          ),
        ],
      ),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({required this.data});
  final Map<String, Object?> data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = AppThemeScope.of(context);
    final modules = [
      for (final m in (data['modules'] as List? ?? const []))
        if (m is Map<String, Object?>) m,
    ];

    if (modules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: CupertinoEmpty(
          message: l10n.noAnnounce,
          icon: CupertinoIcons.speaker_slash,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in modules)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: CupertinoCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: p.warning.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.speaker_2_fill,
                          size: 14,
                          color: p.warning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (m['name'] as String?) ?? l10n.announcement,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: p.label,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Sep(),
                  const SizedBox(height: 12),
                  Text(
                    (m['content'] as String?) ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: p.label,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
