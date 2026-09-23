/// 选课课程页：某轮次的选课课程列表与选退课操作。
/// 具备：
/// - 实时余量比例进度条（动态变色：充足绿、紧张橙、爆满红）
/// - 搜索关键词与多标签复合筛选（通识/专业/校区/仅有余量/仅已选）
/// - SliverList 懒加载流畅滚动与防误触确认弹窗
/// - 课程详细参数与排课时间抽屉
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/elective_vm.dart';
import '../widgets/cupertino_kit.dart';

/// 辅助格式化工具（防御各种动态类型）。
String _formatCredits(Object? val) {
  if (val == null) return '';
  if (val is num) {
    return val % 1 == 0 ? val.toInt().toString() : val.toString();
  }
  final n = num.tryParse(val.toString());
  if (n != null) {
    return n % 1 == 0 ? n.toInt().toString() : n.toString();
  }
  return val.toString();
}

String _formatTeachers(Object? val) {
  if (val == null) return '';
  if (val is String) return val;
  if (val is List) {
    return val.map((e) {
      if (e is Map) return e['name']?.toString() ?? '';
      return e.toString();
    }).where((e) => e.isNotEmpty).join('、');
  }
  return val.toString();
}

String _formatArrangeInfo(Object? val) {
  if (val == null) return '';
  if (val is String) return val;
  if (val is List) {
    final list = <String>[];
    for (final item in val) {
      if (item is Map) {
        final time = item['time'] ?? item['weekState'] ?? '';
        final room = item['room'] ?? item['place'] ?? '';
        final teacher = item['teacher'] ?? '';
        final line = [time, room, teacher]
            .where((e) => e.toString().trim().isNotEmpty)
            .join(' · ');
        if (line.isNotEmpty) list.add(line);
      } else if (item != null && item.toString().trim().isNotEmpty) {
        list.add(item.toString());
      }
    }
    return list.join('；');
  }
  return val.toString();
}

class ElectiveLessonsPage extends ConsumerStatefulWidget {
  const ElectiveLessonsPage({super.key, required this.profile});
  final Map<String, Object?> profile;

  @override
  ConsumerState<ElectiveLessonsPage> createState() =>
      _ElectiveLessonsPageState();
}

class _ElectiveLessonsPageState extends ConsumerState<ElectiveLessonsPage> {
  final _query = TextEditingController();
  final Set<String> _types = {};
  final Set<String> _campuses = {};
  final Set<String> _states = {}; // 'available' | 'selected'

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(electiveProvider.notifier).openProfile(widget.profile),
    );
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(electiveProvider.notifier).refreshProfile();
  Future<void> _retry() =>
      ref.read(electiveProvider.notifier).openProfile(widget.profile);

  Future<void> _act(Map<String, Object?> lesson, bool elect) async {
    final id = lesson['id'];
    if (id is! int) return;
    final l10n = context.l10n;
    final name = s(lesson, 'name').isEmpty ? l10n.course : s(lesson, 'name');

    final ok = await confirm(
      context,
      title: elect ? l10n.confirmSelectTitle : l10n.confirmWithdrawTitle,
      message: (elect ? l10n.confirmSelectMsg : l10n.confirmWithdrawMsg)
          .replaceFirst('%1', name),
      destructive: !elect,
    );
    if (!ok || !mounted) return;
    final msg = await ref.read(electiveProvider.notifier).operate(id, elect);
    if (mounted && msg != null) toast(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(electiveProvider);
    final data = async.value;
    final profile = widget.profile;
    final electOpen = s(profile, 'elect_open').isNotEmpty;
    final withdrawOpen = s(profile, 'withdraw_open').isNotEmpty;
    final all = data?.merged ?? const [];
    final loading = (data?.detailLoading ?? false) && all.isEmpty;
    final error = data?.error;
    final showError = error != null && all.isEmpty;
    final l10n = context.l10n;
    final p = AppThemeScope.of(context);

    final myElect = data?.myElect ?? const <String>{};
    final ttCodes = data?.ttCodes ?? const <String>{};
    final filtered = _filter(all, myElect, ttCodes, electOpen, withdrawOpen);
    final types = _uniq(all, 'courseTypeName');
    final campuses = _uniq(all, 'campusName');

    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: p.bar,
        border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
        middle: Text(
          s(profile, 'name').isEmpty ? l10n.elective : s(profile, 'name'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      child: CustomScrollView(
        physics:
            const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: _refresh),
          if (loading)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator(radius: 14)),
            )
          else if (showError)
            SliverFillRemaining(
              child: CupertinoErrorCard(
                message: error,
                onRetry: _retry,
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CupertinoSearchTextField(
                      controller: _query,
                      placeholder: l10n.searchCourses,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    _FilterSection(
                      types: types,
                      campuses: campuses,
                      selectedTypes: _types,
                      selectedCampuses: _campuses,
                      selectedStates: _states,
                      onToggleType: (v) => setState(() =>
                          _types.contains(v) ? _types.remove(v) : _types.add(v)),
                      onToggleCampus: (v) => setState(() => _campuses.contains(v)
                          ? _campuses.remove(v)
                          : _campuses.add(v)),
                      onToggleState: (v) => setState(() => _states.contains(v)
                          ? _states.remove(v)
                          : _states.add(v)),
                      p: p,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        '${l10n.filterResults} · ${l10n.lessonsCountSuffix(filtered.length)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: p.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                child: CupertinoEmpty(
                  message: l10n.noLessons,
                  icon: CupertinoIcons.tray,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = filtered[index];
                      final lesson = entry['lesson'] as Map<String, Object?>;
                      final isSelected = _isMine(lesson, myElect, ttCodes);
                      final sc = entry['sc'] as int? ??
                          i(lesson, 'stdCount') ??
                          i(lesson, 'sc');
                      final lc = entry['lc'] as int? ??
                          i(lesson, 'limitCount') ??
                          i(lesson, 'lc');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LessonCard(
                          lesson: lesson,
                          sc: sc,
                          lc: lc,
                          electOpen: electOpen,
                          withdrawOpen: withdrawOpen,
                          selected: isSelected,
                          operating: data?.operatingLessonId,
                          onTap: () => _showDetail(entry, l10n),
                          onAct: (elect) => _act(lesson, elect),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  List<Map<String, Object?>> _filter(
    List<Map<String, Object?>> all,
    Set<String> myElect,
    Set<String> ttCodes,
    bool electOpen,
    bool withdrawOpen,
  ) {
    final q = _query.text.trim().toLowerCase();
    return all.where((e) {
      final lesson = e['lesson'] as Map<String, Object?>? ?? const {};
      final name = s(lesson, 'name').toLowerCase();
      final code = s(lesson, 'code').toLowerCase();
      final teacher = _formatTeachers(lesson['teachers']).toLowerCase();
      if (q.isNotEmpty &&
          !name.contains(q) &&
          !code.contains(q) &&
          !teacher.contains(q)) {
        return false;
      }

      if (_types.isNotEmpty && !_types.contains(s(lesson, 'courseTypeName'))) {
        return false;
      }
      if (_campuses.isNotEmpty &&
          !_campuses.contains(s(lesson, 'campusName'))) {
        return false;
      }

      final isSelected = _isMine(lesson, myElect, ttCodes);
      final sc = (e['sc'] as int?) ?? i(lesson, 'stdCount') ?? 0;
      final lc = (e['lc'] as int?) ?? i(lesson, 'limitCount') ?? 0;
      final isFull = lc > 0 && sc >= lc;

      if (_states.contains('selected') && !isSelected) return false;
      if (_states.contains('available') && (isFull || isSelected)) return false;

      return true;
    }).toList();
  }

  bool _isMine(
    Map<String, Object?> lesson,
    Set<String> myElect,
    Set<String> ttCodes,
  ) {
    final id = lesson['id']?.toString() ?? '';
    if (id.isNotEmpty && myElect.contains(id)) return true;
    final code = s(lesson, 'code');
    if (code.isNotEmpty && ttCodes.contains(code)) return true;
    return false;
  }

  List<String> _uniq(List<Map<String, Object?>> all, String key) {
    final out = <String>{};
    for (final e in all) {
      final lesson = e['lesson'] as Map<String, Object?>? ?? const {};
      final v = s(lesson, key);
      if (v.isNotEmpty) out.add(v);
    }
    return out.toList();
  }

  void _showDetail(Map<String, Object?> entry, AppStrings l10n) {
    final lesson = entry['lesson'] as Map<String, Object?>? ?? const {};
    final name = s(lesson, 'name');
    final code = s(lesson, 'code');
    final no = s(lesson, 'no');
    final credits = _formatCredits(lesson['credits']);
    final typeName = s(lesson, 'courseTypeName');
    final campus = s(lesson, 'campusName');
    final department = s(lesson, 'departmentName');
    final teachers = _formatTeachers(lesson['teachers']);
    final arrange = _formatArrangeInfo(lesson['arrangeInfo']);
    final suggest = s(lesson, 'suggest');
    final remark = s(lesson, 'remark');

    final sc =
        entry['sc'] as int? ?? i(lesson, 'stdCount') ?? i(lesson, 'sc');
    final lc =
        entry['lc'] as int? ?? i(lesson, 'limitCount') ?? i(lesson, 'lc');

    showCupertinoModalSheet<void>(
      context: context,
      builder: (ctx) {
        final p = AppThemeScope.of(ctx);
        return CupertinoSheetContainer(
          title: name.isEmpty ? l10n.course : name,
          subtitle: code.isNotEmpty ? l10n.courseCode(code) : null,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 余量进度卡片
              if (sc != null && lc != null) ...[
                CupertinoCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.liveSeatsRemain,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _CapacityBar(sc: sc, lc: lc, p: p),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 基础信息卡片
              CupertinoCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    if (no.isNotEmpty)
                      _InfoRow(label: l10n.classNo, value: no, p: p),
                    if (credits.isNotEmpty)
                      _InfoRow(label: l10n.fieldCredits, value: l10n.creditsLabel.replaceFirst('%1', credits), p: p),
                    if (typeName.isNotEmpty)
                      _InfoRow(label: l10n.courseNature, value: typeName, p: p),
                    if (campus.isNotEmpty)
                      _InfoRow(label: l10n.fieldCampus, value: campus, p: p),
                    if (department.isNotEmpty)
                      _InfoRow(label: l10n.department, value: department, p: p),
                    if (teachers.isNotEmpty)
                      _InfoRow(label: l10n.fieldTeachers, value: teachers, p: p),
                  ],
                ),
              ),

              // 排课安排卡片
              if (arrange.isNotEmpty) ...[
                const SizedBox(height: 14),
                CupertinoCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.scheduleTimePlace,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        arrange,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: p.label,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 选课建议与备注
              if (suggest.isNotEmpty || remark.isNotEmpty) ...[
                const SizedBox(height: 14),
                CupertinoCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (suggest.isNotEmpty) ...[
                        Text(
                          l10n.electiveAdvice,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: p.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          suggest,
                          style: TextStyle(
                            fontSize: 13,
                            color: p.label,
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (suggest.isNotEmpty && remark.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Sep(),
                        ),
                      if (remark.isNotEmpty) ...[
                        Text(
                          l10n.remarkNote,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: p.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          remark,
                          style: TextStyle(
                            fontSize: 13,
                            color: p.secondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.p,
  });

  final String label;
  final String value;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: p.secondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.types,
    required this.campuses,
    required this.selectedTypes,
    required this.selectedCampuses,
    required this.selectedStates,
    required this.onToggleType,
    required this.onToggleCampus,
    required this.onToggleState,
    required this.p,
  });

  final List<String> types;
  final List<String> campuses;
  final Set<String> selectedTypes;
  final Set<String> selectedCampuses;
  final Set<String> selectedStates;
  final ValueChanged<String> onToggleType;
  final ValueChanged<String> onToggleCampus;
  final ValueChanged<String> onToggleState;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _chip(
            context.l10n.onlyAvailable,
            selectedStates.contains('available'),
            () => onToggleState('available'),
          ),
          _chip(
            context.l10n.onlySelected,
            selectedStates.contains('selected'),
            () => onToggleState('selected'),
          ),
          for (final t in types)
            _chip(t, selectedTypes.contains(t), () => onToggleType(t)),
          for (final c in campuses)
            _chip(c, selectedCampuses.contains(c), () => onToggleCampus(c)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: CupertinoScaleButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? p.primary : p.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? p.primary : p.border, width: 0.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? CupertinoColors.white : p.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.sc,
    required this.lc,
    required this.electOpen,
    required this.withdrawOpen,
    required this.selected,
    required this.operating,
    required this.onTap,
    required this.onAct,
  });

  final Map<String, Object?> lesson;
  final int? sc;
  final int? lc;
  final bool electOpen;
  final bool withdrawOpen;
  final bool selected;
  final int? operating;
  final VoidCallback onTap;
  final ValueChanged<bool> onAct;

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;
    final name = s(lesson, 'name');
    final code = s(lesson, 'code');
    final credits = _formatCredits(lesson['credits']);
    final teachers = _formatTeachers(lesson['teachers']);
    final campus = s(lesson, 'campusName');
    final typeName = s(lesson, 'courseTypeName');
    final arrange = _formatArrangeInfo(lesson['arrangeInfo']);
    final lessonId = lesson['id'];
    final isOperatingThis = operating != null && operating == lessonId;

    final isFull = lc != null && sc != null && lc! > 0 && sc! >= lc!;
    final canElect = electOpen && !selected && !isFull;
    final canWithdraw = withdrawOpen && selected;

    return CupertinoCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.label,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (selected)
                CupertinoPillBadge(
                  text: l10n.enrolledBadge,
                  icon: CupertinoIcons.checkmark_seal_fill,
                  color: p.success.withValues(alpha: 0.15),
                  textColor: p.success,
                ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              if (credits.isNotEmpty)
                CupertinoPillBadge(
                  text: l10n.creditsLabel.replaceFirst('%1', credits),
                  color: p.primary.withValues(alpha: 0.1),
                  textColor: p.primary,
                ),
              if (typeName.isNotEmpty) ...[
                const SizedBox(width: 6),
                CupertinoPillBadge(
                  text: typeName,
                  color: p.secondary.withValues(alpha: 0.1),
                  textColor: p.secondary,
                ),
              ],
              if (campus.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  campus,
                  style: TextStyle(fontSize: 12, color: p.tertiary),
                ),
              ],
              const Spacer(),
              if (code.isNotEmpty)
                Text(
                  code,
                  style: TextStyle(fontSize: 11, color: p.tertiary),
                ),
            ],
          ),

          if (teachers.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(CupertinoIcons.person_fill, size: 13, color: p.secondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    teachers,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: p.secondary),
                  ),
                ),
              ],
            ),
          ],

          if (arrange.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    CupertinoIcons.clock,
                    size: 12,
                    color: p.tertiary,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    arrange,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: p.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Sep(),
          const SizedBox(height: 12),

          // 容量进度条与操作按钮
          Row(
            children: [
              if (sc != null && lc != null)
                Expanded(child: _CapacityBar(sc: sc!, lc: lc!, p: p))
              else
                const Spacer(),
              const SizedBox(width: 14),

              if (selected)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: const Size(60, 32),
                  color: p.destructive.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  onPressed: isOperatingThis || !canWithdraw ? null : () => onAct(false),
                  child: isOperatingThis
                      ? CupertinoActivityIndicator(radius: 8, color: p.destructive)
                      : Text(
                          l10n.withdraw,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: canWithdraw ? p.destructive : p.tertiary,
                          ),
                        ),
                )
              else
                CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: const Size(64, 32),
                  borderRadius: BorderRadius.circular(14),
                  onPressed: isOperatingThis || !canElect ? null : () => onAct(true),
                  child: isOperatingThis
                      ? const CupertinoActivityIndicator(
                          radius: 8, color: CupertinoColors.white)
                      : Text(
                          isFull ? l10n.stateFull : l10n.select,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapacityBar extends StatelessWidget {
  const _CapacityBar({required this.sc, required this.lc, required this.p});
  final int sc;
  final int lc;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ratio = lc > 0 ? (sc / lc).clamp(0.0, 1.0) : 0.0;
    Color barColor = p.success;
    if (ratio >= 1.0) {
      barColor = p.destructive;
    } else if (ratio >= 0.85) {
      barColor = p.warning;
    }

    final remain = (lc - sc).clamp(0, 9999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.enrolledOfCap('$sc', '$lc'),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.secondary),
            ),
            const Spacer(),
            Text(
              remain > 0 ? l10n.remainSeats(remain) : l10n.fullSeats,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 5,
          decoration: BoxDecoration(
            color: p.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
