/// Cupertino 共享小组件 —— 正式 UI 的统一呈现工具。
///
/// 提供：toast、确认弹窗、错误弹窗、异步状态视图(Sliver)、
/// 现代化的 Inset Grouped 列表组件、Tile、KV 行等。
/// 所有页面依赖本文件；颜色取自 [AppThemeScope] 色板。
library;

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';

/// 主色（随主题；如需品牌色改 AppTheme 色板即可全局生效）。
Color primary(BuildContext context) => AppThemeScope.of(context).primary;

// ---------------------------------------------------------------------------
// 基础装饰器
// ---------------------------------------------------------------------------

/// 磨砂玻璃容器（iOS 核心视觉特征）。
class BlurView extends StatelessWidget {
  const BlurView({
    super.key,
    required this.child,
    this.borderRadius,
    this.color,
    this.blur = 10.0,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final Color? color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.of(context);
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color ?? theme.card.withValues(alpha: 0.7),
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 弹窗与提示
// ---------------------------------------------------------------------------

/// 现代化的 Toast（支持磨砂玻璃效果）。
void toast(BuildContext context, String msg, {bool error = false}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: MediaQuery.paddingOf(context).top + 60,
      left: 24,
      right: 24,
      child: Center(
        child: IgnorePointer(
          child: BlurView(
            borderRadius: BorderRadius.circular(14),
            blur: 15,
            color: error 
                ? const Color(0xCCFF3B30) 
                : const Color(0xCC1C1C1E),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CupertinoColors.white, 
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(Duration(seconds: error ? 4 : 2), () {
    entry.remove();
  });
}

/// 二次确认弹窗。
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
      content: Text(message),
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

/// 基础信息弹窗。
Future<void> alertInfo(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(ctx.l10n.ok),
        ),
      ],
    ),
  );
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
        child: _ErrorView(
          message: e is Exception ? '$e' : '$e',
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

class CupertinoEmpty extends StatelessWidget {
  const CupertinoEmpty({super.key, this.message, this.icon});
  final String? message;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? CupertinoIcons.tray, size: 48, color: p.secondary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            message ?? context.l10n.emptyDefault,
            style: TextStyle(color: p.secondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle,
                size: 48, color: CupertinoColors.systemOrange),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.secondary, fontSize: 15)),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                color: p.primary,
                borderRadius: BorderRadius.circular(10),
                onPressed: onRetry!,
                child: Text(context.l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 现代 Inset Grouped 列表
// ---------------------------------------------------------------------------

/// 统一的列表分组容器（使用 iOS 15+ 风格的 Inset Grouped）。
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
        header: header,
        footer: footer,
        backgroundColor: CupertinoColors.transparent,
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(12),
        ),
        dividerMargin: 56,
        additionalDividerMargin: 0,
        children: children,
      ),
    );
  }
}

/// 现代列表项。
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
          color: destructive ? CupertinoColors.systemRed : p.label,
          fontSize: 17,
        ),
        child: title,
      ),
      subtitle: subtitle != null
          ? DefaultTextStyle.merge(
              style: TextStyle(color: p.secondary, fontSize: 14),
              child: subtitle!,
            )
          : null,
      leading: leading,
      trailing: trailing ?? (onTap != null ? const CupertinoListTileChevron() : null),
      onTap: onTap,
    );
  }
}

/// 带背景色的 iOS 风格图标（用于 HubPage 或设置页）。
class TileIcon extends StatelessWidget {
  const TileIcon({
    super.key,
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Icon(icon, color: CupertinoColors.white, size: 18),
      ),
    );
  }
}

/// KV 行（详情页使用）。
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
              fontSize: 16,
            ),
          ),
        );
}

/// 细分割线（Cupertino 风格）。
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
// 导航与工具
// ---------------------------------------------------------------------------

/// 下钻压栈。
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

/// Map 取值 helper。
String s(Map<String, Object?> m, String k) => m[k] as String? ?? '';
int? i(Map<String, Object?> m, String k) => m[k] as int?;
