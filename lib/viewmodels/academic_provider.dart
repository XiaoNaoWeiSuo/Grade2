// 学业数据容器：替代旧 MainPage 的 7 个构造参数
//（topdata/listdata/otherdata/schedule/userlist/examlist/allgradelist）。
// 数据由登录流程（auth_provider）或离线恢复（offline_provider）一次性写入。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/course.dart';
import '../data/models/exam_data.dart';
import '../data/models/grade.dart';
import '../data/models/student.dart';

/// 一次登录/离线恢复得到的完整学业数据快照。
/// [gradeAverages] 与 [courseTotals] 对应旧 allgradelist 的 [0]/[1] 两个元素。
class AcademicData {
  final List<Student> students;
  final List<Course> planCourses;
  final List<CourseDataModel> grades;
  final List<List<Coursesis>> schedule;
  final List<ExamData> exams;
  final List<GradeAverange> gradeAverages;
  final List<CourseTotal> courseTotals;

  AcademicData({
    required this.students,
    required this.planCourses,
    required this.grades,
    required this.schedule,
    required this.exams,
    required this.gradeAverages,
    required this.courseTotals,
  });
}

class AcademicNotifier extends Notifier<AcademicData?> {
  @override
  AcademicData? build() => null;

  void set(AcademicData data) {
    state = data;
  }
}

final academicProvider =
    NotifierProvider<AcademicNotifier, AcademicData?>(AcademicNotifier.new);
