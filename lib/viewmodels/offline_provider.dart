// 离线恢复：合并旧 Loadpage.load()（main.dart L104-208）与
// LoginPage.handleTimeout()（main.dart L557-661）中重复的 root.json 解析逻辑，
// 成为唯一实现。仅做文件 IO 与解析，不含导航/Toast。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/json_store.dart';
import '../data/models/course.dart';
import '../data/models/exam_data.dart';
import '../data/models/grade.dart';
import '../data/models/student.dart';
import 'academic_provider.dart';

/// 恢复结果状态
enum OfflineStatus {
  /// data.json 无 setting 键（从未登录过）
  noAccount,

  /// 恢复成功
  ok,

  /// root.json 解析失败（旧代码的"离线数据错误"分支）
  parseError,
}

class OfflineResult {
  final OfflineStatus status;
  final AcademicData? data;

  const OfflineResult(this.status, this.data);
}

class OfflineRestore {
  final JsonStore _dataStore = JsonStore("data.json");
  final JsonStore _rootStore = JsonStore("root.json");

  /// 读取 data.json + root.json 并解析为模型。永不抛异常。
  Future<OfflineResult> restore() async {
    final Map data = await _dataStore.read();
    if (!data.containsKey("setting")) {
      return const OfflineResult(OfflineStatus.noAccount, null);
    }
    try {
      final rootData = await _rootStore.read();

      final List<Student> students = [
        for (final a in rootData["maintable"][0]) Student.fromJson(a)
      ];
      final List<Course> planCourses = [
        for (final a in rootData["maintable"][1]) Course.fromJson(a)
      ];
      final List<CourseDataModel> grades = [
        for (final a in rootData["gradetable"]) CourseDataModel.fromJson(a)
      ];
      final List<List<Coursesis>> schedule = [
        for (final a in rootData["schedule"])
          [for (final b in a) Coursesis.fromJson(b)]
      ];
      final List<ExamData> exams = [
        for (final a in rootData["examlist"]) ExamData.fromJson(a)
      ];
      final List<GradeAverange> gradeAverages = [
        for (final a in rootData["allgradelist"][0]) GradeAverange.fromJson(a)
      ];
      final List<CourseTotal> courseTotals = [
        for (final a in rootData["allgradelist"][1]) CourseTotal.fromJson(a)
      ];

      final data0 = AcademicData(
        students: students,
        planCourses: planCourses,
        grades: grades,
        schedule: schedule,
        exams: exams,
        gradeAverages: gradeAverages,
        courseTotals: courseTotals,
      );
      return OfflineResult(OfflineStatus.ok, data0);
    } catch (e) {
      return const OfflineResult(OfflineStatus.parseError, null);
    }
  }
}

final offlineRestoreProvider = Provider<OfflineRestore>((ref) => OfflineRestore());
