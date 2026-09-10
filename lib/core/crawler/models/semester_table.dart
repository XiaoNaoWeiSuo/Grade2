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

  /// 按日期推算"当前"学期 id（本地计算，零网络）。
  ///
  /// 校历规则：9-12 月与 1 月 = 第 1 学期（1 月为考试周），
  /// 2-7 月 = 第 2 学期。学校若调整校历，以网络 [EamsApi.semesters]
  /// 的权威结果为准（ViewModel 落盘后覆盖本地推算）。
  static int currentSemesterId([DateTime? now]) {
    final t = now ?? DateTime.now();
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

  /// 学期展示文案（如 '2026-2027学年 1学期'）。
  static String labelFor(int id) {
    final e = byId(id);
    if (e == null) return '学期 $id';
    return '${e.$2}学年 ${e.$3}学期';
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
