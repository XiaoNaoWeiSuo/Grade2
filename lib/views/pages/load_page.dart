/// 启动过渡页：会话恢复（cookie SSO）期间展示。Cupertino 风格。
library;

import 'package:flutter/cupertino.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../widgets/cupertino_kit.dart';

/// [message] 为空表示仍在恢复流程（转圈）；有值则展示恢复结果说明。
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, this.message});
  final String? message;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: Stack(
        children: [
          // 背景微光
          Positioned.fill(
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.primary.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: BlurView(
                    borderRadius: BorderRadius.circular(24),
                    color: p.primary.withValues(alpha: 0.1),
                    blur: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Icon(CupertinoIcons.book_fill, size: 80, color: p.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  context.l10n.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: p.label,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 48),
                widget.message == null
                    ? const CupertinoActivityIndicator(radius: 12)
                    : FadeIn(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Text(
                            widget.message!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: p.secondary, fontSize: 14),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FadeIn extends StatefulWidget {
  const FadeIn({super.key, required this.child});
  final Widget child;
  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _opacity = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: widget.child);
}

