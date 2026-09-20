/// 选课课程页：某轮次的课程列表。采用现代化的 Cupertino 设计，优化搜索与筛选。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/elective_vm.dart';
import '../widgets/cupertino_kit.dart';

class ElectiveLessonsPage extends ConsumerStatefulWidget {
  const ElectiveLessonsPage({super.key, required this.profile});
  final Map<String, Object?> profile;

  @override
  ConsumerState<ElectiveLessonsPage> createState() => _ElectiveLessonsPageState();
}

class _ElectiveLessonsPageState extends ConsumerState<ElectiveLessonsPage> {
  final _query = TextEditingController();
  final Set<String> _types = {};
  final Set<String> _campuses = {};
  final Set<String> _states = {}; // 'open' | 'full' | 'withdrawable'

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(electiveProvider.notifier).openProfile(widget.profile));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _refresh() => ref.read(electiveProvider.notifier).refreshProfile();
  Future<void> _retry() => ref.read(electiveProvider.notifier).openProfile(widget.profile);

  Future<void> _act(Map<String, Object?> lesson, bool elect) async {
    final id = lesson['id'];
    if (id is! int) return;
    final l10n = context.l10n;
    final name = s(lesson, 'name').isEmpty ? l10n.course : s(lesson, 'name');
    final ok = await confirm(
      context,
      title: elect ? l10n.confirmSelectTitle : l10n.confirmWithdrawTitle,
      message: (elect ? l10n.confirmSelectMsg : l10n.confirmWithdrawMsg).replaceFirst('%1', name),
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
    final filtered = _filter(all, myElect, ttCodes, electOpen, withdrawOpen, l10n);
    final types = _uniq(all, 'courseTypeName');
    final campuses = _uniq(all, 'campusName');
    
    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: p.bar.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
        middle: Text(s(profile, 'name').isEmpty ? l10n.elective : s(profile, 'name'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: _refresh),
          
          if (loading)
            const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator(radius: 12)))
          else if (showError)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: CupertinoColors.systemOrange),
                    const SizedBox(height: 16),
                    Text(error, textAlign: TextAlign.center, style: TextStyle(color: p.secondary)),
                    const SizedBox(height: 20),
                    CupertinoButton.filled(onPressed: _retry, child: Text(l10n.retry)),
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderInfo(profile: profile, l10n: l10n, p: p),
                    const SizedBox(height: 16),
                    CupertinoSearchTextField(
                      controller: _query,
                      placeholder: l10n.searchCourses,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _FilterSection(
                      types: types,
                      campuses: campuses,
                      selectedTypes: _types,
                      selectedCampuses: _campuses,
                      selectedStates: _states,
                      onToggleType: (v) => setState(() => _types.contains(v) ? _types.remove(v) : _types.add(v)),
                      onToggleCampus: (v) => setState(() => _campuses.contains(v) ? _campuses.remove(v) : _campuses.add(v)),
                      onToggleState: (v) => setState(() => _states.contains(v) ? _states.remove(v) : _states.add(v)),
                      l10n: l10n,
                      p: p,
                    ),
                    const SizedBox(height: 8),
                    Text('${l10n.filterResults} · ${filtered.length}', style: TextStyle(fontSize: 12, color: p.secondary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            
            if (filtered.isEmpty)
              SliverFillRemaining(child: CupertinoEmpty(message: l10n.noLessons, icon: CupertinoIcons.tray))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = filtered[index];
                      final lesson = entry['lesson'] as Map<String, Object?>;
                      final isSelected = _isMine(lesson, myElect, ttCodes);
                      return _LessonCard(
                        lesson: lesson,
                        sc: entry['sc'] as int?,
                        lc: entry['lc'] as int?,
                        electOpen: electOpen,
                        withdrawOpen: withdrawOpen,
                        selected: isSelected,
                        operating: data?.operatingLessonId,
                        onTap: () => _showDetail(entry, l10n),
                        onElect: () => _act(lesson, true),
                        onWithdraw: () => _act(lesson, false),
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

  List<Map<String, Object?>> _filter(List<Map<String, Object?>> all, Set<String> myElect, Set<String> ttCodes, bool electOpen, bool withdrawOpen, AppStrings l10n) {
    final q = _query.text.trim().toLowerCase();
    return all.where((entry) {
      final lesson = entry['lesson'] as Map<String, Object?>?;
      if (lesson == null) return false;
      final isSelected = _isMine(lesson, myElect, ttCodes);
      if (q.isNotEmpty && !s(lesson, 'name').toLowerCase().contains(q)) return false;
      if (_types.isNotEmpty && !_types.contains(s(lesson, 'courseTypeName'))) return false;
      if (_campuses.isNotEmpty && !_campuses.contains(s(lesson, 'campusName'))) return false;
      if (_states.isNotEmpty) {
        final full = _isFull(entry);
        final hitSel = _states.contains('selected') && isSelected;
        final hitOpen = _states.contains('open') && electOpen && !full && !isSelected;
        final hitFull = _states.contains('full') && full;
        final hitWd = _states.contains('withdrawable') && withdrawOpen && isSelected;
        if (!hitSel && !hitOpen && !hitFull && !hitWd) return false;
      }
      return true;
    }).toList();
  }

  bool _isFull(Map<String, Object?> entry) {
    final sc = entry['sc'];
    final lc = entry['lc'];
    return sc is int && lc is int && sc >= lc;
  }

  List<String> _uniq(List<Map<String, Object?>> all, String key) {
    final seen = <String>{};
    for (final entry in all) {
      final v = s(entry['lesson'] as Map<String, Object?>? ?? {}, key);
      if (v.isNotEmpty) seen.add(v);
    }
    return seen.toList()..sort();
  }

  void _showDetail(Map<String, Object?> entry, AppStrings l10n) {
    final lesson = entry['lesson'] as Map<String, Object?>? ?? const {};
    final p = AppThemeScope.of(context);
    
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => BlurView(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 5, decoration: BoxDecoration(color: p.separator, borderRadius: BorderRadius.circular(2.5))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(s(lesson, 'name'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _detailRow(l10n.fieldCourseNo, s(lesson, 'code')),
                    _detailRow(l10n.fieldType, s(lesson, 'courseTypeName')),
                    _detailRow(l10n.fieldCredits, lesson['credits']),
                    _detailRow(l10n.fieldTeachers, _teachers(lesson)),
                    _detailRow(l10n.fieldCampus, s(lesson, 'campusName')),
                    if (lesson['arrangeInfo'] is List)
                      for (final a in (lesson['arrangeInfo'] as List).whereType<Map>())
                        _detailRow(l10n.fieldSchedule, _formatArrange(a, l10n)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CupertinoButton(child: Text(l10n.close, style: const TextStyle(fontWeight: FontWeight.bold)), onPressed: () => Navigator.of(ctx).pop()),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, Object? value) {
    final str = _pretty(value);
    if (str.isEmpty) return const SizedBox.shrink();
    return KVRow(label: label, value: str);
  }

  String _formatArrange(Map a, AppStrings l10n) {
    final wd = (a['weekDay'] as num?)?.toInt();
    final su = (a['startUnit'] as num?)?.toInt();
    final eu = (a['endUnit'] as num?)?.toInt();
    final digest = a['weekStateDigest'] as String? ?? '';
    final rooms = _pretty(a['rooms']);
    return [
      if (wd != null) _wdLabel(l10n, wd),
      if (su != null) l10n.periodUnit.replaceFirst('%1', eu != null && eu != su ? '$su-$eu' : '$su'),
      if (digest.isNotEmpty) '$digest周',
      if (rooms.isNotEmpty) rooms,
    ].join(' · ');
  }

  static bool _isMine(Map<String, Object?> lesson, Set<String> myElect, Set<String> ttCodes) {
    if (myElect.contains('${lesson['id']}')) return true;
    final code = s(lesson, 'code');
    return code.isNotEmpty && ttCodes.contains(code);
  }

  static String _teachers(Map<String, Object?> lesson) {
    final t = lesson['teachers'];
    if (t is String) return t;
    if (t is List) return t.map(_pretty).where((e) => e.isNotEmpty).join('、');
    return '';
  }

  static String _pretty(Object? v) {
    if (v == null) return '';
    if (v is String) return v.trim();
    if (v is num || v is bool) return '$v';
    if (v is List) return v.map(_pretty).where((e) => e.isNotEmpty).join('、');
    return '$v';
  }

  static String _wdLabel(AppStrings l10n, int wd) => switch (wd) {
    1 => l10n.mon, 2 => l10n.tue, 3 => l10n.wed, 4 => l10n.thu, 5 => l10n.fri, 6 => l10n.sat, 7 => l10n.sun, _ => '$wd',
  };
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({required this.profile, required this.l10n, required this.p});
  final Map<String, Object?> profile;
  final AppStrings l10n;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    final et = s(profile, 'elect_open');
    final wt = s(profile, 'withdraw_open');
    return BlurView(
      borderRadius: BorderRadius.circular(12),
      color: p.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (et.isNotEmpty) _row(CupertinoIcons.checkmark_seal, '${l10n.select}：$et'),
            if (wt.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: _row(CupertinoIcons.xmark_seal, '${l10n.withdraw}：$wt')),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 14, color: p.primary),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: p.secondary, fontWeight: FontWeight.w500))),
    ],
  );
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.types, required this.campuses, required this.selectedTypes, required this.selectedCampuses, required this.selectedStates,
    required this.onToggleType, required this.onToggleCampus, required this.onToggleState, required this.l10n, required this.p,
  });
  final List<String> types, campuses;
  final Set<String> selectedTypes, selectedCampuses, selectedStates;
  final ValueChanged<String> onToggleType, onToggleCampus, onToggleState;
  final AppStrings l10n;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (types.isNotEmpty) _row(l10n.filterType, types, selectedTypes, onToggleType),
        if (campuses.isNotEmpty) _row(l10n.filterCampus, campuses, selectedCampuses, onToggleCampus),
        _row(l10n.filterState, const ['selected', 'open', 'full', 'withdrawable'], selectedStates, onToggleState, isState: true),
      ],
    );
  }

  Widget _row(String label, List<String> options, Set<String> selected, ValueChanged<String> onToggle, {bool isState = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(width: 44, child: Text(label, style: TextStyle(fontSize: 12, color: p.secondary, fontWeight: FontWeight.bold))),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final o in options)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onToggle(o),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected.contains(o) ? p.primary : p.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selected.contains(o) ? p.primary : p.separator),
                        ),
                        child: Text(
                          isState ? _stateLabel(o) : o,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected.contains(o) ? CupertinoColors.white : p.label),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  String _stateLabel(String key) => switch (key) {
    'selected' => l10n.stateSelected, 'open' => l10n.stateChooseable, 'full' => l10n.stateFull, 'withdrawable' => l10n.stateWithdrawable, _ => key,
  };
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson, required this.sc, required this.lc, required this.electOpen, required this.withdrawOpen,
    required this.selected, required this.onTap, required this.onElect, required this.onWithdraw, this.operating,
  });
  final Map<String, Object?> lesson;
  final int? sc, lc, operating;
  final bool electOpen, withdrawOpen, selected;
  final VoidCallback onTap;
  final VoidCallback onElect, onWithdraw;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = AppThemeScope.of(context);
    final isOperating = lesson['id'] == operating;
    final full = sc != null && lc != null && sc! >= lc!;
    final canElect = electOpen && !full && !selected;
    final canWithdraw = withdrawOpen && selected && lesson['withdrawable'] != false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: p.separator.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
        border: selected ? Border.all(color: p.primary.withValues(alpha: 0.3), width: 1.5) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(s(lesson, 'name'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: p.label, height: 1.2)),
                  ),
                  if (selected)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(4)),
                      child: Text(l10n.selectedBadge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _meta(p, [s(lesson, 'courseTypeName'), '${lesson['credits'] ?? ''}学分', s(lesson, 'campusName')].where((e) => e.isNotEmpty).join(' · ')),
              _meta(p, s(lesson, 'teachers'), icon: CupertinoIcons.person),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(6)),
                    child: Text('${l10n.selectedOf.replaceFirst('%1', sc?.toString() ?? '--').replaceFirst('%2', lc?.toString() ?? '--')} 人',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: full ? CupertinoColors.systemRed : p.primary)),
                  ),
                  const Spacer(),
                  if (isOperating)
                    const CupertinoActivityIndicator(radius: 10)
                  else if (canElect)
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      color: p.primary,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: onElect,
                      child: Text(l10n.select, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    )
                  else if (canWithdraw)
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      onPressed: onWithdraw,
                      child: Text(l10n.withdraw, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: CupertinoColors.systemRed)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(AppPalette p, String text, {IconData? icon}) => text.isEmpty ? const SizedBox.shrink() : Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 12, color: p.secondary), const SizedBox(width: 4)],
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: p.secondary, fontWeight: FontWeight.w500))),
      ],
    ),
  );
}
