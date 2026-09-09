// 抽取自原 lib/login.dart（L389-553）：GradeAverange（全部成绩页学期汇总）、
// CourseTotal（课程成绩），字段/构造/序列化行为保持不变。

/// 全部成绩页模型
class GradeAverange {
  final int semester;
  final int number;
  final String year;
  final double totalgrade;
  final double averangegrade;
  GradeAverange(
      {required this.number,
      required this.year,
      required this.totalgrade,
      required this.averangegrade,
      required this.semester});

  Map<String, dynamic> toJson() {
    return {
      'number': number.toString(),
      'year': year,
      'totalgrade': totalgrade.toString(),
      'averangegrade': averangegrade.toString(),
      'semester': semester.toString(),
    };
  }

  factory GradeAverange.fromJson(Map<String, dynamic> json) {
    return GradeAverange(
      number: int.parse(json['number']),
      year: json['year'],
      totalgrade: double.parse(json['totalgrade']),
      averangegrade: double.parse(json['averangegrade']),
      semester: int.parse(json['semester']),
    );
  }

  @override
  String toString() {
    return "年份:$year 学期:$semester 必修数:$number 总成绩:$totalgrade 平均成绩:$averangegrade";
  }
}

/// 课程成绩模型
class CourseTotal {
  String academicYear; // 学年学期
  String courseCode; // 课程代码
  String courseNum; // 课程序号
  String courseName; // 课程名称
  String courseType; // 课程类别
  String credit; // 学分
  String? reexamScore; // 补考成绩
  String totalScore; // 总评成绩
  String finalScore; // 最终成绩
  String gradePoint; // 绩点

  CourseTotal({
    required this.academicYear,
    required this.courseCode,
    required this.courseNum,
    required this.courseName,
    required this.courseType,
    required this.credit,
    required this.totalScore,
    required this.finalScore,
    required this.gradePoint,
    this.reexamScore,
  });
  Map<String, dynamic> toJson() {
    return {
      'academicYear': academicYear,
      'courseCode': courseCode,
      'courseNum': courseNum,
      'courseName': courseName,
      'courseType': courseType,
      'credit': credit,
      'reexamScore': reexamScore,
      'totalScore': totalScore,
      'finalScore': finalScore,
      'gradePoint': gradePoint,
    };
  }

  factory CourseTotal.fromJson(Map<String, dynamic> json) {
    return CourseTotal(
      academicYear: json['academicYear'],
      courseCode: json['courseCode'],
      courseNum: json['courseNum'],
      courseName: json['courseName'],
      courseType: json['courseType'],
      credit: json['credit'],
      reexamScore: json['reexamScore'],
      totalScore: json['totalScore'],
      finalScore: json['finalScore'],
      gradePoint: json['gradePoint'],
    );
  }

  @override
  String toString() {
    return 'CourseModel{学年学期: $academicYear, 课程代码: $courseCode, 课程序号: $courseNum, '
        '课程名称: $courseName, 课程类别: $courseType, 学分: $credit, 补考成绩: $reexamScore, '
        '总评成绩: $totalScore, 最终: $finalScore, 绩点: $gradePoint}';
  }
}
