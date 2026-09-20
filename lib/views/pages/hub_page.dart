/// 『更多』功能中枢页 —— 聚合全部业务模块（窗期高频 + 低频查询 + 事务）。
/// 采用现代化的 Inset Grouped 列表与大标题导航栏。
library;

import 'package:flutter/cupertino.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../widgets/cupertino_kit.dart';
import 'elective_page.dart';
import 'exam_page.dart';
import 'grades_page.dart';
import 'messages_page.dart';
import 'plan_page.dart';
import 'std_detail_page.dart';
import 'evaluate_page.dart';
import 'welcome_page.dart';

class HubPage extends StatelessWidget {
  const HubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = AppThemeScope.of(context);
    
    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(l10n.more),
            backgroundColor: p.bar.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
            stretch: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 10),
                
                // --- 选课与考试 ---
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

                // --- 数据查询 ---
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
                      onTap: () => pushPage(context, const StdDetailPage()),
                    ),
                  ],
                ),

                // --- 事务与通知 ---
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
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
