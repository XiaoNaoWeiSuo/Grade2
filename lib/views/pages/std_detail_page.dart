/// 学籍信息页 —— 校园卡风格的个人学籍档案与分段 KV 展示。
///
/// 特性：
/// - 校园卡风格的学生档案 Header（包含照片、姓名、学号、院系）
/// - Inset Grouped 分段展示学籍、教务、联系方式等元数据
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
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.stdInfo),
            backgroundColor: p.bar.withValues(alpha: 0.82),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: () => ref.read(stdDetailProvider.notifier).refresh(),
              child: const Icon(CupertinoIcons.arrow_clockwise, size: 20),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(stdDetailProvider.notifier).refresh(),
          ),
          const _StdBody(),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
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

    return async.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CupertinoActivityIndicator(radius: 14)),
      ),
      error: (e, _) => SliverFillRemaining(
        child: CupertinoErrorCard(
          message: '$e',
          onRetry: () => ref.read(stdDetailProvider.notifier).refresh(),
        ),
      ),
      data: (data) {
        if (data == null || data.isEmpty) {
          return SliverFillRemaining(
            child: CupertinoEmpty(
              message: context.l10n.noStdInfo,
              icon: CupertinoIcons.person_badge_minus,
            ),
          );
        }

        final photo = data['photo'] as String?;
        final sections = data['sections'];
        final p = AppThemeScope.of(context);
        final l10n = context.l10n;

        // 提取主要信息生成学生卡
        String studentName = l10n.student;
        String studentNo = '';
        String department = '';
        String major = '';

        if (sections is List) {
          for (final s in sections.whereType<Map>()) {
            final kv = s['kv'];
            if (kv is Map) {
              if (kv.containsKey('姓名')) studentName = '${kv['姓名']}';
              if (kv.containsKey('学号')) studentNo = '${kv['学号']}';
              if (kv.containsKey('学院') || kv.containsKey('院系')) {
                department = '${kv['学院'] ?? kv['院系']}';
              }
              if (kv.containsKey('专业')) major = '${kv['专业']}';
            }
          }
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 12),

              // 校园卡风格 Header
              CupertinoCard(
                padding: const EdgeInsets.all(20),
                color: p.card,
                child: Row(
                  children: [
                    _StudentAvatar(photoUrl: photo, name: studentName, p: p),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: p.label,
                              letterSpacing: -0.4,
                            ),
                          ),
                          if (studentNo.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.studentIdNo(studentNo),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: p.primary,
                              ),
                            ),
                          ],
                          if (department.isNotEmpty || major.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              [department, major].where((e) => e.isNotEmpty).join(' · '),
                              style: TextStyle(
                                fontSize: 12,
                                color: p.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 分段信息组
              if (sections is List)
                for (final s in sections.whereType<Map>()) ...[
                  Builder(
                    builder: (ctx) {
                      final name = s['section'] as String? ?? l10n.archiveInfo;
                      final kv = s['kv'];
                      final rows = <Widget>[];

                      if (kv is Map) {
                        for (final e in kv.entries) {
                          if (e.key == '照片') continue;
                          rows.add(
                            KVRow(
                              label: '${e.key}',
                              value: '${e.value}',
                            ),
                          );
                        }
                      }

                      if (rows.isEmpty) return const SizedBox.shrink();

                      return Group(
                        header: Text(name),
                        children: rows,
                      );
                    },
                  ),
                ],
            ]),
          ),
        );
      },
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({
    required this.photoUrl,
    required this.name,
    required this.p,
  });

  final String? photoUrl;
  final String name;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    const size = 68.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.secondary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: p.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
              )
            : _fallbackAvatar(),
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: p.primary.withValues(alpha: 0.15),
      child: Center(
        child: name.isNotEmpty
            ? Text(
                name.substring(0, 1),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: p.primary,
                ),
              )
            : Icon(
                CupertinoIcons.person_fill,
                size: 28,
                color: p.primary,
              ),
      ),
    );
  }
}
