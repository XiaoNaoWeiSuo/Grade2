// 抽取自原 lib/login.dart Student（L74-163）：学号数据标准模型，字段/构造/序列化行为保持不变。

/// 学号数据标准模型
class Student {
  String studentId;
  String name;
  String grade;
  String educationLevel;
  String studentCategory;
  String department;
  String major;
  double requiredCredits;
  double earnedCredits;
  double gpa;
  String auditResult;
  DateTime auditTime;
  String auditor;
  String remark;
  Student({
    required this.studentId,
    required this.name,
    required this.grade,
    required this.educationLevel,
    required this.studentCategory,
    required this.department,
    required this.major,
    required this.requiredCredits,
    required this.earnedCredits,
    required this.gpa,
    required this.auditResult,
    required this.auditTime,
    required this.auditor,
    required this.remark,
  });
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'name': name,
      'grade': grade,
      'educationLevel': educationLevel,
      'studentCategory': studentCategory,
      'department': department,
      'major': major,
      'requiredCredits': requiredCredits.toString(),
      'earnedCredits': earnedCredits.toString(),
      'gpa': gpa.toString(),
      'auditResult': auditResult,
      'auditTime': auditTime.toIso8601String(),
      'auditor': auditor,
      'remark': remark,
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['studentId'],
      name: json['name'],
      grade: json['grade'],
      educationLevel: json['educationLevel'],
      studentCategory: json['studentCategory'],
      department: json['department'],
      major: json['major'],
      requiredCredits: double.parse(json['requiredCredits']),
      earnedCredits: double.parse(json['earnedCredits']),
      gpa: double.parse(json['gpa']),
      auditResult: json['auditResult'],
      auditTime: DateTime.parse(json['auditTime']),
      auditor: json['auditor'],
      remark: json['remark'],
    );
  }

  @override
  String toString() {
    return 'Student('
        'StudentId: $studentId, '
        'Name: $name, '
        'Grade: $grade, '
        'EducationLevel: $educationLevel, '
        'StudentCategory: $studentCategory, '
        'Department: $department, '
        'Major: $major, '
        'RequiredCredits: $requiredCredits, '
        'EarnedCredits: $earnedCredits, '
        'GPA: $gpa, '
        'AuditResult: $auditResult, '
        'AuditTime: $auditTime, '
        'Auditor: $auditor, '
        'Remark: $remark'
        ')';
  }
}
