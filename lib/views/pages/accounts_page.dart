/// 『账号管理』页 —— 账号簿多账号管理。采用现代化的 Inset Grouped 列表与更优雅的布局。
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
    final ok = await confirm(context,
        title: context.l10n.deleteAccount,
        message: context.l10n.deleteAccountMsg.replaceFirst('%1', username),
        destructive: true);
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
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.accountManage),
            backgroundColor: p.bar.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 10),
                
                // --- 账号簿 ---
                Group(
                  header: Text(l10n.bookTitle),
                  children: [
                    if (accounts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Text(l10n.noAccounts, style: TextStyle(color: p.secondary))),
                      )
                    else
                      for (final a in accounts)
                        Tile(
                          leading: TileIcon(icon: CupertinoIcons.person_fill, color: p.primary.withValues(alpha: 0.1)),
                          title: Text(a['username'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(a['remember'] == true ? l10n.remembered : l10n.notRemembered),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (a['username'] == current)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Icon(CupertinoIcons.check_mark_circled, size: 20, color: p.primary),
                                )
                              else
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  color: p.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  onPressed: _busy ? null : () => _switchTo(a),
                                  child: Text(l10n.switchAcct, style: TextStyle(color: p.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                              CupertinoButton(
                                padding: const EdgeInsets.only(left: 8),
                                onPressed: _busy ? null : () => _remove(a),
                                child: const Icon(CupertinoIcons.trash, size: 18, color: CupertinoColors.systemGrey),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),

                // --- 添加新账号 ---
                Group(
                  header: Text(l10n.addNewAccount),
                  children: [
                    _CupertinoField(
                      controller: _username,
                      placeholder: l10n.username,
                      keyboardType: TextInputType.number,
                      prefix: const Padding(padding: EdgeInsets.only(left: 12), child: Icon(CupertinoIcons.person_add, size: 20)),
                    ),
                    _CupertinoField(
                      controller: _password,
                      placeholder: l10n.password,
                      obscureText: true,
                      prefix: const Padding(padding: EdgeInsets.only(left: 12), child: Icon(CupertinoIcons.lock, size: 20)),
                    ),
                    Tile(
                      title: Text(l10n.rememberPwd, style: const TextStyle(fontSize: 16)),
                      trailing: CupertinoSwitch(
                        value: _remember,
                        onChanged: (v) => setState(() => _remember = v),
                      ),
                    ),
                    Tile(
                      title: Center(
                        child: _busy
                            ? const CupertinoActivityIndicator()
                            : Text(l10n.addToBook, style: TextStyle(color: p.primary, fontWeight: FontWeight.bold)),
                      ),
                      onTap: _busy ? null : _save,
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(l10n.accountManageSub, style: TextStyle(fontSize: 12, color: p.secondary, height: 1.4)),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CupertinoField extends StatelessWidget {
  const _CupertinoField({
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.obscureText = false,
    this.prefix,
  });

  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscureText,
      keyboardType: keyboardType,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      autocorrect: false,
      prefix: prefix,
      decoration: BoxDecoration(color: p.card),
      placeholderStyle: TextStyle(color: p.secondary.withValues(alpha: 0.5)),
    );
  }
}
