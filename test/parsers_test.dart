// 解析清洗器单元测试：clean / js_literal / table_miner / 各域解析器。
//
// 结构与语义均对标 grabber/api/*.py（已通过 golden 逐字段比对），此处用
// 手工构造的最小 HTML 固定关键行为，防止回归。
import 'package:flutter_test/flutter_test.dart';
import 'package:grade2/core/crawler/parsers/clean.dart';
import 'package:grade2/core/crawler/parsers/elective_parser.dart';
import 'package:grade2/core/crawler/parsers/exam_parser.dart';
import 'package:grade2/core/crawler/parsers/grade_parser.dart';
import 'package:grade2/core/crawler/parsers/js_literal.dart';
import 'package:grade2/core/crawler/parsers/misc_parser.dart';
import 'package:grade2/core/crawler/parsers/plan_parser.dart';
import 'package:grade2/core/crawler/parsers/table_miner.dart';
import 'package:grade2/core/crawler/parsers/timetable_parser.dart';

void main() {
  group('clean.dart', () {
    test('cleanWs 压缩空白含 nbsp', () {
      expect(cleanWs('  a\u00a0 \n b\t '), 'a b');
      expect(cleanWs(null), '');
      expect(cleanWs(''), '');
    });

    test('toNum 数值化与不误伤', () {
      expect(toNum('85'), 85);
      expect(toNum('85.50'), 85.5);
      expect(toNum('-3'), -3);
      expect(toNum('14:00~15:50'), '14:00~15:50');
      expect(toNum(''), null);
      expect(toNum('abc'), 'abc');
    });

    test('weekParse 位串 → 摘要/列表/计数', () {
      final w = weekParse('01111001');
      expect(w['raw'], '01111001');
      expect(w['digest'], '2-5,8');
      expect(w['list'], [2, 3, 4, 5, 8]);
      expect(w['count'], 5);
      expect(w['total'], 8);
      expect(weekParse(null)['count'], 0);
    });

    test('weekDigest 连续区间合并', () {
      expect(weekDigest([1, 2, 3, 7, 9, 10, 11]), '1-3,7,9-11');
      expect(weekDigest([]), '');
    });

    test('weekParse URP 53位串解析与单双周识别', () {
      // 职场菜鸟礼仪指南：单周 3-15 周（单周第3周开始）
      final oddCourse =
          weekParse('00010101010101010000000000000000000000000000000000000');
      expect(oddCourse['list'], [3, 5, 7, 9, 11, 13, 15]);
      expect(oddCourse['digest'], '单3-15');
      expect(oddCourse['count'], 7);
      expect(oddCourse['total'], 52);

      // 广告创意设计：双周 2-16 周（双周第2周开始）
      final evenCourse =
          weekParse('00101010101010101000000000000000000000000000000000000');
      expect(evenCourse['list'], [2, 4, 6, 8, 10, 12, 14, 16]);
      expect(evenCourse['digest'], '双2-16');

      // 工艺设计简史：1-9 周
      final contCourse =
          weekParse('01111111110000000000000000000000000000000000000000000');
      expect(contCourse['list'], [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(contCourse['digest'], '1-9');

      // AIGC：3-18 周
      final aigcCourse =
          weekParse('00011111111111111110000000000000000000000000000000000');
      expect(aigcCourse['list'],
          [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]);
      expect(aigcCourse['digest'], '3-18');
    });

    test('weekDigestFromBits 单周与区间', () {
      expect(weekDigestFromBits('000011110000'), '5-8');
      expect(weekDigestFromBits('01000000'), '2');
    });

    test('stripTags 不解码实体（与 Python strip_tags 对齐）', () {
      expect(stripTags('<div>红字&nbsp;格</div>'), '红字 格');
      expect(stripTags('<b>a&amp;b</b>'), 'a&amp;b'); // 不解码 &amp;
    });

    test('stripAll 解码实体', () {
      expect(stripAll('<b>a&amp;b</b>'), 'a&b');
    });

    test('stripChars / rstripChars', () {
      expect(stripChars(' ,、a,、 ', ' ,、'), 'a');
      expect(rstripChars('学期：： ', '： '), '学期');
    });

    test('splitBefore 匹配起点切分', () {
      expect(splitBefore('a<bXc<bXd', RegExp(r'<b')),
          ['<bXc', '<bXd']);
      expect(splitBefore('no-match', RegExp(r'<b')), isEmpty);
    });
  });

  group('js_literal.dart', () {
    test('splitJsArgs 尊重引号与括号', () {
      expect(
          splitJsArgs('6758, "a,b", \'c)\' , [1,2], null, "", x'),
          ['6758', '"a,b"', "'c)'", '[1,2]', 'null', '""', 'x']);
    });

    test('extractBalanced 配平提取', () {
      expect(extractBalanced('xx[1,[2],"a]b"]tail', '['), '[1,[2],"a]b"]');
      expect(extractBalanced('{"a":"}b"}', '{'), '{"a":"}b"}');
      expect(() => extractBalanced('no brace', '{'),
          throwsFormatException);
      expect(() => extractBalanced('{unclosed', '{'),
          throwsFormatException);
    });

    test('jsLiteralToDart 无引号键 + 单引号字符串', () {
      final v = jsLiteralToDart("{id:123,name:'高数',lab:false,f:1.5,e:null}")
          as Map<String, Object?>;
      expect(v['id'], 123);
      expect(v['name'], '高数');
      expect(v['lab'], false);
      expect(v['f'], 1.5);
      expect(v['e'], null);
    });
  });

  group('table_miner.dart', () {
    const rowspanHtml = '<div style="font-weight:bold">成绩表</div>'
        '<table class="gridtable">'
        '<thead><tr><th>课程</th><th>学分</th></tr></thead>'
        '<tbody>'
        '<tr><td rowspan="2">高数</td><td>4</td></tr>'
        '<tr><td>3</td></tr>'
        '</tbody></table>';

    test('表格提取 + 标题 + rowspan 展开', () {
      final tables = parseTables(rowspanHtml);
      expect(tables.length, 1);
      final t = tables.first;
      expect(t['title'], '成绩表');
      expect(t['headers'], ['课程', '学分']);
      expect(t['n_rows'], 2);
      expect(t['n_cols'], 2);
      final row1 = (t['rows'] as List)[1] as List;
      // 跨行占位继承源值并打 span 标记
      expect((row1[0] as Map)['span'], 'row');
      expect((row1[0] as Map)['text'], '高数');
      expect((row1[1] as Map)['span'], null);
    });

    test('table_records 数值化 + 占位排除产生 _group 行', () {
      final recs = tableRecords(parseTables(rowspanHtml).first);
      expect(recs.length, 2);
      expect(recs[0], {'课程': '高数', '学分': 4});
      // 第二行排除占位后仅剩一个真实单元格 → 分组行（与 Python 语义一致）
      expect(recs[1], {'_group': '3'});
    });

    test('table_records 双行表头重复列名合并', () {
      const html = '<table class="gridtable"><thead>'
          '<tr><th colspan="2">成绩</th></tr>'
          '<tr><th>期中</th><th>期末</th></tr>'
          '</thead><tbody><tr><td>80</td><td>90</td></tr></tbody></table>';
      final t = parseTables(html).first;
      expect(t['headers'], ['成绩', '成绩']);
      final recs = tableRecords(t);
      // 与 Python 一致：首个重复列名保留原样，后续并子表头
      expect(recs.first, {'成绩': 80, '成绩期末': 90});
    });

    test('单元格链接 → _links', () {
      const html = '<table><thead><tr><th>考场</th><th>座位号</th></tr></thead>'
          '<tbody><tr><td><a href="/room?examRoom.id=42">座位表</a></td>'
          '<td>12</td></tr></tbody></table>';
      final recs = tableRecords(parseTables(html).first);
      final links = recs.first['_links'] as List;
      expect(links.first,
          {'href': '/room?examRoom.id=42', 'text': '座位表', 'col': '考场'});
    });

    test('嵌套表独立产出 + 外层壳表被过滤（与 Python 一致）', () {
      const html = '<table id="outer"><tr><td>'
          '<table id="inner"><tr><td>x</td></tr></table>'
          '</td></tr></table>';
      final tables = parseTables(html);
      expect(tables.map((t) => t['id']), ['inner']);
    });

    test('pickTable 按 class/标题挑选', () {
      final tables = parseTables(rowspanHtml);
      expect(pickTable(tables, classKw: 'gridtable'), isNotNull);
      expect(pickTable(tables, classKw: '不存在'), isNull);
      expect(pickTable(tables, titleKw: '成绩表'), isNotNull);
    });

    test('kvTables 冒号键值 + darkColumn 分段 + 照片', () {
      const html = '<div style="font-weight:bold">学籍信息</div>'
          '<table>'
          '<tr><td class="darkColumn">基本信息</td></tr>'
          '<tr><td>学号：</td><td>2022007923</td><td><img src="/p.jpg"></td></tr>'
          '</table>';
      final kvs = kvTables(html);
      expect(kvs.length, 1);
      // 与 Python 一致：表内 darkColumn 分组行会覆盖前置标题
      expect(kvs.first['section'], '基本信息');
      final kv = kvs.first['kv'] as Map<String, Object?>;
      expect(kv['学号'], '2022007923');
      expect(kv['照片'], '/p.jpg');
    });
  });

  group('timetable_parser.dart', () {
    const js = '''
var unitCount = 5;
var teachers = [{id:6758,name:"漆良蜜",lab:false}];
var actTeachers = [{id:6758,name:"漆良蜜",lab:false}];
var assistantName = "";
activity = new TaskActivity(6758, "漆良蜜", "115251(752764)", "高等数学(115252)", "301", "一教301", "0111100100", null, null, assistantName, "", "");
index = 1 * unitCount + 2;
''';
    test('parseCourseHtml 全字段捕获', () {
      final r = parseCourseHtml(js);
      expect(r['unit_count'], 5);
      expect(r['course_count'], 1);
      final c = (r['courses'] as List).first as Map<String, Object?>;
      expect(c['teachers'], [
        {'id': 6758, 'name': '漆良蜜', 'lab': false}
      ]);
      expect(c['teacher_names'], '漆良蜜');
      expect(c['task_no'], '115251');
      expect(c['course_code'], '752764');
      expect(c['clazz'], '115251(752764)');
      expect(c['name'], '高等数学');
      expect(c['course_code2'], '115252');
      expect(c['room_id'], '301');
      expect(c['room'], '一教301');
      expect(c['day'], 2); // idx=7 → 7~/5+1
      expect(c['day_name'], '周二');
      expect(c['unit'], 3); // 7%5+1
      expect((c['weeks'] as Map)['digest'], '2-5,8');
      expect(c['flag'], '');
      expect((c['params_raw'] as List).length, 12);
      // 聚合
      final m = (r['merged'] as List).first as Map<String, Object?>;
      expect(m['name'], '高等数学');
      expect(m['rooms'], ['一教301']);
      expect(m['times'], ['周二3节']);
      expect(m['units'], 1);
    });

    test('parseCourseHtml 多节次连课捕获（单活动多个 index 赋值）', () {
      const multiJs = '''
var unitCount = 8;
var teachers = [{id:115218,name:"李老师",lab:false}];
var actTeachers = [{id:115218,name:"李老师",lab:false}];
var assistantName = "";
activity = new TaskActivity(115218, "李老师", "115218(752760)", "快题设计(752760)", "2988", "实验楼204", "000001111000", null, null, assistantName, "", "1");
index = 1 * unitCount + 2;
index = 1 * unitCount + 3;
''';
      final r = parseCourseHtml(multiJs);
      expect(r['unit_count'], 8);
      expect(r['course_count'], 2);
      final courses = r['courses'] as List;
      final c1 = courses[0] as Map<String, Object?>;
      final c2 = courses[1] as Map<String, Object?>;
      expect(c1['name'], '快题设计');
      expect(c1['day'], 2);
      expect(c1['unit'], 3);
      expect(c2['name'], '快题设计');
      expect(c2['day'], 2);
      expect(c2['unit'], 4);
    });

    test('parseCourseTableIds', () {
      const html = 'addInput(form,"ids","1225");addInput(form,"ids","1226");';
      final ids = parseCourseTableIds(html);
      expect(ids['std'], '1225');
      expect(ids['class'], '1226');
    });
  });

  group('grade/exam 解析器', () {
    test('parseGradesHtml 表头 + 数值化 + 原始行', () {
      const html = '<table class="gridtable"><thead><tr>'
          '<th>课程名称</th><th>学分</th><th>总评成绩</th></tr></thead>'
          '<tbody><tr><td>高数</td><td>4</td><td>95</td></tr></tbody></table>';
      final r = parseGradesHtml(html);
      expect(r['headers'], ['课程名称', '学分', '总评成绩']);
      expect(r['count'], 1);
      expect((r['records'] as List).first, {'课程名称': '高数', '学分': 4, '总评成绩': 95});
      expect(r['rows'], [
        ['高数', '4', '95']
      ]);
    });

    test('parseExamHtml 注入 exam_room_id', () {
      const html = '<table class="gridtable"><thead><tr><th>考场</th><th>日期</th></tr></thead>'
          '<tbody><tr><td><a href="/x?examRoom.id=42">座位表</a></td><td>01-10</td></tr></tbody></table>';
      final r = parseExamHtml(html);
      expect((r['records'] as List).first['exam_room_id'], 42);
    });

    test('parseOtherExamsHtml 按标题分流报名/成绩', () {
      const html = '<h2>报名信息</h2>'
          '<table><tr><td>四六级</td></tr></table>'
          '<h2>成绩</h2>'
          '<table><tr><td>425</td></tr></table>';
      final r = parseOtherExamsHtml(html);
      expect(r['signup_count'], 1);
      expect(r['score_count'], 1);
    });

    test('parseExamBatchesHtml', () {
      const html = '<select name="examBatch.id">'
          '<option value="1">正常考试</option>'
          '<option value="9" selected>补考</option></select>';
      final b = parseExamBatchesHtml(html);
      expect(b, [
        {'id': 1, 'selected': false, 'name': '正常考试'},
        {'id': 9, 'selected': true, 'name': '补考'},
      ]);
    });
  });

  group('plan/elective/misc 解析器', () {
    test('parsePlanCompletionHtml 分组结构', () {
      const html = '<table class="formTable"><tr><td>课程</td><td>学分</td></tr>'
          '<tr><td colspan="2">必修(小计 60)</td></tr>'
          '<tr><td>高数</td><td>4</td></tr>'
          '<tr><td>英语</td><td>2</td></tr></table>';
      final r = parsePlanCompletionHtml(html);
      expect((r['sections'] as List).length, 1);
      final s = (r['sections'] as List).first as Map<String, Object?>;
      expect(s['group'], '必修(小计 60)');
      expect((s['records'] as List).length, 2);
      expect(r['count'], 2);
      expect((r['records'] as List).first['group'], '必修(小计 60)');
    });

    test('parseProfilesHtml 轮次解析', () {
      const html = '<h2>第一轮选课</h2>'
          'electionProfile.id=6254 选课轮次 1 '
          '选课开放时间: 2026-09-01 08:00 - 2026-09-05 23:59 '
          '退课开放时间: 2026-09-06 08:00 - 2026-09-07 23:59 '
          '选课限制: 只允许选1门, 不允许跨年级 注意事项: 请认真选择 进入选课';
      final ps = parseProfilesHtml(html);
      expect(ps.length, 1);
      final p = ps.first;
      expect(p['id'], 6254);
      expect(p['name'], '第一轮选课');
      expect(p['round'], 1);
      expect(p['elect_open'], '2026-09-01 08:00 ~ 2026-09-05 23:59');
      expect(p['withdraw_open'], '2026-09-06 08:00 ~ 2026-09-07 23:59');
      expect(p['limits'], [': 只允许选1门', '不允许跨年级']);
      // 与 Python 一致：notice 仅 strip 首尾空白，冒号保留
      expect(p['notice'], ': 请认真选择');
    });

    test('parseElectiveContextHtml', () {
      const html = 'queryStdCount.action?projectId=1&semesterId=409';
      final c = parseElectiveContextHtml(html, 6254);
      expect(c, {'profile_id': 6254, 'project_id': 1, 'semester_id': 409});
    });

    test('parseLessonsHtml / parseCountsHtml', () {
      final lessons = parseLessonsHtml(
          "var lessonJSONs = [{id:3203944,name:'综合英语',credits:2.0}];");
      expect((lessons).first['name'], '综合英语');
      expect(parseLessonsHtml('var other = 1;'), isEmpty);
      final counts = parseCountsHtml(
          "window.lessonId2Counts={'3203944':{sc:30,lc:60}};");
      expect(counts['3203944'], {'sc': 30, 'lc': 60});
      expect(parseCountsHtml('nothing'), isEmpty);
    });

    test('parseOperateResultHtml 三分支', () {
      // 红色错误 div
      final fail = parseOperateResultHtml(
          '<div style="color:red;font-weight:bold">人数已满&nbsp;!</div>',
          42, true);
      expect(fail, {'success': false, 'message': '人数已满 !', 'lesson_id': 42});
      // 选课成功
      expect(parseOperateResultHtml('elected : true', 42, true),
          {'success': true, 'message': '选课成功', 'lesson_id': 42});
      // 退课成功（elected=false 即退课成功）
      expect(parseOperateResultHtml('elected : false', 42, false),
          {'success': true, 'message': '退课成功', 'lesson_id': 42});
    });

    test('parseSemestersHtml 定向正则 + 回退当前学期', () {
      const full =
          '{yearDom:"<tr>x</tr>",semesters:{},semesterId:"409",yearIndex:"16"}'
          '{id:369,schoolYear:"2024-2025",name:"2"}'
          '{id:409,schoolYear:"2025-2026",name:"1"}';
      final r = parseSemestersHtml(full);
      expect((r['semesters'] as List).length, 2);
      expect(r['current'], 409);
      expect(r['year_index'], '16');
      final s = (r['semesters'] as List).last as Map<String, Object?>;
      expect(s['label'], '2025-2026学年 1学期');
      // 空响应 → current 回退 null
      final empty = parseSemestersHtml(
          '{yearDom:"",termDom:"",semesters:{},yearIndex:"-1",semesterId:""}');
      expect(empty['current'], null);
      // 无 semesterId → 回退最新学期
      expect(parseSemestersHtml('{id:369,schoolYear:"a",name:"2"}')['current'],
          369);
    });

    test('parseWelcomeHtml / parseStdDetailHtml / parseMessagesHtml', () {
      const w = '<h2 class="header"><a>欢迎信息</a></h2>'
          '<div class="modulebody">你好<b>世界</b>&amp;再见</div>';
      final wr = parseWelcomeHtml(w);
      expect((wr['modules'] as List).first,
          {'name': '欢迎信息', 'content': '你好 世界 &再见'});
      expect(wr['welcome_text'], '你好 世界 &再见');

      const d = '<h3>学籍</h3><table>'
          '<tr><td>学号：</td><td>2022007923</td><td><img src="/p.jpg"></td></tr>'
          '</table>';
      final dr = parseStdDetailHtml(d);
      expect(dr['photo'], '/p.jpg');
      expect((dr['kv'] as Map)['学号'], '2022007923');

      const m = '<table class="gridtable"><thead><tr><th>主题</th><th>时间</th></tr></thead>'
          '<tbody><tr><td>通知A</td><td>2026-09-01</td></tr></tbody></table>';
      expect((parseMessagesHtml(m)['records'] as List).first,
          {'主题': '通知A', '时间': '2026-09-01'});
    });

    test('parseMidtermHtml / parseEvaluateHtml / parseStdApplyHtml', () {
      const mt = '<h3>中期考核</h3><p>正文</p>';
      final mr = parseMidtermHtml(mt);
      expect(mr['message'], '中期考核');
      expect(mr['text'], '中期考核 正文');

      const ev = '<table class="gridtable"><thead><tr><th>课程</th><th>类别</th></tr></thead>'
          '<tbody><tr><td>体育</td><td>必修</td></tr></tbody></table>';
      expect((parseEvaluateHtml(ev)['records'] as List).first,
          {'课程': '体育', '类别': '必修'});

      const ap = '<h2>提示</h2><a href="/a">链接一</a><a href="/b">链接二</a>';
      final ar = parseStdApplyHtml(ap);
      expect(ar['message'], '提示');
      expect((ar['menus'] as List).length, 2);
      expect(ar['text'], '提示 链接一 链接二');
    });
  });
}
