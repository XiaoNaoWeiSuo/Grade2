/// 课表首页（authed 根路由，常驻主界面）。
/// 极致还原 Apple iOS Cupertino 体验，包含：
/// - 遵循长江大学真实大节作息规律（上午两节、下午两节、晚间两节，大课间为节次分界）
/// - 顶部导航栏学期/周次快捷浮层、今日/回本周快跳与中枢/账户下钻
/// - 水平教学周滑动切换条与真实学期周次自动定位（秋季学期 9.1 起算）
/// - 长江大学大课间作息体系（09:35-10:05 大课间 30 分钟，15:35-15:55 大课间 20 分钟）
/// - 连续联课智能合并网格（跨大节实验/连堂大课合并为高跨度便当卡片）
/// - 不等大小便当网格布局（无课整列/整行压缩尺寸，空间留给有课列放大展开）
/// - 每日打开自动对齐定位当天 X 轴列并高光聚焦
/// - 响应式多主题课程卡片配色代币与全维度课程详情抽屉
library;

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/crawler/models/semester_table.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/app_theme.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/semester_vm.dart';
import '../../viewmodels/timetable_vm.dart';
import '../widgets/bank_card_surface.dart';
import '../widgets/cupertino_kit.dart';
import '../widgets/tategaki_text.dart';
import 'account_page.dart';
import 'hub_page.dart';

/// 长江大学标准大节作息时间定义。
///
/// 遵循长江大学教学作息规律：
/// - 5分钟小课间属于一整节大课内部的休息调节；
/// - **大课间**才是两节大课之间的真正分界线；
/// - 全天标准结构为：上午两节大课、下午两节大课、晚间两节大课。
class YangtzeSession {
  final int sessionIndex; // 1..6
  final String sessionName; // '第1节', '第2节', '第3节', '第4节', '第5节', '第6节'
  final String periodDesc; // '上午', '上午', '下午', '下午', '晚间', '晚间'
  final int startUnit; // 1, 3, 5, 7, 9, 11
  final int endUnit; // 2, 4, 6, 8, 10, 12
  final String startTime; // '08:00', '10:05', '14:00', '15:55', '18:30', '20:15'
  final String endTime; // '09:35', '11:40', '15:35', '17:30', '20:05', '21:50'
  final String? interbreakTitle; // '大课间', '午休', '大课间', '晚餐晚休', '课间'
  final String? interbreakTime; // '09:35 - 10:05', '11:40 - 14:00' 等
  final double interbreakHeight;

  const YangtzeSession({
    required this.sessionIndex,
    required this.sessionName,
    required this.periodDesc,
    required this.startUnit,
    required this.endUnit,
    required this.startTime,
    required this.endTime,
    this.interbreakTitle,
    this.interbreakTime,
    this.interbreakHeight = 22.0,
  });

  String get timeRange => '$startTime-$endTime';
}

/// 长江大学 6 大节标准作息表（上午 2 节、下午 2 节、晚间 2 节）。
const kYangtzeSessions = [
  // 上午两节（中间为 30 分钟大课间）
  YangtzeSession(
    sessionIndex: 1,
    sessionName: '第1节',
    periodDesc: '上午',
    startUnit: 1,
    endUnit: 2,
    startTime: '08:00',
    endTime: '09:35',
    interbreakTitle: '大课间 30m',
    interbreakTime: '09:35 - 10:05',
    interbreakHeight: 22.0,
  ),
  YangtzeSession(
    sessionIndex: 2,
    sessionName: '第2节',
    periodDesc: '上午',
    startUnit: 3,
    endUnit: 4,
    startTime: '10:05',
    endTime: '11:40',
    interbreakTitle: '午休',
    interbreakTime: '11:40 - 14:00',
    interbreakHeight: 24.0,
  ),

  // 下午两节（中间为 20 分钟大课间）
  YangtzeSession(
    sessionIndex: 3,
    sessionName: '第3节',
    periodDesc: '下午',
    startUnit: 5,
    endUnit: 6,
    startTime: '14:00',
    endTime: '15:35',
    interbreakTitle: '大课间 20m',
    interbreakTime: '15:35 - 15:55',
    interbreakHeight: 22.0,
  ),
  YangtzeSession(
    sessionIndex: 4,
    sessionName: '第4节',
    periodDesc: '下午',
    startUnit: 7,
    endUnit: 8,
    startTime: '15:55',
    endTime: '17:30',
    interbreakTitle: '晚餐晚休',
    interbreakTime: '17:30 - 18:30',
    interbreakHeight: 24.0,
  ),

  // 晚间两节
  YangtzeSession(
    sessionIndex: 5,
    sessionName: '第5节',
    periodDesc: '晚间',
    startUnit: 9,
    endUnit: 10,
    startTime: '18:30',
    endTime: '20:05',
    interbreakTitle: '课间 10m',
    interbreakTime: '20:05 - 20:15',
    interbreakHeight: 18.0,
  ),
  YangtzeSession(
    sessionIndex: 6,
    sessionName: '第6节',
    periodDesc: '晚间',
    startUnit: 11,
    endUnit: 12,
    startTime: '20:15',
    endTime: '21:50',
    interbreakTitle: null,
    interbreakTime: null,
    interbreakHeight: 0.0,
  ),
];

/// 星期标签转换。
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

String _shortDayName(BuildContext context, int d) {
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

/// 合并后的大节课程块模型。
class MergedSessionBlock {
  final int startSession; // 1..6
  final int endSession; // 1..6
  final List<Map<String, Object?>> items;

  const MergedSessionBlock({
    required this.startSession,
    required this.endSession,
    required this.items,
  });

  int get span => endSession - startSession + 1;
  bool get isEmpty => items.isEmpty;
  Map<String, Object?>? get primary => items.isEmpty ? null : items.first;
  String get name => (primary?['name'] as String?) ?? '';
  String get room => (primary?['room'] as String?) ?? '';
  String get teachers => (primary?['teacher_names'] as String?) ?? '';

  String get timeRange {
    final s = kYangtzeSessions[startSession - 1];
    final e = kYangtzeSessions[endSession - 1];
    return '${s.startTime}-${e.endTime}';
  }

  String get sessionLabel {
    if (span == 1) {
      return kYangtzeSessions[startSession - 1].sessionName;
    }
    return '${kYangtzeSessions[startSession - 1].sessionName}-${kYangtzeSessions[endSession - 1].sessionName}';
  }
}

/// 中国大陆日出日落与白昼时长天象计算结果。
class SolarInfo {
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime solarNoon;
  final Duration dayLength;
  final String sunriseStr;
  final String sunsetStr;
  final String noonStr;
  final String dayLengthStr;

  const SolarInfo({
    required this.sunrise,
    required this.sunset,
    required this.solarNoon,
    required this.dayLength,
    required this.sunriseStr,
    required this.sunsetStr,
    required this.noonStr,
    required this.dayLengthStr,
  });
}

/// 中国大陆真实日出日落与作息日照光能计算引擎（以长江大学地理坐标为基准）。
class ChinaSolarEngine {
  /// 长江大学地理坐标（荆州校区 北纬30.33°，东经112.24°；武汉校区 北纬30.48°，东经114.15°）
  static const double lat = 30.33;
  static const double lng = 112.24;

  static SolarInfo calculate(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays + 1;

    final gamma = (2 * math.pi / 365.0) * (dayOfYear - 1);

    final eqtime = 229.18 *
        (0.000075 +
            0.001868 * math.cos(gamma) -
            0.032077 * math.sin(gamma) -
            0.014615 * math.cos(2 * gamma) -
            0.040849 * math.sin(2 * gamma));

    final decl = 0.006918 -
        0.399912 * math.cos(gamma) +
        0.070257 * math.sin(gamma) -
        0.006758 * math.cos(2 * gamma) +
        0.000907 * math.sin(2 * gamma) -
        0.002697 * math.cos(3 * gamma) +
        0.00148 * math.sin(3 * gamma);

    final latRad = lat * math.pi / 180.0;
    final cosZenithRefracted = math.cos(90.833 * math.pi / 180.0);
    final cosHourAngle =
        (cosZenithRefracted - math.sin(latRad) * math.sin(decl)) /
            (math.cos(latRad) * math.cos(decl));

    final clampedCos = cosHourAngle.clamp(-1.0, 1.0);
    final hourAngle = math.acos(clampedCos);

    final dayLengthMinutes = (hourAngle * 2 / (math.pi / 12.0)) * 60.0;
    final solarNoonUtc8Minutes = 720.0 - (lng * 4.0) - eqtime + (8 * 60.0);

    final sunriseMinutes = solarNoonUtc8Minutes - (dayLengthMinutes / 2.0);
    final sunsetMinutes = solarNoonUtc8Minutes + (dayLengthMinutes / 2.0);

    String formatMin(double m) {
      var rounded = m.round() % (24 * 60);
      if (rounded < 0) rounded += 24 * 60;
      final hh = (rounded ~/ 60).toString().padLeft(2, '0');
      final mm = (rounded % 60).toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    final dlHours = dayLengthMinutes.round() ~/ 60;
    final dlMins = dayLengthMinutes.round() % 60;

    return SolarInfo(
      sunrise: DateTime(date.year, date.month, date.day,
          sunriseMinutes.round() ~/ 60, sunriseMinutes.round() % 60),
      sunset: DateTime(date.year, date.month, date.day,
          sunsetMinutes.round() ~/ 60, sunsetMinutes.round() % 60),
      solarNoon: DateTime(date.year, date.month, date.day,
          solarNoonUtc8Minutes.round() ~/ 60,
          solarNoonUtc8Minutes.round() % 60),
      dayLength: Duration(minutes: dayLengthMinutes.round()),
      sunriseStr: formatMin(sunriseMinutes),
      sunsetStr: formatMin(sunsetMinutes),
      noonStr: formatMin(solarNoonUtc8Minutes),
      dayLengthStr: '${dlHours}h ${dlMins}m',
    );
  }
}

/// 大节天象与日照富豪榜排位定义。
class SessionSolarRank {
  final int sessionIndex;
  final String celestialIcon;
  final String rankTitle;
  final String rankBadge;
  final Color ambientColor;
  final String solarDesc;

  const SessionSolarRank({
    required this.sessionIndex,
    required this.celestialIcon,
    required this.rankTitle,
    required this.rankBadge,
    required this.ambientColor,
    required this.solarDesc,
  });
}

const kSessionSolarRanks = [
  SessionSolarRank(
    sessionIndex: 1,
    celestialIcon: '🌅',
    rankTitle: 'TOP 4 晨晖金榜',
    rankBadge: 'TOP 4',
    ambientColor: Color(0xFFF39C12),
    solarDesc: '晨光初盛 · 日出破晓后第1堂课',
  ),
  SessionSolarRank(
    sessionIndex: 2,
    celestialIcon: '☀️',
    rankTitle: 'TOP 2 纯阳金榜',
    rankBadge: 'TOP 2',
    ambientColor: Color(0xFFE67E22),
    solarDesc: '日照极佳 · 黄金专注光照时段',
  ),
  SessionSolarRank(
    sessionIndex: 3,
    celestialIcon: '🌤️',
    rankTitle: 'TOP 3 盛照金榜',
    rankBadge: 'TOP 3',
    ambientColor: Color(0xFFD35400),
    solarDesc: '温暖斜阳 · 午后光充沛',
  ),
  SessionSolarRank(
    sessionIndex: 4,
    celestialIcon: '🌇',
    rankTitle: 'TOP 5 晚霞金榜',
    rankBadge: 'TOP 5',
    ambientColor: Color(0xFFC0392B),
    solarDesc: '夕照霞光 · 临近日落交替线',
  ),
  SessionSolarRank(
    sessionIndex: 5,
    celestialIcon: '🌙',
    rankTitle: '伴月银榜 榜首',
    rankBadge: '伴月',
    ambientColor: Color(0xFF8E44AD),
    solarDesc: '日落入夜 · 华灯初上暮色',
  ),
  SessionSolarRank(
    sessionIndex: 6,
    celestialIcon: '🌌',
    rankTitle: '星夜银榜 榜首',
    rankBadge: '星夜',
    ambientColor: Color(0xFF2C3E50),
    solarDesc: '深夜静谧 · 沉浸自修',
  ),
];

class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: const _TimetableBody(),
    );
  }
}

class _TimetableBody extends ConsumerStatefulWidget {
  const _TimetableBody();

  @override
  ConsumerState<_TimetableBody> createState() => _TimetableBodyState();
}

class _TimetableBodyState extends ConsumerState<_TimetableBody> {
  late PageController _pageController;

  /// 晚间两节大课折叠开关（整周无晚间大课时默认折叠收拢）
  bool _expandEveningManually = false;

  /// 记录上一次同步的周次，避免频繁 PageController 重复 animate
  int _lastSyncedWeek = 1;

  @override
  void initState() {
    super.initState();
    BankCardShaderService.init();
    final initialWeek = ref.read(weekIndexProvider);
    _lastSyncedWeek = initialWeek;
    _pageController =
        PageController(initialPage: (initialWeek - 1).clamp(0, 30));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 优雅切换教学周，并以流畅弹性曲线驱动 PageView
  void _jumpToWeek(int targetWeek, int totalWeeks) {
    if (targetWeek < 1 || targetWeek > totalWeeks) return;
    HapticFeedback.selectionClick();
    _lastSyncedWeek = targetWeek;
    ref.read(weekIndexProvider.notifier).state = targetWeek;
    if (_pageController.hasClients &&
        _pageController.page?.round() != targetWeek - 1) {
      _pageController.animateToPage(
        targetWeek - 1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).value ?? const AuthState();
    final async = ref.watch(timetableProvider);
    final currentWeek = ref.watch(weekIndexProvider);
    final actualWeek = ref.watch(actualCurrentWeekProvider);
    final data = async.value;
    final selection = ref.watch(semesterSelectionProvider).value;
    final semesterId =
        selection?.currentId ?? SemesterTable.currentSemesterId();
    final isCurrentSemester = (semesterId == SemesterTable.currentSemesterId());
    final semesterLabel = selection?.label ?? '';
    final isViewingCurrentWeek =
        isCurrentSemester && (currentWeek == actualWeek);
    final totalWeeks = data?.totalWeeks ?? 20;

    // 外部修改周次时（如切换学期、点击回本周等），同步 PageView 页面
    if (_pageController.hasClients && _lastSyncedWeek != currentWeek) {
      _lastSyncedWeek = currentWeek;
      final targetPage = (currentWeek - 1).clamp(0, totalWeeks - 1);
      if (_pageController.page?.round() != targetPage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients &&
              _pageController.page?.round() != targetPage) {
            _pageController.animateToPage(
              targetPage,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
            );
          }
        });
      }
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildFloatingTopBar(
            context: context,
            auth: auth,
            semesterLabel: semesterLabel,
            week: currentWeek,
            actualWeek: actualWeek,
            isViewingCurrentWeek: isViewingCurrentWeek,
            isCurrentSemester: isCurrentSemester,
            totalWeeks: totalWeeks,
          ),
          Expanded(
            child: (async.isLoading && data == null)
                ? const Center(child: CupertinoActivityIndicator(radius: 14))
                : (async.hasError && data == null)
                    ? CupertinoErrorCard(
                        message: '${async.error}',
                        onRetry: () =>
                            ref.read(timetableProvider.notifier).refresh(),
                      )
                    : (data == null || data.courses.isEmpty)
                        ? CustomScrollView(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            slivers: [
                              CupertinoSliverRefreshControl(
                                onRefresh: () => ref
                                    .read(timetableProvider.notifier)
                                    .refresh(),
                              ),
                              SliverFillRemaining(
                                child: CupertinoEmpty(
                                  message: context.l10n.noTimetable,
                                  description: context.l10n.pullToRefreshTimetable,
                                  icon: CupertinoIcons.calendar_badge_minus,
                                  actionText: context.l10n.syncTimetableOnline,
                                  onAction: () => ref
                                      .read(timetableProvider.notifier)
                                      .refresh(),
                                ),
                              ),
                            ],
                          )
                        : CustomScrollView(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            slivers: [
                              CupertinoSliverRefreshControl(
                                onRefresh: () => ref
                                    .read(timetableProvider.notifier)
                                    .refresh(),
                              ),
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 8, 10, 32),
                                sliver: SliverToBoxAdapter(
                                  child: _buildBentoTimetable(
                                    context: context,
                                    data: data,
                                    currentWeek: currentWeek,
                                    actualWeek: actualWeek,
                                    semesterId: semesterId,
                                    isCurrentSemester: isCurrentSemester,
                                    semesterLabel: semesterLabel,
                                    totalWeeks: totalWeeks,
                                    pageController: _pageController,
                                    onWeekChanged: (pageIndex) {
                                      final newWeek = pageIndex + 1;
                                      if (newWeek != _lastSyncedWeek) {
                                        _lastSyncedWeek = newWeek;
                                        HapticFeedback.selectionClick();
                                        ref
                                            .read(weekIndexProvider.notifier)
                                            .state = newWeek;
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  /// 顶部悬浮三组件栏：
  /// - 组件1（左侧）：个人中心头像圆钮（跳转 AccountPage）
  /// 顶部悬浮导航与状态栏：
  /// - 左侧：个人中心头像圆钮 + 当前学期微胶囊
  /// - 右侧：非本周时的“回本周”微胶囊 + 周次状态微控制器（‹ 第 N 周 ›）+ 离线标识 + 快捷中枢按钮
  Widget _buildFloatingTopBar({
    required BuildContext context,
    required AuthState auth,
    required String semesterLabel,
    required int week,
    required int actualWeek,
    required bool isViewingCurrentWeek,
    required bool isCurrentSemester,
    required int totalWeeks,
  }) {
    final p = AppThemeScope.of(context);
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      color: p.bg,
      child: Row(
        children: [
          // 左侧：个人中心头像圆钮
          CupertinoScaleButton(
            onTap: () => pushPage(context, const AccountPage()),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: p.card,
                shape: BoxShape.circle,
                border: Border.all(color: p.border, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.person_crop_circle_fill,
                  size: 24,
                  color: p.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 左侧：学期选择微胶囊
          CupertinoScaleButton(
            onTap: () => _pickSemesterAndWeek(context),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.border, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    semesterLabel.isEmpty ? l10n.timetable : semesterLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: p.label,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 9,
                    color: p.secondary,
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // 右侧：非本周时的“回本周”微胶囊
          if (isCurrentSemester && !isViewingCurrentWeek) ...[
            CupertinoScaleButton(
              onTap: () => _jumpToWeek(actualWeek, totalWeeks),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: p.primary.withValues(alpha: 0.28),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_uturn_left,
                      size: 10,
                      color: p.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      l10n.thisWeek(actualWeek),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: p.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 右侧：周次状态控制器（微步进 ‹ 第 N 周 › + 点击展开抽屉）
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 前一周微按钮
                CupertinoScaleButton(
                  onTap: week > 1
                      ? () => _jumpToWeek(week - 1, totalWeeks)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 3, 4),
                    child: Icon(
                      CupertinoIcons.chevron_left,
                      size: 11,
                      color: week > 1 ? p.secondary : p.border.withValues(alpha: 0.4),
                    ),
                  ),
                ),

                // 中间周次状态与微指示点
                CupertinoScaleButton(
                  onTap: () => _pickSemesterAndWeek(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.weekNumber(week),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isViewingCurrentWeek ? p.primary : p.label,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (isViewingCurrentWeek) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: p.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 后一周微按钮
                CupertinoScaleButton(
                  onTap: week < totalWeeks
                      ? () => _jumpToWeek(week + 1, totalWeeks)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(3, 4, 6, 4),
                    child: Icon(
                      CupertinoIcons.chevron_right,
                      size: 11,
                      color: week < totalWeeks
                          ? p.secondary
                          : p.border.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 离线指示标识
          if (auth.offline) ...[
            const SizedBox(width: 6),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: p.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.cloud_fill,
                  size: 13,
                  color: p.warning,
                ),
              ),
            ),
          ],

          const SizedBox(width: 6),

          // 快捷中枢按钮
          CupertinoScaleButton(
            onTap: () => pushPage(context, const HubPage()),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: p.card,
                shape: BoxShape.circle,
                border: Border.all(color: p.border, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.square_grid_2x2_fill,
                  size: 15,
                  color: p.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSemesterAndWeek(BuildContext context) async {
    final selection = ref.read(semesterSelectionProvider).value;
    if (selection == null) return;
    final timetable = ref.read(timetableProvider).value;
    final totalWeeks = timetable?.totalWeeks ?? 20;
    final actualWeek = ref.read(actualCurrentWeekProvider);

    await showCupertinoModalSheet<void>(
      context: context,
      builder: (ctx) {
        final p = AppThemeScope.of(ctx);
        final l10n = ctx.l10n;
        return CupertinoSheetContainer(
          title: l10n.switchSemester,
          subtitle: l10n.selectSemesterOrWeek,
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(48, 32),
            onPressed: selection.fromNetwork
                ? null
                : () async {
                    Navigator.of(ctx).pop();
                    final err = await ref
                        .read(semesterSelectionProvider.notifier)
                        .refreshFromNetwork();
                    if (context.mounted) {
                      toast(
                        context,
                        err ?? l10n.semesterSynced,
                        error: err != null,
                      );
                    }
                  },
            child: Text(
              l10n.sync,
              style: TextStyle(
                color: selection.fromNetwork ? p.tertiary : p.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  l10n.switchSemester,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.secondary,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border, width: 0.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < selection.options.length; i++) ...[
                      if (i > 0) const Sep(indent: 16),
                      Builder(
                        builder: (itemCtx) {
                          final opt = selection.options.reversed.toList()[i];
                          final isCurrent = opt['id'] == selection.currentId;
                          return Tile(
                            title: Text(
                                opt['label'] as String? ?? '${opt['id']}'),
                            trailing: isCurrent
                                ? Icon(
                                    CupertinoIcons.checkmark_alt,
                                    color: p.primary,
                                    size: 18,
                                  )
                                : null,
                            onTap: () {
                              Navigator.of(ctx).pop();
                              final newSemId = opt['id'] as int;
                              ref
                                  .read(semesterSelectionProvider.notifier)
                                  .select(newSemId);
                              final isCurSem = (newSemId ==
                                  SemesterTable.currentSemesterId());
                              final targetWeek = isCurSem ? actualWeek : 1;
                              _jumpToWeek(targetWeek, totalWeeks);
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      l10n.jumpToWeek,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: p.secondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (selection.currentId == SemesterTable.currentSemesterId())
                    Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 8),
                      child: Text(
                        l10n.actualCurrentWeek(actualWeek),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: p.primary,
                        ),
                      ),
                    ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var w = 1; w <= totalWeeks; w++)
                    CupertinoScaleButton(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _jumpToWeek(w, totalWeeks);
                      },
                      child: Container(
                        width: 54,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ref.watch(weekIndexProvider) == w
                              ? p.primary
                              : (selection.currentId ==
                                          SemesterTable.currentSemesterId() &&
                                      w == actualWeek
                                  ? p.primary.withValues(alpha: 0.1)
                                  : p.card),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: ref.watch(weekIndexProvider) == w
                                ? p.primary
                                : (selection.currentId ==
                                            SemesterTable.currentSemesterId() &&
                                        w == actualWeek
                                    ? p.primary
                                    : p.border),
                            width: (selection.currentId ==
                                        SemesterTable.currentSemesterId() &&
                                    w == actualWeek)
                                ? 1.0
                                : 0.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.weekShort(w),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ref.watch(weekIndexProvider) == w
                                    ? CupertinoColors.white
                                    : (selection.currentId ==
                                                SemesterTable
                                                    .currentSemesterId() &&
                                            w == actualWeek
                                        ? p.primary
                                        : p.label),
                              ),
                            ),
                            if (selection.currentId ==
                                    SemesterTable.currentSemesterId() &&
                                w == actualWeek)
                              Text(
                                l10n.thisWeek(w),
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: ref.watch(weekIndexProvider) == w
                                      ? CupertinoColors.white
                                      : p.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  /// 弹出长江大学校区光照与天文节律抽屉（Apple Weather 极简高雅风格）
  Future<void> _showSolarRankSheet({
    required BuildContext context,
    required SolarInfo solar,
    required String semesterLabel,
    required int week,
  }) async {
    await showCupertinoModalSheet<void>(
      context: context,
      builder: (ctx) {
        final p = AppThemeScope.of(ctx);
        return CupertinoSheetContainer(
          title: ctx.l10n.solarAstroRhythm,
          subtitle: ctx.l10n.solarAstroSub,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. 日出、正午、日落核心天文三指标
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.border, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSolarMetric(
                          icon: CupertinoIcons.sunrise_fill,
                          title: ctx.l10n.sunrise,
                          time: solar.sunriseStr,
                          color: const Color(0xFFFFA726),
                          p: p,
                        ),
                        Container(width: 0.5, height: 32, color: p.separator),
                        _buildSolarMetric(
                          icon: CupertinoIcons.sun_max_fill,
                          title: ctx.l10n.solarNoon,
                          time: solar.noonStr,
                          color: const Color(0xFFFF9800),
                          p: p,
                        ),
                        Container(width: 0.5, height: 32, color: p.separator),
                        _buildSolarMetric(
                          icon: CupertinoIcons.sunset_fill,
                          title: ctx.l10n.sunset,
                          time: solar.sunsetStr,
                          color: const Color(0xFFFF7043),
                          p: p,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: p.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ctx.l10n.solarDayLengthBanner(solar.dayLengthStr),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: p.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 2. 作息自然光度分布
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  ctx.l10n.solarLightingDistribution,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.secondary,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.border, width: 0.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildLightScheduleRow(
                      timeLabel: '11:40 - 14:00',
                      sessionTitle: '正午午休时段',
                      lightLevel: '100%',
                      desc: '太阳高度角峰值 · 校园充沛纯净日光',
                      indicatorColor: const Color(0xFFFF9800),
                      p: p,
                    ),
                    const Sep(indent: 16),
                    _buildLightScheduleRow(
                      timeLabel: '10:05 - 11:40',
                      sessionTitle: '上午第 2 节',
                      lightLevel: '92%',
                      desc: '纯阳黄金时段 · 采光清晰专注',
                      indicatorColor: const Color(0xFFFFA726),
                      p: p,
                    ),
                    const Sep(indent: 16),
                    _buildLightScheduleRow(
                      timeLabel: '14:00 - 15:35',
                      sessionTitle: '下午第 3 节',
                      lightLevel: '80%',
                      desc: '午后盛照倾洒 · 温暖充足自然光',
                      indicatorColor: const Color(0xFFFFB300),
                      p: p,
                    ),
                    const Sep(indent: 16),
                    _buildLightScheduleRow(
                      timeLabel: '08:00 - 09:35',
                      sessionTitle: '上午第 1 节',
                      lightLevel: '65%',
                      desc: '晨曦初露金辉 · 日出后第一堂课',
                      indicatorColor: const Color(0xFFFFB74D),
                      p: p,
                    ),
                    const Sep(indent: 16),
                    _buildLightScheduleRow(
                      timeLabel: '15:55 - 17:30',
                      sessionTitle: '下午第 4 节',
                      lightLevel: '45%',
                      desc: '暮霞西斜落日 · 临近日落交替线',
                      indicatorColor: const Color(0xFFFF7043),
                      p: p,
                    ),
                    const Sep(indent: 16),
                    _buildLightScheduleRow(
                      timeLabel: '18:30 - 20:05',
                      sessionTitle: '晚间第 5 节',
                      lightLevel: '夜幕',
                      desc: '暮色降临 · 华灯初上 · 教室护眼照明',
                      indicatorColor: const Color(0xFF3949AB),
                      p: p,
                    ),
                    const Sep(indent: 16),
                    _buildLightScheduleRow(
                      timeLabel: '20:15 - 21:50',
                      sessionTitle: '晚间第 6 节',
                      lightLevel: '星夜',
                      desc: '夜深星河静谧 · 沉浸自修时段',
                      indicatorColor: const Color(0xFF1A237E),
                      p: p,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSolarMetric({
    required IconData icon,
    required String title,
    required String time,
    required Color color,
    required AppPalette p,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: p.label,
            letterSpacing: -0.3,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: p.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildLightScheduleRow({
    required String timeLabel,
    required String sessionTitle,
    required String lightLevel,
    required String desc,
    required Color indicatorColor,
    required AppPalette p,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sessionTitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: p.label,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: p.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: p.secondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            lightLevel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: indicatorColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 核心便当布局网格（大课间划分模式：上午两节、下午两节、晚间两节）
  /// 遵循“固定周和面板，仅翻页内部网格”的设计哲学：
  /// - 外层卡片边框、底色、阴影与左侧大节作息时间标尺 100% 固定不位移
  /// - 内部 7 日网格列包裹于 PageView.builder，仅横向滑动手势驱动周次翻页
  Widget _buildBentoTimetable({
    required BuildContext context,
    required TimetableData data,
    required int currentWeek,
    required int actualWeek,
    required int semesterId,
    required bool isCurrentSemester,
    required String semesterLabel,
    required int totalWeeks,
    required PageController pageController,
    required ValueChanged<int> onWeekChanged,
  }) {
    final p = AppThemeScope.of(context);
    const kTimeRulerWidth = 40.0;

    // 检查学期内是否有晚间排课（若整学期均无晚间排课且未手动展开，则折叠第 5、6 节）
    var hasEveningCoursesInSemester = false;
    for (final c in data.courses) {
      final unit = c['unit'] as int?;
      if (unit == null) continue;
      final sessionIdx = (data.unitCount <= 8) ? unit : (((unit - 1) ~/ 2) + 1);
      if (sessionIdx >= 5) {
        hasEveningCoursesInSemester = true;
        break;
      }
    }
    final shouldCollapseEvening =
        !hasEveningCoursesInSemester && !_expandEveningManually;
    final maxSession = shouldCollapseEvening ? 4 : 6;

    // 精确计算标尺与各日便当列的一致物理总高度
    var dayBodyHeight = 0.0;
    for (var sIdx = 1; sIdx <= maxSession; sIdx++) {
      dayBodyHeight += 88.0; // kSessionCardHeight
      if (sIdx < maxSession &&
          kYangtzeSessions[sIdx - 1].interbreakTitle != null) {
        dayBodyHeight += kYangtzeSessions[sIdx - 1].interbreakHeight;
      }
    }
    // 50.0 = 顶部日期列头高度，8.0 = 上下垂直边距 (vertical: 4)
    final totalGridHeight = 50.0 + 8.0 + dayBodyHeight;

    // 学期真实公历起始周一
    final semesterStartMonday = SemesterTable.startDateFor(semesterId);
    final now = DateTime.now();
    DateTime dateForDay(int w, int d) =>
        semesterStartMonday.add(Duration(days: (w - 1) * 7 + (d - 1)));
    final currentSolar =
        ChinaSolarEngine.calculate(dateForDay(currentWeek, 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 固定外层便当卡片面板（圆角、边框、投影均保持不动，通过分层裁剪与防护边框杜绝圆角被内部突破）
        Container(
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: p.isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0x06000000),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // 内层同心平滑裁剪（15.4px 与外层 16px 边框完全同心，防止子组件手势或排印溢出突破）
              ClipRRect(
                borderRadius: BorderRadius.circular(15.4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 左侧大节时间标尺与极细日照物理光谱渐变光轴（纯固定，不随内部网格横滑）
                    _buildSessionTimeRuler(
                      context: context,
                      maxSession: maxSession,
                      rulerWidth: kTimeRulerWidth,
                      solar: currentSolar,
                      firstDate: dateForDay(currentWeek, 1),
                      onTapSolar: () => _showSolarRankSheet(
                        context: context,
                        solar: currentSolar,
                        semesterLabel: semesterLabel,
                        week: currentWeek,
                      ),
                    ),

                    // 2. 右侧内部 7 日网格（仅在此处由 PageView.builder 驱动横滑翻周）
                    Expanded(
                      child: SizedBox(
                        height: totalGridHeight,
                        child: PageView.builder(
                          controller: pageController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: totalWeeks,
                          onPageChanged: onWeekChanged,
                          itemBuilder: (ctx, pageIndex) {
                            final pageWeek = pageIndex + 1;
                            return _buildWeekDayColumns(
                              context: context,
                              data: data,
                              pageWeek: pageWeek,
                              semesterStartMonday: semesterStartMonday,
                              isCurrentSemester: isCurrentSemester,
                              maxSession: maxSession,
                              now: now,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 顶层不受内部渲染侵蚀的防护边框（对齐 16px 外层圆角，彻底杜绝圆角被内部突破）
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.border, width: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 晚间大课极简折叠提示（整学期无晚间课时出现）
        if (!hasEveningCoursesInSemester)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CupertinoScaleButton(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _expandEveningManually = !_expandEveningManually;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expandEveningManually
                          ? context.l10n.collapseEvening
                          : context.l10n.expandEvening,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: p.tertiary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expandEveningManually
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 10,
                      color: p.tertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 绘制指定周的 7 日便当列（支持根据排课情况自适应压缩留白无课列）
  Widget _buildWeekDayColumns({
    required BuildContext context,
    required TimetableData data,
    required int pageWeek,
    required DateTime semesterStartMonday,
    required bool isCurrentSemester,
    required int maxSession,
    required DateTime now,
  }) {
    const kColGap = 3.0;

    final daySessionMap = <int, Map<int, List<Map<String, Object?>>>>{};
    final dayCourseCounts = <int, int>{for (var d = 1; d <= 7; d++) d: 0};

    for (final c in data.courses) {
      final day = c['day'] as int?;
      final unit = c['unit'] as int?;
      final weeks = c['weeks'];
      final list = weeks is Map ? weeks['list'] as List? : null;
      if (day == null || unit == null || list == null || !list.contains(pageWeek)) {
        continue;
      }

      final sessionIdx = (data.unitCount <= 8)
          ? unit
          : (((unit - 1) ~/ 2) + 1);
      if (sessionIdx < 1 || sessionIdx > 6) continue;

      daySessionMap.putIfAbsent(day, () => {}).putIfAbsent(sessionIdx, () => []);

      final currentList = daySessionMap[day]![sessionIdx]!;
      final alreadyAdded = currentList.any((m) =>
          m['name'] == c['name'] &&
          m['room'] == c['room'] &&
          m['teacher_names'] == c['teacher_names']);
      if (!alreadyAdded) {
        currentList.add(c);
        dayCourseCounts[day] = (dayCourseCounts[day] ?? 0) + 1;
      }
    }

    final hasCourses = <int, bool>{
      for (var d = 1; d <= 7; d++) d: (dayCourseCounts[d] ?? 0) > 0,
    };

    var compressedCount = 0;
    for (var d = 1; d <= 7; d++) {
      if (!hasCourses[d]!) compressedCount++;
    }
    final activeCount = 7 - compressedCount;

    DateTime dateForDay(int d) =>
        semesterStartMonday.add(Duration(days: (pageWeek - 1) * 7 + (d - 1)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var d = 1; d <= 7; d++) ...[
            if (d > 1) const SizedBox(width: kColGap),
            if (!hasCourses[d]! && compressedCount > 0 && activeCount > 0)
              SizedBox(
                width: 18.0,
                child: _buildDayColumn(
                  context: context,
                  day: d,
                  date: dateForDay(d),
                  isToday: isCurrentSemester &&
                      (dateForDay(d).year == now.year &&
                          dateForDay(d).month == now.month &&
                          dateForDay(d).day == now.day),
                  hasCourses: hasCourses[d]!,
                  sessionCourses: daySessionMap[d] ?? const {},
                  maxSession: maxSession,
                  colWidth: 18.0,
                ),
              )
            else
              Expanded(
                child: _buildDayColumn(
                  context: context,
                  day: d,
                  date: dateForDay(d),
                  isToday: isCurrentSemester &&
                      (dateForDay(d).year == now.year &&
                          dateForDay(d).month == now.month &&
                          dateForDay(d).day == now.day),
                  hasCourses: hasCourses[d]!,
                  sessionCourses: daySessionMap[d] ?? const {},
                  maxSession: maxSession,
                  colWidth: double.infinity,
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// 绘制左侧大节作息标尺列（集成 2px 物理光谱连续日照渐变微光轴，无 Emoji 与冗余文字堆砌）
  Widget _buildSessionTimeRuler({
    required BuildContext context,
    required int maxSession,
    required double rulerWidth,
    required SolarInfo solar,
    required DateTime firstDate,
    required VoidCallback onTapSolar,
  }) {
    final p = AppThemeScope.of(context);
    const kSessionCardHeight = 88.0;

    return Container(
      width: rulerWidth,
      decoration: BoxDecoration(
        color: p.card,
        border: Border(right: BorderSide(color: p.separator, width: 0.5)),
      ),
      child: Column(
        children: [
          // 顶部月份（与右侧星期/日期行等高 50px，极简字体排版）
          CupertinoScaleButton(
            onTap: onTapSolar,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15.4),
                ),
                border: Border(
                  bottom: BorderSide(color: p.separator, width: 0.5),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.monthLabel(firstDate.month),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.secondary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB300),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 大节刻度与连续物理光谱渐变光轴
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 纯粹数字与时间刻度
                Expanded(
                  child: Column(
                    children: [
                      for (var sIdx = 1; sIdx <= maxSession; sIdx++) ...[
                        Builder(
                          builder: (_) {
                            final s = kYangtzeSessions[sIdx - 1];
                            return CupertinoScaleButton(
                              onTap: onTapSolar,
                              child: Container(
                                height: kSessionCardHeight,
                                alignment: Alignment.center,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: sIdx == maxSession
                                      ? const BorderRadius.only(
                                          bottomLeft: Radius.circular(15.4),
                                        )
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$sIdx',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: p.label,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      s.startTime,
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w500,
                                        color: p.tertiary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    Text(
                                      s.endTime,
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w400,
                                        color:
                                            p.tertiary.withValues(alpha: 0.65),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // 大课间 / 午休 / 晚餐 时段自然留白（空间自身即是语言）
                        if (sIdx < maxSession &&
                            kYangtzeSessions[sIdx - 1].interbreakTitle != null) ...[
                          SizedBox(
                            height: kYangtzeSessions[sIdx - 1].interbreakHeight,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                // 2. 右边缘贯穿全天的 2px 极细日照光谱色彩渐变微光轴
                Container(
                  width: 2.0,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  height: () {
                    var total = 0.0;
                    for (var i = 1; i <= maxSession; i++) {
                      total += kSessionCardHeight;
                      if (i < maxSession &&
                          kYangtzeSessions[i - 1].interbreakTitle != null) {
                        total += kYangtzeSessions[i - 1].interbreakHeight;
                      }
                    }
                    return total;
                  }(),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFB74D), // 08:00 晨曦微金
                        Color(0xFFFFA726), // 10:05 上午明澈金
                        Color(0xFFFF9800), // 11:40 正午至阳纯金
                        Color(0xFFFFB300), // 14:00 午后麦浪暖光
                        Color(0xFFFF7043), // 15:55 暮霞斜阳
                        Color(0xFFAB47BC), // 17:30~18:30 日落紫霞
                        Color(0xFF3949AB), // 18:30~20:05 入夜暮色
                        Color(0xFF1A237E), // 20:15~21:50 深邃星夜
                      ],
                      stops: [0.0, 0.20, 0.38, 0.55, 0.72, 0.82, 0.92, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 绘制单日便当列（支持压缩无课纯留白列与大节联课合并）
  Widget _buildDayColumn({
    required BuildContext context,
    required int day,
    required DateTime date,
    required bool isToday,
    required bool hasCourses,
    required Map<int, List<Map<String, Object?>>> sessionCourses,
    required int maxSession,
    required double colWidth,
  }) {
    final p = AppThemeScope.of(context);
    const kSessionCardHeight = 88.0;

    // 计算列总高（各 session 高度 + 各大课间休息时段高度）
    double computeTotalDayHeight() {
      var h = 0.0;
      for (var sIdx = 1; sIdx <= maxSession; sIdx++) {
        h += kSessionCardHeight;
        if (sIdx < maxSession &&
            kYangtzeSessions[sIdx - 1].interbreakTitle != null) {
          h += kYangtzeSessions[sIdx - 1].interbreakHeight;
        }
      }
      return h;
    }

    // 1. 列头（星期与日期）
    Widget header;
    if (!hasCourses) {
      // 压缩无课列头部：极度克制、清淡的呼吸列标
      header = Container(
        height: 50,
        width: colWidth,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _shortDayName(context, day),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday
                    ? p.primary
                    : p.tertiary.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                color: isToday
                    ? p.primary
                    : p.tertiary.withValues(alpha: 0.45),
              ),
            ),
            if (isToday) ...[
              const SizedBox(height: 2),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: p.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      );
    } else {
      // 展开有课列头部：层级鲜明
      header = Container(
        height: 50,
        width: colWidth,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
        ),
        child: isToday
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _dayLabel(context, day),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: p.primary,
                      ),
                    ),
                    Text(
                      '${date.month}/${date.day}',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: p.primary,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayLabel(context, day),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: p.label,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: p.tertiary,
                    ),
                  ),
                ],
              ),
      );
    }

    // 2. 列体（无课纯留白 / 有课大节联课卡片）
    Widget body;
    if (!hasCourses) {
      // Less is more: 彻底摒弃灰色背景框与“无排课”多余陈述，纯粹干净的结构留白！
      final totalColHeight = computeTotalDayHeight();
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: colWidth,
          height: totalColHeight,
        ),
      );
    } else {
      // 有课列：大节联课合并网格
      final blocks = _buildMergedSessionBlocks(
        sessionCourses: sessionCourses,
        maxSession: maxSession,
      );

      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (final b in blocks) ...[
              _buildSessionBlockCard(
                context: context,
                block: b,
                colWidth: colWidth,
                baseHeight: kSessionCardHeight,
              ),
              // 如果本块结束后有大课间/午休休息，且未合并，则补齐休息间隔
              if (b.endSession < maxSession &&
                  kYangtzeSessions[b.endSession - 1].interbreakTitle != null)
                SizedBox(
                  height: kYangtzeSessions[b.endSession - 1].interbreakHeight,
                ),
            ],
          ],
        ),
      );
    }

    return Container(
      width: colWidth,
      decoration: BoxDecoration(
        color: (isToday && hasCourses)
            ? p.primary.withValues(alpha: 0.02)
            : null,
      ),
      child: Column(
        children: [
          header,
          body,
        ],
      ),
    );
  }

  /// 大节联课合并算法：连续大节（如同上午第1、2节连续实验）合并为单个高跨度大便当卡片
  List<MergedSessionBlock> _buildMergedSessionBlocks({
    required Map<int, List<Map<String, Object?>>> sessionCourses,
    required int maxSession,
  }) {
    final blocks = <MergedSessionBlock>[];
    var s = 1;

    while (s <= maxSession) {
      final curList = sessionCourses[s];
      if (curList == null || curList.isEmpty) {
        // 空白大节
        blocks.add(MergedSessionBlock(
          startSession: s,
          endSession: s,
          items: const [],
        ));
        s++;
        continue;
      }

      final primary = curList.first;
      final name = (primary['name'] as String?) ?? '';
      final room = (primary['room'] as String?) ?? '';
      final teachers = (primary['teacher_names'] as String?) ?? '';

      // 探查是否与下一大节为同一门课程（在上午 1->2、下午 3->4 或晚间 5->6 内合并，不跨午休/晚饭自然时段）
      var endS = s;
      if (s == 1 && maxSession >= 2) {
        final nextList = sessionCourses[2];
        if (nextList != null && nextList.isNotEmpty) {
          final nextPrimary = nextList.first;
          if (name == (nextPrimary['name'] as String?) &&
              room == (nextPrimary['room'] as String?) &&
              teachers == (nextPrimary['teacher_names'] as String?)) {
            endS = 2;
          }
        }
      } else if (s == 3 && maxSession >= 4) {
        final nextList = sessionCourses[4];
        if (nextList != null && nextList.isNotEmpty) {
          final nextPrimary = nextList.first;
          if (name == (nextPrimary['name'] as String?) &&
              room == (nextPrimary['room'] as String?) &&
              teachers == (nextPrimary['teacher_names'] as String?)) {
            endS = 4;
          }
        }
      } else if (s == 5 && maxSession >= 6) {
        final nextList = sessionCourses[6];
        if (nextList != null && nextList.isNotEmpty) {
          final nextPrimary = nextList.first;
          if (name == (nextPrimary['name'] as String?) &&
              room == (nextPrimary['room'] as String?) &&
              teachers == (nextPrimary['teacher_names'] as String?)) {
            endS = 6;
          }
        }
      }

      final mergedItems = <Map<String, Object?>>[];
      for (var i = s; i <= endS; i++) {
        final list = sessionCourses[i];
        if (list != null) {
          for (final item in list) {
            if (!mergedItems.any((m) =>
                m['name'] == item['name'] &&
                m['room'] == item['room'] &&
                m['teacher_names'] == item['teacher_names'])) {
              mergedItems.add(item);
            }
          }
        }
      }
      if (mergedItems.isEmpty) mergedItems.addAll(curList);

      blocks.add(MergedSessionBlock(
        startSession: s,
        endSession: endS,
        items: mergedItems,
      ));

      s = endS + 1;
    }

    return blocks;
  }

  /// 绘制单个大节课程卡片（采用片段着色器体积卡片、连课虚线分割、双套排版与重叠多卡物理层叠）
  Widget _buildSessionBlockCard({
    required BuildContext context,
    required MergedSessionBlock block,
    required double colWidth,
    required double baseHeight,
  }) {
    final p = AppThemeScope.of(context);

    // 计算卡片高度：跨多大节时需包含中间的大课间高度
    var cardHeight = block.span * baseHeight;
    for (var i = block.startSession; i < block.endSession; i++) {
      cardHeight += kYangtzeSessions[i - 1].interbreakHeight;
    }

    if (block.isEmpty) {
      return SizedBox(
        width: colWidth,
        height: cardHeight,
      );
    }

    final token = p.courseTokenFor(block.name.hashCode);
    final hasConflict = block.items.length > 1;
    final secondaryToken = hasConflict
        ? p.courseTokenFor((block.items[1]['name'] ?? '').hashCode)
        : token;

    final item1 = block.items[0];
    final item2 = hasConflict ? block.items[1] : null;
    final name1 = (item1['name'] as String?) ?? '';
    final name2 = item2 != null ? ((item2['name'] as String?) ?? '') : '';
    final room1 = (item1['room'] as String?) ?? '';
    final room2 = item2 != null ? ((item2['room'] as String?) ?? '') : '';
    final token1 = p.courseTokenFor(name1.hashCode);
    final token2 = hasConflict ? p.courseTokenFor(name2.hashCode) : token1;

    // 计算连课分割虚线的 Y 轴物理坐标（位于各大节交界正中）
    final dashedYs = <double>[];
    if (block.span > 1) {
      var yAcc = 0.0;
      for (var s = block.startSession; s < block.endSession; s++) {
        yAcc += baseHeight;
        final breakH = kYangtzeSessions[s - 1].interbreakHeight;
        dashedYs.add(yAcc + (breakH / 2.0));
        yAcc += breakH;
      }
    }

    // 研判是否采用日文竖排设计（竖直长方形卡片：span >= 2 或高宽比显著大于 1.55）
    final isTallVertical =
        block.span >= 2 || (colWidth > 0 && cardHeight / colWidth >= 1.55);

    // 卡片内纯内容组件
    Widget cardContent;
    if (hasConflict) {
      // ===== 重叠课程卡片设计优化（同时展示两门课程名称与核心信息） =====
      if (isTallVertical) {
        // 竖直长方形：日文竖排双列并排（两门课程均呈现）
        cardContent = Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 4, 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 顶部：重叠课程标识微胶囊
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1),
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: token.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.layers_fill,
                      size: 7.0,
                      color: token.accent,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${block.items.length}门重叠',
                      style: TextStyle(
                        fontSize: 7.0,
                        fontWeight: FontWeight.w700,
                        color: token.accent,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // 双门课程纵向并排
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    // 课程 1（右侧首位）
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TategakiText(
                              text: name1,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: token1.text,
                                height: 1.12,
                              ),
                              maxCharsPerColumn: block.span >= 3 ? 7 : 5,
                              maxColumns: 1,
                              columnSpacing: 1.0,
                            ),
                          ),
                          if (room1.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.location_solid,
                                  size: 6.0,
                                  color: token1.accent,
                                ),
                                const SizedBox(width: 1),
                                Flexible(
                                  child: Text(
                                    room1,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 6.5,
                                      fontWeight: FontWeight.w600,
                                      color: token1.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // 中间微弱纵向分割线
                    Container(
                      width: 0.5,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 1.5, vertical: 4),
                      color: token.accent.withValues(alpha: 0.25),
                    ),

                    // 课程 2（左侧次位）
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TategakiText(
                              text: name2,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: token2.text,
                                height: 1.12,
                              ),
                              maxCharsPerColumn: block.span >= 3 ? 7 : 5,
                              maxColumns: 1,
                              columnSpacing: 1.0,
                            ),
                          ),
                          if (room2.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.location_solid,
                                  size: 6.0,
                                  color: token2.accent,
                                ),
                                const SizedBox(width: 1),
                                Flexible(
                                  child: Text(
                                    room2,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 6.5,
                                      fontWeight: FontWeight.w600,
                                      color: token2.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 2),
              // 底部大节标注
              Center(
                child: Text(
                  block.sessionLabel,
                  style: TextStyle(
                    fontSize: 7.0,
                    fontWeight: FontWeight.w600,
                    color: token.accent,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // 常规横排：紧凑分栏双课呈现
        cardContent = Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 课程 1
              Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: token1.accent,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      name1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: token1.text,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
              if (room1.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 6.5, top: 1.0),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 7.0,
                        color: token1.accent,
                      ),
                      const SizedBox(width: 1.5),
                      Expanded(
                        child: Text(
                          room1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                            color: token1.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 内部横向分割线
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Container(
                  height: 0.5,
                  color: token.accent.withValues(alpha: 0.2),
                ),
              ),

              // 课程 2
              Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: token2.accent,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      name2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: token2.text,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
              if (room2.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 6.5, top: 1.0),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 7.0,
                        color: token2.accent,
                      ),
                      const SizedBox(width: 1.5),
                      Expanded(
                        child: Text(
                          room2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                            color: token2.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      }
    } else if (isTallVertical) {
      // 1. 竖直长方形：日文排版设计（縦書き · 文字由右至左竖排推进，进一步缩小字号提升信息密度与可读性）
      cardContent = Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 4, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部/右上区：日文排版风格的从右至左垂直课程名称
            Expanded(
              child: Align(
                alignment: Alignment.topRight,
                child: TategakiText(
                  text: block.name,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: token.text,
                    height: 1.15,
                    letterSpacing: 0.5,
                  ),
                  maxCharsPerColumn: block.span >= 3 ? 8 : 6,
                  maxColumns: 3,
                  columnSpacing: 2.0,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // 下部：紧凑微排印辅助信息（节次微标签、教室、教师）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              margin: const EdgeInsets.only(bottom: 2.5),
              decoration: BoxDecoration(
                color: token.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                block.sessionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  color: token.accent,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            // 教室地点微胶囊
            if (block.room.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: token.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.location_solid,
                      size: 7.5,
                      color: token.accent,
                    ),
                    const SizedBox(width: 1.5),
                    Expanded(
                      child: Text(
                        block.room,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8.0,
                          fontWeight: FontWeight.w600,
                          color: token.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
            ],

            // 教师信息微排版
            if (block.teachers.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    CupertinoIcons.person_fill,
                    size: 7.0,
                    color: token.text.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 1.5),
                  Expanded(
                    child: Text(
                      block.teachers,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w500,
                        color: token.text.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    } else {
      // 2. 常规横排排版（单大节偏方型：高密度横排与微胶囊）
      cardContent = Padding(
        padding: const EdgeInsets.fromLTRB(6, 5, 4, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 课程名称
            Expanded(
              child: Text(
                block.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: token.text,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 2),

            // 教室地点（带微胶囊）
            if (block.room.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: token.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.location_solid,
                      size: 8.0,
                      color: token.accent,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        block.room,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: token.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 教师信息与连课时段
            if (block.teachers.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.person_fill,
                    size: 7.5,
                    color: token.text.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      block.teachers,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.0,
                        fontWeight: FontWeight.w500,
                        color: token.text.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (block.span > 1) ...[
              const SizedBox(height: 2),
              Text(
                block.timeRange,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w500,
                  color: token.text.withValues(alpha: 0.65),
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget mainCard = BankCardSurface(
      baseColor: token.bg,
      accentColor: token.accent,
      isDark: p.isDark,
      seed: (block.name.hashCode.abs() % 1000).toDouble() / 100.0,
      borderRadius: 10.0,
      dashedSeparatorYs: dashedYs,
      margin: const EdgeInsets.symmetric(vertical: 1.0),
      child: Stack(
        children: [
          cardContent,

          // 冲突多卡层叠角标
          if (hasConflict)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [token.accent, secondaryToken.accent],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: token.accent.withValues(alpha: 0.35),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.layers_fill,
                      size: 6.5,
                      color: CupertinoColors.white,
                    ),
                    const SizedBox(width: 1.5),
                    Text(
                      '${block.items.length}',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    // 实体卡片物理双层叠卡露边视觉效果（Stacked Physical Bank Cards）
    Widget finalCard = mainCard;
    if (hasConflict) {
      finalCard = Stack(
        clipBehavior: Clip.none,
        children: [
          // 后层卡片露角（向右上方微偏移 2.0px，显现第二门课程的物理卡片底色）
          Positioned(
            top: -1.5,
            right: -1.5,
            left: 3.5,
            bottom: 3.0,
            child: Container(
              decoration: BoxDecoration(
                color: secondaryToken.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: secondaryToken.accent.withValues(alpha: 0.35),
                  width: 0.6,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 3,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
          mainCard,
        ],
      );
    }

    return CupertinoScaleButton(
      onTap: () {
        HapticFeedback.lightImpact();
        _showCourseDetail(context, block.name, block.items, block);
      },
      child: SizedBox(
        width: colWidth,
        height: math.max(0.0, cardHeight - 2.0),
        child: finalCard,
      ),
    );
  }

  /// 呼出课程详情抽屉
  void _showCourseDetail(
    BuildContext context,
    String name,
    List<Map<String, Object?>> items,
    MergedSessionBlock block,
  ) {
    showCupertinoModalSheet<void>(
      context: context,
      builder: (ctx) {
        final p = AppThemeScope.of(ctx);
        final l10n = ctx.l10n;
        final hasConflict = items.length > 1;

        return CupertinoSheetContainer(
          title: hasConflict
              ? '${block.sessionLabel} · 重叠课程 (${items.length}门)'
              : (name.isEmpty ? l10n.courseDetail : name),
          subtitle: hasConflict
              ? l10n.lessonsOverlapping(items.length, block.timeRange)
              : '${l10n.appName} · ${block.sessionLabel} · ${block.timeRange}',
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (subCtx, index) => _CourseDetailCard(
              item: items[index],
              index: index,
              totalCount: items.length,
              block: block,
              p: p,
              l10n: l10n,
            ),
          ),
        );
      },
    );
  }
}

/// 课程卡片详情面板（含长江大学精确作息时间、独立课程名称标题、教室一键复制与专属色彩全学期矩阵）
class _CourseDetailCard extends StatelessWidget {
  const _CourseDetailCard({
    required this.item,
    required this.index,
    required this.totalCount,
    required this.block,
    required this.p,
    required this.l10n,
  });

  final Map<String, Object?> item;
  final int index;
  final int totalCount;
  final MergedSessionBlock block;
  final AppPalette p;
  final AppStrings l10n;

  @override
  Widget build(BuildContext context) {
    final courseName = (item['name'] as String?)?.trim() ?? '';
    final teachers = (item['teacher_names'] as String?)?.trim() ?? '';
    final room = (item['room'] as String?)?.trim() ?? '';
    final dayName = (item['day_name'] as String?)?.trim() ?? '';
    final courseCode = (item['course_code'] as String?)?.trim() ?? '';
    final clazz = (item['clazz'] as String?)?.trim() ?? '';
    final assistant = (item['assistant'] as String?)?.trim() ?? '';
    final weeks = item['weeks'];
    final weeksDigest = weeks is Map ? (weeks['digest']?.toString()) : null;
    final activeList = weeks is Map ? (weeks['list'] as List?) : null;
    final activeSet =
        activeList != null ? activeList.cast<int>().toSet() : <int>{};

    final token = p.courseTokenFor(courseName.hashCode);

    return CupertinoCard(
      padding: const EdgeInsets.all(16),
      border: totalCount > 1
          ? Border.all(
              color: token.accent.withValues(alpha: 0.28),
              width: 1.0,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 课程序号与节次徽章行
          Row(
            children: [
              if (totalCount > 1) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: token.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: token.accent.withValues(alpha: 0.35),
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.layers_fill,
                        size: 11,
                        color: token.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '课程 ${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: token.accent,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              CupertinoPillBadge(
                text:
                    '$dayName ${block.sessionLabel} (${block.timeRange})',
                icon: CupertinoIcons.clock_fill,
              ),
              if (weeksDigest != null) ...[
                const SizedBox(width: 8),
                CupertinoPillBadge(
                  text: '$weeksDigest${l10n.weekSuffix}',
                  color: token.accent.withValues(alpha: 0.12),
                  textColor: token.accent,
                ),
              ],
              const Spacer(),
              if (courseCode.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    courseCode,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: p.tertiary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // 课程名称主标题（每门课程均显示完整名称，带左侧色柱标示）
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3.5,
                height: 19,
                margin: const EdgeInsets.only(top: 2, right: 8),
                decoration: BoxDecoration(
                  color: token.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Text(
                  courseName.isEmpty ? l10n.courseDetail : courseName,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: p.label,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 教室与一键复制
          if (room.isNotEmpty)
            _MetaRow(
              icon: CupertinoIcons.location_solid,
              title: l10n.room.replaceFirst('%1', room),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 24),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Clipboard.setData(ClipboardData(text: room));
                  toast(context, l10n.roomCopied);
                },
                child: Text(
                  l10n.copy,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: token.accent,
                  ),
                ),
              ),
              p: p,
            ),

          // 授课教师
          if (teachers.isNotEmpty) ...[
            const SizedBox(height: 10),
            _MetaRow(
              icon: CupertinoIcons.person_fill,
              title: l10n.teacher.replaceFirst('%1', teachers),
              p: p,
            ),
          ],

          // 助教
          if (assistant.isNotEmpty) ...[
            const SizedBox(height: 10),
            _MetaRow(
              icon: CupertinoIcons.person_badge_plus_fill,
              title: '助教：$assistant',
              p: p,
            ),
          ],

          // 教学班级
          if (clazz.isNotEmpty) ...[
            const SizedBox(height: 10),
            _MetaRow(
              icon: CupertinoIcons.person_2_fill,
              title: l10n.clazz.replaceFirst('%1', clazz),
              p: p,
            ),
          ],

          const SizedBox(height: 16),
          const Sep(),
          const SizedBox(height: 14),

          // 全学期周次分布矩阵（活跃周使用该门课的专属强调色 token.accent）
          Row(
            children: [
              Text(
                l10n.fullTermWeekDistribution,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.secondary,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Text(
                l10n.darkColorIsActiveWeek,
                style: TextStyle(
                  fontSize: 11,
                  color: p.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var w = 1; w <= 20; w++)
                Container(
                  width: 28,
                  height: 26,
                  decoration: BoxDecoration(
                    color: activeSet.contains(w)
                        ? token.accent
                        : p.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: activeSet.contains(w)
                          ? token.accent
                          : p.border.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$w',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: activeSet.contains(w)
                          ? CupertinoColors.white
                          : p.secondary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.title,
    this.trailing,
    required this.p,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: p.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: p.label,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
