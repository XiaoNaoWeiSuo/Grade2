/// 登录页 —— 极致极简优雅的 iOS Cupertino 设计风格（贯彻 Less is More 理念）。
///
/// 具备：
/// - 原生 Inset Grouped 输入框体系与密码可见性切换
/// - 账号簿轻量胶囊 Chips 快捷横条（即点即切、快捷删除）
/// - 两个登录时选项：【自动登录】与【下次缓存】
/// - 登录按钮分色裂变：连续失败达阈值且存在本地缓存时，左侧重试登录、右侧从缓存进入
/// - 极简 6 位原生 PIN 格短信验证码面板（自动聚焦、满 6 位自动提交）
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _autoLogin = true;
  bool _startWithCache = false;
  bool _obscure = true;
  bool _hasCache = false;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _username.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _username.removeListener(_onUsernameChanged);
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    _checkCache();
  }

  Future<void> _checkCache() async {
    final u = _username.text.trim();
    if (u.isEmpty) {
      if (mounted && _hasCache) setState(() => _hasCache = false);
      return;
    }
    final has = await ref.read(authProvider.notifier).hasCacheFor(u);
    if (mounted && has != _hasCache) {
      setState(() => _hasCache = has);
    }
  }

  void _prefill(List<Map<String, Object?>> accounts) {
    if (_prefilled || accounts.isEmpty) return;
    _prefilled = true;
    final last = accounts.last;
    final u = last['username'] as String? ?? '';
    _username.text = u;
    _remember = last['remember'] != false;
    _autoLogin = last['autoLogin'] != false;
    _startWithCache = last['startWithCache'] == true;
    _checkCache();
  }

  Future<void> _submit() async {
    final u = _username.text.trim();
    final p = _password.text;
    if (u.isEmpty || p.isEmpty) {
      toast(context, context.l10n.enterAcctPwd, error: true);
      return;
    }
    TextInput.finishAutofillContext();
    await ref.read(authProvider.notifier).login(
          u,
          p,
          _remember,
          _autoLogin,
          _startWithCache,
        );
  }

  Future<void> _enterCache() async {
    final u = _username.text.trim();
    if (u.isEmpty) {
      toast(context, context.l10n.enterAcctPwd, error: true);
      return;
    }
    await ref.read(authProvider.notifier).enterFromCache(u);
    if (mounted) {
      toast(context, context.l10n.offlineCacheToast);
    }
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
    final l10n = context.l10n;

    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: Stack(
        children: [
          // 顶部柔和环境弥散光
          Positioned(
            top: -140,
            left: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    p.primary.withValues(alpha: p.isDark ? 0.15 : 0.09),
                    p.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: state.status == AuthStatus.needsSms
                ? _SmsPanel(state: state)
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 36),

                      // 品牌徽标与欢迎词（Less is more，极简灵动）
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [p.primary, p.primary.withValues(alpha: 0.82)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: p.primary.withValues(alpha: 0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.calendar_today,
                              size: 34,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: p.label,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.appSlogan,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: p.secondary,
                          letterSpacing: -0.2,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 快捷已存账号水平胶囊（有账号时极简呈现，即点即切）
                      if (state.accounts.isNotEmpty) ...[
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: state.accounts.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (ctx, idx) {
                              final a = state.accounts[idx];
                              final u = a['username'] as String? ?? '';
                              final isCurrent = _username.text == u;
                              return CupertinoScaleButton(
                                onTap: busy
                                    ? null
                                    : () {
                                        setState(() {
                                          _username.text = u;
                                          _autoLogin = a['autoLogin'] != false;
                                          _startWithCache = a['startWithCache'] == true;
                                          _remember = a['remember'] != false;
                                        });
                                        _checkCache();
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isCurrent ? p.primary.withValues(alpha: 0.12) : p.card,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isCurrent ? p.primary : p.border,
                                      width: isCurrent ? 1.2 : 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.person_crop_circle,
                                        size: 15,
                                        color: isCurrent ? p.primary : p.secondary,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        u,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isCurrent ? p.primary : p.label,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => ref
                                            .read(authProvider.notifier)
                                            .removeAccount(u),
                                        child: Icon(
                                          CupertinoIcons.xmark_circle_fill,
                                          size: 13,
                                          color: p.tertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 表单输入容器
                      Container(
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: p.border, width: 0.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            CupertinoTextField(
                              controller: _username,
                              placeholder: l10n.username,
                              keyboardType: TextInputType.text,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              prefix: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Icon(
                                  CupertinoIcons.person,
                                  size: 20,
                                  color: p.secondary,
                                ),
                              ),
                              clearButtonMode: OverlayVisibilityMode.editing,
                              decoration: const BoxDecoration(color: CupertinoColors.transparent),
                              style: TextStyle(color: p.label, fontSize: 16),
                              placeholderStyle: TextStyle(
                                color: p.tertiary,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const Sep(indent: 52),
                            CupertinoTextField(
                              controller: _password,
                              placeholder: l10n.password,
                              obscureText: _obscure,
                              keyboardType: TextInputType.visiblePassword,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              prefix: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Icon(
                                  CupertinoIcons.lock,
                                  size: 20,
                                  color: p.secondary,
                                ),
                              ),
                              suffix: CupertinoButton(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(40, 40),
                                onPressed: () => setState(() => _obscure = !_obscure),
                                child: Icon(
                                  _obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                                  size: 20,
                                  color: p.secondary,
                                ),
                              ),
                              decoration: const BoxDecoration(color: CupertinoColors.transparent),
                              style: TextStyle(color: p.label, fontSize: 16),
                              placeholderStyle: TextStyle(
                                color: p.tertiary,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                              onSubmitted: (_) => busy ? null : _submit(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 登录选项体系：自动登录与下次缓存
                      Container(
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: p.border, width: 0.5),
                        ),
                        child: Column(
                          children: [
                            // 自动登录
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.autoLogin,
                                          style: TextStyle(
                                            color: p.label,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.autoLoginSub,
                                          style: TextStyle(
                                            color: p.secondary,
                                            fontSize: 12,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoSwitch(
                                    value: _autoLogin,
                                    activeTrackColor: p.primary,
                                    onChanged: busy
                                        ? null
                                        : (v) {
                                            setState(() {
                                              _autoLogin = v;
                                              if (v) _startWithCache = false;
                                            });
                                          },
                                  ),
                                ],
                              ),
                            ),
                            const Sep(indent: 16),
                            // 下次缓存
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.startWithCache,
                                          style: TextStyle(
                                            color: p.label,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.startWithCacheSub,
                                          style: TextStyle(
                                            color: p.secondary,
                                            fontSize: 12,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoSwitch(
                                    value: _startWithCache,
                                    activeTrackColor: CupertinoColors.activeGreen,
                                    onChanged: busy
                                        ? null
                                        : (v) {
                                            setState(() {
                                              _startWithCache = v;
                                              if (v) _autoLogin = false;
                                            });
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 登录主操作区：支持失败过多时分色双拼裂变
                      if (state.failureCount >= 2 && _hasCache) ...[
                        Row(
                          children: [
                            // 左侧：重试登录（主色）
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: CupertinoButton.filled(
                                  padding: EdgeInsets.zero,
                                  borderRadius: BorderRadius.circular(14),
                                  onPressed: busy ? null : _submit,
                                  child: busy
                                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                                      : Text(
                                          l10n.retryLogin,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 右侧：从缓存进入（温润翠绿 + 归档图标）
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  color: CupertinoColors.activeGreen,
                                  borderRadius: BorderRadius.circular(14),
                                  onPressed: busy ? null : _enterCache,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.archivebox_fill,
                                        size: 17,
                                        color: CupertinoColors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.enterFromCache,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: CupertinoColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // 正常全宽单按钮
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: CupertinoButton.filled(
                            borderRadius: BorderRadius.circular(14),
                            onPressed: busy ? null : _submit,
                            child: busy
                                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                                : Text(
                                    l10n.loginBtn,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                          ),
                        ),
                        if (_hasCache) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              onPressed: busy ? null : _enterCache,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.archivebox,
                                    size: 15,
                                    color: p.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    l10n.enterFromCache,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: p.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 20),

                      // 底部安全提示
                      Text(
                        l10n.casHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: p.tertiary,
                          fontSize: 12,
                          height: 1.4,
                          letterSpacing: -0.2,
                        ),
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

/// 极简 6 位 PIN 体验的短信验证码面板（Less is More）
class _SmsPanel extends ConsumerStatefulWidget {
  const _SmsPanel({required this.state});
  final AuthState state;

  @override
  ConsumerState<_SmsPanel> createState() => _SmsPanelState();
}

class _SmsPanelState extends ConsumerState<_SmsPanel> {
  final _code = TextEditingController();
  final _focusNode = FocusNode();
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _countdown = widget.state.smsInterval;
    _tick();
    _code.addListener(_onCodeChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onCodeChanged() {
    setState(() {});
    if (_code.text.trim().length == 6) {
      _submit();
    }
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
    _code.removeListener(_onCodeChanged);
    _code.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.length < 4) return;
    final err =
        await ref.read(authProvider.notifier).submitSmsCode(code);
    if (err != null && mounted) toast(context, err, error: true);
  }

  Future<void> _resend() async {
    final err = await ref.read(authProvider.notifier).resendSms();
    if (mounted) {
      if (err != null) {
        toast(context, err, error: true);
      } else {
        toast(context, context.l10n.smsSent);
        setState(
            () => _countdown = ref.read(authProvider).value?.smsInterval ?? 60);
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
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 12),

        // 顶部取消/返回按钮
        Align(
          alignment: Alignment.centerLeft,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: busy
                ? null
                : () => ref.read(authProvider.notifier).cancelSms(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.chevron_back, size: 20, color: p.primary),
                const SizedBox(width: 2),
                Text(
                  l10n.cancel,
                  style: TextStyle(
                    fontSize: 16,
                    color: p.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 36),

        // 极简标题与手机号副标题
        Text(
          l10n.needSms,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: p.label,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state.smsMaskedPhone == null
              ? l10n.smsHint
              : l10n.smsSentTo.replaceFirst('%1', state.smsMaskedPhone!),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: p.secondary,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 40),

        // 6 位原生极简 PIN 格验证码面板
        Stack(
          alignment: Alignment.center,
          children: [
            // 隐藏但承载原生键盘与 Autofill 的输入控件
            Opacity(
              opacity: 0.0,
              child: CupertinoTextField(
                controller: _code,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            // 6 个独立精致方格
            GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (idx) {
                  final text = _code.text;
                  final digit = idx < text.length ? text[idx] : '';
                  final isCurrent = idx == text.length;
                  return Container(
                    width: 44,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? p.primary
                            : (digit.isNotEmpty
                                ? p.label.withValues(alpha: 0.3)
                                : p.border),
                        width: isCurrent ? 1.8 : 0.8,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: p.primary.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        digit,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: p.label,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),

        const SizedBox(height: 36),

        // 验证主按钮
        SizedBox(
          width: double.infinity,
          height: 50,
          child: CupertinoButton.filled(
            borderRadius: BorderRadius.circular(14),
            onPressed: busy || _code.text.trim().length < 6 ? null : _submit,
            child: busy
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : Text(
                    l10n.verifyBtn,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 14),

        // 重新发送文本按钮
        Center(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onPressed: busy || _countdown > 0 ? null : _resend,
            child: Text(
              _countdown > 0
                  ? '${l10n.resend} (${_countdown}s)'
                  : l10n.resendNow,
              style: TextStyle(
                color: _countdown > 0 ? p.secondary : p.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
