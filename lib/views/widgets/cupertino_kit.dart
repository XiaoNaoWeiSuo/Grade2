/// Cupertino 共享小组件 —— 现代化 iOS 原生质感与交互体系。
///
/// 提供：
/// - 现代弹窗体系：[toast]（动态岛悬浮）、[confirm]（原生警示对话框）、[alertInfo]、[showCupertinoSheet]
/// - 质感卡片与容器：[BlurView]、[CupertinoCard]、[CupertinoSheetContainer]
/// - 列表分层体系：[Group] / [CupertinoSection]、[Tile] / [CupertinoCell]、[TileIcon]、[KVRow]、[Sep]
/// - 状态展示与徽章：[CupertinoPillBadge]、[AsyncSliver]、[CupertinoEmpty]、[CupertinoErrorCard]
/// - 交互触觉按钮：[CupertinoScaleButton]
/// - 工具函数：[pushPage]、[humanBytes]、[s]、[i]
library;

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';

/// 当前主题主色。
Color primary(BuildContext context) => AppThemeScope.of(context).primary;

// ---------------------------------------------------------------------------
// 基础视觉与磨砂玻璃
// ---------------------------------------------------------------------------

/// 磨砂玻璃容器（iOS 核心材质质感）。
class BlurView extends StatelessWidget {
  const BlurView({
    super.key,
    required this.child,
    this.borderRadius,
    this.color,
    this.blur = 16.0,
    this.border,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final Color? color;
  final double blur;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.of(context);
    final radius = borderRadius ?? BorderRadius.zero;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? theme.card.withValues(alpha: theme.isDark ? 0.75 : 0.82),
            borderRadius: radius,
            border: border ?? Border.all(color: theme.border, width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 带有按压缩放反馈的交互容器。
class CupertinoScaleButton extends StatefulWidget {
  const CupertinoScaleButton({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<CupertinoScaleButton> createState() => _CupertinoScaleButtonState();
}

class _CupertinoScaleButtonState extends State<CupertinoScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// 现代化 iOS 卡片（支持细腻阴影与按压效果）。
class CupertinoCard extends StatelessWidget {
  const CupertinoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.color,
    this.onTap,
    this.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final cardWidget = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.card,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: p.border, width: 0.5),
        boxShadow: p.isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0x0A000000),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );

    if (onTap == null) return cardWidget;
    return CupertinoScaleButton(onTap: onTap, child: cardWidget);
  }
}

// ---------------------------------------------------------------------------
// 弹窗、ActionSheet 与底部抽屉
// ---------------------------------------------------------------------------

/// 现代化动态岛悬浮 Toast。
void toast(BuildContext context, String msg, {bool error = false}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _ToastWidget(
      msg: msg,
      error: error,
      onDismissed: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.msg,
    required this.error,
    required this.onDismissed,
  });

  final String msg;
  final bool error;
  final VoidCallback onDismissed;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<double>(begin: -20, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    _ctrl.forward();
    Future.delayed(Duration(seconds: widget.error ? 3 : 2), () {
      if (mounted) {
        _ctrl.reverse().then((_) {
          if (mounted) widget.onDismissed();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: topPadding + 12,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (ctx, child) => Transform.translate(
          offset: Offset(0, _slide.value),
          child: Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: child,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: widget.error
                  ? const Color(0xE6FF3B30)
                  : const Color(0xE61C1C1E),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.error
                      ? CupertinoIcons.exclamationmark_circle_fill
                      : CupertinoIcons.checkmark_circle_fill,
                  color: CupertinoColors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 二次确认原生弹窗。
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmText,
  bool destructive = false,
}) async {
  final s = context.l10n;
  final r = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(message),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(s.cancel),
        ),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          isDefaultAction: !destructive,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmText ?? s.ok),
        ),
      ],
    ),
  );
  return r == true;
}

/// 基础信息原生弹窗。
Future<void> alertInfo(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showCupertinoDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(ctx.l10n.ok),
        ),
      ],
    ),
  );
}

/// 呼出 iOS 风格底部抽屉。
Future<T?> showCupertinoModalSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (ctx) => builder(ctx),
  );
}

/// 底部抽屉统一容器（含顶部药丸指示器、标题、关闭按钮）。
class CupertinoSheetContainer extends StatelessWidget {
  const CupertinoSheetContainer({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.maxHeightFraction = 0.85,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final double maxHeightFraction;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * maxHeightFraction;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: p.cardElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: p.border, width: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 28,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部抓手药丸条
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: p.secondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: p.label,
                              letterSpacing: -0.4,
                            ),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                subtitle!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: p.secondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null)
                      trailing!
                    else
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(32, 32),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: p.secondary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 14,
                            color: p.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const Sep(),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 徽章与状态胶囊
// ---------------------------------------------------------------------------

/// 现代化 iOS 药丸微型徽章。
class CupertinoPillBadge extends StatelessWidget {
  const CupertinoPillBadge({
    super.key,
    required this.text,
    this.icon,
    this.color,
    this.textColor,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
  });

  final String text;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final double fontSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final bg = color ?? p.primary.withValues(alpha: 0.12);
    final fg = textColor ?? (color != null ? color! : p.primary);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 列表与分组（Inset Grouped 体验）
// ---------------------------------------------------------------------------

/// 统一的列表分组容器（iOS 16+ Inset Grouped）。
class Group extends StatelessWidget {
  const Group({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.margin = const EdgeInsets.only(bottom: 20),
  });

  final List<Widget> children;
  final Widget? header;
  final Widget? footer;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    return Padding(
      padding: margin,
      child: CupertinoListSection.insetGrouped(
        header: header != null
            ? DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: p.secondary,
                  letterSpacing: -0.2,
                ),
                child: header!,
              )
            : null,
        footer: footer != null
            ? DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: 13,
                  color: p.secondary,
                ),
                child: footer!,
              )
            : null,
        backgroundColor: CupertinoColors.transparent,
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border, width: 0.5),
        ),
        dividerMargin: 56,
        additionalDividerMargin: 0,
        children: children,
      ),
    );
  }
}

/// 现代化列表项。
class Tile extends StatelessWidget {
  const Tile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    return CupertinoListTile.notched(
      title: DefaultTextStyle.merge(
        style: TextStyle(
          color: destructive ? p.destructive : p.label,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.3,
        ),
        child: title,
      ),
      subtitle: subtitle != null
          ? DefaultTextStyle.merge(
              style: TextStyle(
                color: p.secondary,
                fontSize: 13,
                letterSpacing: -0.2,
              ),
              child: subtitle!,
            )
          : null,
      leading: leading,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: p.tertiary,
                )
              : null),
      onTap: onTap,
    );
  }
}

/// 带背景色的 iOS 风格图标（设置或中枢使用）。
class TileIcon extends StatelessWidget {
  const TileIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 30,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: Center(
        child: Icon(icon, color: CupertinoColors.white, size: size * 0.62),
      ),
    );
  }
}

/// KV 键值行（详情页使用）。
class KVRow extends Tile {
  KVRow({
    super.key,
    required String label,
    required String value,
  }) : super(
          title: Text(label),
          trailing: Text(
            value,
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 15,
            ),
          ),
        );
}

/// 细分割线。
class Sep extends StatelessWidget {
  const Sep({super.key, this.indent = 0, this.endIndent = 0});
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    return Container(
      margin: EdgeInsets.only(left: indent, right: endIndent),
      height: 0.5,
      color: p.separator,
    );
  }
}

// ---------------------------------------------------------------------------
// 异步状态视图
// ---------------------------------------------------------------------------

class AsyncSliver<T> extends ConsumerWidget {
  const AsyncSliver({
    super.key,
    required this.async,
    required this.builder,
    this.onRetry,
    this.emptyText,
    this.sliverPadding = EdgeInsets.zero,
  });

  final AsyncValue<T> async;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final String? emptyText;
  final EdgeInsets sliverPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return async.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CupertinoActivityIndicator(radius: 12)),
      ),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: CupertinoErrorCard(
          message: '$e',
          onRetry: onRetry,
        ),
      ),
      data: (data) {
        final isEmpty = data == null || data is List && data.isEmpty;
        if (isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: CupertinoEmpty(message: emptyText),
          );
        }
        return SliverPadding(
          padding: sliverPadding,
          sliver: SliverToBoxAdapter(child: builder(context, data)),
        );
      },
    );
  }
}

/// 空状态视图。
class CupertinoEmpty extends StatelessWidget {
  const CupertinoEmpty({
    super.key,
    this.message,
    this.description,
    this.icon,
    this.actionText,
    this.onAction,
  });

  final String? message;
  final String? description;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: p.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon ?? CupertinoIcons.tray,
                  size: 36,
                  color: p.secondary.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? context.l10n.emptyDefault,
              style: TextStyle(
                color: p.label,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: p.secondary,
                  fontSize: 13,
                ),
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                borderRadius: BorderRadius.circular(18),
                onPressed: onAction,
                child: Text(
                  actionText!,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 错误卡片视图。
class CupertinoErrorCard extends StatelessWidget {
  const CupertinoErrorCard({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: p.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  size: 32,
                  color: p.warning,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: p.secondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                color: p.primary,
                borderRadius: BorderRadius.circular(20),
                onPressed: onRetry!,
                child: Text(
                  context.l10n.retry,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 导航与基础工具
// ---------------------------------------------------------------------------

/// 原生平滑下钻压栈。
Future<T?> pushPage<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(
    CupertinoPageRoute<T>(builder: (_) => page),
  );
}

/// 字节数 → 可读文本。
String humanBytes(int n) => n < 1024
    ? '$n B'
    : (n < 1024 * 1024
        ? '${(n / 1024).toStringAsFixed(1)} KB'
        : '${(n / 1024 / 1024).toStringAsFixed(2)} MB');

/// Map 取值 helper（安全防御类型转换，避免 double/int/num 与 String 强转崩溃）。
String s(Map<String, Object?> m, String k) {
  final val = m[k];
  if (val == null) return '';
  return val.toString();
}

int? i(Map<String, Object?> m, String k) {
  final val = m[k];
  if (val == null) return null;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}

num? n(Map<String, Object?> m, String k) {
  final val = m[k];
  if (val == null) return null;
  if (val is num) return val;
  if (val is String) return num.tryParse(val);
  return null;
}
