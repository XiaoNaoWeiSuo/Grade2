// 抽取自原 lib/login.dart（L165-370）：Course（计划完成情况）、CourseDataModel（课程成绩）、
// Coursesis（课程表根模型），字段/构造/序列化行为保持不变。

import 'dart:ui';

/// 计划完成情况模型
class Course {
  int serialNumber;
  String courseCode;
  String courseName;
  int requiredCredits;
  int earnedCredits;
  String score;
  String isCompulsory;
  String isDegreeCourse;
  String isPassed;
  String remark;

  Course({
    required this.serialNumber,
    required this.courseCode,
    required this.courseName,
    required this.requiredCredits,
    required this.earnedCredits,
    required this.score,
    required this.isCompulsory,
    required this.isDegreeCourse,
    required this.isPassed,
    required this.remark,
  });
  Map<String, dynamic> toJson() {
    return {
      'serialNumber': serialNumber,
      'courseCode': courseCode,
      'courseName': courseName,
      'requiredCredits': requiredCredits,
      'earnedCredits': earnedCredits,
      'score': score,
      'isCompulsory': isCompulsory,
      'isDegreeCourse': isDegreeCourse,
      'isPassed': isPassed,
      'remark': remark,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      serialNumber: json['serialNumber'],
      courseCode: json['courseCode'],
      courseName: json['courseName'],
      requiredCredits: json['requiredCredits'],
      earnedCredits: json['earnedCredits'],
      score: json['score'],
      isCompulsory: json['isCompulsory'],
      isDegreeCourse: json['isDegreeCourse'],
      isPassed: json['isPassed'],
      remark: json['remark'],
    );
  }

  @override
  String toString() {
    return 'Course('
        'SerialNumber: $serialNumber, '
        'CourseCode: $courseCode, '
        'CourseName: $courseName, '
        'RequiredCredits: $requiredCredits, '
        'EarnedCredits: $earnedCredits, '
        'Score: $score, '
        'IsCompulsory: $isCompulsory, '
        'IsDegreeCourse: $isDegreeCourse, '
        'IsPassed: $isPassed, '
        'Remark: $remark'
        ')';
  }
}

/// 课程成绩模型
class CourseDataModel {
  String courseCode;
  String courseName;
  String courseType;
  double credit;
  double score;
  double gradePoint;

  CourseDataModel({
    required this.courseCode,
    required this.courseName,
    required this.courseType,
    required this.credit,
    required this.score,
    required this.gradePoint,
  });
  Map<String, dynamic> toJson() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'courseType': courseType,
      'credit': credit.toString(),
      'score': score.toString(),
      'gradePoint': gradePoint.toString(),
    };
  }

  factory CourseDataModel.fromJson(Map<String, dynamic> json) {
    return CourseDataModel(
      courseCode: json['courseCode'],
      courseName: json['courseName'],
      courseType: json['courseType'],
      credit: double.parse(json['credit']),
      score: double.parse(json['score']),
      gradePoint: double.parse(json['gradePoint']),
    );
  }

  @override
  String toString() {
    return 'CourseDataModel: { Course Code: $courseCode, Course Name: $courseName, Course Type: $courseType, Credit: $credit, Score: $score, Grade Point: $gradePoint }';
  }
}

/// 课程表根模型
class Coursesis {
  String teacherName;
  String courseName;
  String classroomNumber;
  String coursePeriod;
  String courseTimes;
  List coursePosition;
  Color color;
  String interal;
  bool state;
  String? sonName = "";
  String? sonTeac = "";
  String? sonInter = "";
  String? sonPeriod = "";
  Coursesis(
      {required this.teacherName,
      required this.courseName,
      required this.classroomNumber,
      required this.coursePeriod,
      required this.courseTimes,
      required this.coursePosition,
      required this.color,
      required this.interal,
      this.sonTeac,
      this.sonName,
      this.sonInter,
      this.sonPeriod,
      required this.state});
  Map<String, dynamic> toJson() {
    return {
      'teacherName': teacherName,
      'courseName': courseName,
      'classroomNumber': classroomNumber,
      'coursePeriod': coursePeriod,
      'courseTimes': courseTimes,
      'coursePosition': coursePosition,
      'color': color.toString(),
      'interal': interal,
      'state': state.toString(),
      'sonName': sonName,
      'sonTeac': sonTeac,
      'sonInter': sonInter,
      'sonPeriod': sonPeriod
    };
  }

  factory Coursesis.fromJson(Map<String, dynamic> json) {
    return Coursesis(
        teacherName: json['teacherName'],
        courseName: json['courseName'],
        classroomNumber: json['classroomNumber'],
        coursePeriod: json['coursePeriod'],
        courseTimes: json['courseTimes'],
        coursePosition: List.from(json['coursePosition']),
        color: Color(
            int.parse(json['color'].split('(0x')[1].split(')')[0], radix: 16)),
        interal: json['interal'],
        state: bool.parse(json['state']),
        sonName: json['sonName'],
        sonTeac: json['sonTeac'],
        sonInter: json['sonInter'],
        sonPeriod: json['sonPeriod']);
  }

  @override
  String toString() {
    return 'Coursesis { teacherName: $teacherName, courseName: $courseName, classroomNumber: $classroomNumber, coursePeriod: $coursePeriod, courseTimes: $courseTimes, coursePosition: $coursePosition }';
  }
}
