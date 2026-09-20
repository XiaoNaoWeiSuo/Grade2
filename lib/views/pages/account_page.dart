/// 『账户』页 —— 账号信息、外观/语言设置、学期网络同步、清除缓存、关于、登出。
/// 采用现代化的 Inset Grouped 列表与大标题导航栏。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_settings.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/providers.dart';
import '../../viewmodels/semester_vm.dart';
import '../../viewmodels/timetable_vm.dart';
import '../widgets/cupertino_kit.dart';
import 'accounts_page.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value ?? const AuthState();
    final displayName = auth.displayName ?? auth.username ?? '';
    final offline = auth.offline;
    final l10n = context.l10n;
    final p = AppThemeScope.of(context);
    final settings = ref.watch(appSettingsProvider);

    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.account),
            backgroundColor: p.bar.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 10),
                
                // --- 账户信息 ---
                Group(
                  header: Text(l10n.accountInfo),
                  children: [
                    Tile(
                      leading: Icon(CupertinoIcons.person_crop_circle_fill, size: 40, color: p.primary),
                      title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(offline ? '${auth.username ?? ''} · ${l10n.offlineMode}' : (auth.username ?? '')),
                      trailing: offline ? Icon(CupertinoIcons.cloud, size: 18, color: CupertinoColors.systemGrey) : null,
                    ),
                  ],
                ),

                // --- 外观与语言 ---
                Group(
                  header: Text(l10n.appearance),
                  children: [
                    Tile(
                      title: Text(l10n.appearance),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: CupertinoSegmentedControl<AppThemeMode>(
                          groupValue: settings.theme,
                          onValueChanged: (v) => ref.read(appSettingsProvider.notifier).setTheme(v),
                          children: {
                            AppThemeMode.system: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(l10n.modeSystem, style: const TextStyle(fontSize: 13))),
                            AppThemeMode.light: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(l10n.modeLight, style: const TextStyle(fontSize: 13))),
                            AppThemeMode.dark: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(l10n.modeDark, style: const TextStyle(fontSize: 13))),
                            AppThemeMode.eye: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(l10n.modeEye, style: const TextStyle(fontSize: 13))),
                          },
                        ),
                      ),
                    ),
                    Tile(
                      title: Text(l10n.language),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(settings.locale.code, style: TextStyle(color: p.secondary, fontSize: 15)),
                          const CupertinoListTileChevron(),
                        ],
                      ),
                      onTap: () => _pickLocale(context, ref, settings.locale),
                    ),
                  ],
                ),

                // --- 账户设置 ---
                Group(
                  header: Text(l10n.accountSettings),
                  children: [
                    Tile(
                      leading: const TileIcon(icon: CupertinoIcons.person_2_fill, color: CupertinoColors.systemBlue),
                      title: Text(l10n.accountManage),
                      subtitle: Text(l10n.accountManageSub),
                      onTap: () => pushPage(context, const AccountsPage()),
                    ),
                    Tile(
                      leading: const TileIcon(icon: CupertinoIcons.arrow_clockwise_circle_fill, color: CupertinoColors.systemGreen),
                      title: Text(l10n.syncSemester),
                      subtitle: Text(l10n.syncSemesterSub),
                      onTap: () => _syncSemester(context, ref),
                    ),
                    Tile(
                      leading: const TileIcon(icon: CupertinoIcons.trash_fill, color: CupertinoColors.systemOrange),
                      title: Text(l10n.clearCache),
                      subtitle: Text(l10n.clearCacheSub),
                      onTap: () => _clearCache(context, ref),
                    ),
                    Tile(
                      leading: const TileIcon(icon: CupertinoIcons.info_circle_fill, color: CupertinoColors.systemGrey),
                      title: Text(l10n.about),
                      subtitle: Text(l10n.aboutSub),
                      onTap: () => _about(context),
                    ),
                  ],
                ),

                // --- 登出 ---
                Group(
                  children: [
                    Tile(
                      destructive: true,
                      title: Center(child: Text(l10n.logout, style: const TextStyle(fontWeight: FontWeight.w600))),
                      onTap: () => _logout(context, ref),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _about(BuildContext context) {
    final l10n = context.l10n;
    alertInfo(context, title: l10n.about, message: '${l10n.appName}\n\n${l10n.aboutSub}');
  }

  Future<void> _pickLocale(BuildContext context, WidgetRef ref, AppLocale current) async {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;
    final selected = await showCupertinoModalPopup<AppLocale>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.language),
        actions: [
          for (final l in supportedAppLocales)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(l),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${l.code} · ${l.label}'),
                  if (l.code == current.code) ...[
                    const SizedBox(width: 8),
                    Icon(CupertinoIcons.check_mark, size: 18, color: p.primary),
                  ],
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel),
        ),
      ),
    );
    if (selected != null && context.mounted) {
      await ref.read(appSettingsProvider.notifier).setLocale(selected);
    }
  }

  Future<void> _syncSemester(BuildContext context, WidgetRef ref) async {
    final err = await ref.read(semesterSelectionProvider.notifier).refreshFromNetwork();
    if (context.mounted) {
      final l10n = context.l10n;
      toast(context, err ?? l10n.semesterSynced, error: err != null);
    }
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await confirm(context, title: l10n.clearCacheTitle, message: l10n.clearCacheMsg, destructive: true);
    if (!ok || !context.mounted) return;
    final cache = await ref.read(localCacheProvider.future);
    await cache.clearAll();
    if (context.mounted) {
      toast(context, l10n.cacheCleared);
      ref.invalidate(timetableProvider);
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await confirm(context, title: l10n.logoutTitle, message: l10n.logoutMsg, destructive: true);
    if (ok && context.mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}
