/// 课表首页（authed 根路由，常驻）。
/// 采用现代化的 Cupertino 设计，引入磨砂玻璃质感与更优雅的布局。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/semester_vm.dart';
import '../../viewmodels/timetable_vm.dart';
import '../widgets/cupertino_kit.dart';
import 'account_page.dart';
import 'hub_page.dart';

/// 星期标签。
String _dayLabel(BuildContext context, int d) {
  final s = context.l10n;
  return switch (d) {
    1 => s.mon,
    2 => s.tue,
    3 => s.wed,
    4 => s.thu,
    5 => s.fri,
    6 => s.sat,
    7 => s.sun,
    _ => '$d',
  };
}

/// 课程格底色。
const _cellColors = [
  Color(0xFFE3F2FD),
  Color(0xFFF1F8E9),
  Color(0xFFFFF3E0),
  Color(0xFFFCE4EC),
  Color(0xFFF3E5F5),
  Color(0xFFE0F2F1),
  Color(0xFFFFF1F1),
  Color(0xFFE8EAF6),
];

class TimetablePage extends ConsumerWidget {
  const TimetablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value ?? const AuthState();
    final selection = ref.watch(semesterSelectionProvider).value;
    final semesterLabel = selection?.label ?? '';
    final p = AppThemeScope.of(context);

    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: p.bar.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => pushPage(context, const AccountPage()),
          child: Icon(
            CupertinoIcons.person_crop_circle,
            size: 28,
            color: p.primary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (auth.offline)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  CupertinoIcons.cloud,
                  size: 18,
                  color: CupertinoColors.systemOrange,
                ),
              ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => pushPage(context, const HubPage()),
              child: Icon(
                CupertinoIcons.square_grid_2x2,
                size: 24,
                color: p.primary,
              ),
            ),
          ],
        ),
        middle: GestureDetector(
          onTap: () => _pickSemester(context, ref),
          child: BlurView(
            borderRadius: BorderRadius.circular(20),
            color: p.primary.withValues(alpha: 0.1),
            blur: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      semesterLabel.isEmpty
                          ? context.l10n.timetable
                          : semesterLabel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: p.label,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 12,
                    color: p.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      child: const _TimetableBody(),
    );
  }

  Future<void> _pickSemester(BuildContext context, WidgetRef ref) async {
    final selection = ref.read(semesterSelectionProvider).value;
    if (selection == null) return;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        final p = AppThemeScope.of(ctx);
        return BlurView(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: p.separator,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        ctx.l10n.switchSemester,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: selection.fromNetwork
                            ? null
                            : () async {
                                final err = await ref
                                    .read(semesterSelectionProvider.notifier)
                                    .refreshFromNetwork();
                                if (ctx.mounted)
                                  toast(
                                    ctx,
                                    err ?? ctx.l10n.semesterSynced,
                                    error: err != null,
                                  );
                              },
                        child: Text(ctx.l10n.sync),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: selection.options.length,
                    separatorBuilder: (_, __) => Sep(indent: 16, endIndent: 16),
                    itemBuilder: (ctx, index) {
                      final opt = selection.options.reversed.toList()[index];
                      final isCurrent = opt['id'] == selection.currentId;
                      return Tile(
                        title: Text(opt['label'] as String? ?? '${opt['id']}'),
                        trailing: isCurrent
                            ? Icon(
                                CupertinoIcons.check_mark,
                                color: p.primary,
                                size: 18,
                              )
                            : null,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          ref
                              .read(semesterSelectionProvider.notifier)
                              .select(opt['id'] as int);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimetableBody extends ConsumerStatefulWidget {
  const _TimetableBody();
  @override
  ConsumerState<_TimetableBody> createState() => _TimetableBodyState();
}

class _TimetableBodyState extends ConsumerState<_TimetableBody> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(timetableProvider);
    final week = ref.watch(weekIndexProvider);
    final todayWeekday = DateTime.now().weekday;
    final data = async.value;
    final p = AppThemeScope.of(context);

    return CustomScrollView(
      controller: _scroll,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () => ref.read(timetableProvider.notifier).refresh(),
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              if (data != null) _buildWeekBar(context, data, week),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (async.isLoading && data == null)
          const SliverFillRemaining(
            child: Center(child: CupertinoActivityIndicator(radius: 16)),
          )
        else if (async.hasError && data == null)
          SliverFillRemaining(
            child: CupertinoEmpty(
              message: '${async.error}',
              icon: CupertinoIcons.exclamationmark_circle,
            ),
          )
        else if (data == null || data.courses.isEmpty)
          const SliverFillRemaining(
            child: CupertinoEmpty(icon: CupertinoIcons.calendar_badge_minus),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverToBoxAdapter(
              child: _buildGrid(context, data, week, todayWeekday),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildWeekBar(BuildContext context, TimetableData data, int week) {
    final p = AppThemeScope.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: BlurView(
          borderRadius: BorderRadius.circular(12),
          color: p.card.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: week > 1
                      ? () => ref.read(weekIndexProvider.notifier).state =
                            week - 1
                      : null,
                  child: Icon(
                    CupertinoIcons.chevron_left_circle_fill,
                    size: 28,
                    color: week > 1
                        ? p.primary
                        : p.secondary.withValues(alpha: 0.3),
                  ),
                ),
                const Spacer(),
                Column(
                  children: [
                    Text(
                      context.l10n.weekLabel
                          .replaceFirst('%1', '$week')
                          .replaceFirst('%2', '${data.totalWeeks}'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '当前周次',
                      style: TextStyle(fontSize: 10, color: p.secondary),
                    ),
                  ],
                ),
                const Spacer(),
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: week < data.totalWeeks
                      ? () => ref.read(weekIndexProvider.notifier).state =
                            week + 1
                      : null,
                  child: Icon(
                    CupertinoIcons.chevron_right_circle_fill,
                    size: 28,
                    color: week < data.totalWeeks
                        ? p.primary
                        : p.secondary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    TimetableData data,
    int week,
    int todayWeekday,
  ) {
    final p = AppThemeScope.of(context);
    final unitCount = data.unitCount;
    final grid = <int, Map<int, List<Map<String, Object?>>>>{};
    for (final c in data.courses) {
      final day = c['day'] as int?;
      final unit = c['unit'] as int?;
      final weeks = c['weeks'];
      final list = weeks is Map ? weeks['list'] as List? : null;
      if (day == null || unit == null || list == null || !list.contains(week))
        continue;
      grid.putIfAbsent(day, () => {})[unit] = [
        ...(grid[day]?[unit] ?? const []),
        c,
      ];
    }

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: p.separator.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: {
          0: const FixedColumnWidth(30),
          for (var i = 1; i <= 7; i++) i: const FlexColumnWidth(),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: p.secondary.withValues(alpha: 0.05),
            ),
            children: [
              const SizedBox(height: 36),
              for (var d = 1; d <= 7; d++)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _dayLabel(context, d),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: d == todayWeekday
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: d == todayWeekday ? p.primary : p.secondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (var u = 1; u <= unitCount; u++)
            TableRow(
              children: [
                SizedBox(
                  height: 64,
                  child: Center(
                    child: Text(
                      '$u',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: p.secondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                for (var d = 1; d <= 7; d++) _cell(context, grid[d]?[u]),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, List<Map<String, Object?>>? items) {
    if (items == null || items.isEmpty) return const SizedBox(height: 64);
    final c = items.first;
    final name = (c['name'] as String?) ?? '';
    final room = (c['room'] as String?) ?? '';
    final colorBase = _cellColors[name.hashCode.abs() % _cellColors.length];
    final extra = items.length > 1 ? '+${items.length - 1}' : '';

    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.fill,
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: GestureDetector(
          onTap: () => _showCourse(context, name, items),
          child: Container(
            decoration: BoxDecoration(
              color: colorBase.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$name$extra',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                if (room.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      room,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
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

  void _showCourse(
    BuildContext context,
    String name,
    List<Map<String, Object?>> items,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        final p = AppThemeScope.of(ctx);
        return BlurView(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: p.separator,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    name.isEmpty ? ctx.l10n.courseDetail : name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Sep(indent: 16, endIndent: 16),
                    itemBuilder: (ctx, index) => _courseTile(ctx, items[index]),
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoButton(
                  child: Text(
                    ctx.l10n.close,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _courseTile(BuildContext context, Map<String, Object?> it) {
    final p = AppThemeScope.of(context);
    final teachers = (it['teacher_names'] as String?) ?? '';
    final room = (it['room'] as String?) ?? '';
    final dayName = (it['day_name'] as String?) ?? '';
    final unit = it['unit'];
    final weeksRaw = it['weeks'] is Map ? (it['weeks'] as Map)['digest'] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.time,
                size: 14,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 6),
              Text(
                '$dayName ${context.l10n.periodUnit.replaceFirst('%1', '${unit ?? '?'}')}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${weeksRaw ?? ''}周',
                style: TextStyle(
                  fontSize: 13,
                  color: p.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (teachers.isNotEmpty)
            _infoRow(
              CupertinoIcons.person,
              context.l10n.teacher.replaceFirst('%1', teachers),
            ),
          if (room.isNotEmpty)
            _infoRow(
              CupertinoIcons.location,
              context.l10n.room.replaceFirst('%1', room),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: CupertinoColors.systemGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
