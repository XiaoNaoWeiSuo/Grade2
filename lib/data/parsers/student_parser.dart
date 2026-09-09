// 抽取自原 lib/login.dart Requests.parseStudentTable / parseCourseTable（L1355-1463）：
// HTML→模型 的纯解析函数，签名保持，无 IO、无网络。

import 'package:html/parser.dart' as parser;

import '../models/course.dart';
import '../models/student.dart';

/// 解析计划完成情况页中的学生信息表（原 Requests.parseStudentTable）
List<Student> parseStudentTable(String htmlSource) {
  List<Student> studentList = [];
  var document = parser.parse(htmlSource);

  var table = document.querySelector('table.infoTable');
  if (table == null) {
    return studentList;
  }

  var rows = table.querySelectorAll('tr');
  if (rows.length < 5) {
    return studentList;
  }

  var cells = rows[0].querySelectorAll('td.content');
  var studentId = cells[0].text.trim();
  var name = cells[1].text.trim();
  var grade = cells[2].text.trim();

  cells = rows[1].querySelectorAll('td.content');
  var educationLevel = cells[0].text.trim();
  var studentCategory = cells[1].text.trim();
  var department = cells[2].text.trim();

  cells = rows[2].querySelectorAll('td.content');
  var major = cells[0].text.trim();
  var credits = cells[1].text.split('/');
  var requiredCredits = double.tryParse(credits[0].trim()) ?? 0;
  var earnedCredits = double.tryParse(credits[1].trim()) ?? 0;
  var gpa = double.tryParse(cells[2].text.trim()) ?? 0.0;

  cells = rows[3].querySelectorAll('td.content');
  var auditResult = cells[0].text.trim();
  var auditTime = DateTime.tryParse(cells[1].text.trim());
  var auditor = cells[2].text.trim();

  cells = rows[4].querySelectorAll('td.content');
  var remark = cells[0].text.trim();

  var student = Student(
    studentId: studentId,
    name: name,
    grade: grade,
    educationLevel: educationLevel,
    studentCategory: studentCategory,
    department: department,
    major: major,
    requiredCredits: requiredCredits,
    earnedCredits: earnedCredits,
    gpa: gpa,
    auditResult: auditResult,
    auditTime: auditTime ?? DateTime(0),
    auditor: auditor,
    remark: remark,
  );

  studentList.add(student);
  return studentList;
}

/// 解析计划完成情况页中的课程表格（原 Requests.parseCourseTable）
List<Course> parseCourseTable(String htmlSource) {
  List<Course> courseList = [];
  var document = parser.parse(htmlSource);

  var table = document.querySelector('div#chartView table.formTable');
  if (table == null) {
    return courseList;
  }

  var rows = table.querySelectorAll('tr');
  if (rows.length < 2) {
    return courseList;
  }

  for (var i = 1; i < rows.length; i++) {
    var cells = rows[i].querySelectorAll('td');
    if (cells.length < 10) {
      continue;
    }

    var serialNumber = int.tryParse(cells[0].text.trim()) ?? 0;
    var courseCode = cells[1].text.trim();
    var courseName = cells[2].text.trim();
    var requiredCredits = int.tryParse(cells[3].text.trim()) ?? 0;
    var earnedCredits = int.tryParse(cells[4].text.trim()) ?? 0;
    var score = cells[5].text.trim();
    var isCompulsory = cells[6].text.trim();
    var isDegreeCourse = cells[7].text.trim();
    var isPassed = cells[8].text.trim();
    var remark = cells[9].text.trim();

    var course = Course(
      serialNumber: serialNumber,
      courseCode: courseCode,
      courseName: courseName,
      requiredCredits: requiredCredits,
      earnedCredits: earnedCredits,
      score: score,
      isCompulsory: isCompulsory,
      isDegreeCourse: isDegreeCourse,
      isPassed: isPassed,
      remark: remark,
    );

    courseList.add(course);
  }

  return courseList;
}
