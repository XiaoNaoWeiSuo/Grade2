/// 『账号管理』页 —— 账号簿多账号管理。
/// 具备：
/// - 系统级 Keychain / Keystore 安全存储凭据
/// - 当前已登入账号高亮药丸徽章
/// - 一键免密快速切换账号
/// - 新增账号登记与滑动/按钮删除
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/auth_vm.dart';
import '../widgets/cupertino_kit.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _switchTo(Map<String, Object?> a) async {
    setState(() => _busy = true);
    await ref.read(authProvider.notifier).loginWithSaved(a);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    final u = _username.text.trim();
    final pwd = _password.text;
    if (u.isEmpty || pwd.isEmpty) {
      toast(context, '${context.l10n.username} / ${context.l10n.password}', error: true);
      return;
    }
    setState(() => _busy = true);
    final err = await ref.read(authProvider.notifier).saveAccount(u, pwd, _remember);
    if (mounted) {
      setState(() => _busy = false);
      if (err == null) {
        _username.clear();
        _password.clear();
        toast(context, context.l10n.addedToBook);
      } else {
        toast(context, err, error: true);
      }
    }
  }

  Future<void> _remove(Map<String, Object?> a) async {
    final username = a['username'] as String? ?? '';
    final ok = await confirm(
      context,
      title: context.l10n.deleteAccount,
      message: context.l10n.deleteAccountMsg.replaceFirst('%1', username),
      destructive: true,
    );
    if (ok && mounted) {
      await ref.read(authProvider.notifier).removeAccount(username);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).value ?? const AuthState();
    final accounts = auth.accounts;
    final current = auth.username;
    final l10n = context.l10n;
    final p = AppThemeScope.of(context);

    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.accountManage),
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

                  // 账号列表组
                  Group(
                    header: Text('${l10n.bookTitle} · ${accounts.length}'),
                    children: [
                      if (accounts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: CupertinoEmpty(
                            message: l10n.noAccounts,
                            icon: CupertinoIcons.person_crop_circle_badge_exclam,
                          ),
                        )
                      else
                        for (final a in accounts)
                          _AccountVaultTile(
                            account: a,
                            isCurrent: a['username'] == current,
                            busy: _busy,
                            onSwitch: () => _switchTo(a),
                            onDelete: () => _remove(a),
                            p: p,
                            l10n: l10n,
                          ),
                    ],
                  ),

                  // 添加新账号组
                  Group(
                    header: Text(l10n.addNewAccount),
                    children: [
                      CupertinoTextField(
                        controller: _username,
                        placeholder: l10n.username,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefix: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Icon(CupertinoIcons.person_add, size: 20, color: p.secondary),
                        ),
                        decoration: const BoxDecoration(color: CupertinoColors.transparent),
                        style: TextStyle(color: p.label, fontSize: 16),
                      ),
                      const Sep(indent: 52),
                      CupertinoTextField(
                        controller: _password,
                        placeholder: l10n.password,
                        obscureText: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefix: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Icon(CupertinoIcons.lock, size: 20, color: p.secondary),
                        ),
                        decoration: const BoxDecoration(color: CupertinoColors.transparent),
                        style: TextStyle(color: p.label, fontSize: 16),
                      ),
                      Tile(
                        title: Text(l10n.rememberPwd, style: const TextStyle(fontSize: 15)),
                        trailing: CupertinoSwitch(
                          value: _remember,
                          activeTrackColor: p.primary,
                          onChanged: (v) => setState(() => _remember = v),
                        ),
                      ),
                      Tile(
                        title: Center(
                          child: _busy
                              ? const CupertinoActivityIndicator()
                              : Text(
                                  l10n.addToBook,
                                  style: TextStyle(
                                    color: p.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        onTap: _busy ? null : _save,
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.accountManageSub,
                      style: TextStyle(fontSize: 12, color: p.secondary, height: 1.4),
                    ),
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
}

class _AccountVaultTile extends StatelessWidget {
  const _AccountVaultTile({
    required this.account,
    required this.isCurrent,
    required this.busy,
    required this.onSwitch,
    required this.onDelete,
    required this.p,
    required this.l10n,
  });

  final Map<String, Object?> account;
  final bool isCurrent;
  final bool busy;
  final VoidCallback onSwitch;
  final VoidCallback onDelete;
  final AppPalette p;
  final AppStrings l10n;

  @override
  Widget build(BuildContext context) {
    final username = account['username'] as String? ?? '';
    final remember = account['remember'] == true;

    return Tile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isCurrent
              ? p.primary.withValues(alpha: 0.15)
              : p.secondary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            CupertinoIcons.person_fill,
            size: 16,
            color: isCurrent ? p.primary : p.secondary,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(username, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (isCurrent) ...[
            const SizedBox(width: 8),
            CupertinoPillBadge(
              text: l10n.currentBadge,
              color: p.primary.withValues(alpha: 0.12),
              textColor: p.primary,
            ),
          ],
        ],
      ),
      subtitle: Text(remember ? l10n.remembered : l10n.notRemembered),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCurrent)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(48, 28),
              color: p.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              onPressed: busy ? null : onSwitch,
              child: Text(
                l10n.switchAcct,
                style: TextStyle(
                  color: p.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          CupertinoButton(
            padding: const EdgeInsets.only(left: 8),
            minimumSize: const Size(28, 28),
            onPressed: busy ? null : onDelete,
            child: Icon(CupertinoIcons.trash, size: 16, color: p.secondary),
          ),
        ],
      ),
    );
  }
}
