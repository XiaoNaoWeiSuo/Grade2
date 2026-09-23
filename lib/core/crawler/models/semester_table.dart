/// 学期编号本地常量表（模型层，零依赖纯常量）。
///
/// ## 依据（2026-09 实测，63 个学期全量抓包）
/// - 学期 id 是校方固定编号：189(2020-2021-2) 起严格 **+20/学期**，
///   锚点 `409 = 2026-2027 学年第 1 学期`（2026-09-10 在线验证）。
/// - 更早的学期步进不规则（1/2/20/60 混合），用全量常量表覆盖。
///
/// ## 用途
/// - `currentSemesterId()` 按日期本地推算当前学期，**零网络请求**
///   （此前每次冷启动都要 semesters() 三连请求：预热+projectId+semesterCalendar）
/// - `labelFor/byId/allAsMaps` 供 UI 离线渲染学期选择
/// - 网络接口 [EamsApi.semesters] 仍是权威源：成功后由 ViewModel 写入
///   LocalCache（meta/current_semester），优先级高于本地推算
library;

/// 学期条目：(id, schoolYear 如 '2026-2027', name '1'|'2')。
typedef SemesterEntry = (int, String, String);

/// 全量学期表（抓包快照；服务端新增学期后由公式自动外推）。
const List<SemesterEntry> kSemesterEntries = [
  (2, '1995-1996', '1'), (3, '1995-1996', '2'),
  (4, '1996-1997', '1'), (5, '1996-1997', '2'),
  (6, '1997-1998', '1'), (7, '1997-1998', '2'),
  (8, '1998-1999', '1'), (9, '1998-1999', '2'),
  (10, '1999-2000', '1'), (11, '1999-2000', '2'),
  (12, '2000-2001', '1'), (13, '2000-2001', '2'),
  (14, '2001-2002', '1'), (15, '2001-2002', '2'),
  (16, '2002-2003', '1'), (17, '2002-2003', '2'),
  (18, '2003-2004', '1'), (19, '2003-2004', '2'),
  (20, '2004-2005', '1'), (21, '2004-2005', '2'),
  (22, '2005-2006', '1'), (23, '2005-2006', '2'),
  (24, '2006-2007', '1'), (25, '2006-2007', '2'),
  (26, '2007-2008', '1'), (27, '2007-2008', '2'),
  (28, '2008-2009', '1'), (29, '2008-2009', '2'),
  (30, '2009-2010', '1'), (31, '2009-2010', '2'),
  (32, '2010-2011', '1'), (33, '2010-2011', '2'),
  (34, '2011-2012', '1'), (35, '2011-2012', '2'),
  (36, '2012-2013', '1'), (37, '2012-2013', '2'),
  (38, '2013-2014', '1'), (39, '2013-2014', '2'),
  (40, '2014-2015', '1'), (41, '2014-2015', '2'),
  (42, '2015-2016', '1'), (43, '2015-2016', '2'),
  (44, '2016-2017', '1'), (45, '2016-2017', '2'),
  (46, '2017-2018', '1'), (48, '2017-2018', '2'),
  (49, '2018-2019', '1'), (69, '2018-2019', '2'),
  (89, '2019-2020', '1'), (109, '2019-2020', '2'),
  (169, '2020-2021', '1'), (189, '2020-2021', '2'),
  (209, '2021-2022', '1'), (229, '2021-2022', '2'),
  (249, '2022-2023', '1'), (269, '2022-2023', '2'),
  (289, '2023-2024', '1'), (309, '2023-2024', '2'),
  (329, '2024-2025', '1'), (349, '2024-2025', '2'),
  (369, '2025-2026', '1'), (389, '2025-2026', '2'),
  (409, '2026-2027', '1'),
];

/// 学期 id 本地推算工具。
abstract final class SemesterTable {
  /// 公式锚点：409 = 2026-2027 学年第 1 学期。
  static const int anchorId = 409;
  static const int anchorYear = 2026;
  static const int step = 20; // 每学期步进（2020-2021-2 起实测稳定）

  static final Map<int, SemesterEntry> _byId = {
    for (final e in kSemesterEntries) e.$1: e,
  };

  /// 锚点学期 id（可随公式外推到未来学期）。
  static int idFor(int academicStartYear, int term) =>
      anchorId + step * ((academicStartYear - anchorYear) * 2 + (term - 1));

  /// 默认当前学期（教务系统抓包与在册排课权威锚点：369 = 2025-2026 学年第 1 学期）。
  static const int defaultSemesterId = 369;

  /// 按日期推算"当前"学期 id（本地计算，零网络）。
  /// 若未传 now，默认返回当前在线权威学期 [defaultSemesterId] (369)。
  static int currentSemesterId([DateTime? now]) {
    if (now == null) return defaultSemesterId;
    final t = now;
    final int term;
    final int academicStartYear;
    if (t.month >= 8) {
      term = 1;
      academicStartYear = t.year;
    } else if (t.month == 1) {
      term = 1;
      academicStartYear = t.year - 1;
    } else {
      term = 2;
      academicStartYear = t.year - 1;
    }
    return idFor(academicStartYear, term);
  }

  /// 按学期 id 取条目；常量表未收录时按公式外推（+20 网格内可靠）。
  static SemesterEntry? byId(int id) {
    final hit = _byId[id];
    if (hit != null) return hit;
    final k = (id - anchorId) ~/ step;
    if ((id - anchorId) % step != 0) return null; // 不在 +20 网格
    final term = k.isEven ? 1 : 2;
    final year = anchorYear + (k - (term - 1)) ~/ 2;
    return (id, '$year-${year + 1}', '$term');
  }

  /// 学期展示文案（如 '2025-2026学年 1学期'）。
  static String labelFor(int id) {
    final e = byId(id);
    if (e == null) return '学期 $id';
    return '${e.$2}学年 ${e.$3}学期';
  }

  /// 学期开学日期（以开学第 1 周周一为基准）。
  ///
  /// - 秋季学期（第 1 学期）：以 9 月 1 日所在周的周一为第 1 周起始（9.1 为第一周）。
  /// - 春季学期（第 2 学期）：次年春季 2 月下旬（约 2 月 20 日前后周一）开学。
  /// - 查询当前权威学期时，对齐当前自然日历学年（如 2026 年秋对应 2026-08-31 起始）。
  static DateTime startDateFor(int semesterId, [DateTime? now]) {
    final e = byId(semesterId);
    final int startYear;
    final int term;
    if (e != null) {
      term = int.tryParse(e.$3) ?? 1;
      if (semesterId == defaultSemesterId) {
        final ref = now ?? DateTime.now();
        startYear = (ref.month >= 8 || ref.month == 1)
            ? (ref.month == 1 ? ref.year - 1 : ref.year)
            : ref.year - 1;
      } else {
        startYear = int.tryParse(e.$2.split('-').first) ?? anchorYear;
      }
    } else {
      startYear = anchorYear;
      term = 1;
    }
    if (term == 1) {
      final sep1 = DateTime(startYear, 9, 1);
      return DateTime(sep1.year, sep1.month, sep1.day)
          .subtract(Duration(days: sep1.weekday - 1));
    } else {
      final feb20 = DateTime(startYear + 1, 2, 20);
      final offset = (feb20.weekday == 1) ? 0 : (8 - feb20.weekday);
      final firstMonday = feb20.add(Duration(days: offset));
      return DateTime(firstMonday.year, firstMonday.month, firstMonday.day);
    }
  }

  /// 计算指定日期在当前学期所处的真实周次（从 1 开始）。
  ///
  /// 开学前返回 1；超过 [maxWeeks] 则限制至 [maxWeeks]。
  static int calculateCurrentWeek(int semesterId,
      [DateTime? now, int maxWeeks = 25]) {
    final t = now ?? DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    final start = startDateFor(semesterId, now);
    if (today.isBefore(start)) {
      return 1;
    }
    final diffDays = today.difference(start).inDays;
    final week = (diffDays ~/ 7) + 1;
    if (week > maxWeeks) return maxWeeks;
    return week < 1 ? 1 : week;
  }

  /// 与 [EamsApi.semesters] 输出同形的全量表（离线渲染用）。
  static List<Map<String, Object?>> allAsMaps() => [
        for (final e in kSemesterEntries)
          {
            'id': e.$1,
            'schoolYear': e.$2,
            'name': e.$3,
            'label': '${e.$2}学年 ${e.$3}学期',
          }
      ];
}
