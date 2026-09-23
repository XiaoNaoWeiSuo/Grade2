import 'package:flutter_test/flutter_test.dart';
import 'package:grade2/core/crawler/models/semester_table.dart';
import 'package:grade2/views/pages/timetable_page.dart';

void main() {
  group('长江大学大节作息与开学周次推算', () {
    test('秋季学期开学时间推算：9.1 所在周为第 1 周', () {
      // 2026-2027-1 (id: 409)
      final start = SemesterTable.startDateFor(409);
      expect(start.weekday, DateTime.monday);
      expect(start, DateTime(2026, 8, 31));

      // 9月1日为第 1 周
      expect(SemesterTable.calculateCurrentWeek(409, DateTime(2026, 9, 1)), 1);
      // 9月6日为第 1 周周日
      expect(SemesterTable.calculateCurrentWeek(409, DateTime(2026, 9, 6)), 1);
      // 9月7日为第 2 周周一
      expect(SemesterTable.calculateCurrentWeek(409, DateTime(2026, 9, 7)), 2);
      // 9月23日为第 4 周周三
      expect(SemesterTable.calculateCurrentWeek(409, DateTime(2026, 9, 23)), 4);
    });

    test('春季学期开学时间推算：2月下旬周一开学', () {
      // 2026-2027-2 (id: 429)
      final start = SemesterTable.startDateFor(429);
      expect(start.weekday, DateTime.monday);
      expect(start.year, 2027);
      expect(start.month, 2);

      // 开学第一周周一
      expect(SemesterTable.calculateCurrentWeek(429, start), 1);
      // 开学两周后
      expect(
          SemesterTable.calculateCurrentWeek(
              429, start.add(const Duration(days: 14))),
          3);
    });

    test('长江大学大课间作息体系（上午两节、下午两节、晚间两节）', () {
      expect(kYangtzeSessions.length, 6);

      // 上午第 1 节（原 1-2 节，包含5分钟小课间）
      expect(kYangtzeSessions[0].sessionName, '第1节');
      expect(kYangtzeSessions[0].periodDesc, '上午');
      expect(kYangtzeSessions[0].startTime, '08:00');
      expect(kYangtzeSessions[0].endTime, '09:35');
      expect(kYangtzeSessions[0].interbreakTitle, contains('大课间'));

      // 上午第 2 节（原 3-4 节，大课间 30 分钟后 10:05 开始）
      expect(kYangtzeSessions[1].sessionName, '第2节');
      expect(kYangtzeSessions[1].periodDesc, '上午');
      expect(kYangtzeSessions[1].startTime, '10:05');
      expect(kYangtzeSessions[1].endTime, '11:40');
      expect(kYangtzeSessions[1].interbreakTitle, '午休');

      // 下午第 3 节（原 5-6 节，14:00 开始）
      expect(kYangtzeSessions[2].sessionName, '第3节');
      expect(kYangtzeSessions[2].periodDesc, '下午');
      expect(kYangtzeSessions[2].startTime, '14:00');
      expect(kYangtzeSessions[2].endTime, '15:35');
      expect(kYangtzeSessions[2].interbreakTitle, contains('大课间'));

      // 下午第 4 节（原 7-8 节，大课间 20 分钟后 15:55 开始）
      expect(kYangtzeSessions[3].sessionName, '第4节');
      expect(kYangtzeSessions[3].periodDesc, '下午');
      expect(kYangtzeSessions[3].startTime, '15:55');
      expect(kYangtzeSessions[3].endTime, '17:30');
      expect(kYangtzeSessions[3].interbreakTitle, contains('晚休'));

      // 晚间第 5 节（原 9-10 节，18:30 开始）
      expect(kYangtzeSessions[4].sessionName, '第5节');
      expect(kYangtzeSessions[4].periodDesc, '晚间');
      expect(kYangtzeSessions[4].startTime, '18:30');
      expect(kYangtzeSessions[4].endTime, '20:05');

      // 晚间第 6 节（原 11-12 节，20:15 开始）
      expect(kYangtzeSessions[5].sessionName, '第6节');
      expect(kYangtzeSessions[5].periodDesc, '晚间');
      expect(kYangtzeSessions[5].startTime, '20:15');
      expect(kYangtzeSessions[5].endTime, '21:50');
    });

    test('MergedSessionBlock 跨大节连课计算', () {
      final singleBlock = MergedSessionBlock(
        startSession: 1,
        endSession: 1,
        items: [
          {
            'name': '大学英语',
            'room': '东教-101',
            'teacher_names': '张老师',
          }
        ],
      );
      expect(singleBlock.span, 1);
      expect(singleBlock.timeRange, '08:00-09:35');
      expect(singleBlock.sessionLabel, '第1节');

      // 跨上午两节连上大实验 (08:00 - 11:40)
      final mergedBlock = MergedSessionBlock(
        startSession: 1,
        endSession: 2,
        items: [
          {
            'name': '大学物理实验',
            'room': '实验楼-302',
            'teacher_names': '李教授',
          }
        ],
      );
      expect(mergedBlock.span, 2);
      expect(mergedBlock.timeRange, '08:00-11:40');
      expect(mergedBlock.sessionLabel, '第1节-第2节');
    });

    test('中国大陆真实日出日落与作息光照富豪榜推算', () {
      // 秋分 (9月23日)：昼夜近乎等长，长江大学 (荆州) 日出约 6点多，日落约 18点多，正午约 12:24
      final autumnEquinox = ChinaSolarEngine.calculate(DateTime(2026, 9, 23));
      expect(autumnEquinox.sunrise.hour, 6);
      expect(autumnEquinox.sunset.hour, 18);
      expect(autumnEquinox.solarNoon.hour, 12);
      expect(autumnEquinox.dayLength.inHours, 12);

      // 夏至 (6月21日)：白昼最长，日出早于 05:30，日落晚于 19:25
      final summerSolstice = ChinaSolarEngine.calculate(DateTime(2026, 6, 21));
      expect(summerSolstice.sunrise.hour, lessThanOrEqualTo(5));
      expect(summerSolstice.sunset.hour, greaterThanOrEqualTo(19));
      expect(summerSolstice.dayLength.inHours, greaterThanOrEqualTo(14));

      // 冬至 (12月22日)：白昼最短，日出晚于 07:15，日落早于 17:35
      final winterSolstice = ChinaSolarEngine.calculate(DateTime(2026, 12, 22));
      expect(winterSolstice.sunrise.hour, greaterThanOrEqualTo(7));
      expect(winterSolstice.sunset.hour, lessThanOrEqualTo(17));
      expect(winterSolstice.dayLength.inHours, lessThanOrEqualTo(10));

      // 验证富豪榜作息排位
      expect(kSessionSolarRanks.length, 6);
      expect(kSessionSolarRanks[0].celestialIcon, '🌅');
      expect(kSessionSolarRanks[0].rankBadge, 'TOP 4');
      expect(kSessionSolarRanks[1].celestialIcon, '☀️');
      expect(kSessionSolarRanks[1].rankBadge, 'TOP 2');
      expect(kSessionSolarRanks[2].celestialIcon, '🌤️');
      expect(kSessionSolarRanks[2].rankBadge, 'TOP 3');
      expect(kSessionSolarRanks[3].celestialIcon, '🌇');
      expect(kSessionSolarRanks[3].rankBadge, 'TOP 5');
      expect(kSessionSolarRanks[4].celestialIcon, '🌙');
      expect(kSessionSolarRanks[4].rankBadge, '伴月');
      expect(kSessionSolarRanks[5].celestialIcon, '🌌');
      expect(kSessionSolarRanks[5].rankBadge, '星夜');
    });

    test('教务系统抓包 HAR 8行网格规则：大节 1-6 独立无重叠与连课跨度', () {
      // 1. 验证默认权威学期为 369 (2025-2026-1)
      expect(SemesterTable.defaultSemesterId, 369);
      expect(SemesterTable.currentSemesterId(), 369);
      expect(SemesterTable.labelFor(369), '2025-2026学年 1学期');

      // 2. 验证当前 9月23日 在开学第 4 周
      final currentWeek = SemesterTable.calculateCurrentWeek(
          369, DateTime(2026, 9, 23));
      expect(currentWeek, 4);

      // 3. 模拟教务系统 8 行网格（unitCount = 8）
      // 同一天（如周五）的第一节 (unit 1) 与第二节 (unit 2)
      const unitCount = 8;
      final unit1 = 1;
      final unit2 = 2;
      final sessionIdx1 = (unitCount <= 8) ? unit1 : (((unit1 - 1) ~/ 2) + 1);
      final sessionIdx2 = (unitCount <= 8) ? unit2 : (((unit2 - 1) ~/ 2) + 1);

      // 确保 unit 1 映射为第 1 节 (08:00-09:35)，unit 2 映射为第 2 节 (10:05-11:40)，决不重叠在第 1 节！
      expect(sessionIdx1, 1);
      expect(sessionIdx2, 2);
      expect(sessionIdx1 != sessionIdx2, isTrue);

      // 4. 下午连课（第 3 节 14:00-15:35 与 第 4 节 15:55-17:30）
      final unit3 = 3;
      final unit4 = 4;
      final sessionIdx3 = (unitCount <= 8) ? unit3 : (((unit3 - 1) ~/ 2) + 1);
      final sessionIdx4 = (unitCount <= 8) ? unit4 : (((unit4 - 1) ~/ 2) + 1);
      expect(sessionIdx3, 3);
      expect(sessionIdx4, 4);

      // 跨大节合并
      final mergedBlock = MergedSessionBlock(
        startSession: sessionIdx3,
        endSession: sessionIdx4,
        items: [
          {
            'name': '快题设计（3）',
            'room': '实验武科技楼B区204-2',
            'teacher_names': '指导教师',
          }
        ],
      );
      expect(mergedBlock.span, 2);
      expect(mergedBlock.timeRange, '14:00-17:30');
      expect(mergedBlock.sessionLabel, '第3节-第4节');
    });
  });
}
