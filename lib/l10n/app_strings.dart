/// 应用国际化 —— 简体中文 / 繁体中文 / English / 日本語 / اردو。
///
/// - [supportedAppLocales] 支持的语言列表（供选择/排序）。
/// - [AppL10nScope] 响应式 InheritedWidget，当全局语言切换时瞬时驱动全树重绘。
/// - [localeProvider] / [appStringsProvider] 双向打通 [appSettingsProvider]。
/// - 页面通过 `context.l10n.xxx` 响应式提取文案，零延时实时切换。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings.dart';

/// 应用语言。
class AppLocale {
  const AppLocale(this.code, this.label);
  final String code;
  final String label;

  Locale get locale {
    if (code == 'zh-Hans') {
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN');
    } else if (code == 'zh-Hant') {
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW');
    } else if (code == 'ja') {
      return const Locale('ja', 'JP');
    } else if (code == 'ur') {
      return const Locale('ur', 'PK');
    }
    return const Locale('en', 'US');
  }

  bool get isRtl => code == 'ur';
}

const List<AppLocale> supportedAppLocales = [
  AppLocale('zh-Hans', '简体中文'),
  AppLocale('zh-Hant', '繁體中文'),
  AppLocale('en', 'English'),
  AppLocale('ja', '日本語'),
  AppLocale('ur', 'اردو'),
];

/// InheritedWidget 承载层，保证局部及跨层组件在语言切换时无刷新即刻响应。
class AppL10nScope extends InheritedWidget {
  const AppL10nScope({
    super.key,
    required this.strings,
    required this.locale,
    required super.child,
  });

  final AppStrings strings;
  final AppLocale locale;

  static AppL10nScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppL10nScope>();

  static AppL10nScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No AppL10nScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppL10nScope oldWidget) =>
      strings != oldWidget.strings || locale != oldWidget.locale;
}

/// 当前语言 Provider（与 AppSettings 保持同步联动）。
final localeProvider = Provider<AppLocale>((ref) {
  return ref.watch(appSettingsProvider.select((s) => s.locale));
});

/// 当前文案字典 Provider。
final appStringsProvider = Provider<AppStrings>((ref) {
  final code = ref.watch(appSettingsProvider.select((s) => s.locale.code));
  return AppStrings(code);
});

extension L10nContext on BuildContext {
  AppStrings get l10n {
    final scope = AppL10nScope.maybeOf(this);
    if (scope != null) return scope.strings;
    // 降级保护（在单元测试或无 Scope 作用域下安全读取）
    return const AppStrings('zh-Hans');
  }

  AppLocale get appLocale {
    final scope = AppL10nScope.maybeOf(this);
    if (scope != null) return scope.locale;
    return supportedAppLocales.first;
  }
}

// ---------------------------------------------------------------------------
// 文案字典
// ---------------------------------------------------------------------------

class AppStrings {
  const AppStrings(this._code);

  final String _code;

  static final Map<String, Map<String, String>> _t = {
    'zh-Hans': _zh,
    'zh-Hant': _zhTw,
    'en': _en,
    'ja': _ja,
    'ur': _ur,
  };

  Map<String, String> get _m => _t[_code] ?? _zh;

  String g(String key) => _m[key] ?? _zh[key] ?? key;

  // ---- 通用 ----
  String get cancel => g('cancel');
  String get ok => g('ok');
  String get close => g('close');
  String get retry => g('retry');
  String get emptyDefault => g('emptyDefault');

  // ---- 导航/标题 ----
  String get appName => g('appName');
  String get more => g('more');
  String get account => g('account');
  String get timetable => g('timetable');
  String get grades => g('grades');
  String get elective => g('elective');
  String get exam => g('exam');
  String get plan => g('plan');
  String get stdInfo => g('stdInfo');
  String get messages => g('messages');
  String get evaluate => g('evaluate');
  String get welcome => g('welcome');
  String get switchSemester => g('switchSemester');
  String get sync => g('sync');
  String get courseDetail => g('courseDetail');

  // ---- 中枢 ----
  String get hubWindow => g('hubWindow');
  String get hubData => g('hubData');
  String get hubAffair => g('hubAffair');

  // ---- 账户 ----
  String get accountInfo => g('accountInfo');
  String get accountSettings => g('accountSettings');
  String get accountManage => g('accountManage');
  String get accountManageSub => g('accountManageSub');
  String get syncSemester => g('syncSemester');
  String get syncSemesterSub => g('syncSemesterSub');
  String get clearCache => g('clearCache');
  String get clearCacheSub => g('clearCacheSub');
  String get about => g('about');
  String get aboutSub => g('aboutSub');
  String get logout => g('logout');
  String get logoutTitle => g('logoutTitle');
  String get logoutMsg => g('logoutMsg');
  String get clearCacheTitle => g('clearCacheTitle');
  String get clearCacheMsg => g('clearCacheMsg');
  String get cacheCleared => g('cacheCleared');
  String get semesterSynced => g('semesterSynced');
  String get offlineMode => g('offlineMode');

  // ---- 账号管理 ----
  String get bookTitle => g('bookTitle');
  String get addNewAccount => g('addNewAccount');
  String get rememberPwd => g('rememberPwd');
  String get addToBook => g('addToBook');
  String get switchAcct => g('switchAcct');
  String get deleteAccount => g('deleteAccount');
  String get deleteAccountMsg => g('deleteAccountMsg');
  String get remembered => g('remembered');
  String get notRemembered => g('notRemembered');
  String get noAccounts => g('noAccounts');
  String get addedToBook => g('addedToBook');

  // ---- 登录 ----
  String get loginTab => g('loginTab');
  String get bookTab => g('bookTab');
  String get username => g('username');
  String get password => g('password');
  String get rememberAcct => g('rememberAcct');
  String get loginBtn => g('loginBtn');
  String get autoLogin => g('autoLogin');
  String get autoLoginSub => g('autoLoginSub');
  String get startWithCache => g('startWithCache');
  String get startWithCacheSub => g('startWithCacheSub');
  String get enterFromCache => g('enterFromCache');
  String get retryLogin => g('retryLogin');
  String get offlineCacheToast => g('offlineCacheToast');
  String get noCacheAvailable => g('noCacheAvailable');
  String get needSms => g('needSms');
  String get smsSentTo => g('smsSentTo');
  String get smsHint => g('smsHint');
  String get verifyBtn => g('verifyBtn');
  String get resend => g('resend');
  String get resendNow => g('resendNow');
  String get saveToBook => g('saveToBook');
  String get accountExists => g('accountExists');

  // ---- 课表 ----
  String get weekLabel => g('weekLabel');
  String get offlineBanner => g('offlineBanner');
  String get teacher => g('teacher');
  String get room => g('room');
  String get clazz => g('clazz');
  String get periodUnit => g('periodUnit');

  // ---- 成绩 ----
  String get noGrades => g('noGrades');
  String get gradesDetail => g('gradesDetail');
  String get fromCache => g('fromCache');
  String get fromOnline => g('fromOnline');
  String get recordDetail => g('recordDetail');

  // ---- 考试 ----
  String get batchLoadFail => g('batchLoadFail');
  String get noBatches => g('noBatches');
  String get examArrange => g('examArrange');
  String get noExamArrange => g('noExamArrange');
  String get othersExam => g('othersExam');
  String get signup => g('signup');
  String get scores => g('scores');
  String get noSignups => g('noSignups');
  String get noScores => g('noScores');
  String get midterm => g('midterm');
  String get noMidterm => g('noMidterm');

  // ---- 选课 ----
  String get noProfiles => g('noProfiles');
  String get electiveProfiles => g('electiveProfiles');
  String get electOpen => g('electOpen');
  String get electClosed => g('electClosed');
  String get withdrawOpen => g('withdrawOpen');
  String get withdrawClosed => g('withdrawClosed');
  String get roundLabel => g('roundLabel');
  String get noLessons => g('noLessons');
  String get select => g('select');
  String get withdraw => g('withdraw');
  String get campus => g('campus');
  String get creditsLabel => g('creditsLabel');
  String get selectedOf => g('selectedOf');
  String get confirmSelectTitle => g('confirmSelectTitle');
  String get confirmWithdrawTitle => g('confirmWithdrawTitle');
  String get confirmSelectMsg => g('confirmSelectMsg');
  String get confirmWithdrawMsg => g('confirmWithdrawMsg');
  String get course => g('course');

  // ---- 培养计划 ----
  String get tabCompletion => g('tabCompletion');
  String get tabMyPlan => g('tabMyPlan');
  String get tabMajorPlan => g('tabMajorPlan');
  String get tabStdApply => g('tabStdApply');
  String get noPermission => g('noPermission');

  // ---- 学籍/消息/评价/欢迎 ----
  String get noStdInfo => g('noStdInfo');
  String get noMessages => g('noMessages');
  String get noSubject => g('noSubject');
  String get msgDetail => g('msgDetail');
  String get noDetail => g('noDetail');
  String get noEvaluate => g('noEvaluate');
  String get pendingTasks => g('pendingTasks');
  String get unnamedTask => g('unnamedTask');
  String get clickToView => g('clickToView');
  String get evalDetail => g('evalDetail');
  String get noAnnounce => g('noAnnounce');
  String get announcement => g('announcement');

  // ---- 主题模式 / 星期 / 补充 ----
  String get modeSystem => g('modeSystem');
  String get modeLight => g('modeLight');
  String get modeDark => g('modeDark');
  String get modeEye => g('modeEye');
  String get appearance => g('appearance');
  String get language => g('language');
  String get mon => g('mon');
  String get tue => g('tue');
  String get wed => g('wed');
  String get thu => g('thu');
  String get fri => g('fri');
  String get sat => g('sat');
  String get sun => g('sun');
  String get enterAcctPwd => g('enterAcctPwd');
  String get smsSent => g('smsSent');
  String get casHint => g('casHint');
  String get bookHint => g('bookHint');
  String get savedToBook => g('savedToBook');

  // ---- 选课增强 ----
  String get searchCourses => g('searchCourses');
  String get filterType => g('filterType');
  String get filterCampus => g('filterCampus');
  String get filterState => g('filterState');
  String get stateChooseable => g('stateChooseable');
  String get stateFull => g('stateFull');
  String get stateWithdrawable => g('stateWithdrawable');
  String get stateSelected => g('stateSelected');
  String get selectedBadge => g('selectedBadge');
  String get detail => g('detail');
  String get fieldName => g('fieldName');
  String get fieldType => g('fieldType');
  String get fieldCredits => g('fieldCredits');
  String get fieldTeachers => g('fieldTeachers');
  String get fieldCampus => g('fieldCampus');
  String get fieldCapacity => g('fieldCapacity');
  String get fieldClassNo => g('fieldClassNo');
  String get fieldCourseNo => g('fieldCourseNo');
  String get fieldDay => g('fieldDay');
  String get fieldTime => g('fieldTime');
  String get fieldWeeks => g('fieldWeeks');
  String get fieldMapNo => g('fieldMapNo');
  String get filterResults => g('filterResults');
  String get semesterWiki => g('semesterWiki');
  String get fieldSchedule => g('fieldSchedule');
  String get fieldPeriod => g('fieldPeriod');
  String get fieldRemark => g('fieldRemark');
  String get weekSuffix => g('weekSuffix');

  // ---- 问候与通用 ----
  String get student => g('student');
  String hello(String name) => g('hello').replaceAll('%1', name);
  String get systemTitle => g('systemTitle');
  String get appSlogan => g('appSlogan');
  String get quickSavedLogin => g('quickSavedLogin');
  String get currentBadge => g('currentBadge');
  String thisWeek(int w) => g('thisWeek').replaceAll('%1', '$w');
  String get jumpToWeek => g('jumpToWeek');
  String get selectSemesterOrWeek => g('selectSemesterOrWeek');
  String actualCurrentWeek(int w) => g('actualCurrentWeek').replaceAll('%1', '$w');
  String get noTimetable => g('noTimetable');
  String get pullToRefreshTimetable => g('pullToRefreshTimetable');
  String get syncTimetableOnline => g('syncTimetableOnline');
  String get copied => g('copied');
  String get roomCopied => g('roomCopied');
  String get copy => g('copy');
  String get fullTermWeekDistribution => g('fullTermWeekDistribution');
  String get darkColorIsActiveWeek => g('darkColorIsActiveWeek');
  String get collapseEvening => g('collapseEvening');
  String get expandEvening => g('expandEvening');
  String lessonsOverlapping(int count, String time) =>
      g('lessonsOverlapping').replaceAll('%1', '$count').replaceAll('%2', time);
  String get morning => g('morning');
  String get afternoon => g('afternoon');
  String get evening => g('evening');
  String get period1 => g('period1');
  String get period2 => g('period2');
  String get period3 => g('period3');
  String get period4 => g('period4');
  String get period5 => g('period5');
  String get period6 => g('period6');
  String get break30 => g('break30');
  String get noonBreak => g('noonBreak');
  String get break20 => g('break20');
  String get dinnerBreak => g('dinnerBreak');
  String get break10 => g('break10');

  // ---- 成绩增强 ----
  String get searchCoursePlaceholder => g('searchCoursePlaceholder');
  String get cardFlowView => g('cardFlowView');
  String get tableRawView => g('tableRawView');
  String get historySemesterGrades => g('historySemesterGrades');
  String get gpaLabel => g('gpaLabel');
  String get totalCreditsLabel => g('totalCreditsLabel');
  String get noGradesMatched => g('noGradesMatched');
  String get courseName => g('courseName');
  String get gpa => g('gpa');
  String get rawGradesDetail => g('rawGradesDetail');

  // ---- 学籍与关于 ----
  String studentIdNo(String id) => g('studentIdNo').replaceAll('%1', id);
  String get archiveInfo => g('archiveInfo');
  String get basicStudentDossier => g('basicStudentDossier');
  String get aboutAppDetail => g('aboutAppDetail');

  // ---- 评教与考试 ----
  String get evaluateClosed => g('evaluateClosed');
  String get examScoresObtained => g('examScoresObtained');
  String get examSignupRecords => g('examSignupRecords');
  String get examRoomCopied => g('examRoomCopied');
  String get examSubject => g('examSubject');
  String get examTime => g('examTime');
  String get examRoom => g('examRoom');
  String get examSeat => g('examSeat');
  String seatLabel(String s) => g('seatLabel').replaceAll('%1', s);

  // ---- 计划 ----
  String get noPlanByMajor => g('noPlanByMajor');
  String get noPlanMajor => g('noPlanMajor');
  String get noPlanCompletion => g('noPlanCompletion');
  String get creditsOverview => g('creditsOverview');
  String get moduleDetail => g('moduleDetail');
  String get courseScheme => g('courseScheme');
  String get noStdApply => g('noStdApply');
  String get affairChannel => g('affairChannel');

  // ---- 选课详情与标签 ----
  String lessonsCountSuffix(int count) => g('lessonsCountSuffix').replaceAll('%1', '$count');
  String coursesCountSuffix(int count) => g('coursesCountSuffix').replaceAll('%1', '$count');
  String courseCode(String code) => g('courseCode').replaceAll('%1', code);
  String get liveSeatsRemain => g('liveSeatsRemain');
  String get classNo => g('classNo');
  String get courseNature => g('courseNature');
  String get department => g('department');
  String get scheduleTimePlace => g('scheduleTimePlace');
  String get electiveAdvice => g('electiveAdvice');
  String get remarkNote => g('remarkNote');
  String get onlyAvailable => g('onlyAvailable');
  String get onlySelected => g('onlySelected');
  String get enrolledBadge => g('enrolledBadge');
  String enrolledOfCap(String sc, String lc) =>
      g('enrolledOfCap').replaceAll('%1', sc).replaceAll('%2', lc);
  String remainSeats(int r) => g('remainSeats').replaceAll('%1', '$r');
  String get fullSeats => g('fullSeats');
  String weekNumber(int w) => g('weekNumber').replaceAll('%1', '$w');
  String weekShort(int w) => g('weekShort').replaceAll('%1', '$w');
  String monthLabel(int m) => g('monthLabel').replaceAll('%1', '$m');

  // ---- 天文光照 ----
  String get solarAstroRhythm => g('solarAstroRhythm');
  String get solarAstroSub => g('solarAstroSub');
  String get sunrise => g('sunrise');
  String get solarNoon => g('solarNoon');
  String get sunset => g('sunset');
  String solarDayLengthBanner(String length) =>
      g('solarDayLengthBanner').replaceAll('%1', length);
  String get solarLightingDistribution => g('solarLightingDistribution');
}

// ---------------------------------------------------------------------------
// 五语文案
// ---------------------------------------------------------------------------

const Map<String, String> _zh = {
  'about': '关于',
  'aboutAppDetail': 'Grade\n版本: 2.5.31\n\n纯本地运行，不设后端中转，所有凭据仅加密保存于系统 Keychain/Keystore，数据绝不上传第三方。',
  'aboutSub': '长江大学教务课程表 · 仅供学习与研究',
  'account': '账户',
  'accountExists': '该账号已在账号簿中',
  'accountInfo': '账号',
  'accountManage': '账号管理',
  'accountManageSub': '多账号切换 / 登记 / 删除（密码安全存储）',
  'accountSettings': '数据与设置',
  'actualCurrentWeek': '当前实际为第 %1 周',
  'addNewAccount': '登记新账号',
  'addToBook': '添加到账号簿',
  'addedToBook': '已添加到账号簿',
  'affairChannel': '相关事务申请通道',
  'afternoon': '下午',
  'announcement': '公告',
  'appName': 'Grade',
  'appSlogan': '长江大学课表 · 成绩 · 选课助手',
  'appearance': '外观',
  'archiveInfo': '档案信息',
  'basicStudentDossier': '基本信息与学籍卡片',
  'batchLoadFail': '批次加载失败：%1',
  'bookHint': 'CAS 不支持在线注册。此处将账号登记到本机账号簿，便于多账号管理与一键切换登录。',
  'bookTab': '账号簿',
  'bookTitle': '本机账号簿',
  'break10': '课间 10m',
  'break20': '大课间 20m',
  'break30': '大课间 30m',
  'cacheCleared': '缓存已清除',
  'campus': '校区：%1',
  'cancel': '取消',
  'cardFlowView': '卡片流',
  'casHint': 'CAS 密码 POST 每次会话最多 1 次，失败不自动重试（防封号）；CASTGC 有效期内自动免密 SSO。',
  'classNo': '教学班号',
  'clazz': '教学班：%1',
  'clearCache': '清除本地缓存',
  'clearCacheMsg': '将删除课表/成绩等业务缓存（会话令牌与账号簿不受影响）。确定？',
  'clearCacheSub': '删除课表/成绩等缓存数据（会话令牌不受影响）',
  'clearCacheTitle': '清除本地缓存',
  'clickToView': '可评价 · 点击查看详情',
  'close': '关闭',
  'collapseEvening': '收起晚间作息',
  'confirmSelectMsg': '课程：%1\n\n确认选择该课程？',
  'confirmSelectTitle': '选课',
  'confirmWithdrawMsg': '课程：%1\n\n确认退选该课程？',
  'confirmWithdrawTitle': '退课',
  'copied': '已复制',
  'copy': '复制',
  'course': '该课程',
  'courseCode': '课程代码 %1',
  'courseDetail': '课程详情',
  'courseName': '课程名称',
  'courseNature': '课程性质',
  'courseScheme': '课程方案',
  'coursesCountSuffix': '%1 门',
  'creditsLabel': '%1 学分',
  'creditsOverview': '学分完成总览',
  'currentBadge': '当前',
  'darkColorIsActiveWeek': '深色为上课周',
  'deleteAccount': '删除账号',
  'deleteAccountMsg': '将删除账号 %1 及其本地保存的密码，确定？',
  'department': '开课院系',
  'detail': '课程详情',
  'dinnerBreak': '晚餐晚休',
  'electClosed': '选课未开放',
  'electOpen': '选课开放',
  'elective': '选课',
  'electiveAdvice': '选课建议',
  'electiveProfiles': '选课轮次',
  'emptyDefault': '暂无数据',
  'enrolledBadge': '已选课',
  'enrolledOfCap': '已选 %1 / 限额 %2',
  'enterAcctPwd': '请输入账号与密码',
  'evalDetail': '评价详情',
  'evaluate': '教学评价',
  'evaluateClosed': '当前学期评教通道未开启或已全部完成',
  'evening': '晚间',
  'exam': '考试',
  'examArrange': '考试安排',
  'examRoom': '考场',
  'examRoomCopied': '考场地点已复制',
  'examScoresObtained': '已获等级考试成绩',
  'examSeat': '座位号',
  'examSignupRecords': '等级考试报名记录',
  'examSubject': '考试科目',
  'examTime': '考试时间',
  'expandEvening': '晚间无排课 · 点击展开晚自习时段',
  'fieldCampus': '开课校区',
  'fieldCapacity': '已选 / 上限',
  'fieldClassNo': '教学班',
  'fieldCourseNo': '课程编号',
  'fieldCredits': '学分',
  'fieldDay': '上课星期',
  'fieldMapNo': '选课序号',
  'fieldName': '课程名称',
  'fieldPeriod': '总学时',
  'fieldRemark': '备注',
  'fieldSchedule': '上课安排',
  'fieldTeachers': '任课教师',
  'fieldTime': '上课时间',
  'fieldType': '课程类型',
  'fieldWeeks': '开课周次',
  'filterCampus': '校区',
  'filterResults': '筛选结果',
  'filterState': '状态',
  'filterType': '课程类型',
  'fri': '五',
  'fromCache': '本地缓存',
  'fromOnline': '在线',
  'fullSeats': '满员',
  'fullTermWeekDistribution': '全学期周次分布',
  'gpa': '绩点',
  'gpaLabel': '平均学分绩点',
  'grades': '成绩',
  'gradesDetail': '成绩明细',
  'hello': '你好，%1',
  'historySemesterGrades': '切换查看历史学期成绩',
  'hubAffair': '事务',
  'hubData': '数据查询',
  'hubWindow': '窗期高频',
  'jumpToWeek': '跳往指定周次',
  'language': '语言',
  'lessonsCountSuffix': '%1 门课程',
  'lessonsOverlapping': '共 %1 门课程时段重叠 · 长江大学 %2',
  'liveSeatsRemain': '选课实时余量',
  'loginBtn': '登 录',
  'autoLogin': '自动登录',
  'autoLoginSub': '下次打开自动登录刷新数据',
  'startWithCache': '下次缓存',
  'startWithCacheSub': '下次启动直接读取缓存渲染，不登录刷新',
  'enterFromCache': '从缓存进入',
  'retryLogin': '重试登录',
  'offlineCacheToast': '已从本地缓存进入（离线模式）',
  'noCacheAvailable': '当前账号暂无本地缓存数据',
  'loginTab': '登录',
  'logout': '登出',
  'logoutMsg': '将清除本地会话令牌（保留账号簿），确定登出？',
  'logoutTitle': '登出',
  'messages': '系统消息',
  'midterm': '中期考核',
  'modeDark': '暗色',
  'modeEye': '护眼',
  'modeLight': '亮色',
  'modeSystem': '跟随系统',
  'moduleDetail': '模块明细',
  'mon': '一',
  'monthLabel': '%1月',
  'more': '更多',
  'morning': '上午',
  'msgDetail': '消息详情',
  'needSms': '需要短信验证',
  'noAccounts': '暂无登记账号',
  'noAnnounce': '暂无公告',
  'noBatches': '暂无考试批次',
  'noDetail': '无详情',
  'noEvaluate': '暂无评教任务',
  'noExamArrange': '暂无考试安排',
  'noGrades': '本学期暂无成绩',
  'noGradesMatched': '未匹配到相关成绩记录',
  'noLessons': '该轮次暂无可选课程',
  'noMessages': '暂无消息',
  'noMidterm': '暂无中期考核内容',
  'noPermission': '无权限访问',
  'noPlanByMajor': '暂无我的计划数据',
  'noPlanCompletion': '暂无培养方案完成进度',
  'noPlanMajor': '暂无培养方案数据',
  'noProfiles': '暂无选课轮次',
  'noScores': '暂无成绩记录',
  'noSignups': '暂无报名记录',
  'noStdApply': '暂无转专业申请信息',
  'noStdInfo': '暂无学籍信息',
  'noSubject': '（无主题）',
  'noTimetable': '当前学期暂无课表记录',
  'noonBreak': '午休',
  'notRemembered': '未记住密码（需手动输入）',
  'offlineBanner': '离线模式：仅显示本地缓存数据，联网后可下拉刷新',
  'offlineMode': '离线模式：仅显示本地缓存数据，联网后可下拉刷新',
  'ok': '确定',
  'onlyAvailable': '仅有余量',
  'onlySelected': '仅看已选',
  'othersExam': '其他考试（四六级）',
  'password': '密码',
  'pendingTasks': '待评教学任务',
  'period1': '第1节',
  'period2': '第2节',
  'period3': '第3节',
  'period4': '第4节',
  'period5': '第5节',
  'period6': '第6节',
  'periodUnit': '第 %1 节',
  'plan': '培养计划',
  'pullToRefreshTimetable': '可尝试下拉刷新同步最新排课',
  'quickSavedLogin': '已存账号快速登入',
  'rawGradesDetail': '教务系统完整原始登记键值',
  'recordDetail': '课程明细',
  'remainSeats': '余 %1',
  'remarkNote': '备注说明',
  'rememberAcct': '记住账号密码（本机存储）',
  'rememberPwd': '记住密码（安全存储）',
  'remembered': '已记住密码',
  'resend': '重新发送',
  'resendNow': '重新发送验证码',
  'retry': '重试',
  'room': '教室：%1',
  'roomCopied': '教室地点已复制',
  'roundLabel': '%1（第%2期）',
  'sat': '六',
  'saveToBook': '保存到账号簿',
  'savedToBook': '已保存到账号簿',
  'scheduleTimePlace': '排课时间地点',
  'scores': '成绩',
  'searchCoursePlaceholder': '搜索课程名称或类型…',
  'searchCourses': '搜索课程名称',
  'seatLabel': '座位 %1',
  'select': '选课',
  'selectSemesterOrWeek': '选择学期或直接跳往指定周次',
  'selectedBadge': '已选',
  'selectedOf': '已选 %1 / %2',
  'semesterSynced': '学期已与服务器同步',
  'signup': '报名',
  'smsHint': '学校网关对本次登录启用了二次认证，请输入短信验证码',
  'smsSent': '已重新发送',
  'smsSentTo': '验证码已发送至 %1',
  'solarAstroRhythm': '校区光照与天文节律',
  'solarAstroSub': '长江大学 (30.33°N, 112.24°E) · 真实日照轨迹',
  'solarDayLengthBanner': '今日白昼总时长约 %1 · 课表左侧光轴与太阳高度角实时映射',
  'solarLightingDistribution': '作息时段自然采光分布',
  'solarNoon': '正午中天',
  'stateChooseable': '可选',
  'stateFull': '已满',
  'stateSelected': '已选',
  'stateWithdrawable': '可退',
  'stdInfo': '学籍信息',
  'student': '同学',
  'studentIdNo': '学号 %1',
  'sun': '日',
  'sunrise': '日出',
  'sunset': '日落',
  'switchAcct': '切换',
  'switchSemester': '切换学期',
  'sync': '同步',
  'syncSemester': '学期网络同步',
  'syncSemesterSub': '从服务器校正学期列表与当前学期',
  'syncTimetableOnline': '在线拉取课表',
  'systemTitle': '长江大学教务系统',
  'tabCompletion': '完成度',
  'tabMajorPlan': '培养方案',
  'tabMyPlan': '我的计划',
  'tabStdApply': '转专业申请',
  'tableRawView': '原始表',
  'teacher': '教师：%1',
  'thisWeek': '本周 %1',
  'thu': '四',
  'timetable': '课表',
  'totalCreditsLabel': '修读总学分',
  'tue': '二',
  'unnamedTask': '（未命名任务）',
  'username': '学号/工号',
  'verifyBtn': '验 证',
  'wed': '三',
  'weekLabel': '第 %1 周 / 共 %2 周',
  'weekNumber': '第 %1 周',
  'weekShort': '%1周',
  'weekSuffix': '周',
  'welcome': '欢迎 / 公告',
  'withdraw': '退课',
  'withdrawClosed': '退课未开放',
  'withdrawOpen': '退课开放',
};

const Map<String, String> _zhTw = {
  'about': '關於',
  'aboutAppDetail': 'Grade\n版本: 2.5.31\n\n純本機運行，不設後端中轉，所有憑據僅加密保存於系統 Keychain/Keystore，數據絕不上傳第三方。',
  'aboutSub': '長江大學教務課程表 · 僅供學習與研究',
  'account': '帳戶',
  'accountExists': '該帳號已在帳號簿中',
  'accountInfo': '帳號',
  'accountManage': '帳號管理',
  'accountManageSub': '多帳號切換 / 登記 / 刪除（密碼安全儲存）',
  'accountSettings': '資料與設定',
  'actualCurrentWeek': '當前實際為第 %1 週',
  'addNewAccount': '登記新帳號',
  'addToBook': '新增到帳號簿',
  'addedToBook': '已新增到帳號簿',
  'affairChannel': '相關事務申請通道',
  'afternoon': '下午',
  'announcement': '公告',
  'appName': 'Grade',
  'appSlogan': '長江大學課表 · 成績 · 選課助手',
  'appearance': '外觀',
  'archiveInfo': '檔案資訊',
  'basicStudentDossier': '基本資訊與學籍卡片',
  'batchLoadFail': '批次載入失敗：%1',
  'bookHint': 'CAS 不支援線上註冊。此處將帳號登記到本機帳號簿，便於多帳號管理與一鍵切換登入。',
  'bookTab': '帳號簿',
  'bookTitle': '本機帳號簿',
  'break10': '課間 10m',
  'break20': '大課間 20m',
  'break30': '大課間 30m',
  'cacheCleared': '快取已清除',
  'campus': '校區：%1',
  'cancel': '取消',
  'cardFlowView': '卡片流',
  'casHint': 'CAS 密碼 POST 每次會話最多 1 次，失敗不自動重試（防封號）；CASTGC 有效期內自動免密 SSO。',
  'classNo': '教學班號',
  'clazz': '教學班：%1',
  'clearCache': '清除本機快取',
  'clearCacheMsg': '將刪除課表/成績等業務快取（會話權杖與帳號簿不受影響）。確定？',
  'clearCacheSub': '刪除課表/成績等快取資料（會話權杖不受影響）',
  'clearCacheTitle': '清除本機快取',
  'clickToView': '可評價 · 點擊查看詳情',
  'close': '關閉',
  'collapseEvening': '收起晚間作息',
  'confirmSelectMsg': '課程：%1\n\n確認選擇該課程？',
  'confirmSelectTitle': '選課',
  'confirmWithdrawMsg': '課程：%1\n\n確認退選該課程？',
  'confirmWithdrawTitle': '退課',
  'copied': '已複製',
  'copy': '複製',
  'course': '該課程',
  'courseCode': '課程代碼 %1',
  'courseDetail': '課程詳情',
  'courseName': '課程名稱',
  'courseNature': '課程性質',
  'courseScheme': '課程方案',
  'coursesCountSuffix': '%1 門',
  'creditsLabel': '%1 學分',
  'creditsOverview': '學分完成總覽',
  'currentBadge': '當前',
  'darkColorIsActiveWeek': '深色為上課週',
  'deleteAccount': '刪除帳號',
  'deleteAccountMsg': '將刪除帳號 %1 及其本機儲存的密碼，確定？',
  'department': '開課院系',
  'detail': '課程詳情',
  'dinnerBreak': '晚餐晚休',
  'electClosed': '選課未開放',
  'electOpen': '選課開放',
  'elective': '選課',
  'electiveAdvice': '選課建議',
  'electiveProfiles': '選課輪次',
  'emptyDefault': '暫無資料',
  'enrolledBadge': '已選課',
  'enrolledOfCap': '已選 %1 / 限額 %2',
  'enterAcctPwd': '請輸入帳號與密碼',
  'evalDetail': '評價詳情',
  'evaluate': '教學評價',
  'evaluateClosed': '當前學期評教通道未開啟或已全部完成',
  'evening': '晚間',
  'exam': '考試',
  'examArrange': '考試安排',
  'examRoom': '考場',
  'examRoomCopied': '考場地點已複製',
  'examScoresObtained': '已獲等級考試成績',
  'examSeat': '座位號',
  'examSignupRecords': '等級考試報名記錄',
  'examSubject': '考試科目',
  'examTime': '考試時間',
  'expandEvening': '晚間無排課 · 點擊展開晚自習時段',
  'fieldCampus': '開課校區',
  'fieldCapacity': '已選 / 上限',
  'fieldClassNo': '教學班',
  'fieldCourseNo': '課程編號',
  'fieldCredits': '學分',
  'fieldDay': '上課星期',
  'fieldMapNo': '選課序號',
  'fieldName': '課程名稱',
  'fieldPeriod': '總學時',
  'fieldRemark': '備註',
  'fieldSchedule': '上課安排',
  'fieldTeachers': '任課教師',
  'fieldTime': '上課時間',
  'fieldType': '課程類型',
  'fieldWeeks': '開課週次',
  'filterCampus': '校區',
  'filterResults': '篩選結果',
  'filterState': '狀態',
  'filterType': '課程類型',
  'fri': '五',
  'fromCache': '本機快取',
  'fromOnline': '線上',
  'fullSeats': '滿員',
  'fullTermWeekDistribution': '全學期週次分布',
  'gpa': '績點',
  'gpaLabel': '平均學分績點',
  'grades': '成績',
  'gradesDetail': '成績明細',
  'hello': '你好，%1',
  'historySemesterGrades': '切換查看歷史學期成績',
  'hubAffair': '事務',
  'hubData': '資料查詢',
  'hubWindow': '窗期高頻',
  'jumpToWeek': '跳往指定週次',
  'language': '語言',
  'lessonsCountSuffix': '%1 門課程',
  'lessonsOverlapping': '共 %1 門課程時段重疊 · 長江大學 %2',
  'liveSeatsRemain': '選課即時餘量',
  'loginBtn': '登 入',
  'autoLogin': '自動登入',
  'autoLoginSub': '下次打開自動登入刷新資料',
  'startWithCache': '下次快取',
  'startWithCacheSub': '下次啟動直接讀取快取渲染，不登入刷新',
  'enterFromCache': '從快取進入',
  'retryLogin': '重試登入',
  'offlineCacheToast': '已從本機快取進入（離線模式）',
  'noCacheAvailable': '當前帳號暫無本機快取資料',
  'loginTab': '登入',
  'logout': '登出',
  'logoutMsg': '將清除本機會話權杖（保留帳號簿），確定登出？',
  'logoutTitle': '登出',
  'messages': '系統訊息',
  'midterm': '中期考核',
  'modeDark': '暗色',
  'modeEye': '護眼',
  'modeLight': '亮色',
  'modeSystem': '跟隨系統',
  'moduleDetail': '模組明細',
  'mon': '一',
  'monthLabel': '%1月',
  'more': '更多',
  'morning': '上午',
  'msgDetail': '訊息詳情',
  'needSms': '需要簡訊驗證',
  'noAccounts': '暫無登記帳號',
  'noAnnounce': '暫無公告',
  'noBatches': '暫無考試批次',
  'noDetail': '無詳情',
  'noEvaluate': '暫無評教任務',
  'noExamArrange': '暫無考試安排',
  'noGrades': '本學期暫無成績',
  'noGradesMatched': '未匹配到相關成績記錄',
  'noLessons': '該輪次暫無可選課程',
  'noMessages': '暫無訊息',
  'noMidterm': '暫無中期考核內容',
  'noPermission': '無權限訪問',
  'noPlanByMajor': '暫無我的計劃資料',
  'noPlanCompletion': '暫無培養方案完成進度',
  'noPlanMajor': '暫無培養方案資料',
  'noProfiles': '暫無選課輪次',
  'noScores': '暫無成績記錄',
  'noSignups': '暫無報名記錄',
  'noStdApply': '暫無轉專業申請資訊',
  'noStdInfo': '暫無學籍資訊',
  'noSubject': '（無主題）',
  'noTimetable': '當前學期暫無課表記錄',
  'noonBreak': '午休',
  'notRemembered': '未記住密碼（需手動輸入）',
  'offlineBanner': '離線模式：僅顯示本機快取資料，連網後可下拉重新整理',
  'offlineMode': '離線模式：僅顯示本機快取資料，連網後可下拉重新整理',
  'ok': '確定',
  'onlyAvailable': '僅有餘量',
  'onlySelected': '僅看已選',
  'othersExam': '其他考試（四六級）',
  'password': '密碼',
  'pendingTasks': '待評教學任務',
  'period1': '第1節',
  'period2': '第2節',
  'period3': '第3節',
  'period4': '第4節',
  'period5': '第5節',
  'period6': '第6節',
  'periodUnit': '第 %1 節',
  'plan': '培養計劃',
  'pullToRefreshTimetable': '可嘗試下拉重新整理同步最新排課',
  'quickSavedLogin': '已存帳號快速登入',
  'rawGradesDetail': '教務系統完整原始登記鍵值',
  'recordDetail': '課程明細',
  'remainSeats': '餘 %1',
  'remarkNote': '備註說明',
  'rememberAcct': '記住帳號密碼（本機儲存）',
  'rememberPwd': '記住密碼（安全儲存）',
  'remembered': '已記住密碼',
  'resend': '重新傳送',
  'resendNow': '重新傳送驗證碼',
  'retry': '重試',
  'room': '教室：%1',
  'roomCopied': '教室地點已複製',
  'roundLabel': '%1（第%2期）',
  'sat': '六',
  'saveToBook': '儲存到帳號簿',
  'savedToBook': '已儲存到帳號簿',
  'scheduleTimePlace': '排課時間地點',
  'scores': '成績',
  'searchCoursePlaceholder': '搜尋課程名稱或類型…',
  'searchCourses': '搜尋課程名稱',
  'seatLabel': '座位 %1',
  'select': '選課',
  'selectSemesterOrWeek': '選擇學期或直接跳往指定週次',
  'selectedBadge': '已選',
  'selectedOf': '已選 %1 / %2',
  'semesterSynced': '學期已與伺服器同步',
  'signup': '報名',
  'smsHint': '學校閘道對本次登入啟用了二次認證，請輸入簡訊驗證碼',
  'smsSent': '已重新傳送',
  'smsSentTo': '驗證碼已傳送至 %1',
  'solarAstroRhythm': '校區光照與天文節律',
  'solarAstroSub': '長江大學 (30.33°N, 112.24°E) · 真實日照軌跡',
  'solarDayLengthBanner': '今日白晝總時長約 %1 · 課表左側光軸與太陽高度角即時映射',
  'solarLightingDistribution': '作息時段自然採光分布',
  'solarNoon': '正午中天',
  'stateChooseable': '可選',
  'stateFull': '已滿',
  'stateSelected': '已選',
  'stateWithdrawable': '可退',
  'stdInfo': '學籍資訊',
  'student': '同學',
  'studentIdNo': '學號 %1',
  'sun': '日',
  'sunrise': '日出',
  'sunset': '日落',
  'switchAcct': '切換',
  'switchSemester': '切換學期',
  'sync': '同步',
  'syncSemester': '學期網路同步',
  'syncSemesterSub': '從伺服器校正學期列表與當前學期',
  'syncTimetableOnline': '線上拉取課表',
  'systemTitle': '長江大學教務系統',
  'tabCompletion': '完成度',
  'tabMajorPlan': '培養方案',
  'tabMyPlan': '我的計劃',
  'tabStdApply': '轉專業申請',
  'tableRawView': '原始表',
  'teacher': '教師：%1',
  'thisWeek': '本週 %1',
  'thu': '四',
  'timetable': '課表',
  'totalCreditsLabel': '修讀總學分',
  'tue': '二',
  'unnamedTask': '（未命名任務）',
  'username': '學號/工號',
  'verifyBtn': '驗 證',
  'wed': '三',
  'weekLabel': '第 %1 週 / 共 %2 週',
  'weekNumber': '第 %1 週',
  'weekShort': '%1週',
  'weekSuffix': '週',
  'welcome': '歡迎 / 公告',
  'withdraw': '退課',
  'withdrawClosed': '退課未開放',
  'withdrawOpen': '退課開放',
};

const Map<String, String> _en = {
  'about': 'About',
  'aboutAppDetail': 'Grade\nVersion: 2.5.31\n\nRuns purely locally with no intermediate server. All credentials are encrypted in system Keychain/Keystore. Data is never uploaded to third parties.',
  'aboutSub': 'Yangtze University timetable · For study only',
  'account': 'Account',
  'accountExists': 'This account already exists',
  'accountInfo': 'Account',
  'accountManage': 'Account Management',
  'accountManageSub': 'Switch / add / remove accounts (secure storage)',
  'accountSettings': 'Data & Settings',
  'actualCurrentWeek': 'Currently week %1',
  'addNewAccount': 'Add New Account',
  'addToBook': 'Add to Account Book',
  'addedToBook': 'Added to account book',
  'affairChannel': 'Academic Requests Channel',
  'afternoon': 'Afternoon',
  'announcement': 'Notice',
  'appName': 'Grade',
  'appSlogan': 'Yangtze University Timetable, Grades & Electives',
  'appearance': 'Appearance',
  'archiveInfo': 'Student Dossier',
  'basicStudentDossier': 'Basic info & student card',
  'batchLoadFail': 'Failed to load batches: %1',
  'bookHint': 'CAS has no online registration. Save accounts to the local book for quick switching and login.',
  'bookTab': 'Accounts',
  'bookTitle': 'Account Book',
  'break10': 'Break 10m',
  'break20': 'Recess 20m',
  'break30': 'Recess 30m',
  'cacheCleared': 'Cache cleared',
  'campus': 'Campus: %1',
  'cancel': 'Cancel',
  'cardFlowView': 'Cards',
  'casHint': 'CAS password POST is limited to 1 per session and never auto-retries (anti-lock). SSO is used while CASTGC is valid.',
  'classNo': 'Class No.',
  'clazz': 'Class: %1',
  'clearCache': 'Clear Local Cache',
  'clearCacheMsg': 'Remove timetable/grades cache. Session & account book kept. Continue?',
  'clearCacheSub': 'Remove timetable/grades cache (session unaffected)',
  'clearCacheTitle': 'Clear Local Cache',
  'clickToView': 'Evaluable · Tap for details',
  'close': 'Close',
  'collapseEvening': 'Collapse evening',
  'confirmSelectMsg': 'Course: %1\n\nEnroll in this course?',
  'confirmSelectTitle': 'Enroll',
  'confirmWithdrawMsg': 'Course: %1\n\nWithdraw from this course?',
  'confirmWithdrawTitle': 'Withdraw',
  'copied': 'Copied',
  'copy': 'Copy',
  'course': 'this course',
  'courseCode': 'Code %1',
  'courseDetail': 'Course Detail',
  'courseName': 'Course Name',
  'courseNature': 'Category',
  'courseScheme': 'Course Scheme',
  'coursesCountSuffix': '%1 courses',
  'creditsLabel': '%1 credits',
  'creditsOverview': 'Credits Overview',
  'currentBadge': 'Current',
  'darkColorIsActiveWeek': 'Dark cells indicate active weeks',
  'deleteAccount': 'Delete Account',
  'deleteAccountMsg': 'Delete account %1 and its saved password?',
  'department': 'Department',
  'detail': 'Course Detail',
  'dinnerBreak': 'Dinner Break',
  'electClosed': 'Enroll Closed',
  'electOpen': 'Enroll Open',
  'elective': 'Electives',
  'electiveAdvice': 'Enrollment Advice',
  'electiveProfiles': 'Elective Rounds',
  'emptyDefault': 'No data',
  'enrolledBadge': 'Enrolled',
  'enrolledOfCap': 'Enrolled %1 / Cap %2',
  'enterAcctPwd': 'Enter ID and password',
  'evalDetail': 'Evaluation Detail',
  'evaluate': 'Evaluation',
  'evaluateClosed': 'Evaluation is closed or all completed',
  'evening': 'Evening',
  'exam': 'Exams',
  'examArrange': 'Exam Schedule',
  'examRoom': 'Room',
  'examRoomCopied': 'Exam room copied',
  'examScoresObtained': 'Proficiency Test Scores',
  'examSeat': 'Seat No.',
  'examSignupRecords': 'Exam Registrations',
  'examSubject': 'Subject',
  'examTime': 'Time',
  'expandEvening': 'No evening classes · Tap to expand study periods',
  'fieldCampus': 'Campus',
  'fieldCapacity': 'Enrolled / Cap',
  'fieldClassNo': 'Class',
  'fieldCourseNo': 'Course No.',
  'fieldCredits': 'Credits',
  'fieldDay': 'Day',
  'fieldMapNo': 'Map No.',
  'fieldName': 'Course',
  'fieldPeriod': 'Hours',
  'fieldRemark': 'Note',
  'fieldSchedule': 'Schedule',
  'fieldTeachers': 'Instructors',
  'fieldTime': 'Time',
  'fieldType': 'Type',
  'fieldWeeks': 'Weeks',
  'filterCampus': 'Campus',
  'filterResults': 'Filtered Results',
  'filterState': 'Status',
  'filterType': 'Type',
  'fri': 'Fri',
  'fromCache': 'cached',
  'fromOnline': 'online',
  'fullSeats': 'Full',
  'fullTermWeekDistribution': 'Full Term Week Distribution',
  'gpa': 'GPA',
  'gpaLabel': 'GPA',
  'grades': 'Grades',
  'gradesDetail': 'Grade Detail',
  'hello': 'Hello, %1',
  'historySemesterGrades': 'Switch to view past semesters',
  'hubAffair': 'Messages & Tasks',
  'hubData': 'Queries',
  'hubWindow': 'High Frequency',
  'jumpToWeek': 'Jump to Week',
  'language': 'Language',
  'lessonsCountSuffix': '%1 courses',
  'lessonsOverlapping': '%1 courses overlapping · %2',
  'liveSeatsRemain': 'Available Seats',
  'loginBtn': 'Sign In',
  'autoLogin': 'Auto Login',
  'autoLoginSub': 'Auto log in & refresh on next launch',
  'startWithCache': 'Next from Cache',
  'startWithCacheSub': 'Launch instantly from cache without login',
  'enterFromCache': 'Enter from Cache',
  'retryLogin': 'Retry Login',
  'offlineCacheToast': 'Entered from local cache (Offline Mode)',
  'noCacheAvailable': 'No local cache found for this account',
  'loginTab': 'Sign In',
  'logout': 'Log Out',
  'logoutMsg': 'Clear local session token (keep account book). Log out?',
  'logoutTitle': 'Log Out',
  'messages': 'Messages',
  'midterm': 'Mid-term Assessment',
  'modeDark': 'Dark',
  'modeEye': 'Eye Care',
  'modeLight': 'Light',
  'modeSystem': 'Follow System',
  'moduleDetail': 'Module Details',
  'mon': 'Mon',
  'monthLabel': 'Month %1',
  'more': 'More',
  'morning': 'Morning',
  'msgDetail': 'Message Detail',
  'needSms': 'SMS Verification',
  'noAccounts': 'No saved accounts',
  'noAnnounce': 'No notices',
  'noBatches': 'No exam batches',
  'noDetail': 'No details',
  'noEvaluate': 'No evaluation tasks',
  'noExamArrange': 'No exam schedule',
  'noGrades': 'No grades for this semester',
  'noGradesMatched': 'No matching grade records found',
  'noLessons': 'No courses in this round',
  'noMessages': 'No messages',
  'noMidterm': 'No mid-term content',
  'noPermission': 'No access permission',
  'noPlanByMajor': 'No personal curriculum data',
  'noPlanCompletion': 'No progress data',
  'noPlanMajor': 'No program plan data',
  'noProfiles': 'No elective rounds',
  'noScores': 'No score records',
  'noSignups': 'No sign-up records',
  'noStdApply': 'No major transfer requests',
  'noStdInfo': 'No student info',
  'noSubject': '(No subject)',
  'noTimetable': 'No timetable for current semester',
  'noonBreak': 'Lunch Break',
  'notRemembered': 'Password not saved (enter manually)',
  'offlineBanner': 'Offline: showing cached data only, pull to refresh when online',
  'offlineMode': 'Offline: showing cached data only, pull to refresh when online',
  'ok': 'OK',
  'onlyAvailable': 'Available only',
  'onlySelected': 'Enrolled only',
  'othersExam': 'Other Exams (CET)',
  'password': 'Password',
  'pendingTasks': 'Pending Evaluations',
  'period1': 'Period 1',
  'period2': 'Period 2',
  'period3': 'Period 3',
  'period4': 'Period 4',
  'period5': 'Period 5',
  'period6': 'Period 6',
  'periodUnit': 'Period %1',
  'plan': 'Curriculum',
  'pullToRefreshTimetable': 'Pull to refresh to sync latest timetable',
  'quickSavedLogin': 'Quick sign-in with saved accounts',
  'rawGradesDetail': 'EAMS complete raw record fields',
  'recordDetail': 'Course Detail',
  'remainSeats': '%1 left',
  'remarkNote': 'Notes',
  'rememberAcct': 'Remember account (stored locally)',
  'rememberPwd': 'Remember password (secure storage)',
  'remembered': 'Password saved',
  'resend': 'Resend',
  'resendNow': 'Resend code',
  'retry': 'Retry',
  'room': 'Room: %1',
  'roomCopied': 'Classroom location copied',
  'roundLabel': '%1 (Round %2)',
  'sat': 'Sat',
  'saveToBook': 'Save to Account Book',
  'savedToBook': 'Saved to account book',
  'scheduleTimePlace': 'Schedule & Location',
  'scores': 'Scores',
  'searchCoursePlaceholder': 'Search course name or type...',
  'searchCourses': 'Search course name',
  'seatLabel': 'Seat %1',
  'select': 'Enroll',
  'selectSemesterOrWeek': 'Select semester or jump to week',
  'selectedBadge': 'Selected',
  'selectedOf': '%1 / %2 enrolled',
  'semesterSynced': 'Semester synced with server',
  'signup': 'Sign-up',
  'smsHint': 'The gateway enabled two-factor auth for this sign-in. Enter the SMS code.',
  'smsSent': 'Resent',
  'smsSentTo': 'Code sent to %1',
  'solarAstroRhythm': 'Solar Rhythm & Natural Light',
  'solarAstroSub': 'Yangtze University (30.33°N, 112.24°E) · Solar Trajectory',
  'solarDayLengthBanner': 'Daylight length ~%1 · Optical axis mapped to solar elevation angle',
  'solarLightingDistribution': 'Natural Lighting by Study Period',
  'solarNoon': 'Solar Noon',
  'stateChooseable': 'Open',
  'stateFull': 'Full',
  'stateSelected': 'Selected',
  'stateWithdrawable': 'Withdrawable',
  'stdInfo': 'Student Info',
  'student': 'Student',
  'studentIdNo': 'ID: %1',
  'sun': 'Sun',
  'sunrise': 'Sunrise',
  'sunset': 'Sunset',
  'switchAcct': 'Switch',
  'switchSemester': 'Switch Semester',
  'sync': 'Sync',
  'syncSemester': 'Sync Semester Online',
  'syncSemesterSub': 'Correct semester list from server',
  'syncTimetableOnline': 'Fetch Timetable Online',
  'systemTitle': 'Yangtze University EAMS',
  'tabCompletion': 'Progress',
  'tabMajorPlan': 'Program Plan',
  'tabMyPlan': 'My Curriculum',
  'tabStdApply': 'Major Transfer',
  'tableRawView': 'Table',
  'teacher': 'Teacher: %1',
  'thisWeek': 'Week %1',
  'thu': 'Thu',
  'timetable': 'Timetable',
  'totalCreditsLabel': 'Total Credits',
  'tue': 'Tue',
  'unnamedTask': '(Unnamed task)',
  'username': 'Student/Staff ID',
  'verifyBtn': 'Verify',
  'wed': 'Wed',
  'weekLabel': 'Week %1 of %2',
  'weekNumber': 'Week %1',
  'weekShort': 'W%1',
  'weekSuffix': 'wks',
  'welcome': 'Welcome / Notices',
  'withdraw': 'Withdraw',
  'withdrawClosed': 'Withdraw Closed',
  'withdrawOpen': 'Withdraw Open',
};

const Map<String, String> _ja = {
  'about': 'このアプリについて',
  'aboutAppDetail': 'Grade\nバージョン: 2.5.31\n\n完全ローカル実行、中継サーバー不使用。すべての資格情報は端末のKeychain/Keystoreに暗号化保存され、外部送信されません。',
  'aboutSub': '長江大学の時間割 · 学習目的専用',
  'account': 'アカウント',
  'accountExists': 'このアカウントは既に登録されています',
  'accountInfo': 'アカウント',
  'accountManage': 'アカウント管理',
  'accountManageSub': '切替・登録・削除（パスワードは安全保管）',
  'accountSettings': 'データと設定',
  'actualCurrentWeek': '現在は第 %1 週',
  'addNewAccount': '新規アカウント登録',
  'addToBook': 'アカウント帳に追加',
  'addedToBook': 'アカウント帳に追加しました',
  'affairChannel': '各種申請窓口',
  'afternoon': '午後',
  'announcement': 'お知らせ',
  'appName': 'Grade',
  'appSlogan': '長江大学 時間割・成績・履修アシスタント',
  'appearance': '外観',
  'archiveInfo': '学籍アーカイブ',
  'basicStudentDossier': '基本情報と学籍カード',
  'batchLoadFail': 'バッチの読み込みに失敗：%1',
  'bookHint': 'CAS にオンライン登録はありません。ローカルのアカウント帳に保存して、素早く切り替えてログインできます。',
  'bookTab': 'アカウント',
  'bookTitle': 'アカウント帳',
  'break10': '休憩 10分',
  'break20': '大休憩 20分',
  'break30': '大休憩 30分',
  'cacheCleared': 'キャッシュを消去しました',
  'campus': 'キャンパス：%1',
  'cancel': 'キャンセル',
  'cardFlowView': 'カード',
  'casHint': 'CAS のパスワード POST はセッションごとに 1 回のみ、自動再試行しません（ロック防止）。CASTGC 有効中は SSO を利用します。',
  'classNo': 'クラス番号',
  'clazz': 'クラス：%1',
  'clearCache': 'キャッシュを消去',
  'clearCacheMsg': '時間割・成績のキャッシュを削除します（セッションとアカウント帳は保持）。続行しますか？',
  'clearCacheSub': '時間割・成績のキャッシュを削除（セッションは影響なし）',
  'clearCacheTitle': 'キャッシュを消去',
  'clickToView': '評価可能 · タップで詳細',
  'close': '閉じる',
  'collapseEvening': '夜間を折りたたむ',
  'confirmSelectMsg': 'コース：%1\n\nこのコースを履修しますか？',
  'confirmSelectTitle': '履修登録',
  'confirmWithdrawMsg': 'コース：%1\n\nこのコースを取消しますか？',
  'confirmWithdrawTitle': '履修取消',
  'copied': 'コピーしました',
  'copy': 'コピー',
  'course': 'このコース',
  'courseCode': 'コード %1',
  'courseDetail': 'コース詳細',
  'courseName': 'コース名',
  'courseNature': '区分',
  'courseScheme': 'コース計画',
  'coursesCountSuffix': '%1 科目',
  'creditsLabel': '%1 単位',
  'creditsOverview': '単位修得状況',
  'currentBadge': '現在',
  'darkColorIsActiveWeek': '濃い色は授業週です',
  'deleteAccount': 'アカウントを削除',
  'deleteAccountMsg': 'アカウント %1 と保存済みパスワードを削除しますか？',
  'department': '学部・学科',
  'detail': 'コース詳細',
  'dinnerBreak': '夕食・夕休み',
  'electClosed': '登録受付外',
  'electOpen': '登録受付中',
  'elective': '履修登録',
  'electiveAdvice': '履修アドバイス',
  'electiveProfiles': '履修ラウンド',
  'emptyDefault': 'データがありません',
  'enrolledBadge': '登録済み',
  'enrolledOfCap': '履修中 %1 / 上限 %2',
  'enterAcctPwd': 'アカウントとパスワードを入力してください',
  'evalDetail': '評価詳細',
  'evaluate': '授業評価',
  'evaluateClosed': '授業評価は現在受付外または完了済みです',
  'evening': '夜間',
  'exam': '試験',
  'examArrange': '試験日程',
  'examRoom': '教室',
  'examRoomCopied': '試験会場をコピーしました',
  'examScoresObtained': '取得済み試験成績',
  'examSeat': '座席番号',
  'examSignupRecords': '試験申込履歴',
  'examSubject': '科目',
  'examTime': '時間',
  'expandEvening': '夜間の授業なし · タップして自習時間を展開',
  'fieldCampus': 'キャンパス',
  'fieldCapacity': '履修中 / 上限',
  'fieldClassNo': 'クラス',
  'fieldCourseNo': 'コース番号',
  'fieldCredits': '単位',
  'fieldDay': '曜日',
  'fieldMapNo': 'マップ番号',
  'fieldName': 'コース名',
  'fieldPeriod': '総時間',
  'fieldRemark': '備考',
  'fieldSchedule': '時間割',
  'fieldTeachers': '担当教員',
  'fieldTime': '時間',
  'fieldType': 'タイプ',
  'fieldWeeks': '週',
  'filterCampus': 'キャンパス',
  'filterResults': '絞り込み結果',
  'filterState': '状態',
  'filterType': 'タイプ',
  'fri': '金',
  'fromCache': 'キャッシュ',
  'fromOnline': 'オンライン',
  'fullSeats': '満員',
  'fullTermWeekDistribution': '全学期の週分布',
  'gpa': 'GPA',
  'gpaLabel': 'GPA',
  'grades': '成績',
  'gradesDetail': '成績詳細',
  'hello': 'こんにちは、%1',
  'historySemesterGrades': '過去の学期の成績を表示',
  'hubAffair': 'メッセージ・タスク',
  'hubData': 'データ照会',
  'hubWindow': '利用頻度が高い',
  'jumpToWeek': '指定週に移動',
  'language': '言語',
  'lessonsCountSuffix': '%1 コース',
  'lessonsOverlapping': '%1 件のコースが重複 · %2',
  'liveSeatsRemain': '空席状況',
  'loginBtn': 'ログイン',
  'autoLogin': '自動ログイン',
  'autoLoginSub': '次回起動時に自動ログインして更新',
  'startWithCache': '次回キャッシュ',
  'startWithCacheSub': '次回起動時にキャッシュから即時起動',
  'enterFromCache': 'キャッシュから入る',
  'retryLogin': '再試行',
  'offlineCacheToast': 'ローカルキャッシュから入りました（オフライン）',
  'noCacheAvailable': 'このアカウントのキャッシュはありません',
  'loginTab': 'ログイン',
  'logout': 'ログアウト',
  'logoutMsg': 'セッションを消去します（アカウント帳は保持）。ログアウトしますか？',
  'logoutTitle': 'ログアウト',
  'messages': 'メッセージ',
  'midterm': '中間評価',
  'modeDark': 'ダーク',
  'modeEye': 'アイケア',
  'modeLight': 'ライト',
  'modeSystem': 'システムに従う',
  'moduleDetail': 'モジュール詳細',
  'mon': '月',
  'monthLabel': '%1月',
  'more': 'その他',
  'morning': '午前',
  'msgDetail': 'メッセージ詳細',
  'needSms': 'SMS認証',
  'noAccounts': '登録アカウントがありません',
  'noAnnounce': 'お知らせがありません',
  'noBatches': '試験バッチがありません',
  'noDetail': '詳細がありません',
  'noEvaluate': '評価タスクがありません',
  'noExamArrange': '試験日程がありません',
  'noGrades': 'この学期の成績はありません',
  'noGradesMatched': '該当する成績が見つかりません',
  'noLessons': 'このラウンドにコースがありません',
  'noMessages': 'メッセージがありません',
  'noMidterm': '中間評価の内容がありません',
  'noPermission': 'アクセス権限がありません',
  'noPlanByMajor': 'マイカリキュラムがありません',
  'noPlanCompletion': '進捗データがありません',
  'noPlanMajor': '履修計画がありません',
  'noProfiles': '履修ラウンドがありません',
  'noScores': '成績記録がありません',
  'noSignups': '申込記録がありません',
  'noStdApply': '専攻変更申請がありません',
  'noStdInfo': '学籍情報がありません',
  'noSubject': '（件名なし）',
  'noTimetable': '今学期の時間割はありません',
  'noonBreak': '昼休み',
  'notRemembered': '未保存（毎回手入力）',
  'offlineBanner': 'オフライン：キャッシュのみ表示、オンラインで引っ張って更新',
  'offlineMode': 'オフライン：キャッシュのみ表示、オンラインで引っ張って更新',
  'ok': 'OK',
  'onlyAvailable': '空席ありのみ',
  'onlySelected': '選択済みのみ',
  'othersExam': 'その他の試験（CET）',
  'password': 'パスワード',
  'pendingTasks': '評価待ちタスク',
  'period1': '第1限',
  'period2': '第2限',
  'period3': '第3限',
  'period4': '第4限',
  'period5': '第5限',
  'period6': '第6限',
  'periodUnit': '第 %1 限',
  'plan': 'カリキュラム',
  'pullToRefreshTimetable': '引っ張って最新の時間割を同期',
  'quickSavedLogin': '保存済みアカウントでクイックログイン',
  'rawGradesDetail': '教務システムの生データ',
  'recordDetail': 'コース詳細',
  'remainSeats': '残 %1',
  'remarkNote': '備考',
  'rememberAcct': 'アカウントを記憶（端末に保存）',
  'rememberPwd': 'パスワードを保存（安全保管）',
  'remembered': 'パスワードを保存済み',
  'resend': '再送信',
  'resendNow': 'コードを再送信',
  'retry': '再試行',
  'room': '教室：%1',
  'roomCopied': '教室の場所をコピーしました',
  'roundLabel': '%1（第%2期）',
  'sat': '土',
  'saveToBook': 'アカウント帳に保存',
  'savedToBook': 'アカウント帳に保存しました',
  'scheduleTimePlace': '時間割・場所',
  'scores': '成績',
  'searchCoursePlaceholder': 'コース名やタイプを検索…',
  'searchCourses': 'コース名を検索',
  'seatLabel': '座席 %1',
  'select': '履修',
  'selectSemesterOrWeek': '学期選択または週へ移動',
  'selectedBadge': '選択済み',
  'selectedOf': '%1 / %2 履修中',
  'semesterSynced': '学期をサーバーと同期しました',
  'signup': '申込',
  'smsHint': 'ゲートウェイが二段階認証を要求しています。SMS認証コードを入力してください。',
  'smsSent': '再送信しました',
  'smsSentTo': '認証コードを %1 に送信しました',
  'solarAstroRhythm': '太陽リズムと自然光',
  'solarAstroSub': '長江大学 (30.33°N, 112.24°E) · リアルタイムの日照軌跡',
  'solarDayLengthBanner': '本日の日照時間 約 %1 · 時間割左側の光軸と太陽高度角がリアルタイム連動',
  'solarLightingDistribution': '時限ごとの自然光の強さ',
  'solarNoon': '正午中天',
  'stateChooseable': '受付中',
  'stateFull': '満員',
  'stateSelected': '選択済み',
  'stateWithdrawable': '取消可',
  'stdInfo': '学籍情報',
  'student': '学生',
  'studentIdNo': '学籍番号: %1',
  'sun': '日',
  'sunrise': '日の出',
  'sunset': '日没',
  'switchAcct': '切替',
  'switchSemester': '学期を切り替え',
  'sync': '同期',
  'syncSemester': '学期をオンライン同期',
  'syncSemesterSub': 'サーバーから学期リストを補正',
  'syncTimetableOnline': '時間割をオンライン取得',
  'systemTitle': '長江大学教務システム',
  'tabCompletion': '進捗',
  'tabMajorPlan': '履修計画',
  'tabMyPlan': 'マイカリキュラム',
  'tabStdApply': '専攻変更申請',
  'tableRawView': '表',
  'teacher': '教員：%1',
  'thisWeek': '今週 %1',
  'thu': '木',
  'timetable': '時間割',
  'totalCreditsLabel': '修得総単位',
  'tue': '火',
  'unnamedTask': '（無名タスク）',
  'username': '学籍番号/職員番号',
  'verifyBtn': '認証',
  'wed': '水',
  'weekLabel': '第 %1 週 / 全 %2 週',
  'weekNumber': '第 %1 週',
  'weekShort': '%1週',
  'weekSuffix': '週',
  'welcome': 'お知らせ',
  'withdraw': '取消',
  'withdrawClosed': '取消受付外',
  'withdrawOpen': '取消受付中',
};

const Map<String, String> _ur = {
  'about': 'تعارف',
  'aboutAppDetail': 'گریڈ\nورژن: 2.5.31\n\nمکمل طور پر مقامی چلتا ہے، کوئی درمیانی سرور نہیں۔ تمام اسناد Keychain/Keystore میں خفیہ رہتی ہیں۔',
  'aboutSub': 'یانگتزے یونیورسٹی نظام اوقات · صرف مطالعہ کے لیے',
  'account': 'اکاؤنٹ',
  'accountExists': 'یہ اکاؤنٹ پہلے سے موجود ہے',
  'accountInfo': 'اکاؤنٹ',
  'accountManage': 'اکاؤنٹ کا انتظام',
  'accountManageSub': 'اکاؤنٹس کو تبدیل/شامل/حذف کریں (محفوظ ذخیرہ)',
  'accountSettings': 'ڈیٹا اور ترتیبات',
  'actualCurrentWeek': 'فی الحال ہفتہ %1 ہے',
  'addNewAccount': 'نیا اکاؤنٹ شامل کریں',
  'addToBook': 'اکاؤنٹ بک میں شامل کریں',
  'addedToBook': 'اکاؤنٹ بک میں شامل ہو گیا',
  'affairChannel': 'متعلقہ امور کی درخواستیں',
  'afternoon': 'دوپہر',
  'announcement': 'اعلان',
  'appName': 'گریڈ',
  'appSlogan': 'یانگتزے یونیورسٹی نظام اوقات، نمبر اور کورس معاون',
  'appearance': 'ظاہری شکل',
  'archiveInfo': 'طالب علم کی فائل',
  'basicStudentDossier': 'بنیادی معلومات اور طالب علم کارڈ',
  'batchLoadFail': 'بیچ لوڈ ناکام: %1',
  'bookHint': 'CAS میں آن لائن رجسٹریشن نہیں۔ اکاؤنٹس کو مقامی بک میں محفوظ کریں تاکہ تیزی سے تبدیل اور لاگ ان ہو سکے۔',
  'bookTab': 'اکاؤنٹس',
  'bookTitle': 'اکاؤنٹ بک',
  'break10': 'وقفہ 10 منٹ',
  'break20': 'بڑا وقفہ 20 منٹ',
  'break30': 'بڑا وقفہ 30 منٹ',
  'cacheCleared': 'کیچ صاف ہو گئی',
  'campus': 'کیمپس: %1',
  'cancel': 'منسوخ',
  'cardFlowView': 'کارڈز',
  'casHint': 'CAS پاس ورڈ POST ہر سیشن میں صرف 1 بار، خودکار دوبارہ کوشش نہیں (لاک روکنے کے لیے)۔ CASTGC درست رہنے پر SSO استعمال ہوتا ہے۔',
  'classNo': 'کلاس نمبر',
  'clazz': 'کلاس: %1',
  'clearCache': 'کیچ صاف کریں',
  'clearCacheMsg': 'نظام اوقات/نمبر کی کیچ حذف کریں۔ سیشن اور اکاؤنٹ بک برقرار رہیں گی۔ جاری رکھیں؟',
  'clearCacheSub': 'نظام اوقات/نمبر کی کیچ حذف کریں (سیشن متاثر نہیں)',
  'clearCacheTitle': 'کیچ صاف کریں',
  'clickToView': 'قابل تشخیص · تفصیل کے لیے تھپتھپائیں',
  'close': 'بند کریں',
  'collapseEvening': 'شام کا شیڈول سمیٹیں',
  'confirmSelectMsg': 'کورس: %1\n\nیہ کورس منتخب کریں؟',
  'confirmSelectTitle': 'کورس منتخب کریں',
  'confirmWithdrawMsg': 'کورس: %1\n\nیہ کورس واپس لیں؟',
  'confirmWithdrawTitle': 'کورس واپس لیں',
  'copied': 'کاپی ہو گیا',
  'copy': 'کاپی',
  'course': 'یہ کورس',
  'courseCode': 'کوڈ %1',
  'courseDetail': 'کورس کی تفصیل',
  'courseName': 'کورس کا نام',
  'courseNature': 'کورس کی قسم',
  'courseScheme': 'کورس منصوبہ',
  'coursesCountSuffix': '%1 کورسز',
  'creditsLabel': '%1 کریڈٹ',
  'creditsOverview': 'کریڈٹ کا جائزہ',
  'currentBadge': 'موجودہ',
  'darkColorIsActiveWeek': 'گہرے خانے کلاس کے ہفتے ظاہر کرتے ہیں',
  'deleteAccount': 'اکاؤنٹ حذف کریں',
  'deleteAccountMsg': 'اکاؤنٹ %1 اور اس کا محفوظ پاس ورڈ حذف کریں؟',
  'department': 'شعبہ',
  'detail': 'کورس کی تفصیل',
  'dinnerBreak': 'شام کا کھانا اور وقفہ',
  'electClosed': 'اندروں بند',
  'electOpen': 'اندروں کھلا',
  'elective': 'کورس چننا',
  'electiveAdvice': 'کورس کی تجاویز',
  'electiveProfiles': 'کورس راؤنڈز',
  'emptyDefault': 'کوئی ڈیٹا نہیں',
  'enrolledBadge': 'منتخب',
  'enrolledOfCap': 'منتخب %1 / حد %2',
  'enterAcctPwd': 'اکاؤنٹ اور پاس ورڈ درج کریں',
  'evalDetail': 'تشخیص کی تفصیل',
  'evaluate': 'تشخیص',
  'evaluateClosed': 'تشخیص فی الحال بند ہے یا تمام مکمل ہو چکی ہیں',
  'evening': 'شام',
  'exam': 'امتحان',
  'examArrange': 'امتحانی شیڈول',
  'examRoom': 'کمرہ',
  'examRoomCopied': 'امتحان کا کمرہ کاپی ہو گیا',
  'examScoresObtained': 'حاصل کردہ امتحانی نمبر',
  'examSeat': 'سیٹ نمبر',
  'examSignupRecords': 'امتحان کی رجسٹریشن',
  'examSubject': 'مضمون',
  'examTime': 'وقت',
  'expandEvening': 'شام کی کلاس نہیں · مطالعہ کا وقت دیکھنے کے لیے تھپتھپائیں',
  'fieldCampus': 'کیمپس',
  'fieldCapacity': 'منتخب / حد',
  'fieldClassNo': 'کلاس',
  'fieldCourseNo': 'کورس نمبر',
  'fieldCredits': 'کریڈٹ',
  'fieldDay': 'دن',
  'fieldMapNo': 'نقشہ نمبر',
  'fieldName': 'کورس',
  'fieldPeriod': 'اوقات',
  'fieldRemark': 'نوٹ',
  'fieldSchedule': 'شیڈول',
  'fieldTeachers': 'اساتذہ',
  'fieldTime': 'وقت',
  'fieldType': 'قسم',
  'fieldWeeks': 'ہفتے',
  'filterCampus': 'کیمپس',
  'filterResults': 'فلٹر شدہ نتائج',
  'filterState': 'حالت',
  'filterType': 'قسم',
  'fri': 'جمعہ',
  'fromCache': 'کیچ',
  'fromOnline': 'آن لائن',
  'fullSeats': 'مکمل',
  'fullTermWeekDistribution': 'پورے سیمسٹر کے ہفتوں کی تقسیم',
  'gpa': 'جی پی اے',
  'gpaLabel': 'جی پی اے',
  'grades': 'نمبر',
  'gradesDetail': 'نمبر کی تفصیل',
  'hello': 'ہیلو، %1',
  'historySemesterGrades': 'پچھلے سیمسٹر کے نمبر دیکھیں',
  'hubAffair': 'پیغامات و کام',
  'hubData': 'استفسارات',
  'hubWindow': 'زیادہ استعمال',
  'jumpToWeek': 'مخصوص ہفتے پر جائیں',
  'language': 'زبان',
  'lessonsCountSuffix': '%1 کورسز',
  'lessonsOverlapping': '%1 کورسز کا وقت مل رہا ہے · %2',
  'liveSeatsRemain': 'دستیاب نشستیں',
  'loginBtn': 'لاگ ان',
  'autoLogin': 'خودکار لاگ ان',
  'autoLoginSub': 'اگلی بار خودکار لاگ ان اور ریفریش',
  'startWithCache': 'اگلی بار کیشے سے',
  'startWithCacheSub': 'بغیر لاگ ان کیشے سے فوری کھولیں',
  'enterFromCache': 'کیشے سے داخل ہوں',
  'retryLogin': 'دوبارہ کوشش کریں',
  'offlineCacheToast': 'مقامی کیشے سے داخل ہو گئے (آف لائن)',
  'noCacheAvailable': 'اس اکاؤنٹ کے لیے کوئی کیشے دستیاب نہیں ہے',
  'loginTab': 'لاگ ان',
  'logout': 'لاگ آؤٹ',
  'logoutMsg': 'مقامی سیشن صاف کریں (اکاؤنٹ بک رکھیں)؟ لاگ آؤٹ کریں؟',
  'logoutTitle': 'لاگ آؤٹ',
  'messages': 'پیغامات',
  'midterm': 'درمیانی تشخیص',
  'modeDark': 'اندھیرا',
  'modeEye': 'آنکھوں کی حفاظت',
  'modeLight': 'روشن',
  'modeSystem': 'سسٹم کے مطابق',
  'moduleDetail': 'ماڈیول کی تفصیلات',
  'mon': 'پیر',
  'monthLabel': 'مہینہ %1',
  'more': 'مزید',
  'morning': 'صبح',
  'msgDetail': 'پیغام کی تفصیل',
  'needSms': 'SMS تصدیق',
  'noAccounts': 'کوئی اکاؤنٹ نہیں',
  'noAnnounce': 'کوئی اعلان نہیں',
  'noBatches': 'کوئی امتحان بیچ نہیں',
  'noDetail': 'کوئی تفصیل نہیں',
  'noEvaluate': 'کوئی تشخیص کام نہیں',
  'noExamArrange': 'کوئی امتحانی شیڈول نہیں',
  'noGrades': 'اس سیمسٹر میں کوئی نمبر نہیں',
  'noGradesMatched': 'کوئی متعلقہ نمبر ریکارڈ نہیں ملا',
  'noLessons': 'اس راؤنڈ میں کوئی کورس نہیں',
  'noMessages': 'کوئی پیغام نہیں',
  'noMidterm': 'کوئی درمیانی تشخیص نہیں',
  'noPermission': 'رسائی کی اجازت نہیں',
  'noPlanByMajor': 'کوئی نصابی ڈیٹا نہیں',
  'noPlanCompletion': 'پیش رفت کا کوئی ڈیٹا نہیں',
  'noPlanMajor': 'کوئی پروگرام منصوبہ نہیں',
  'noProfiles': 'کوئی کورس راؤنڈ نہیں',
  'noScores': 'کوئی نمبر نہیں',
  'noSignups': 'کوئی رجسٹریشن نہیں',
  'noStdApply': 'شعبہ تبدیلی کی کوئی معلومات نہیں',
  'noStdInfo': 'کوئی طالب علم معلومات نہیں',
  'noSubject': '(بغیر موضوع)',
  'noTimetable': 'اس سیمسٹر کا کوئی نظام اوقات نہیں',
  'noonBreak': 'دوپہر کا وقفہ',
  'notRemembered': 'پاس ورڈ محفوظ نہیں (ہر بار دستی داخل)',
  'offlineBanner': 'آف لائن: صرف محفوظ ڈیٹا، آن لائن پر تازہ کریں',
  'offlineMode': 'آف لائن: صرف محفوظ ڈیٹا دکھایا جا رہا ہے، آن لائن پر تازہ کریں',
  'ok': 'ٹھیک ہے',
  'onlyAvailable': 'صرف دستیاب',
  'onlySelected': 'صرف منتخب کردہ',
  'othersExam': 'دیگر امتحانات (CET)',
  'password': 'پاس ورڈ',
  'pendingTasks': 'زیر التوا تشخیصات',
  'period1': 'پیریڈ 1',
  'period2': 'پیریڈ 2',
  'period3': 'پیریڈ 3',
  'period4': 'پیریڈ 4',
  'period5': 'پیریڈ 5',
  'period6': 'پیریڈ 6',
  'periodUnit': 'پیریڈ %1',
  'plan': 'نصاب',
  'pullToRefreshTimetable': 'تازہ ترین نظام اوقات کے لیے نیچے کھینچیں',
  'quickSavedLogin': 'محفوظ اکاؤنٹ سے فوری لاگ ان',
  'rawGradesDetail': 'تعلیمی نظام کا مکمل ریکارڈ',
  'recordDetail': 'کورس کی تفصیل',
  'remainSeats': 'باقی %1',
  'remarkNote': 'نوٹ',
  'rememberAcct': 'اکاؤنٹ یاد رکھیں (مقامی ذخیرہ)',
  'rememberPwd': 'پاس ورڈ محفوظ کریں (محفوظ ذخیرہ)',
  'remembered': 'پاس ورڈ محفوظ',
  'resend': 'دوبارہ بھیجیں',
  'resendNow': 'کوڈ دوبارہ بھیجیں',
  'retry': 'دوبارہ کوشش',
  'room': 'کلاس روم: %1',
  'roomCopied': 'کلاس روم کا مقام کاپی ہو گیا',
  'roundLabel': '%1 (راؤنڈ %2)',
  'sat': 'ہفتہ',
  'saveToBook': 'اکاؤنٹ بک میں محفوظ کریں',
  'savedToBook': 'اکاؤنٹ بک میں محفوظ ہو گیا',
  'scheduleTimePlace': 'وقت اور جگہ',
  'scores': 'نمبر',
  'searchCoursePlaceholder': 'کورس کا نام یا قسم تلاش کریں…',
  'searchCourses': 'کورس کا نام تلاش کریں',
  'seatLabel': 'سیٹ %1',
  'select': 'منتخب کریں',
  'selectSemesterOrWeek': 'سیمسٹر منتخب کریں یا ہفتے پر جائیں',
  'selectedBadge': 'منتخب',
  'selectedOf': '%1 / %2 منتخب',
  'semesterSynced': 'سیمسٹر سرور سے ہم آہنگ ہو گیا',
  'signup': 'رجسٹریشن',
  'smsHint': 'گیٹ وے نے دوہری تصدیق فعال کی۔ SMS کوڈ درج کریں۔',
  'smsSent': 'دوبارہ بھیج دیا گیا',
  'smsSentTo': 'کوڈ %1 پر بھیج دیا گیا',
  'solarAstroRhythm': 'شمسی تال اور قدرتی روشنی',
  'solarAstroSub': 'یانگتزے یونیورسٹی (30.33°N, 112.24°E) · حقیقی شمسی راستہ',
  'solarDayLengthBanner': 'دن کی کل روشنی ~%1 · بائیں طرف کا نوری محور سورج کی بلندی سے جڑا ہے',
  'solarLightingDistribution': 'مطالعہ کے اوقات میں قدرتی روشنی کی تقسیم',
  'solarNoon': 'دوپہر',
  'stateChooseable': 'کھلا',
  'stateFull': 'مکمل',
  'stateSelected': 'منتخب',
  'stateWithdrawable': 'واپسی ممکن',
  'stdInfo': 'طالب علم کی معلومات',
  'student': 'طالب علم',
  'studentIdNo': 'طالب علم آئی ڈی %1',
  'sun': 'اتوار',
  'sunrise': 'طلوع آفتاب',
  'sunset': 'غروب آفتاب',
  'switchAcct': 'تبدیل',
  'switchSemester': 'سیمسٹر تبدیل کریں',
  'sync': 'مطابقت',
  'syncSemester': 'سیمسٹر آن لائن مطابقت',
  'syncSemesterSub': 'سرور سے سیمسٹر فہرست درست کریں',
  'syncTimetableOnline': 'آن لائن نظام اوقات لائیں',
  'systemTitle': 'یانگتزے یونیورسٹی تعلیمی نظام',
  'tabCompletion': 'پیش رفت',
  'tabMajorPlan': 'پروگرام منصوبہ',
  'tabMyPlan': 'میرا نصاب',
  'tabStdApply': 'شعبہ تبدیلی',
  'tableRawView': 'جدول',
  'teacher': 'استاد: %1',
  'thisWeek': 'ہفتہ %1',
  'thu': 'جمعرات',
  'timetable': 'نظام اوقات',
  'totalCreditsLabel': 'کل کریڈٹ',
  'tue': 'منگل',
  'unnamedTask': '(بغیر نام کا کام)',
  'username': 'طالب علم/عملہ آئی ڈی',
  'verifyBtn': 'تصدیق',
  'wed': 'بدھ',
  'weekLabel': 'ہفتہ %1 / کل %2',
  'weekNumber': 'ہفتہ %1',
  'weekShort': 'ہ%1',
  'weekSuffix': 'ہفتے',
  'welcome': 'خوش آمدید / اعلانات',
  'withdraw': 'واپس لیں',
  'withdrawClosed': 'واپسی بند',
  'withdrawOpen': 'واپسی کھلا',
};
