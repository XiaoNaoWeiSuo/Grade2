/// 『更多』功能中枢页 —— 聚合全校教务服务能力。
/// 采用现代 iOS Control Center / Inset Grouped 视觉体系，按使用场景清晰分层。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/semester_vm.dart';
import '../widgets/cupertino_kit.dart';
import 'elective_page.dart';
import 'exam_page.dart';
import 'grades_page.dart';
import 'messages_page.dart';
import 'plan_page.dart';
import 'std_detail_page.dart';
import 'evaluate_page.dart';
import 'welcome_page.dart';

class HubPage extends ConsumerWidget {
  const HubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = AppThemeScope.of(context);
    final auth = ref.watch(authProvider).value;
    final displayName = auth?.displayName ?? auth?.username ?? l10n.student;
    final selection = ref.watch(semesterSelectionProvider).value;

    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.more),
            backgroundColor: p.bar.withValues(alpha: 0.82),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // 顶部学业概览卡片
                  CupertinoCard(
                    padding: const EdgeInsets.all(18),
                    color: p.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [p.primary, p.primary.withValues(alpha: 0.75)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.sparkles,
                                  color: CupertinoColors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.hello(displayName),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: p.label,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    selection?.label ?? l10n.systemTitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: p.secondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Sep(),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _QuickActionPill(
                              icon: CupertinoIcons.chart_bar_fill,
                              label: l10n.grades,
                              color: CupertinoColors.systemGreen,
                              onTap: () => pushPage(context, const GradesPage()),
                            ),
                            const SizedBox(width: 8),
                            _QuickActionPill(
                              icon: CupertinoIcons.square_grid_2x2_fill,
                              label: l10n.elective,
                              color: CupertinoColors.systemBlue,
                              onTap: () => pushPage(context, const ElectivePage()),
                            ),
                            const SizedBox(width: 8),
                            _QuickActionPill(
                              icon: CupertinoIcons.doc_text_fill,
                              label: l10n.exam,
                              color: CupertinoColors.systemIndigo,
                              onTap: () => pushPage(context, const ExamPage()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- 窗期高频服务 ---
                  Group(
                    header: Text(l10n.hubWindow),
                    children: [
                      Tile(
                        leading: const TileIcon(
                          icon: CupertinoIcons.square_grid_2x2_fill,
                          color: CupertinoColors.systemBlue,
                        ),
                        title: Text(l10n.elective),
                        subtitle: Text(l10n.electiveProfiles),
                        onTap: () => pushPage(context, const ElectivePage()),
                      ),
                      Tile(
                        leading: const TileIcon(
                          icon: CupertinoIcons.doc_text_fill,
                          color: CupertinoColors.systemIndigo,
                        ),
                        title: Text(l10n.exam),
                        subtitle: Text(l10n.examArrange),
                        onTap: () => pushPage(context, const ExamPage()),
                      ),
                    ],
                  ),

                  // --- 数据与学业档案 ---
                  Group(
                    header: Text(l10n.hubData),
                    children: [
                      Tile(
                        leading: const TileIcon(
                          icon: CupertinoIcons.chart_bar_fill,
                          color: CupertinoColors.systemGreen,
                        ),
                        title: Text(l10n.grades),
                        subtitle: Text(l10n.gradesDetail),
                        onTap: () => pushPage(context, const GradesPage()),
                      ),
                      Tile(
                        leading: const TileIcon(
                          icon: CupertinoIcons.list_bullet_indent,
                          color: CupertinoColors.systemTeal,
                        ),
                        title: Text(l10n.plan),
                        subtitle: Text(l10n.tabMajorPlan),
                        onTap: () => pushPage(context, const PlanPage()),
                      ),
                      Tile(
                        leading: const TileIcon(
                          icon: CupertinoIcons.person_2_fill,
                          color: CupertinoColors.systemPurple,
                        ),
                        title: Text(l10n.stdInfo),
                        subtitle: Text(l10n.basicStudentDossier),
                        onTap: () => pushPage(context, const StdDetailPage()),
                      ),
                    ],
                  ),

                  // --- 校园事务与通知 ---
                  Group(
                    header: Text(l10n.hubAffair),
                    children: [
                      Tile(
                        leading: const TileIcon(
                          icon: CupertinoIcons.speaker_2_fill,
                          color: CupertinoColors.systemOrange,
                        ),
                        title: Text(l10n.welcome),
                        subtitle: Text(l10n.announcement),
                        onTap: () => pushPage(context, const WelcomePage()),
                      ),
                      Tile(
                        leading: const TileIcon(
                          icon: CupertinoIcons.envelope_fill,
                          color: CupertinoColors.systemRed,
                        ),
                        title: Text(l10n.messages),
                        subtitle: Text(l10n.msgDetail),
                        onTap: () => pushPage(context, const MessagesPage()),
                      ),
                      Tile(
                        leading: const TileIcon(
                          icon: CupertinoIcons.checkmark_square_fill,
                          color: CupertinoColors.systemYellow,
                        ),
                        title: Text(l10n.evaluate),
                        subtitle: Text(l10n.pendingTasks),
                        onTap: () => pushPage(context, const EvaluatePage()),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  const _QuickActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoScaleButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
