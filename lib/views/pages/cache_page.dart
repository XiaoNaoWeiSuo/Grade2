/// 缓存管理工具页 —— LocalCache 可视化：命名空间/条目/编辑/删除/清空/统计。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/cache_vm.dart';
import '../../viewmodels/providers.dart';
import '../widgets/kit.dart';

class CachePage extends ConsumerWidget {
  const CachePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cacheProvider);
    return async.when(
      loading: () => const CenterMessage(message: '扫描缓存…', busy: true),
      error: (e, _) => CenterMessage(
          icon: Icons.error_outline, message: '缓存读取失败: $e'),
      data: (st) {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // ---- 统计 + 操作 ----
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storage, size: 20),
                        const SizedBox(width: 8),
                        Text('LocalCache：${humanBytes(st.bytes)} / '
                            '${st.entries} 条 / ${st.namespaces.length} 个命名空间'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('根目录：${ref.read(localCacheProvider).value?.baseDir ?? '…'}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.outline)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('刷新'),
                          onPressed: () =>
                              ref.read(cacheProvider.notifier).refresh(),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('写测试条目'),
                          onPressed: () =>
                              ref.read(cacheProvider.notifier).addDemoEntry(),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(
                              Icons.delete_forever_outlined,
                              size: 18),
                          label: const Text('清空全部'),
                          onPressed: () async {
                            final ok = await confirmDialog(context,
                                title: '清空全部缓存',
                                content: '将删除所有命名空间（含账号簿记住的密码与课表缓存），确定？');
                            if (ok) {
                              await ref
                                  .read(cacheProvider.notifier)
                                  .clearAll();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ---- 命名空间列表 ----
            if (st.namespaces.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CenterMessage(
                    icon: Icons.inbox_outlined, message: '缓存为空'),
              ),
            for (final ns in st.namespaces)
              _NsCard(ns: ns, entries: st.dumps[ns] ?? const {}),
          ],
        );
      },
    );
  }
}

/// 单命名空间卡片（展开显示全部键）。
class _NsCard extends ConsumerWidget {
  const _NsCard({required this.ns, required this.entries});

  final String ns;
  final Map<String, Object?> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = entries.keys.map((k) => k.toString()).toList()..sort();
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(ns,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${keys.length} 条'),
        trailing: IconButton(
          tooltip: '删除命名空间',
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () async {
            final ok = await confirmDialog(context,
                title: '清空 $ns', content: '删除该命名空间下全部条目，确定？');
            if (ok) await ref.read(cacheProvider.notifier).clearNs(ns);
          },
        ),
        children: [
          if (keys.isEmpty)
            const Padding(
                padding: EdgeInsets.all(16), child: Text('（空）')),
          for (final k in keys)
            _EntryTile(ns: ns, cacheKey: k, entry: entries[k]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 单条目行。
class _EntryTile extends ConsumerWidget {
  const _EntryTile(
      {required this.ns, required this.cacheKey, required this.entry});

  final String ns;
  final String cacheKey;
  final Object? entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = entry is Map ? (entry as Map)['v'] : null;
    final exp = entry is Map ? (entry as Map)['exp'] : null;
    final pretty = prettyJson(v);
    return ListTile(
      dense: true,
      title: Text(cacheKey, style: const TextStyle(fontSize: 13)),
      subtitle: Text(
        pretty.replaceAll('\n', ' ').length > 80
            ? '${pretty.replaceAll('\n', ' ').substring(0, 80)}…'
            : pretty.replaceAll('\n', ' '),
        style: TextStyle(
            fontSize: 11, color: Theme.of(context).colorScheme.outline),
      ),
      trailing: exp is int
          ? Text('TTL',
              style: TextStyle(
                  fontSize: 10, color: Theme.of(context).colorScheme.tertiary))
          : null,
      onTap: () => showJsonDialog(
        context,
        title: '$ns / $cacheKey',
        json: pretty,
        editable: true,
        onSave: (newJson) async {
          final err = await ref
              .read(cacheProvider.notifier)
              .writeJson(ns, cacheKey, newJson);
          if (err != null && context.mounted) snack(context, err, error: true);
        },
      ),
      onLongPress: () async {
        final ok = await confirmDialog(context,
            title: '删除条目', content: '$ns / $cacheKey');
        if (ok) {
          await ref.read(cacheProvider.notifier).deleteKey(ns, cacheKey);
        }
      },
    );
  }
}
