/// 登录页（含本机账号簿 = 工程期"注册"）。
///
/// - 登录：CAS 四步鉴权由 AuthController 驱动，本页只收集输入
/// - 账号簿：登记/切换/删除本机保存的账号（CAS 无在线注册，此处仅本机登记）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/auth_vm.dart';
import '../widgets/kit.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _obscure = true;

  @override
  void dispose() {
    _tab.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _prefillFromBook(List<Map<String, Object?>> accounts) {
    if (_username.text.isNotEmpty || accounts.isEmpty) return;
    final last =
        accounts.where((a) => a['remember'] == true).toList();
    if (last.isEmpty) return;
    final entry = last.last;
    _username.text = entry['username'] as String? ?? '';
  }

  Future<void> _submitLogin() async {
    final u = _username.text.trim();
    final p = _password.text;
    if (u.isEmpty || p.isEmpty) {
      snack(context, '请输入账号与密码', error: true);
      return;
    }
    await ref.read(authProvider.notifier).login(u, p, _remember);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      final err = next.value?.error;
      if (err != null && next.value?.status != AuthStatus.authed) {
        snack(context, err, error: true);
      }
    });

    final auth = ref.watch(authProvider);
    final state = auth.value ?? const AuthState();
    _prefillFromBook(state.accounts);
    final busy = state.status == AuthStatus.busy;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: state.status == AuthStatus.needsSms
              ? _SmsPanel(state: state)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Icon(Icons.school,
                        size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    const Text('Grade',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TabBar(
                      controller: _tab,
                      tabs: const [Tab(text: '登录'), Tab(text: '账号簿')],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tab,
                        children: [
                          _buildLoginTab(busy),
                          _buildBookTab(state.accounts, busy),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ---------------- 登录 tab ----------------

  Widget _buildLoginTab(bool busy) {
    return ListView(
      padding: const EdgeInsets.only(top: 24),
      children: [
        TextField(
          controller: _username,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: '学号/工号', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: '密码',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          onSubmitted: (_) => _submitLogin(),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _remember,
          onChanged: (v) => setState(() => _remember = v ?? true),
          title: const Text('记住账号密码（本机存储）'),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy ? null : _submitLogin,
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('登 录'),
        ),
        const SizedBox(height: 12),
        Text(
          '工程期提示：CAS 密码 POST 每次会话最多 1 次，'
          '失败不自动重试（防封号）；CASTGC 有效期内自动免密 SSO。',
          style: TextStyle(
              fontSize: 12, color: Theme.of(context).colorScheme.outline),
        ),
      ],
    );
  }

  // ---------------- 账号簿 tab ----------------

  Widget _buildBookTab(List<Map<String, Object?>> accounts, bool busy) {
    return ListView(
      padding: const EdgeInsets.only(top: 24),
      children: [
        Text(
          'CAS 不支持在线注册。此处将账号登记到本机账号簿，'
          '便于多账号管理与一键切换登录。',
          style: TextStyle(
              fontSize: 12, color: Theme.of(context).colorScheme.outline),
        ),
        const SizedBox(height: 12),
        _AccountForm(
          busy: busy,
          onSave: (u, p, remember) async {
            final err = await ref
                .read(authProvider.notifier)
                .saveAccount(u, p, remember);
            if (mounted) {
              snack(context, err ?? '已保存到账号簿', error: err != null);
            }
          },
        ),
        const SizedBox(height: 16),
        if (accounts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text('暂无登记账号',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).disabledColor)),
          )
        else
          ...[
            for (final a in accounts)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(a['username'] as String? ?? ''),
                  subtitle: Text((a['remember'] == true)
                      ? '已记住密码'
                      : '未记住密码（每次手动输入）'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => ref
                                .read(authProvider.notifier)
                                .loginWithSaved(a),
                        child: const Text('登录'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => ref
                            .read(authProvider.notifier)
                            .removeAccount(a['username'] as String? ?? ''),
                      ),
                    ],
                  ),
                ),
              ),
          ],
      ],
    );
  }
}

/// 短信验证码面板（网关风控增强认证）。
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
    final err =
        await ref.read(authProvider.notifier).submitSmsCode(_code.text.trim());
    if (err != null && mounted) snack(context, err, error: true);
  }

  Future<void> _resend() async {
    final err = await ref.read(authProvider.notifier).resendSms();
    if (mounted) {
      if (err != null) {
        snack(context, err, error: true);
      } else {
        snack(context, '已重新发送');
        setState(() => _countdown =
            ref.read(authProvider).value?.smsInterval ?? 60);
        _tick();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final state = auth.value ?? widget.state;
    final busy = state.status == AuthStatus.busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Icon(Icons.sms_outlined,
            size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          state.smsMaskedPhone == null
              ? '需要短信验证'
              : '验证码已发送至 ${state.smsMaskedPhone}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text('学校网关对本次登录启用了二次认证，请输入短信验证码',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).colorScheme.outline)),
        const SizedBox(height: 24),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '------',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => busy ? null : _submit(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy ? null : _submit,
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('验 证'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy || _countdown > 0 ? null : _resend,
          child: Text(_countdown > 0 ? '重新发送(${_countdown}s)' : '重新发送验证码'),
        ),
        const SizedBox(height: 8),
        Text(
          state.error ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12, color: Theme.of(context).colorScheme.error),
        ),
      ],
    );
  }
}

/// 账号登记表单。
class _AccountForm extends StatefulWidget {
  const _AccountForm({required this.busy, required this.onSave});

  final bool busy;
  final Future<void> Function(String u, String p, bool remember) onSave;

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _remember = true;

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _u,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: '学号/工号', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _p,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: '密码', isDense: true),
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _remember,
              onChanged: (v) => setState(() => _remember = v ?? true),
              title: const Text('同时记住密码'),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.busy || _u.text.trim().isEmpty
                    ? null
                    : () => widget.onSave(
                        _u.text.trim(), _p.text, _remember),
                child: const Text('保存到账号簿'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
