/// 学籍信息页 —— 学籍/联系/家庭等多 section 分段 KV 展示 + 顶部照片。
/// 采用现代化的 Inset Grouped 列表与大标题导航栏。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/std_vm.dart';
import '../widgets/cupertino_kit.dart';

class StdDetailPage extends ConsumerWidget {
  const StdDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;
    
    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.stdInfo),
            backgroundColor: p.bar.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => ProviderScope.containerOf(context).read(stdDetailProvider.notifier).refresh(),
              child: const Icon(CupertinoIcons.arrow_clockwise),
            ),
          ),
          const _StdBody(),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _StdBody extends ConsumerWidget {
  const _StdBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stdDetailProvider);
    final notifier = ref.read(stdDetailProvider.notifier);
    
    return async.when(
      loading: () => const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator(radius: 12))),
      error: (e, _) => SliverFillRemaining(child: Center(child: CupertinoButton(child: Text(context.l10n.retry), onPressed: () => notifier.refresh()))),
      data: (data) {
        if (data == null || data.isEmpty) {
          return SliverFillRemaining(child: CupertinoEmpty(message: context.l10n.noStdInfo));
        }
        
        final children = <Widget>[];
        final photo = data['photo'];
        if (photo is String && photo.isNotEmpty) {
          children.add(const SizedBox(height: 20));
          children.add(_Photo(url: photo));
          children.add(const SizedBox(height: 20));
        }

        final sections = data['sections'];
        if (sections is List) {
          for (final s in sections.whereType<Map>()) {
            final name = s['section'];
            final groupChildren = <Widget>[];
            final kv = s['kv'];
            if (kv is Map) {
              for (final e in kv.entries) {
                if (e.key == '照片') continue;
                groupChildren.add(KVRow(label: '${e.key}', value: '${e.value}'));
              }
            }
            if (groupChildren.isNotEmpty) {
              children.add(
                Group(
                  header: name is String && name.isNotEmpty ? Text(name) : null,
                  margin: const EdgeInsets.only(bottom: 12),
                  children: groupChildren,
                ),
              );
            }
          }
        }
        
        return SliverList(delegate: SliverChildListDelegate(children));
      },
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    const size = 100.0;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: p.separator.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: p.card,
              child: Icon(CupertinoIcons.person_fill, size: 50, color: p.secondary.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ),
    );
  }
}
