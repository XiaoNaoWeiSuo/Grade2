/// 工程期共享小组件（正式 UI 重写时整体替换，不约束设计）。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 居中状态视图：loading / error / empty 三合一。
class CenterMessage extends StatelessWidget {
  const CenterMessage({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.busy = false,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final bool busy;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 缩进 JSON 查看弹窗（可选编辑模式：JSON 文本框 + 保存回调）。
Future<void> showJsonDialog(
  BuildContext context, {
  required String title,
  required String json,
  bool editable = false,
  Future<void> Function(String newJson)? onSave,
}) {
  final controller = TextEditingController(text: json);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: controller,
          maxLines: 14,
          readOnly: !editable,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: const InputDecoration(
              border: OutlineInputBorder(), isDense: true),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: controller.text));
            snack(ctx, '已复制');
          },
          child: const Text('复制'),
        ),
        if (editable && onSave != null)
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              await onSave(controller.text);
              if (ctx.mounted) navigator.pop();
            },
            child: const Text('保存'),
          ),
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭')),
      ],
    ),
  );
}

/// 通用确认弹窗。返回 true = 确认。
Future<bool> confirmDialog(BuildContext context,
    {required String title, required String content}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消')),
        FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定')),
      ],
    ),
  );
  return ok == true;
}

/// SnackBar 提示（替代 fluttertoast，零插件）。
void snack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      duration: Duration(seconds: error ? 4 : 2),
    ));
}

/// 字节数 → 可读文本。
String humanBytes(int n) =>
    n < 1024 ? '$n B' : (n < 1024 * 1024 ? '${(n / 1024).toStringAsFixed(1)} KB' : '${(n / 1024 / 1024).toStringAsFixed(2)} MB');

/// 缓存根目录体积（设置页/工具页展示）。
Future<int> dirSizeBytes(String path) async {
  final dir = Directory(path);
  if (!await dir.exists()) return 0;
  var total = 0;
  await for (final e in dir.list(recursive: true)) {
    if (e is File) total += await e.length();
  }
  return total;
}
