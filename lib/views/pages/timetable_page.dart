/// 课程表页 —— 基础网格渲染：X 轴星期、Y 轴节次、周数翻页（工程期最简实现）。
///
/// 数据：timetableProvider（缓存优先），课程单元格里显示 课程名/教室，
/// 点击弹窗查看全字段；周翻页只切换 [weekIndexProvider]。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/providers.dart';
import '../../viewmodels/semester_vm.dart';
import '../../viewmodels/timetable_vm.dart';
import '../widgets/kit.dart';

const _dayNames = ['一', '二', '三', '四', '五', '六', '日'];

/// 课程格底色（按课程名 hash 稳定取色）。
const _cellBg = [
  Color(0xFFDBEAFE), Color(0xFFDCFCE7), Color(0xFFFEF3C7),
  Color(0xFFFCE7F3), Color(0xFFEDE9FE), Color(0xFFCCFBF1),
  Color(0xFFFFE4E6), Color(0xFFE0F2FE),
];

class TimetablePage extends ConsumerWidget {
  const TimetablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(timetableProvider);
    return async.when(
      loading: () => const CenterMessage(message: '加载课表中…', busy: true),
      error: (e, _) => CenterMessage(
        icon: Icons.error_outline,
        message: e is Exception ? '$e' : '课表加载失败：$e',
        actionLabel: '重试',
        onAction: () =>
            ref.invalidate(timetableProvider),
      ),
      data: (data) {
        if (data == null || data.courses.isEmpty) {
          return CenterMessage(
            icon: Icons.event_busy,
            message: data == null ? '暂无课表数据' : '本学期暂无课程',
            actionLabel: '刷新',
            onAction: () =>
                ref.read(timetableProvider.notifier).refresh(),
          );
        }
        return _TimetableView(data: data);
      },
    );
  }
}

class _TimetableView extends ConsumerWidget {
  const _TimetableView({required this.data});

  final TimetableData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(weekIndexProvider);
    final notifier = ref.read(weekIndexProvider.notifier);
    final todayWeekday = DateTime.now().weekday; // 1=周一

    return Column(
      children: [
        // ---- 顶部：学期选择 + 刷新 ----
        ListTile(
          dense: true,
          onTap: () => _pickSemester(context, ref),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  data.semesterLabel.isEmpty
                      ? '学期 ${data.semesterId ?? '?'}'
                      : data.semesterLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.expand_more, size: 18),
            ],
          ),
          subtitle: Text(
            '点击切换学期 · ${data.fromCache ? '本地缓存数据' : '在线数据'}',
            style: TextStyle(
                fontSize: 11,
                color: data.fromCache
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.primary),
          ),
          trailing: IconButton(
            tooltip: '强制刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(timetableProvider.notifier).refresh(),
          ),
        ),
        if (data.fallbackError != null)
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                Expanded(
                    child: Text(data.fallbackError!,
                        style: const TextStyle(fontSize: 12))),
              ]),
            ),
          ),
        // ---- 周数翻页 ----
        Row(
          children: [
            IconButton(
              tooltip: '上一周',
              icon: const Icon(Icons.chevron_left),
              onPressed: week > 1 ? () => notifier.state = week - 1 : null,
            ),
            Expanded(
              child: Center(
                child: Text(
                  '第 $week 周 / 共 ${data.totalWeeks} 周',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            IconButton(
              tooltip: '下一周',
              icon: const Icon(Icons.chevron_right),
              onPressed:
                  week < data.totalWeeks ? () => notifier.state = week + 1 : null,
            ),
          ],
        ),
        const Divider(height: 1),
        // ---- 课表网格 ----
        Expanded(
          child: SingleChildScrollView(
            child: _buildGrid(context, week, todayWeekday),
          ),
        ),
      ],
    );
  }

  /// 学期选择底部弹窗（新学期在前，当前学期高亮）。
  Future<void> _pickSemester(BuildContext context, WidgetRef ref) async {
    final selection = ref.read(semesterSelectionProvider).value;
    if (selection == null) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 8),
                const Text('切换学期',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: selection.fromNetwork
                      ? null
                      : () async {
                          final err = await ref
                              .read(semesterSelectionProvider.notifier)
                              .refreshFromNetwork();
                          if (ctx.mounted) {
                            snack(ctx, err ?? '已与服务器同步', error: err != null);
                          }
                        },
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('同步', style: TextStyle(fontSize: 12)),
                ),
              ]),
            ),
            const Divider(height: 1),
            for (final opt
                in selection.options.reversed.toList()) // 新学期在前
              ListTile(
                dense: true,
                leading: opt['id'] == selection.currentId
                    ? Icon(Icons.check_circle,
                        size: 18, color: Theme.of(ctx).colorScheme.primary)
                    : const SizedBox(width: 18),
                title: Text(opt['label'] as String? ?? '${opt['id']}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: opt['id'] == selection.currentId
                            ? FontWeight.w600
                            : FontWeight.normal)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref
                      .read(semesterSelectionProvider.notifier)
                      .select(opt['id'] as int);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, int week, int todayWeekday) {
    final unitCount = data.unitCount;

    // (day, unit) → 该时段课程列表
    final grid = <int, Map<int, List<Map<String, Object?>>>>{};
    for (final c in data.courses) {
      final day = c['day'] as int?;
      final unit = c['unit'] as int?;
      final weeks = c['weeks'];
      final list = weeks is Map ? weeks['list'] as List? : null;
      if (day == null || unit == null) continue;
      if (list == null || !list.contains(week)) continue;
      grid.putIfAbsent(day, () => {})[unit] = [
        ...(grid[day]?[unit] ?? const []),
        c,
      ];
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: {
          0: const FixedColumnWidth(32),
          for (var i = 1; i <= 7; i++) i: const FlexColumnWidth(),
        },
        children: [
          // 表头：周x
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade100),
            children: [
              const SizedBox(height: 28),
              for (var d = 1; d <= 7; d++)
                Center(
                  child: Text(
                    _dayNames[d - 1],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: d == todayWeekday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: d == todayWeekday
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          // 数据行：节次
          for (var u = 1; u <= unitCount; u++)
            TableRow(
              children: [
                SizedBox(
                  height: 64,
                  child: Center(
                    child: Text('$u',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.outline)),
                  ),
                ),
                for (var d = 1; d <= 7; d++)
                  _buildCell(context, grid[d]?[u]),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, List<Map<String, Object?>>? items) {
    if (items == null || items.isEmpty) return const SizedBox(height: 64);
    final c = items.first;
    final name = (c['name'] as String?) ?? '';
    final room = (c['room'] as String?) ?? '';
    final bg = _cellBg[name.hashCode.abs() % _cellBg.length];
    final extra = items.length > 1 ? '+${items.length - 1}' : '';
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.fill,
      child: InkWell(
        onTap: () => showJsonDialog(
          context,
          title: name.isEmpty ? '课程详情' : name,
          json: prettyJson([for (final it in items) it]),
        ),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(2),
          color: bg,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$name$extra',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600)),
              if (room.isNotEmpty)
                Text(room,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 9, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}
