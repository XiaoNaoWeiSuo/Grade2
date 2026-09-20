/// 应用国际化 —— 简体中文 / 繁体中文 / English / 日本語 / اردو。
///
/// - [supportedAppLocales] 支持的语言列表（供选择/排序）。
/// - [localeProvider] 当前语言（StateProvider，持久化到 LocalCache ns=meta key=locale）。
/// - [appStringsProvider] 按当前语言解析的 [AppStrings]。
/// - 页面用 `context.l10n.xxx` 取文案（见 [L10nContext]）。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 应用语言。
class AppLocale {
  const AppLocale(this.code, this.label);
  final String code;
  final String label; // 用本语言自述（语言切换器展示）
  Locale get locale => Locale(code.split('-').first, code.contains('-') ? code.split('-').last : '');
  bool get isRtl => code == 'ur';
}

const List<AppLocale> supportedAppLocales = [
  AppLocale('zh-Hans', '简体中文'),
  AppLocale('zh-Hant', '繁體中文'),
  AppLocale('en', 'English'),
  AppLocale('ja', '日本語'),
  AppLocale('ur', 'اردو'),
];

/// 当前语言 Provider（持久化）。
final localeProvider = StateProvider<AppLocale>((ref) => supportedAppLocales.first);

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
}

extension L10nContext on BuildContext {
  AppStrings get l10n =>
      ProviderScope.containerOf(this).read(appStringsProvider);
}

final appStringsProvider = Provider<AppStrings>(
    (ref) => AppStrings(ref.watch(localeProvider).code));

// ---------------------------------------------------------------------------
// 五语文案
// ---------------------------------------------------------------------------

const Map<String, String> _zh = {
  'cancel': '取消',
  'ok': '确定',
  'close': '关闭',
  'retry': '重试',
  'emptyDefault': '暂无数据',
  'appName': 'Grade',
  'more': '更多',
  'account': '账户',
  'timetable': '课表',
  'grades': '成绩',
  'elective': '选课',
  'exam': '考试',
  'plan': '培养计划',
  'stdInfo': '学籍信息',
  'messages': '系统消息',
  'evaluate': '教学评价',
  'welcome': '欢迎 / 公告',
  'switchSemester': '切换学期',
  'sync': '同步',
  'courseDetail': '课程详情',
  'hubWindow': '窗期高频',
  'hubData': '数据查询',
  'hubAffair': '事务',
  'accountInfo': '账号',
  'accountSettings': '数据与设置',
  'accountManage': '账号管理',
  'accountManageSub': '多账号切换 / 登记 / 删除（密码安全存储）',
  'syncSemester': '学期网络同步',
  'syncSemesterSub': '从服务器校正学期列表与当前学期',
  'clearCache': '清除本地缓存',
  'clearCacheSub': '删除课表/成绩等缓存数据（会话令牌不受影响）',
  'about': '关于',
  'aboutSub': '长江大学教务课程表 · 仅供学习与研究',
  'logout': '登出',
  'logoutTitle': '登出',
  'logoutMsg': '将清除本地会话令牌（保留账号簿），确定登出？',
  'clearCacheTitle': '清除本地缓存',
  'clearCacheMsg': '将删除课表/成绩等业务缓存（会话令牌与账号簿不受影响）。确定？',
  'cacheCleared': '缓存已清除',
  'semesterSynced': '学期已与服务器同步',
  'offlineMode': '离线模式：仅显示本地缓存数据，联网后可下拉刷新',
  'bookTitle': '本机账号簿',
  'addNewAccount': '登记新账号',
  'rememberPwd': '记住密码（安全存储）',
  'addToBook': '添加到账号簿',
  'switchAcct': '切换',
  'deleteAccount': '删除账号',
  'deleteAccountMsg': '将删除账号 %1 及其本地保存的密码，确定？',
  'remembered': '已记住密码',
  'notRemembered': '未记住密码（需手动输入）',
  'noAccounts': '暂无登记账号',
  'addedToBook': '已添加到账号簿',
  'loginTab': '登录',
  'bookTab': '账号簿',
  'username': '学号/工号',
  'password': '密码',
  'rememberAcct': '记住账号密码（本机存储）',
  'loginBtn': '登 录',
  'needSms': '需要短信验证',
  'smsSentTo': '验证码已发送至 %1',
  'smsHint': '学校网关对本次登录启用了二次认证，请输入短信验证码',
  'verifyBtn': '验 证',
  'resend': '重新发送',
  'resendNow': '重新发送验证码',
  'saveToBook': '保存到账号簿',
  'accountExists': '该账号已在账号簿中',
  'weekLabel': '第 %1 周 / 共 %2 周',
  'offlineBanner': '离线模式：仅显示本地缓存数据，联网后可下拉刷新',
  'teacher': '教师：%1',
  'room': '教室：%1',
  'clazz': '教学班：%1',
  'periodUnit': '第 %1 节',
  'noGrades': '本学期暂无成绩',
  'gradesDetail': '成绩明细',
  'fromCache': '本地缓存',
  'fromOnline': '在线',
  'recordDetail': '课程明细',
  'batchLoadFail': '批次加载失败：%1',
  'noBatches': '暂无考试批次',
  'examArrange': '考试安排',
  'noExamArrange': '暂无考试安排',
  'othersExam': '其他考试（四六级）',
  'signup': '报名',
  'scores': '成绩',
  'noSignups': '暂无报名记录',
  'noScores': '暂无成绩记录',
  'midterm': '中期考核',
  'noMidterm': '暂无中期考核内容',
  'noProfiles': '暂无选课轮次',
  'electiveProfiles': '选课轮次',
  'electOpen': '选课开放',
  'electClosed': '选课未开放',
  'withdrawOpen': '退课开放',
  'withdrawClosed': '退课未开放',
  'roundLabel': '%1（第%2期）',
  'noLessons': '该轮次暂无可选课程',
  'select': '选课',
  'withdraw': '退课',
  'campus': '校区：%1',
  'creditsLabel': '%1 学分',
  'selectedOf': '已选 %1 / %2',
  'confirmSelectTitle': '选课',
  'confirmWithdrawTitle': '退课',
  'confirmSelectMsg': '课程：%1\n\n确认选择该课程？',
  'confirmWithdrawMsg': '课程：%1\n\n确认退选该课程？',
  'course': '该课程',
  'tabCompletion': '完成度',
  'tabMyPlan': '我的计划',
  'tabMajorPlan': '培养方案',
  'tabStdApply': '转专业申请',
  'noPermission': '无权限访问',
  'noStdInfo': '暂无学籍信息',
  'noMessages': '暂无消息',
  'noSubject': '（无主题）',
  'msgDetail': '消息详情',
  'noDetail': '无详情',
  'noEvaluate': '暂无评教任务',
  'pendingTasks': '待评教学任务',
  'unnamedTask': '（未命名任务）',
  'clickToView': '可评价 · 点击查看详情',
  'evalDetail': '评价详情',
  'noAnnounce': '暂无公告',
  'announcement': '公告',
  'modeSystem': '跟随系统',
  'modeLight': '亮色',
  'modeDark': '暗色',
  'modeEye': '护眼',
  'appearance': '外观',
  'language': '语言',
  'mon': '一',
  'tue': '二',
  'wed': '三',
  'thu': '四',
  'fri': '五',
  'sat': '六',
  'sun': '日',
  'enterAcctPwd': '请输入账号与密码',
  'smsSent': '已重新发送',
  'casHint': 'CAS 密码 POST 每次会话最多 1 次，失败不自动重试（防封号）；CASTGC 有效期内自动免密 SSO。',
  'bookHint': 'CAS 不支持在线注册。此处将账号登记到本机账号簿，便于多账号管理与一键切换登录。',
  'savedToBook': '已保存到账号簿',
  'searchCourses': '搜索课程名称',
  'filterType': '课程类型',
  'filterCampus': '校区',
  'filterState': '状态',
  'stateChooseable': '可选',
  'stateFull': '已满',
  'stateWithdrawable': '可退',
  'stateSelected': '已选',
  'selectedBadge': '已选',
  'detail': '课程详情',
  'fieldName': '课程名称',
  'fieldType': '课程类型',
  'fieldCredits': '学分',
  'fieldTeachers': '任课教师',
  'fieldCampus': '开课校区',
  'fieldCapacity': '已选 / 上限',
  'fieldClassNo': '教学班',
  'fieldCourseNo': '课程编号',
  'fieldDay': '上课星期',
  'fieldTime': '上课时间',
  'fieldWeeks': '开课周次',
  'fieldMapNo': '选课序号',
  'filterResults': '筛选结果',
  'fieldSchedule': '上课安排',
  'fieldPeriod': '总学时',
  'fieldRemark': '备注',
  'weekSuffix': '周',
};

const Map<String, String> _zhTw = {
  'cancel': '取消',
  'ok': '確定',
  'close': '關閉',
  'retry': '重試',
  'emptyDefault': '暫無資料',
  'appName': 'Grade',
  'more': '更多',
  'account': '帳戶',
  'timetable': '課表',
  'grades': '成績',
  'elective': '選課',
  'exam': '考試',
  'plan': '培養計劃',
  'stdInfo': '學籍資訊',
  'messages': '系統訊息',
  'evaluate': '教學評價',
  'welcome': '歡迎 / 公告',
  'switchSemester': '切換學期',
  'sync': '同步',
  'courseDetail': '課程詳情',
  'hubWindow': '窗期高頻',
  'hubData': '資料查詢',
  'hubAffair': '事務',
  'accountInfo': '帳號',
  'accountSettings': '資料與設定',
  'accountManage': '帳號管理',
  'accountManageSub': '多帳號切換 / 登記 / 刪除（密碼安全儲存）',
  'syncSemester': '學期網路同步',
  'syncSemesterSub': '從伺服器校正學期列表與當前學期',
  'clearCache': '清除本機快取',
  'clearCacheSub': '刪除課表/成績等快取資料（會話權杖不受影響）',
  'about': '關於',
  'aboutSub': '長江大學教務課程表 · 僅供學習與研究',
  'logout': '登出',
  'logoutTitle': '登出',
  'logoutMsg': '將清除本機會話權杖（保留帳號簿），確定登出？',
  'clearCacheTitle': '清除本機快取',
  'clearCacheMsg': '將刪除課表/成績等業務快取（會話權杖與帳號簿不受影響）。確定？',
  'cacheCleared': '快取已清除',
  'semesterSynced': '學期已與伺服器同步',
  'offlineMode': '離線模式：僅顯示本機快取資料，連網後可下拉重新整理',
  'bookTitle': '本機帳號簿',
  'addNewAccount': '登記新帳號',
  'rememberPwd': '記住密碼（安全儲存）',
  'addToBook': '新增到帳號簿',
  'switchAcct': '切換',
  'deleteAccount': '刪除帳號',
  'deleteAccountMsg': '將刪除帳號 %1 及其本機儲存的密碼，確定？',
  'remembered': '已記住密碼',
  'notRemembered': '未記住密碼（需手動輸入）',
  'noAccounts': '暫無登記帳號',
  'addedToBook': '已新增到帳號簿',
  'loginTab': '登入',
  'bookTab': '帳號簿',
  'username': '學號/工號',
  'password': '密碼',
  'rememberAcct': '記住帳號密碼（本機儲存）',
  'loginBtn': '登 入',
  'needSms': '需要簡訊驗證',
  'smsSentTo': '驗證碼已傳送至 %1',
  'smsHint': '學校閘道對本次登入啟用了二次認證，請輸入簡訊驗證碼',
  'verifyBtn': '驗 證',
  'resend': '重新傳送',
  'resendNow': '重新傳送驗證碼',
  'saveToBook': '儲存到帳號簿',
  'accountExists': '該帳號已在帳號簿中',
  'weekLabel': '第 %1 週 / 共 %2 週',
  'offlineBanner': '離線模式：僅顯示本機快取資料，連網後可下拉重新整理',
  'teacher': '教師：%1',
  'room': '教室：%1',
  'clazz': '教學班：%1',
  'periodUnit': '第 %1 節',
  'noGrades': '本學期暫無成績',
  'gradesDetail': '成績明細',
  'fromCache': '本機快取',
  'fromOnline': '線上',
  'recordDetail': '課程明細',
  'batchLoadFail': '批次載入失敗：%1',
  'noBatches': '暫無考試批次',
  'examArrange': '考試安排',
  'noExamArrange': '暫無考試安排',
  'othersExam': '其他考試（四六級）',
  'signup': '報名',
  'scores': '成績',
  'noSignups': '暫無報名記錄',
  'noScores': '暫無成績記錄',
  'midterm': '中期考核',
  'noMidterm': '暫無中期考核內容',
  'noProfiles': '暫無選課輪次',
  'electiveProfiles': '選課輪次',
  'electOpen': '選課開放',
  'electClosed': '選課未開放',
  'withdrawOpen': '退課開放',
  'withdrawClosed': '退課未開放',
  'roundLabel': '%1（第%2期）',
  'noLessons': '該輪次暫無可選課程',
  'select': '選課',
  'withdraw': '退課',
  'campus': '校區：%1',
  'creditsLabel': '%1 學分',
  'selectedOf': '已選 %1 / %2',
  'confirmSelectTitle': '選課',
  'confirmWithdrawTitle': '退課',
  'confirmSelectMsg': '課程：%1\n\n確認選擇該課程？',
  'confirmWithdrawMsg': '課程：%1\n\n確認退選該課程？',
  'course': '該課程',
  'tabCompletion': '完成度',
  'tabMyPlan': '我的計劃',
  'tabMajorPlan': '培養方案',
  'tabStdApply': '轉專業申請',
  'noPermission': '無權限訪問',
  'noStdInfo': '暫無學籍資訊',
  'noMessages': '暫無訊息',
  'noSubject': '（無主題）',
  'msgDetail': '訊息詳情',
  'noDetail': '無詳情',
  'noEvaluate': '暫無評教任務',
  'pendingTasks': '待評教學任務',
  'unnamedTask': '（未命名任務）',
  'clickToView': '可評價 · 點擊查看詳情',
  'evalDetail': '評價詳情',
  'noAnnounce': '暫無公告',
  'announcement': '公告',
  'modeSystem': '跟隨系統',
  'modeLight': '亮色',
  'modeDark': '暗色',
  'modeEye': '護眼',
  'appearance': '外觀',
  'language': '語言',
  'mon': '一',
  'tue': '二',
  'wed': '三',
  'thu': '四',
  'fri': '五',
  'sat': '六',
  'sun': '日',
  'enterAcctPwd': '請輸入帳號與密碼',
  'smsSent': '已重新傳送',
  'casHint': 'CAS 密碼 POST 每次會話最多 1 次，失敗不自動重試（防封號）；CASTGC 有效期內自動免密 SSO。',
  'bookHint': 'CAS 不支援線上註冊。此處將帳號登記到本機帳號簿，便於多帳號管理與一鍵切換登入。',
  'savedToBook': '已儲存到帳號簿',
  'searchCourses': '搜尋課程名稱',
  'filterType': '課程類型',
  'filterCampus': '校區',
  'filterState': '狀態',
  'stateChooseable': '可選',
  'stateFull': '已滿',
  'stateWithdrawable': '可退',
  'stateSelected': '已選',
  'selectedBadge': '已選',
  'detail': '課程詳情',
  'fieldName': '課程名稱',
  'fieldType': '課程類型',
  'fieldCredits': '學分',
  'fieldTeachers': '任課教師',
  'fieldCampus': '開課校區',
  'fieldCapacity': '已選 / 上限',
  'fieldClassNo': '教學班',
  'fieldCourseNo': '課程編號',
  'fieldDay': '上課星期',
  'fieldTime': '上課時間',
  'fieldWeeks': '開課週次',
  'fieldMapNo': '選課序號',
  'filterResults': '篩選結果',
  'fieldSchedule': '上課安排',
  'fieldPeriod': '總學時',
  'fieldRemark': '備註',
  'weekSuffix': '週',
};

const Map<String, String> _en = {
  'cancel': 'Cancel',
  'ok': 'OK',
  'close': 'Close',
  'retry': 'Retry',
  'emptyDefault': 'No data',
  'appName': 'Grade',
  'more': 'More',
  'account': 'Account',
  'timetable': 'Timetable',
  'grades': 'Grades',
  'elective': 'Electives',
  'exam': 'Exams',
  'plan': 'Curriculum',
  'stdInfo': 'Student Info',
  'messages': 'Messages',
  'evaluate': 'Evaluation',
  'welcome': 'Welcome / Notices',
  'switchSemester': 'Switch Semester',
  'sync': 'Sync',
  'courseDetail': 'Course Detail',
  'hubWindow': 'High Frequency',
  'hubData': 'Queries',
  'hubAffair': 'Messages & Tasks',
  'accountInfo': 'Account',
  'accountSettings': 'Data & Settings',
  'accountManage': 'Account Management',
  'accountManageSub': 'Switch / add / remove accounts (secure storage)',
  'syncSemester': 'Sync Semester Online',
  'syncSemesterSub': 'Correct semester list from server',
  'clearCache': 'Clear Local Cache',
  'clearCacheSub': 'Remove timetable/grades cache (session unaffected)',
  'about': 'About',
  'aboutSub': 'Yangtze University timetable · For study only',
  'logout': 'Log Out',
  'logoutTitle': 'Log Out',
  'logoutMsg': 'Clear local session token (keep account book). Log out?',
  'clearCacheTitle': 'Clear Local Cache',
  'clearCacheMsg': 'Remove timetable/grades cache. Session & account book kept. Continue?',
  'cacheCleared': 'Cache cleared',
  'semesterSynced': 'Semester synced with server',
  'offlineMode': 'Offline: showing cached data only, pull to refresh when online',
  'bookTitle': 'Account Book',
  'addNewAccount': 'Add New Account',
  'rememberPwd': 'Remember password (secure storage)',
  'addToBook': 'Add to Account Book',
  'switchAcct': 'Switch',
  'deleteAccount': 'Delete Account',
  'deleteAccountMsg': 'Delete account %1 and its saved password?',
  'remembered': 'Password saved',
  'notRemembered': 'Password not saved (enter manually)',
  'noAccounts': 'No saved accounts',
  'addedToBook': 'Added to account book',
  'loginTab': 'Sign In',
  'bookTab': 'Accounts',
  'username': 'Student/Staff ID',
  'password': 'Password',
  'rememberAcct': 'Remember account (stored locally)',
  'loginBtn': 'Sign In',
  'needSms': 'SMS Verification',
  'smsSentTo': 'Code sent to %1',
  'smsHint': 'The gateway enabled two-factor auth for this sign-in. Enter the SMS code.',
  'verifyBtn': 'Verify',
  'resend': 'Resend',
  'resendNow': 'Resend code',
  'saveToBook': 'Save to Account Book',
  'accountExists': 'This account already exists',
  'weekLabel': 'Week %1 of %2',
  'offlineBanner': 'Offline: showing cached data only, pull to refresh when online',
  'teacher': 'Teacher: %1',
  'room': 'Room: %1',
  'clazz': 'Class: %1',
  'periodUnit': 'Period %1',
  'noGrades': 'No grades for this semester',
  'gradesDetail': 'Grade Detail',
  'fromCache': 'cached',
  'fromOnline': 'online',
  'recordDetail': 'Course Detail',
  'batchLoadFail': 'Failed to load batches: %1',
  'noBatches': 'No exam batches',
  'examArrange': 'Exam Schedule',
  'noExamArrange': 'No exam schedule',
  'othersExam': 'Other Exams (CET)',
  'signup': 'Sign-up',
  'scores': 'Scores',
  'noSignups': 'No sign-up records',
  'noScores': 'No score records',
  'midterm': 'Mid-term Assessment',
  'noMidterm': 'No mid-term content',
  'noProfiles': 'No elective rounds',
  'electiveProfiles': 'Elective Rounds',
  'electOpen': 'Enroll Open',
  'electClosed': 'Enroll Closed',
  'withdrawOpen': 'Withdraw Open',
  'withdrawClosed': 'Withdraw Closed',
  'roundLabel': '%1 (Round %2)',
  'noLessons': 'No courses in this round',
  'select': 'Enroll',
  'withdraw': 'Withdraw',
  'campus': 'Campus: %1',
  'creditsLabel': '%1 credits',
  'selectedOf': '%1 / %2 enrolled',
  'confirmSelectTitle': 'Enroll',
  'confirmWithdrawTitle': 'Withdraw',
  'confirmSelectMsg': 'Course: %1\n\nEnroll in this course?',
  'confirmWithdrawMsg': 'Course: %1\n\nWithdraw from this course?',
  'course': 'this course',
  'tabCompletion': 'Progress',
  'tabMyPlan': 'My Curriculum',
  'tabMajorPlan': 'Program Plan',
  'tabStdApply': 'Major Transfer',
  'noPermission': 'No access permission',
  'noStdInfo': 'No student info',
  'noMessages': 'No messages',
  'noSubject': '(No subject)',
  'msgDetail': 'Message Detail',
  'noDetail': 'No details',
  'noEvaluate': 'No evaluation tasks',
  'pendingTasks': 'Pending Evaluations',
  'unnamedTask': '(Unnamed task)',
  'clickToView': 'Evaluable · Tap for details',
  'evalDetail': 'Evaluation Detail',
  'noAnnounce': 'No notices',
  'announcement': 'Notice',
  'modeSystem': 'Follow System',
  'modeLight': 'Light',
  'modeDark': 'Dark',
  'modeEye': 'Eye Care',
  'appearance': 'Appearance',
  'language': 'Language',
  'mon': 'Mon',
  'tue': 'Tue',
  'wed': 'Wed',
  'thu': 'Thu',
  'fri': 'Fri',
  'sat': 'Sat',
  'sun': 'Sun',
  'enterAcctPwd': 'Enter ID and password',
  'smsSent': 'Resent',
  'casHint': 'CAS password POST is limited to 1 per session and never auto-retries (anti-lock). SSO is used while CASTGC is valid.',
  'bookHint': 'CAS has no online registration. Save accounts to the local book for quick switching and login.',
  'savedToBook': 'Saved to account book',
  'searchCourses': 'Search course name',
  'filterType': 'Type',
  'filterCampus': 'Campus',
  'filterState': 'Status',
  'stateChooseable': 'Open',
  'stateFull': 'Full',
  'stateWithdrawable': 'Withdrawable',
  'stateSelected': 'Selected',
  'selectedBadge': 'Selected',
  'detail': 'Course Detail',
  'fieldName': 'Course',
  'fieldType': 'Type',
  'fieldCredits': 'Credits',
  'fieldTeachers': 'Instructors',
  'fieldCampus': 'Campus',
  'fieldCapacity': 'Enrolled / Cap',
  'fieldClassNo': 'Class',
  'fieldCourseNo': 'Course No.',
  'fieldDay': 'Day',
  'fieldTime': 'Time',
  'fieldWeeks': 'Weeks',
  'fieldMapNo': 'Map No.',
  'filterResults': 'Filtered Results',
  'fieldSchedule': 'Schedule',
  'fieldPeriod': 'Hours',
  'fieldRemark': 'Note',
  'weekSuffix': 'wks',
};

const Map<String, String> _ja = {
  'cancel': 'キャンセル',
  'ok': 'OK',
  'close': '閉じる',
  'retry': '再試行',
  'emptyDefault': 'データがありません',
  'appName': 'Grade',
  'more': 'その他',
  'account': 'アカウント',
  'timetable': '時間割',
  'grades': '成績',
  'elective': '履修登録',
  'exam': '試験',
  'plan': 'カリキュラム',
  'stdInfo': '学籍情報',
  'messages': 'メッセージ',
  'evaluate': '授業評価',
  'welcome': 'お知らせ',
  'switchSemester': '学期を切り替え',
  'sync': '同期',
  'courseDetail': 'コース詳細',
  'hubWindow': '利用頻度が高い',
  'hubData': 'データ照会',
  'hubAffair': 'メッセージ・タスク',
  'accountInfo': 'アカウント',
  'accountSettings': 'データと設定',
  'accountManage': 'アカウント管理',
  'accountManageSub': '切替・登録・削除（パスワードは安全保管）',
  'syncSemester': '学期をオンライン同期',
  'syncSemesterSub': 'サーバーから学期リストを補正',
  'clearCache': 'キャッシュを消去',
  'clearCacheSub': '時間割・成績のキャッシュを削除（セッションは影響なし）',
  'about': 'このアプリについて',
  'aboutSub': '長江大学の時間割 · 学習目的専用',
  'logout': 'ログアウト',
  'logoutTitle': 'ログアウト',
  'logoutMsg': 'セッションを消去します（アカウント帳は保持）。ログアウトしますか？',
  'clearCacheTitle': 'キャッシュを消去',
  'clearCacheMsg': '時間割・成績のキャッシュを削除します（セッションとアカウント帳は保持）。続行しますか？',
  'cacheCleared': 'キャッシュを消去しました',
  'semesterSynced': '学期をサーバーと同期しました',
  'offlineMode': 'オフライン：キャッシュのみ表示、オンラインで引っ張って更新',
  'bookTitle': 'アカウント帳',
  'addNewAccount': '新規アカウント登録',
  'rememberPwd': 'パスワードを保存（安全保管）',
  'addToBook': 'アカウント帳に追加',
  'switchAcct': '切替',
  'deleteAccount': 'アカウントを削除',
  'deleteAccountMsg': 'アカウント %1 と保存済みパスワードを削除しますか？',
  'remembered': 'パスワードを保存済み',
  'notRemembered': '未保存（毎回手入力）',
  'noAccounts': '登録アカウントがありません',
  'addedToBook': 'アカウント帳に追加しました',
  'loginTab': 'ログイン',
  'bookTab': 'アカウント',
  'username': '学籍番号/職員番号',
  'password': 'パスワード',
  'rememberAcct': 'アカウントを記憶（端末に保存）',
  'loginBtn': 'ログイン',
  'needSms': 'SMS認証',
  'smsSentTo': '認証コードを %1 に送信しました',
  'smsHint': 'ゲートウェイが二段階認証を要求しています。SMS認証コードを入力してください。',
  'verifyBtn': '認証',
  'resend': '再送信',
  'resendNow': 'コードを再送信',
  'saveToBook': 'アカウント帳に保存',
  'accountExists': 'このアカウントは既に登録されています',
  'weekLabel': '第 %1 週 / 全 %2 週',
  'offlineBanner': 'オフライン：キャッシュのみ表示、オンラインで引っ張って更新',
  'teacher': '教員：%1',
  'room': '教室：%1',
  'clazz': 'クラス：%1',
  'periodUnit': '第 %1 限',
  'noGrades': 'この学期の成績はありません',
  'gradesDetail': '成績詳細',
  'fromCache': 'キャッシュ',
  'fromOnline': 'オンライン',
  'recordDetail': 'コース詳細',
  'batchLoadFail': 'バッチの読み込みに失敗：%1',
  'noBatches': '試験バッチがありません',
  'examArrange': '試験日程',
  'noExamArrange': '試験日程がありません',
  'othersExam': 'その他の試験（CET）',
  'signup': '申込',
  'scores': '成績',
  'noSignups': '申込記録がありません',
  'noScores': '成績記録がありません',
  'midterm': '中間評価',
  'noMidterm': '中間評価の内容がありません',
  'noProfiles': '履修ラウンドがありません',
  'electiveProfiles': '履修ラウンド',
  'electOpen': '登録受付中',
  'electClosed': '登録受付外',
  'withdrawOpen': '取消受付中',
  'withdrawClosed': '取消受付外',
  'roundLabel': '%1（第%2期）',
  'noLessons': 'このラウンドにコースがありません',
  'select': '履修',
  'withdraw': '取消',
  'campus': 'キャンパス：%1',
  'creditsLabel': '%1 単位',
  'selectedOf': '%1 / %2 履修中',
  'confirmSelectTitle': '履修登録',
  'confirmWithdrawTitle': '履修取消',
  'confirmSelectMsg': 'コース：%1\n\nこのコースを履修しますか？',
  'confirmWithdrawMsg': 'コース：%1\n\nこのコースを取消しますか？',
  'course': 'このコース',
  'tabCompletion': '進捗',
  'tabMyPlan': 'マイカリキュラム',
  'tabMajorPlan': '履修計画',
  'tabStdApply': '専攻変更申請',
  'noPermission': 'アクセス権限がありません',
  'noStdInfo': '学籍情報がありません',
  'noMessages': 'メッセージがありません',
  'noSubject': '（件名なし）',
  'msgDetail': 'メッセージ詳細',
  'noDetail': '詳細がありません',
  'noEvaluate': '評価タスクがありません',
  'pendingTasks': '評価待ちタスク',
  'unnamedTask': '（無名タスク）',
  'clickToView': '評価可能 · タップで詳細',
  'evalDetail': '評価詳細',
  'noAnnounce': 'お知らせがありません',
  'announcement': 'お知らせ',
  'modeSystem': 'システムに従う',
  'modeLight': 'ライト',
  'modeDark': 'ダーク',
  'modeEye': 'アイケア',
  'appearance': '外観',
  'language': '言語',
  'mon': '月',
  'tue': '火',
  'wed': '水',
  'thu': '木',
  'fri': '金',
  'sat': '土',
  'sun': '日',
  'enterAcctPwd': 'アカウントとパスワードを入力してください',
  'smsSent': '再送信しました',
  'casHint': 'CAS のパスワード POST はセッションごとに 1 回のみ、自動再試行しません（ロック防止）。CASTGC 有効中は SSO を利用します。',
  'bookHint': 'CAS にオンライン登録はありません。ローカルのアカウント帳に保存して、素早く切り替えてログインできます。',
  'savedToBook': 'アカウント帳に保存しました',
  'searchCourses': 'コース名を検索',
  'filterType': 'タイプ',
  'filterCampus': 'キャンパス',
  'filterState': '状態',
  'stateChooseable': '受付中',
  'stateFull': '満員',
  'stateWithdrawable': '取消可',
  'stateSelected': '選択済み',
  'selectedBadge': '選択済み',
  'detail': 'コース詳細',
  'fieldName': 'コース名',
  'fieldType': 'タイプ',
  'fieldCredits': '単位',
  'fieldTeachers': '担当教員',
  'fieldCampus': 'キャンパス',
  'fieldCapacity': '履修中 / 上限',
  'fieldClassNo': 'クラス',
  'fieldCourseNo': 'コース番号',
  'fieldDay': '曜日',
  'fieldTime': '時間',
  'fieldWeeks': '週',
  'fieldMapNo': 'マップ番号',
  'filterResults': '絞り込み結果',
  'fieldSchedule': '時間割',
  'fieldPeriod': '総時間',
  'fieldRemark': '備考',
  'weekSuffix': '週',
};

const Map<String, String> _ur = {
  'cancel': 'منسوخ',
  'ok': 'ٹھیک ہے',
  'close': 'بند کریں',
  'retry': 'دوبارہ کوشش',
  'emptyDefault': 'کوئی ڈیٹا نہیں',
  'appName': 'گریڈ',
  'more': 'مزید',
  'account': 'اکاؤنٹ',
  'timetable': 'نظام اوقات',
  'grades': 'نمبر',
  'elective': 'کورس چننا',
  'exam': 'امتحان',
  'plan': 'نصاب',
  'stdInfo': 'طالب علم کی معلومات',
  'messages': 'پیغامات',
  'evaluate': 'تشخیص',
  'welcome': 'خوش آمدید / اعلانات',
  'switchSemester': 'سیمسٹر تبدیل کریں',
  'sync': 'مطابقت',
  'courseDetail': 'کورس کی تفصیل',
  'hubWindow': 'زیادہ استعمال',
  'hubData': 'استفسارات',
  'hubAffair': 'پیغامات و کام',
  'accountInfo': 'اکاؤنٹ',
  'accountSettings': 'ڈیٹا اور ترتیبات',
  'accountManage': 'اکاؤنٹ کا انتظام',
  'accountManageSub': 'اکاؤنٹس کو تبدیل/شامل/حذف کریں (محفوظ ذخیرہ)',
  'syncSemester': 'سیمسٹر آن لائن مطابقت',
  'syncSemesterSub': 'سرور سے سیمسٹر فہرست درست کریں',
  'clearCache': 'کیچ صاف کریں',
  'clearCacheSub': 'نظام اوقات/نمبر کی کیچ حذف کریں (سیشن متاثر نہیں)',
  'about': 'تعارف',
  'aboutSub': 'یانگتزے یونیورسٹی نظام اوقات · صرف مطالعہ کے لیے',
  'logout': 'لاگ آؤٹ',
  'logoutTitle': 'لاگ آؤٹ',
  'logoutMsg': 'مقامی سیشن صاف کریں (اکاؤنٹ بک رکھیں)؟ لاگ آؤٹ کریں؟',
  'clearCacheTitle': 'کیچ صاف کریں',
  'clearCacheMsg': 'نظام اوقات/نمبر کی کیچ حذف کریں۔ سیشن اور اکاؤنٹ بک برقرار رہیں گی۔ جاری رکھیں؟',
  'cacheCleared': 'کیچ صاف ہو گئی',
  'semesterSynced': 'سیمسٹر سرور سے ہم آہنگ ہو گیا',
  'offlineMode': 'آف لائن: صرف محفوظ ڈیٹا دکھایا جا رہا ہے، آن لائن پر تازہ کریں',
  'bookTitle': 'اکاؤنٹ بک',
  'addNewAccount': 'نیا اکاؤنٹ شامل کریں',
  'rememberPwd': 'پاس ورڈ محفوظ کریں (محفوظ ذخیرہ)',
  'addToBook': 'اکاؤنٹ بک میں شامل کریں',
  'switchAcct': 'تبدیل',
  'deleteAccount': 'اکاؤنٹ حذف کریں',
  'deleteAccountMsg': 'اکاؤنٹ %1 اور اس کا محفوظ پاس ورڈ حذف کریں؟',
  'remembered': 'پاس ورڈ محفوظ',
  'notRemembered': 'پاس ورڈ محفوظ نہیں (ہر بار دستی داخل)',
  'noAccounts': 'کوئی اکاؤنٹ نہیں',
  'addedToBook': 'اکاؤنٹ بک میں شامل ہو گیا',
  'loginTab': 'لاگ ان',
  'bookTab': 'اکاؤنٹس',
  'username': 'طالب علم/عملہ آئی ڈی',
  'password': 'پاس ورڈ',
  'rememberAcct': 'اکاؤنٹ یاد رکھیں (مقامی ذخیرہ)',
  'loginBtn': 'لاگ ان',
  'needSms': 'SMS تصدیق',
  'smsSentTo': 'کوڈ %1 پر بھیج دیا گیا',
  'smsHint': 'گیٹ وے نے دوہری تصدیق فعال کی۔ SMS کوڈ درج کریں۔',
  'verifyBtn': 'تصدیق',
  'resend': 'دوبارہ بھیجیں',
  'resendNow': 'کوڈ دوبارہ بھیجیں',
  'saveToBook': 'اکاؤنٹ بک میں محفوظ کریں',
  'accountExists': 'یہ اکاؤنٹ پہلے سے موجود ہے',
  'weekLabel': 'ہفتہ %1 / کل %2',
  'offlineBanner': 'آف لائن: صرف محفوظ ڈیٹا، آن لائن پر تازہ کریں',
  'teacher': 'استاد: %1',
  'room': 'کلاس روم: %1',
  'clazz': 'کلاس: %1',
  'periodUnit': 'پیریڈ %1',
  'noGrades': 'اس سیمسٹر میں کوئی نمبر نہیں',
  'gradesDetail': 'نمبر کی تفصیل',
  'fromCache': 'کیچ',
  'fromOnline': 'آن لائن',
  'recordDetail': 'کورس کی تفصیل',
  'batchLoadFail': 'بیچ لوڈ ناکام: %1',
  'noBatches': 'کوئی امتحان بیچ نہیں',
  'examArrange': 'امتحانی شیڈول',
  'noExamArrange': 'کوئی امتحانی شیڈول نہیں',
  'othersExam': 'دیگر امتحانات (CET)',
  'signup': 'رجسٹریشن',
  'scores': 'نمبر',
  'noSignups': 'کوئی رجسٹریشن نہیں',
  'noScores': 'کوئی نمبر نہیں',
  'midterm': 'درمیانی تشخیص',
  'noMidterm': 'کوئی درمیانی تشخیص نہیں',
  'noProfiles': 'کوئی کورس راؤنڈ نہیں',
  'electiveProfiles': 'کورس راؤنڈز',
  'electOpen': 'اندروں کھلا',
  'electClosed': 'اندروں بند',
  'withdrawOpen': 'واپسی کھلا',
  'withdrawClosed': 'واپسی بند',
  'roundLabel': '%1 (راؤنڈ %2)',
  'noLessons': 'اس راؤنڈ میں کوئی کورس نہیں',
  'select': 'منتخب کریں',
  'withdraw': 'واپس لیں',
  'campus': 'کیمپس: %1',
  'creditsLabel': '%1 کریڈٹ',
  'selectedOf': '%1 / %2 منتخب',
  'confirmSelectTitle': 'کورس منتخب کریں',
  'confirmWithdrawTitle': 'کورس واپس لیں',
  'confirmSelectMsg': 'کورس: %1\n\nیہ کورس منتخب کریں؟',
  'confirmWithdrawMsg': 'کورس: %1\n\nیہ کورس واپس لیں؟',
  'course': 'یہ کورس',
  'tabCompletion': 'پیش رفت',
  'tabMyPlan': 'میرا نصاب',
  'tabMajorPlan': 'پروگرام منصوبہ',
  'tabStdApply': 'شعبہ تبدیلی',
  'noPermission': 'رسائی کی اجازت نہیں',
  'noStdInfo': 'کوئی طالب علم معلومات نہیں',
  'noMessages': 'کوئی پیغام نہیں',
  'noSubject': '(بغیر موضوع)',
  'msgDetail': 'پیغام کی تفصیل',
  'noDetail': 'کوئی تفصیل نہیں',
  'noEvaluate': 'کوئی تشخیص کام نہیں',
  'pendingTasks': 'زیر التوا تشخیصات',
  'unnamedTask': '(بغیر نام کا کام)',
  'clickToView': 'قابل تشخیص · تفصیل کے لیے تھپتھپائیں',
  'evalDetail': 'تشخیص کی تفصیل',
  'noAnnounce': 'کوئی اعلان نہیں',
  'announcement': 'اعلان',
  'modeSystem': 'سسٹم کے مطابق',
  'modeLight': 'روشن',
  'modeDark': 'اندھیرا',
  'modeEye': 'آنکھوں کی حفاظت',
  'appearance': 'ظاہری شکل',
  'language': 'زبان',
  'mon': 'پیر',
  'tue': 'منگل',
  'wed': 'بدھ',
  'thu': 'جمعرات',
  'fri': 'جمعہ',
  'sat': 'ہفتہ',
  'sun': 'اتوار',
  'enterAcctPwd': 'اکاؤنٹ اور پاس ورڈ درج کریں',
  'smsSent': 'دوبارہ بھیج دیا گیا',
  'casHint': 'CAS پاس ورڈ POST ہر سیشن میں صرف 1 بار، خودکار دوبارہ کوشش نہیں (لاک روکنے کے لیے)۔ CASTGC درست رہنے پر SSO استعمال ہوتا ہے۔',
  'bookHint': 'CAS میں آن لائن رجسٹریشن نہیں۔ اکاؤنٹس کو مقامی بک میں محفوظ کریں تاکہ تیزی سے تبدیل اور لاگ ان ہو سکے۔',
  'savedToBook': 'اکاؤنٹ بک میں محفوظ ہو گیا',
  'searchCourses': 'کورس کا نام تلاش کریں',
  'filterType': 'قسم',
  'filterCampus': 'کیمپس',
  'filterState': 'حالت',
  'stateChooseable': 'کھلا',
  'stateFull': 'مکمل',
  'stateWithdrawable': 'واپسی ممکن',
  'stateSelected': 'منتخب',
  'selectedBadge': 'منتخب',
  'detail': 'کورس کی تفصیل',
  'fieldName': 'کورس',
  'fieldType': 'قسم',
  'fieldCredits': 'کریڈٹ',
  'fieldTeachers': 'اساتذہ',
  'fieldCampus': 'کیمپس',
  'fieldCapacity': 'منتخب / حد',
  'fieldClassNo': 'کلاس',
  'fieldCourseNo': 'کورس نمبر',
  'fieldDay': 'دن',
  'fieldTime': 'وقت',
  'fieldWeeks': 'ہفتے',
  'fieldMapNo': 'نقشہ نمبر',
  'filterResults': 'فلٹر شدہ نتائج',
  'fieldSchedule': 'شیڈول',
  'fieldPeriod': 'اوقات',
  'fieldRemark': 'نوٹ',
  'weekSuffix': 'ہفتے',
};
