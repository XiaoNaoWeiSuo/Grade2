/// 『账户』页 —— 极致对齐 iOS 设置界面的个人中心与系统偏好。
///
/// 特性：
/// - 大头像个人信息横幅（展示学号、姓名、离线状态）
/// - iOS 17/18 风格的【显示与外观】预览切换矩阵（系统、亮色、暗色、护眼）
/// - 多语言切换 ActionSheet
/// - 账号安全存储管理与离线缓存清理
/// - 破坏性退出登录原生弹窗
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
    final l10n = context.l10n;
    final displayName = auth.displayName ?? auth.username ?? l10n.student;
    final username = auth.username ?? '';
    final offline = auth.offline;
    final p = AppThemeScope.of(context);
    final settings = ref.watch(appSettingsProvider);

    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.account),
            backgroundColor: p.bar.withValues(alpha: 0.82),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // 顶部大头像个人信息卡片
                  CupertinoCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [p.primary, p.primary.withValues(alpha: 0.75)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: p.primary.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName.substring(0, 1)
                                  : l10n.student.substring(0, 1),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: p.label,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    username,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: p.secondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (offline) ...[
                                    const SizedBox(width: 8),
                                    CupertinoPillBadge(
                                      text: l10n.offlineMode,
                                      color: p.warning.withValues(alpha: 0.15),
                                      textColor: p.warning,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- 外观与显示（iOS 视觉预览选择器） ---
                  Group(
                    header: Text(l10n.appearance),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _ThemeModeCard(
                              title: l10n.modeSystem,
                              isSelected: settings.theme == AppThemeMode.system,
                              previewColor: const Color(0xFFF2F2F7),
                              accentColor: const Color(0xFF007AFF),
                              onTap: () => ref
                                  .read(appSettingsProvider.notifier)
                                  .setTheme(AppThemeMode.system),
                            ),
                            _ThemeModeCard(
                              title: l10n.modeLight,
                              isSelected: settings.theme == AppThemeMode.light,
                              previewColor: const Color(0xFFFFFFFF),
                              accentColor: const Color(0xFF007AFF),
                              onTap: () => ref
                                  .read(appSettingsProvider.notifier)
                                  .setTheme(AppThemeMode.light),
                            ),
                            _ThemeModeCard(
                              title: l10n.modeDark,
                              isSelected: settings.theme == AppThemeMode.dark,
                              previewColor: const Color(0xFF1C1C1E),
                              accentColor: const Color(0xFF0A84FF),
                              onTap: () => ref
                                  .read(appSettingsProvider.notifier)
                                  .setTheme(AppThemeMode.dark),
                            ),
                            _ThemeModeCard(
                              title: l10n.modeEye,
                              isSelected: settings.theme == AppThemeMode.eye,
                              previewColor: const Color(0xFFF3EFE2),
                              accentColor: const Color(0xFF6F8F5A),
                              onTap: () => ref
                                  .read(appSettingsProvider.notifier)
                                  .setTheme(AppThemeMode.eye),
                            ),
                          ],
                        ),
                      ),
                      Tile(
                        leading: const TileIcon(
                          icon: CupertinoIcons.globe,
                          color: CupertinoColors.systemTeal,
                        ),
                        title: Text(l10n.language),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              settings.locale.label,
                              style: TextStyle(color: p.secondary, fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Icon(CupertinoIcons.chevron_right, size: 14, color: p.tertiary),
                          ],
                        ),
                        onTap: () => _pickLocale(context, ref, settings.locale),
                      ),
                    ],
                  ),

                  // --- 账号与学业同步 ---
                  Group(
                    header: Text(l10n.accountSettings),
                    children: [
                      Tile(
                        leading: const TileIcon(
                          icon: CupertinoIcons.person_2_fill,
                          color: CupertinoColors.systemBlue,
                        ),
                        title: Text(l10n.accountManage),
                        subtitle: Text(l10n.accountManageSub),
                        onTap: () => pushPage(context, const AccountsPage()),
                      ),
                      Tile(
                        leading: const TileIcon(
                          icon: CupertinoIcons.arrow_clockwise_circle_fill,
                          color: CupertinoColors.systemGreen,
                        ),
                        title: Text(l10n.syncSemester),
                        subtitle: Text(l10n.syncSemesterSub),
                        onTap: () => _syncSemester(context, ref),
                      ),
                      Tile(
                        leading: const TileIcon(
                          icon: CupertinoIcons.trash_fill,
                          color: CupertinoColors.systemOrange,
                        ),
                        title: Text(l10n.clearCache),
                        subtitle: Text(l10n.clearCacheSub),
                        onTap: () => _clearCache(context, ref),
                      ),
                      Tile(
                        leading: const TileIcon(
                          icon: CupertinoIcons.info_circle_fill,
                          color: CupertinoColors.systemGrey,
                        ),
                        title: Text(l10n.about),
                        subtitle: Text(l10n.aboutSub),
                        onTap: () => _about(context),
                      ),
                    ],
                  ),

                  // --- 退出登录 ---
                  Group(
                    children: [
                      Tile(
                        destructive: true,
                        title: Center(
                          child: Text(
                            l10n.logout,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        onTap: () => _logout(context, ref),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _about(BuildContext context) {
    final l10n = context.l10n;
    alertInfo(
      context,
      title: l10n.about,
      message: l10n.aboutAppDetail,
    );
  }

  Future<void> _pickLocale(
    BuildContext context,
    WidgetRef ref,
    AppLocale current,
  ) async {
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
                  Text(l.label),
                  if (l.code == current.code) ...[
                    const SizedBox(width: 8),
                    Icon(CupertinoIcons.checkmark_alt, size: 18, color: p.primary),
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
    final err =
        await ref.read(semesterSelectionProvider.notifier).refreshFromNetwork();
    if (context.mounted) {
      final l10n = context.l10n;
      toast(context, err ?? l10n.semesterSynced, error: err != null);
    }
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await confirm(
      context,
      title: l10n.clearCacheTitle,
      message: l10n.clearCacheMsg,
      destructive: true,
    );
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
    final ok = await confirm(
      context,
      title: l10n.logoutTitle,
      message: l10n.logoutMsg,
      destructive: true,
    );
    if (ok && context.mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({
    required this.title,
    required this.isSelected,
    required this.previewColor,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final Color previewColor;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);

    return CupertinoScaleButton(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 94,
            decoration: BoxDecoration(
              color: previewColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accentColor : p.border,
                width: isSelected ? 2.0 : 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x14000000),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 模拟 iOS 界面小缩略图
                Positioned(
                  top: 10,
                  left: 8,
                  right: 8,
                  height: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Positioned(
                  top: 26,
                  left: 8,
                  right: 8,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.checkmark_alt,
                          size: 12,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? p.primary : p.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
