/// 更多页 —— 工程期能力面板：账号信息 + 全部 EamsApi 动作触发 + 结果 JSON 查看。
///
/// 正式 UI 重写时本页将被按功能拆分的正式页面替代（内核调用方式不变）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/api_explorer_vm.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/providers.dart';
import '../widgets/kit.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value ?? const AuthState();
    final explorer = ref.watch(apiExplorerProvider);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ---- 账号信息 ----
        Card(
          child: ListTile(
            leading: Icon(Icons.account_circle,
                size: 40, color: Theme.of(context).colorScheme.primary),
            title: Text(auth.displayName?.isNotEmpty == true
                ? auth.displayName!
                : (auth.username ?? '未命名账号')),
            subtitle: Text(
              '账号 ${auth.username ?? '-'}'
              '${auth.offline ? '  ·  离线模式' : ''}',
            ),
            isThreeLine: false,
          ),
        ),

        // ---- 全局错误 ----
        if (explorer.error != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(explorer.error!,
                  style: const TextStyle(fontSize: 13)),
            ),
          ),

        // ---- 动作按钮 ----
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final e in ApiExplorerController.actions.entries)
                  ActionChip(
                    label: Text(e.value,
                        style: const TextStyle(fontSize: 12)),
                    avatar: explorer.running == e.key
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : null,
                    onPressed: explorer.running == null
                        ? () =>
                            ref.read(apiExplorerProvider.notifier).run(e.key)
                        : null,
                  ),
              ],
            ),
          ),
        ),

        // ---- 结果列表 ----
        for (final e in explorer.results.entries)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.data_object, size: 20),
              title: Text(
                  ApiExplorerController.actions[e.key] ?? e.key,
                  style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                _preview(e.value),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.outline),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => showJsonDialog(
                context,
                title: ApiExplorerController.actions[e.key] ?? e.key,
                json: prettyJson(e.value),
              ),
            ),
          ),

        const SizedBox(height: 16),
        Text('提示：以上动作为工程期调试入口，返回值为内核解析后的原生 '
            'Map/List（形状见 lib/core/crawler/models/data_models.dart）。',
            style: TextStyle(
                fontSize: 11, color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }

  static String _preview(Object? v) {
    final s = prettyJson(v).replaceAll('\n', ' ');
    return s.length > 120 ? s.substring(0, 120) : s;
  }
}
