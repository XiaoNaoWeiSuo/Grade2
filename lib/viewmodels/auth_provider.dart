// 账号簿（data.json）：替代旧代码直接读写 CounterStorage("data.json")。
// data.json 结构（保持旧格式）：{initial: 当前账号, goal: 当前学期,
// setting: "ON"/"OFF"（在线模式开关）, content: {账号: [密码, 自动登录, 学期, 补考]}}
// 该 Map 同时作为旧 MainPage 的 userlist/initdata 参数来源。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/network/session_client.dart';
import '../core/storage/json_store.dart';
import '../core/utils/mail_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/exam_repository.dart';
import '../data/repositories/grade_repository.dart';
import '../data/repositories/schedule_repository.dart';
import 'academic_provider.dart';
import 'session_provider.dart';

class AccountBookNotifier extends Notifier<Map<String, dynamic>> {
  static const Map<String, dynamic> _empty = {
    "initial": "",
    "content": {},
    "goal": "",
    "setting": "",
  };

  final JsonStore _store = JsonStore("data.json");

  @override
  Map<String, dynamic> build() => Map.of(_empty);

  /// 启动时读取 data.json；文件不存在/为空时按旧逻辑写入初始结构。
  Future<void> load() async {
    final value = await _store.read();
    if (value.isEmpty) {
      await _store.write(_empty);
      state = Map.of(_empty);
    } else {
      state = value;
    }
  }

  bool get hasAccount => state.containsKey("setting");

  /// 保存本次登录账号（旧 Loginact 中 rememberPassword 分支）
  Future<void> saveLogin({
    required String account,
    required String password,
    required bool autoLogin,
    required String semester,
    required bool bukao,
  }) async {
    final data = state;
    data["initial"] = account;
    data["goal"] = semester;
    data["content"][account] = [
      password,
      autoLogin.toString(),
      semester,
      bukao.toString()
    ];
    state = Map.of(data);
    await _store.write(state);
  }

  /// 切换默认账号（旧 MainPage.backlogin）
  Future<void> selectAccount(String account) async {
    final data = state;
    data["initial"] = account;
    state = Map.of(data);
    await _store.write(state);
  }

  /// 修改当前学期（旧登录页 _handleInputFinished 写 initdata["goal"]）
  Future<void> setGoal(String goal) async {
    final data = state;
    data["goal"] = goal;
    state = Map.of(data);
    await _store.write(state);
  }

  /// 在线模式开关（旧 AutherPage / Loadpage 读写 setting ON/OFF）
  Future<void> setOnlineMode(bool online) async {
    final data = state;
    data["setting"] = online ? "ON" : "OFF";
    state = Map.of(data);
    await _store.write(state);
  }

  /// 删除账号（旧 MainPage 删账号写 data.json）
  Future<void> removeAccount(String account) async {
    final data = state;
    (data["content"] as Map).remove(account);
    if (data["initial"] == account) {
      data["initial"] = "";
    }
    state = Map.of(data);
    await _store.write(state);
  }
}

final accountBookProvider =
    NotifierProvider<AccountBookNotifier, Map<String, dynamic>>(
        AccountBookNotifier.new);

final loginControllerProvider =
    Provider<LoginController>((ref) => LoginController(ref));

/// 登录流程编排（旧 LoginPage.Loginact）：
/// 登录教务系统 → 拉取五类数据 → 写 root.json / appwidget.json →
/// 记住密码时更新 data.json → 匿名上报登录日志。
class LoginOutcome {
  final bool success;
  final bool wrongPassword;
  final AcademicData? data;

  const LoginOutcome._(this.success, this.wrongPassword, this.data);

  const LoginOutcome.emptyInput()
      : this._(false, false, null);

  const LoginOutcome.wrongPassword() : this._(false, true, null);

  const LoginOutcome.ok(AcademicData data) : this._(true, false, data);
}

class LoginController {
  final Ref ref;

  LoginController(this.ref);

  /// 网络异常会向上抛出（与旧行为一致，由 5 秒超时定时器兜底进入离线模式）。
  Future<LoginOutcome> login({
    required String account,
    required String password,
    required bool autoLogin,
    required bool rememberPassword,
    required bool bukao,
  }) async {
    if (account == "" || password == "") {
      return const LoginOutcome.emptyInput();
    }

    final client = SessionClient();
    final authRepo = AuthRepository(client);
    final LoginResult result = await authRepo.login(account, password);

    if (result.statusCode == 400) {
      return const LoginOutcome.wrongPassword();
    }

    // 当前学期沿用 data.json 中保存的 goal（旧代码读 enterkey 的等价逻辑）
    final semester = ref.read(accountBookProvider)["goal"] as String? ?? "";
    ref.read(currentSemesterProvider.notifier).state = semester;

    final (students, planCourses) = await authRepo.getPlanData();
    final gradeRepo = GradeRepository(client);
    final grades = await gradeRepo.getSemesterGrade(semester);
    final schedule = await ScheduleRepository(client).getSchedule(semester);
    final exams = await ExamRepository(client).getExams(bukao);
    final (gradeAverages, courseTotals) = await gradeRepo.getAllGrade();

    final data = AcademicData(
      students: students,
      planCourses: planCourses,
      grades: grades,
      schedule: schedule,
      exams: exams,
      gradeAverages: gradeAverages,
      courseTotals: courseTotals,
    );

    // 写入离线缓存 root.json（结构与旧代码完全一致）
    final Map<String, dynamic> rootData = {
      "state": "ON",
      "maintable": [
        [for (final a in students) a.toJson()],
        [for (final a in planCourses) a.toJson()],
      ],
      "gradetable": [for (final a in grades) a.toJson()],
      "schedule": [
        for (final week in schedule) [for (final b in week) b.toJson()]
      ],
      "examlist": [for (final a in exams) a.toJson()],
      "allgradelist": [
        [for (final a in gradeAverages) a.toJson()],
        [for (final a in courseTotals) a.toJson()],
      ],
    };
    await JsonStore("root.json").write(rootData);

    // 桌面小组件数据 appwidget.json（剔除 37~50 节，与旧逻辑一致）
    final Map<String, dynamic> appWidgetData = {
      "startdate": [2024, 2, 26],
      "schedule": [
        for (final week in schedule)
          [...week.sublist(0, 36).map((b) => b.toJson()),
           ...week.sublist(50).map((b) => b.toJson())]
      ],
    };
    await JsonStore("appwidget.json").write(appWidgetData);

    if (rememberPassword) {
      await ref.read(accountBookProvider.notifier).saveLogin(
            account: account,
            password: password,
            autoLogin: autoLogin,
            semester: semester,
            bukao: bukao,
          );
    }

    // 匿名上报登录日志（旧 SenMail(state=false)，失败静默）
    try {
      await MailService.send(students[0].name, students[0].department,
          "登录时间${_getCurrentTime()}", false, account);
    } catch (e) {
      Null;
    }

    ref.read(sessionProvider.notifier).signIn(client, result.statusCode, account);
    ref.read(academicProvider.notifier).set(data);
    return LoginOutcome.ok(data);
  }

  String _getCurrentTime() {
    return DateFormat('HH:mm:ss').format(DateTime.now());
  }
}
