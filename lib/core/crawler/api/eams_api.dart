/// 第④步：URP 教务系统接口封装（对应 grabber/api/*.py 的 Mixin 集合）。
///
/// `EamsApi` = 课表 + 考试 + 成绩 + 选课(读/写) + 培养计划 + 杂项，
/// 基于四步鉴权链路的产物（由 `CrawlerSession.ensureApi` 构造）。
///
/// 约定：
/// - 所有请求 1:1 复刻抓包（ajax 参数 + X-Requested-With 头 + Referer）
/// - 每个接口方法：原始响应经 [RawSink] 可选留存，返回结构化原生 Map/List
/// - 会话失效（被踢回登录）统一抛 [SessionLost]，由调用方经
///   `CrawlerSession.withApi` 或再次 ensureApi 重建链路
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../crawler_exceptions.dart';
import '../models/config_models.dart';
import '../models/data_models.dart';
import '../parsers/elective_parser.dart';
import '../parsers/exam_parser.dart';
import '../parsers/grade_parser.dart';
import '../parsers/misc_parser.dart';
import '../parsers/plan_parser.dart';
import '../parsers/timetable_parser.dart';
import '../session/http_client.dart';

/// 原始响应留存接口（对应 Python save → output/）。
///
/// - [DirectoryRawSink]：写文件（调试/离线自检），返回文件路径
/// - [MemoryRawSink]：内存留存（最近 capacity 份）
/// - null：不留存（生产默认）
abstract class RawSink {
  Future<String> write(String name, String content);
}

/// 文件实现（目录由调用方注入，自动创建）。
class DirectoryRawSink implements RawSink {
  DirectoryRawSink(this.dir);
  final String dir;

  @override
  Future<String> write(String name, String content) async {
    final f = File('$dir/$name');
    await f.parent.create(recursive: true);
    await f.writeAsString(content, flush: true);
    return f.path;
  }
}

/// 内存实现。
class MemoryRawSink implements RawSink {
  MemoryRawSink({this.capacity = 16});
  final int capacity;
  final Map<String, String> store = {};

  @override
  Future<String> write(String name, String content) async {
    if (store.length >= capacity && !store.containsKey(name)) {
      store.remove(store.keys.first);
    }
    store[name] = content;
    return name;
  }
}

/// URP 教务系统只读/写操作接口集合（全部方法异步）。
class EamsApi {
  EamsApi({required this.http, required this.config, this.rawSink});

  final SessionHttpClient http;
  final GrabberConfig config;
  final RawSink? rawSink;

  static final Random _rng = Random();
  static const _tooFast = '请不要过快点击';

  // ---- 会话级缓存（EamsApi 实例随会话重建而失效，无需手动清） ----

  /// dataQuery 组件是否已在本会话预热（预热一次即可，省重复请求）
  bool _dataQueryWarmed = false;

  /// 课表入口页 ids 缓存（std/class id 会话内不变，省一次入口页 GET）
  Map<String, Object?>? _courseTableIds;

  // ================= 请求底座（EamsBase） =================

  int _ts() => DateTime.now().millisecondsSinceEpoch;

  Map<String, String> _ajaxHeaders([String? referer]) => {
        'X-Requested-With': 'XMLHttpRequest',
        'Accept': 'text/html, */*; q=0.01',
        'Referer': referer ?? '${config.eamsBase}/eams/home.action',
      };

  Uri _uri(String path, Map<String, String>? params) {
    // 与 Step2Portal.buildPortalUri 同防御：保留 path 自带 query，
    // Uri.replace(queryParameters:) 是整串替换语义
    final base = Uri.parse('${config.eamsBase}$path');
    if (params == null || params.isEmpty) return base;
    return base.replace(queryParameters: {
      ...base.queryParameters,
      ...params,
    });
  }

  /// 会话守卫：被重定向/非 200/落点出教务系统 → [SessionLost]。
  void _guard(HttpTextResponse resp) {
    final m = RegExp(r'https?://[^/]+(/[^;?]*)').firstMatch(resp.url.toString());
    final path = m?.group(1) ?? '';
    if (resp.isRedirect) {
      var loc = resp.header('location') ?? '';
      if (loc.length > 100) loc = loc.substring(0, 100);
      throw SessionLost('被重定向: $loc');
    }
    if (resp.statusCode != 200) {
      throw SessionLost('HTTP ${resp.statusCode}: ${resp.url}');
    }
    if (!path.startsWith('/eams/') ||
        resp.url.toString().contains('authserver')) {
      throw SessionLost('落点不在教务系统: ${resp.url}');
    }
  }

  /// GET ajax：自动附 `_` 时间戳与 sf_request_type=ajax；
  /// 命中 URP 过频保护时等待 2.5s 重试一次（与 Python 一致）。
  Future<String> _getAjax(String path, [Map<String, String>? params]) async {
    final q = <String, String>{...?params}
      ..putIfAbsent('_', () => _ts().toString())
      ..putIfAbsent('sf_request_type', () => 'ajax');
    for (var attempt = 0;; attempt++) {
      final resp = await http.get(_uri(path, q), headers: _ajaxHeaders());
      _guard(resp);
      if (!resp.body.contains(_tooFast) || attempt > 0) return resp.body;
      await Future<void>.delayed(const Duration(milliseconds: 2500));
    }
  }

  /// POST ajax：表单体 + query 参数；过频保护自动等待重试一次。
  Future<String> _postAjax(String path, Map<String, String> data,
      [Map<String, String>? params]) async {
    final q = <String, String>{...?params}
      ..putIfAbsent('sf_request_type', () => 'ajax');
    for (var attempt = 0;; attempt++) {
      final resp =
          await http.post(_uri(path, q), headers: _ajaxHeaders(), form: data);
      _guard(resp);
      if (!resp.body.contains(_tooFast) || attempt > 0) return resp.body;
      await Future<void>.delayed(const Duration(milliseconds: 2500));
    }
  }

  /// 留存原始响应，返回位置标识（无 sink 返回空串）。
  Future<String> _save(String name, String content) async =>
      await rawSink?.write(name, content) ?? '';

  // 10 位随机数（10^9 ~ 10^10-1，对标 Python random.randint）；
  // dart:math nextInt 上限 2^32，故拆首位 + 后 9 位
  String _tagId() =>
      'semesterBar${_rng.nextInt(9) + 1}${_rng.nextInt(1000000000).toString().padLeft(9, '0')}Semester';

  // ================= 杂项（MiscMixin） =================

  /// 首页欢迎信息（各模块完整文本，含今天日期）。
  Future<WelcomeResult> welcome() async {
    final html = await _getAjax('/eams/home!welcome.action');
    final file = await _save('welcome.html', html);
    return {...parseWelcomeHtml(html), 'file': file};
  }

  /// 学籍信息（学籍/联系信息/家庭联系信息 等多 section + 照片 URL）。
  Future<StdDetailResult> stdDetail() async {
    final html = await _getAjax('/eams/stdDetail.action');
    final file = await _save('stdDetail.html', html);
    return {...parseStdDetailHtml(html), 'file': file};
  }

  /// 全部学期列表 + 当前学期（dataQuery semesterCalendar）。
  ///
  /// ⚠ 实测（2026-09）：dataQuery 组件需先访问含 semesterBar 的页面
  /// （如 courseTableForStd）完成会话内注册，否则返回空表
  /// `{yearDom:"",semesters:{},semesterId:""}`——本会话首次调用自动预热。
  Future<SemestersResult> semesters() async {
    var defaultValue = '369';
    if (!_dataQueryWarmed) {
      final warmHtml = await _getAjax('/eams/courseTableForStd.action'); // 预热 dataQuery 组件
      _dataQueryWarmed = true;
      final defaultValM =
          RegExp(r'value\s*:\s*["\x27]?(\d+)').firstMatch(warmHtml);
      if (defaultValM != null) {
        defaultValue = defaultValM.group(1)!;
      }
    }
    // projectId(与抓包一致的预备查询)
    await _postAjax('/eams/dataQuery.action', {'dataType': 'projectId'});
    final html = await _postAjax('/eams/dataQuery.action', {
      'tagId': _tagId(),
      'dataType': 'semesterCalendar',
      'value': defaultValue,
      'empty': 'false',
    });
    await _save('semesters_raw.txt', html);
    return parseSemestersHtml(html);
  }

  /// 切换当前学期（写 cookie semester.id，等价于页面学期条选择）。
  Future<JsonMap> setSemester(int semesterId) async {
    if (!_dataQueryWarmed) {
      await _getAjax('/eams/courseTableForStd.action'); // 预热 dataQuery 组件
      _dataQueryWarmed = true;
    }
    final html = await _postAjax('/eams/dataQuery.action', {
      'tagId': _tagId(),
      'dataType': 'semesterCalendar',
      'value': semesterId.toString(),
      'empty': 'false',
    });
    http.cookies
        .set('semester.id', semesterId.toString(), domain: config.eamsHost);
    await _save('setSemester_raw.txt', html);
    return {'semester_id': semesterId, 'ok': html.trim().isNotEmpty};
  }

  /// 学生系统消息列表（发件人/主题/时间全字段）。
  Future<MessagesResult> messages() async {
    final html = await _getAjax('/eams/systemMessageForStd!search.action');
    final file = await _save('systemMessages.html', html);
    return {...parseMessagesHtml(html), 'file': file};
  }

  /// 教学评价页（评价任务列表：课程/类别/教师/问卷全字段）。
  Future<EvaluateResult> evaluate({int? semesterId}) async {
    if (semesterId != null) {
      await _postAjax(
          '/eams/quality/stdEvaluate.action', {'semester.id': semesterId.toString()});
    }
    final html = await _getAjax('/eams/quality/stdEvaluate.action');
    final file = await _save('stdEvaluate.html', html);
    return {...parseEvaluateHtml(html), 'file': file};
  }

  // ================= 课表（TimetableMixin） =================

  /// 课表（完整清洗：教师/课程代码/周次/节次/教室/实验标记等全部字段）。
  ///
  /// - [kind]：'std' 学生课表 / 'class' 班级课表
  /// - [semesterId]：学期 id（如 409），null = 服务器默认学期
  /// - [startWeek]：起始教学周（如 '5'），null = 全部周
  Future<CourseTableResult> courseTable(
      {String kind = 'std', int? semesterId, String? startWeek}) async {
    if (kind != 'std' && kind != 'class') {
      throw ArgumentError('kind 必须是 "std" 或 "class"');
    }
    // 入口页 ids 会话内不变 → 实例级缓存（省一次 GET；SessionLost 重建
    // EamsApi 实例时自然失效）
    var ids = _courseTableIds;
    if (ids == null) {
      ids = parseCourseTableIds(
          await _getAjax('/eams/courseTableForStd.action'));
      _courseTableIds = ids;
    }
    final sid = ids[kind] as String?;
    if (sid == null) {
      throw StateError('课表入口页未解析到 $kind ids');
    }
    final html = await _postAjax('/eams/courseTableForStd!courseTable.action', {
      'ignoreHead': '1',
      'setting.kind': kind,
      'startWeek': startWeek ?? '',
      'semester.id': semesterId?.toString() ?? '',
      'ids': sid,
    });
    final file =
        await _save('courseTable_${kind}_${semesterId ?? 'default'}.html', html);
    return {
      'kind': kind,
      'ids': sid,
      'semester_id': semesterId,
      'start_week': startWeek,
      'file': file,
      ...parseCourseHtml(html),
    };
  }

  // ================= 成绩（GradeMixin） =================

  /// 查询某学期个人成绩（完整清洗）。[semesterId] 可由 [semesters] 获取。
  Future<GradesResult> grades(int semesterId) async {
    final html = await _getAjax(
        '/eams/teach/grade/course/person!search.action',
        {'semesterId': semesterId.toString(), 'projectType': ''});
    final file = await _save('grades_$semesterId.html', html);
    return {'semester_id': semesterId, ...parseGradesHtml(html), 'file': file};
  }

  // ================= 考试（ExamMixin） =================

  /// 考试批次列表（含补考批次）。
  Future<List<ExamBatch>> examBatches() async {
    final html = await _getAjax('/eams/stdExamTable.action');
    await _save('examBatches.html', html);
    return parseExamBatchesHtml(html);
  }

  /// 某批次考试安排（含补考）：课程/类别/日期/时段/地点/座位号/形式/链接。
  Future<ExamTableResult> examTable(int batchId) async {
    final html = await _getAjax('/eams/stdExamTable!examTable.action',
        {'examBatch.id': batchId.toString()});
    final file = await _save('examTable_$batchId.html', html);
    return {'batch_id': batchId, ...parseExamHtml(html), 'file': file};
  }

  /// 课外/资格考试报名与完成情况（四六级、计算机等级、体育测试等）。
  Future<OtherExamsResult> otherExams() async {
    final html = await _getAjax('/eams/stdOtherExamSignUp.action');
    final file = await _save('otherExamSignUp.html', html);
    return {...parseOtherExamsHtml(html), 'file': file};
  }

  /// 研究生中期考核申请信息（完整页面文本）。
  Future<MidtermResult> midterm({int? semesterId}) async {
    final html = await _getAjax(
        '/eams/postgraduate/midterm/stdExamine!content.action',
        semesterId != null ? {'semester.id': semesterId.toString()} : null);
    final file = await _save('midterm.html', html);
    return {...parseMidtermHtml(html), 'file': file};
  }

  // ================= 培养计划（PlanMixin） =================

  /// 培养计划完成情况：要求/实修学分、GPA、审核结果 + 分组课程明细。
  Future<PlanCompletionResult> planCompletion() async {
    final html = await _getAjax('/eams/myPlanCompl.action');
    final file = await _save('myPlanCompl.html', html);
    return {...parsePlanCompletionHtml(html), 'file': file};
  }

  /// 我的专业培养计划（嵌套表：分类/课程代码/学分/建议修读学期/院系）。
  Future<PlanByMajorResult> planByMajor() async {
    final html = await _getAjax('/eams/myPlanByMajor.action');
    final file = await _save('myPlanByMajor.html', html);
    return {'tables': parsePlanTablesHtml(html), 'file': file};
  }

  /// 专业培养方案（部分账号无权限，返回 `{"error": ...}`）。
  Future<MajorPlanResult> majorPlan() async {
    final html = await _getAjax('/eams/stdMajorPlan.action');
    final file = await _save('stdMajorPlan.html', html);
    final m = RegExp(r'color:\s*red[^>]*>([^<]+)<').firstMatch(html);
    if (m != null) {
      return {'error': m.group(1)!.trim(), 'file': file};
    }
    return {'tables': parsePlanTablesHtml(html), 'file': file};
  }

  /// 转专业申请页（完整：提示语 + 导航菜单链接）。
  Future<StdApplyResult> stdApply() async {
    final html = await _getAjax('/eams/stdApply.action');
    final file = await _save('stdApply.html', html);
    return {...parseStdApplyHtml(html), 'file': file};
  }

  // ================= 选课（ElectiveMixin） =================

  /// 选课入口：当前开放的选课轮次（名称/轮次/时间/限制/注意事项）。
  Future<List<ElectiveProfile>> electiveProfiles() async {
    final html = await _getAjax('/eams/stdElectCourse.action');
    await _save('electiveProfiles.html', html);
    return parseProfilesHtml(html);
  }

  /// 进入选课轮次，返回 `{profile_id, project_id, semester_id}`。
  Future<ElectiveContext> electiveContext(int profileId) async {
    final html = await _getAjax('/eams/stdElectCourse!defaultPage.action',
        {'electionProfile.id': profileId.toString()});
    await _save('electiveDefaultPage_$profileId.html', html);
    return parseElectiveContextHtml(html, profileId);
  }

  /// 选课课程列表（lessonJSONs：课程名/教师/学分/时间/地点/可退性）。
  Future<List<ElectiveLesson>> electiveLessons(int profileId) async {
    final html = await _getAjax(
        '/eams/stdElectCourse!data.action', {'profileId': profileId.toString()});
    final lessons = parseLessonsHtml(html);
    await _save(
        'electiveLessons_$profileId.json',
        lessons.isNotEmpty
            ? const JsonEncoder.withIndent('  ').convert(lessons)
            : html);
    return lessons;
  }

  /// 选课人数余量：`{lesson_id: {"sc": 已选人数, "lc": 人数上限}}`。
  Future<ElectiveCounts> electiveCounts(
      {int projectId = 1, int? semesterId}) async {
    final params = <String, String>{'projectId': projectId.toString()};
    if (semesterId != null) params['semesterId'] = semesterId.toString();
    final html =
        await _getAjax('/eams/stdElectCourse!queryStdCount.action', params);
    return parseCountsHtml(html);
  }

  /// 选课([elect]=true)/退课([elect]=false)。⚠ 写操作，调用方需自行确认。
  Future<ElectiveOperateResult> electiveOperate(
      {required int profileId,
      required int lessonId,
      required bool elect}) async {
    final data = elect
        ? {
            'optype': 'true',
            'operator0': '$lessonId:true:0',
            'lesson0': lessonId.toString(),
            'schLessonGroup_$lessonId': 'undefined',
          }
        : {
            'optype': 'false',
            'operator0': '$lessonId:false',
            'lesson0': lessonId.toString(),
          };
    final html = await _postAjax(
        '/eams/stdElectCourse!batchOperator.action', data,
        {'profileId': profileId.toString()});
    await _save(
        'electiveOp_${elect ? 'elect' : 'withdraw'}_$lessonId.html', html);
    return parseOperateResultHtml(html, lessonId, elect);
  }
}
