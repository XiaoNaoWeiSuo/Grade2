/// 欢迎页 —— 教务首页（公告/新闻模块列表）。Cupertino 风格。
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
            backgroundColor: p.bar.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => ref.read(welcomeProvider.notifier).refresh(),
              child: const Icon(CupertinoIcons.arrow_clockwise),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(welcomeProvider.notifier).refresh(),
          ),
          AsyncSliver<Map<String, Object?>>(
            async: ref.watch(welcomeProvider),
            onRetry: () => ref.invalidate(welcomeProvider),
            emptyText: l10n.noAnnounce,
            sliverPadding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
      return SizedBox(
        height: 200,
        child: CupertinoEmpty(message: l10n.noAnnounce),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in modules)
          Group(
            header: Text((m['name'] as String?) ?? l10n.announcement),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  (m['content'] as String?) ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: p.label,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

