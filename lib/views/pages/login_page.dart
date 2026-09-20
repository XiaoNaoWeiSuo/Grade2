/// 登录页（含本机账号簿）。采用现代化的 Cupertino 设计，引入磨砂玻璃质感与更优雅的布局。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/auth_vm.dart';
import '../widgets/cupertino_kit.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  var _tab = 0; // 0=登录 1=账号簿
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _prefill(List<Map<String, Object?>> accounts) {
    if (_username.text.isNotEmpty || accounts.isEmpty) return;
    final last = accounts.where((a) => a['remember'] == true).toList();
    if (last.isEmpty) return;
    _username.text = last.last['username'] as String? ?? '';
  }

  Future<void> _submit() async {
    final u = _username.text.trim();
    final p = _password.text;
    if (u.isEmpty || p.isEmpty) {
      toast(context, context.l10n.enterAcctPwd, error: true);
      return;
    }
    await ref.read(authProvider.notifier).login(u, p, _remember);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      final err = next.value?.error;
      if (err != null && next.value?.status != AuthStatus.authed) {
        toast(context, err, error: true);
      }
    });

    final auth = ref.watch(authProvider);
    final state = auth.value ?? const AuthState();
    _prefill(state.accounts);
    final busy = state.status == AuthStatus.busy;
    final p = AppThemeScope.of(context);

    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: Stack(
        children: [
          // 背景装饰
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: state.status == AuthStatus.needsSms
                ? _SmsPanel(state: state)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    children: [
                      const SizedBox(height: 60),
                      Center(
                        child: BlurView(
                          borderRadius: BorderRadius.circular(24),
                          color: p.primary.withValues(alpha: 0.1),
                          blur: 10,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Icon(CupertinoIcons.book_fill, size: 64, color: p.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.l10n.appName,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: p.label, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '学期管理 · 成绩查询 · 选课助手',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: p.secondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 40),
                      CupertinoSlidingSegmentedControl<int>(
                        groupValue: _tab,
                        onValueChanged: (v) => setState(() => _tab = v ?? 0),
                        children: {
                          0: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Text(context.l10n.loginTab)),
                          1: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Text(context.l10n.bookTab)),
                        },
                      ),
                      const SizedBox(height: 32),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _tab == 0 ? _buildLoginTab(busy) : _buildBookTab(state.accounts, busy),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTab(bool busy) {
    final p = AppThemeScope.of(context);
    return Column(
      key: const ValueKey('login_tab'),
      children: [
        Group(
          margin: const EdgeInsets.only(bottom: 16),
          children: [
            _CupertinoField(
              controller: _username,
              placeholder: context.l10n.username,
              keyboardType: TextInputType.number,
              prefix: const Padding(padding: EdgeInsets.only(left: 12), child: Icon(CupertinoIcons.person, size: 20)),
            ),
            _CupertinoField(
              controller: _password,
              placeholder: context.l10n.password,
              obscureText: _obscure,
              prefix: const Padding(padding: EdgeInsets.only(left: 12), child: Icon(CupertinoIcons.lock, size: 20)),
              suffix: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _obscure = !_obscure),
                child: Icon(_obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye, size: 20, color: p.secondary),
              ),
              onSubmitted: (_) => busy ? null : _submit(),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(context.l10n.rememberAcct, style: TextStyle(color: p.secondary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            CupertinoSwitch(
              value: _remember,
              activeTrackColor: p.primary,
              onChanged: (v) => setState(() => _remember = v),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            borderRadius: BorderRadius.circular(14),
            onPressed: busy ? null : _submit,
            child: busy
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : Text(context.l10n.loginBtn, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.casHint,
          textAlign: TextAlign.center,
          style: TextStyle(color: p.secondary, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildBookTab(List<Map<String, Object?>> accounts, bool busy) {
    final p = AppThemeScope.of(context);
    return Column(
      key: const ValueKey('book_tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          margin: const EdgeInsets.only(bottom: 24),
          header: Text(context.l10n.bookHint),
          children: [
            _CupertinoField(
              controller: _username,
              placeholder: context.l10n.username,
              prefix: const Padding(padding: EdgeInsets.only(left: 12), child: Icon(CupertinoIcons.person_add, size: 20)),
            ),
            Tile(
              title: Center(child: Text(context.l10n.saveToBook, style: TextStyle(color: p.primary, fontWeight: FontWeight.bold))),
              onTap: busy || _username.text.trim().isEmpty ? null : _saveToBook,
            ),
          ],
        ),
        if (accounts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: CupertinoEmpty(message: context.l10n.noAccounts, icon: CupertinoIcons.person_crop_circle_badge_exclam),
          )
        else
          Group(
            header: Text(context.l10n.bookTab),
            children: [
              for (final a in accounts)
                Tile(
                  leading: TileIcon(icon: CupertinoIcons.person_fill, color: p.primary.withValues(alpha: 0.1)),
                  title: Text(a['username'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(a['remember'] == true ? context.l10n.remembered : context.l10n.notRemembered),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        color: p.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: busy ? null : () => _loginSaved(a),
                        child: Text(context.l10n.loginBtn, style: TextStyle(color: p.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => ref.read(authProvider.notifier).removeAccount(a['username'] as String? ?? ''),
                        child: const Icon(CupertinoIcons.trash, size: 18, color: CupertinoColors.systemGrey),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _saveToBook() async {
    final err = await ref.read(authProvider.notifier).saveAccount(_username.text.trim(), _password.text, true);
    if (mounted) {
      toast(context, err ?? context.l10n.addedToBook, error: err != null);
    }
  }

  Future<void> _loginSaved(Map<String, Object?> a) async {
    await ref.read(authProvider.notifier).loginWithSaved(a);
  }
}

class _CupertinoField extends StatelessWidget {
  const _CupertinoField({
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.prefix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final Widget? prefix;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      autocorrect: false,
      prefix: prefix,
      suffix: suffix,
      decoration: BoxDecoration(color: p.card),
      placeholderStyle: TextStyle(color: p.secondary.withValues(alpha: 0.5)),
    );
  }
}

class _SmsPanel extends ConsumerStatefulWidget {
  const _SmsPanel({required this.state});
  final AuthState state;
  @override
  ConsumerState<_SmsPanel> createState() => _SmsPanelState();
}

class _SmsPanelState extends ConsumerState<_SmsPanel> {
  final _code = TextEditingController();
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _countdown = widget.state.smsInterval;
    _tick();
  }

  void _tick() {
    if (_countdown <= 0) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _countdown = _countdown - 1);
      _tick();
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final err = await ref.read(authProvider.notifier).submitSmsCode(_code.text.trim());
    if (err != null && mounted) toast(context, err, error: true);
  }

  Future<void> _resend() async {
    final err = await ref.read(authProvider.notifier).resendSms();
    if (mounted) {
      if (err != null) {
        toast(context, err, error: true);
      } else {
        toast(context, context.l10n.smsSent);
        setState(() => _countdown = ref.read(authProvider).value?.smsInterval ?? 60);
        _tick();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final state = auth.value ?? widget.state;
    final busy = state.status == AuthStatus.busy;
    final p = AppThemeScope.of(context);
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      children: [
        const SizedBox(height: 60),
        BlurView(
          borderRadius: BorderRadius.circular(20),
          color: CupertinoColors.systemOrange.withValues(alpha: 0.1),
          child: const Padding(padding: EdgeInsets.all(20), child: Icon(CupertinoIcons.shield_lefthalf_fill, size: 52, color: CupertinoColors.systemOrange)),
        ),
        const SizedBox(height: 24),
        Text(
          state.smsMaskedPhone == null ? context.l10n.needSms : context.l10n.smsSentTo.replaceFirst('%1', state.smsMaskedPhone!),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: p.label),
        ),
        const SizedBox(height: 12),
        Text(context.l10n.smsHint, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: p.secondary, height: 1.4)),
        const SizedBox(height: 40),
        CupertinoTextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          autofocus: true,
          style: const TextStyle(fontSize: 32, letterSpacing: 12, fontWeight: FontWeight.bold),
          placeholder: '------',
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.separator)),
          onSubmitted: (_) => busy ? null : _submit(),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            borderRadius: BorderRadius.circular(14),
            onPressed: busy ? null : _submit,
            child: busy ? const CupertinoActivityIndicator(color: CupertinoColors.white) : Text(context.l10n.verifyBtn, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          onPressed: busy || _countdown > 0 ? null : _resend,
          child: Text(_countdown > 0 ? '${context.l10n.resend}(${_countdown}s)' : context.l10n.resendNow, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
