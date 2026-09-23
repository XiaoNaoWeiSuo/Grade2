// SemesterTable 单元测试：常量表与公式推算（映射来自 2026-09 全量抓包）。
import 'package:flutter_test/flutter_test.dart';
import 'package:grade2/core/crawler/models/semester_table.dart';

void main() {
  group('SemesterTable.byId（常量表）', () {
    test('锚点：409 = 2026-2027 第 1 学期', () {
      final e = SemesterTable.byId(409)!;
      expect(e.$2, '2026-2027');
      expect(e.$3, '1');
    });

    test('用户记忆的步进序列 349/369/389', () {
      expect(SemesterTable.byId(349)!.$2, '2024-2025');
      expect(SemesterTable.byId(349)!.$3, '2');
      expect(SemesterTable.byId(369)!.$2, '2025-2026');
      expect(SemesterTable.byId(369)!.$3, '1');
      expect(SemesterTable.byId(389)!.$2, '2025-2026');
      expect(SemesterTable.byId(389)!.$3, '2');
    });

    test('历史不规则段（46→48 跳 2、109→169 跳 60）', () {
      expect(SemesterTable.byId(46)!.$2, '2017-2018');
      expect(SemesterTable.byId(48)!.$3, '2');
      expect(SemesterTable.byId(109)!.$2, '2019-2020');
      expect(SemesterTable.byId(169)!.$2, '2020-2021');
    });

    test('表外且不在 +20 网格 → null', () {
      expect(SemesterTable.byId(47), isNull);
      expect(SemesterTable.byId(410), isNull);
    });

    test('未来学期公式外推（+20/学期）', () {
      // 409 之后：429 = 2026-2027-2, 449 = 2027-2028-1
      expect(SemesterTable.byId(429)!.$2, '2026-2027');
      expect(SemesterTable.byId(429)!.$3, '2');
      expect(SemesterTable.byId(449)!.$2, '2027-2028');
      expect(SemesterTable.byId(449)!.$3, '1');
    });
  });

  group('SemesterTable.currentSemesterId（按日期推算）', () {
    test('9-12 月 → 该学年第 1 学期', () {
      expect(SemesterTable.currentSemesterId(DateTime(2026, 9, 10)), 409);
      expect(SemesterTable.currentSemesterId(DateTime(2026, 12, 31)), 409);
      expect(SemesterTable.currentSemesterId(DateTime(2025, 10, 1)), 369);
    });

    test('1 月 → 上一学年第 1 学期（考试周）', () {
      expect(SemesterTable.currentSemesterId(DateTime(2026, 1, 15)), 389 - 20);
      // 2026-01 属于 2025-2026-1 = 369
      expect(SemesterTable.currentSemesterId(DateTime(2026, 1, 15)), 369);
    });

    test('2-7 月 → 上一学年第 2 学期', () {
      expect(SemesterTable.currentSemesterId(DateTime(2026, 3, 15)), 389);
      expect(SemesterTable.currentSemesterId(DateTime(2026, 7, 1)), 389);
      expect(SemesterTable.currentSemesterId(DateTime(2025, 5, 20)), 349);
    });

    test('常量表与推算公式交叉一致（189 起的 +20 网格段）', () {
      for (final e in kSemesterEntries) {
        if (e.$1 < 189) continue;
        final year = int.parse(e.$2.split('-').first);
        final term = int.parse(e.$3);
        expect(SemesterTable.idFor(year, term), e.$1,
            reason: '$e 公式推算不一致');
      }
    });

    test('labelFor 文案', () {
      expect(SemesterTable.labelFor(409), '2026-2027学年 1学期');
      expect(SemesterTable.labelFor(349), '2024-2025学年 2学期');
      expect(SemesterTable.labelFor(410), '学期 410'); // 非法 id 兜底
    });

    test('startDateFor 与 calculateCurrentWeek（秋季学期9.1第一周推算）', () {
      // 409 = 2026-2027 第 1 学期
      final start409 = SemesterTable.startDateFor(409);
      expect(start409.weekday, DateTime.monday);
      // 2026-09-01 是周二，所在周一为 2026-08-31
      expect(start409, DateTime(2026, 8, 31));

      // 9月1日应属于第 1 周
      expect(SemesterTable.calculateCurrentWeek(409, DateTime(2026, 9, 1)), 1);
      // 开学前兜底为第 1 周
      expect(SemesterTable.calculateCurrentWeek(409, DateTime(2026, 8, 20)), 1);
      // 第二周周一 2026-09-07
      expect(SemesterTable.calculateCurrentWeek(409, DateTime(2026, 9, 7)), 2);
      // 2026-09-23 为第 4 周
      expect(SemesterTable.calculateCurrentWeek(409, DateTime(2026, 9, 23)), 4);
    });

    test('allAsMaps 与 API 输出同形', () {
      final all = SemesterTable.allAsMaps();
      expect(all.length, 63);
      expect(all.first, {
        'id': 2,
        'schoolYear': '1995-1996',
        'name': '1',
        'label': '1995-1996学年 1学期',
      });
    });
  });
}
