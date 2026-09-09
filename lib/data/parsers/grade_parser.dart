// 抽取自原 lib/login.dart Requests 内的成绩 HTML 表格解析（Getgrade/GetAllGrade 使用，L782-846、L1465-1497）：
// 纯解析函数，无 IO、无网络。

import 'package:html/parser.dart' as parser;

import '../models/course.dart';
import '../models/grade.dart';
import 'timetable_parser.dart' show removeParentheses;

/// 解析全部成绩页的学期汇总表（原 Requests.gradeanlysis）
List<GradeAverange> gradeanlysis(dynamic table) {
  var rows = table.querySelectorAll('tr');
  rows.removeAt(0);
  rows.removeAt(rows.length - 1);
  rows.removeAt(rows.length - 1);
  List<GradeAverange> gradedata = [];
  for (var row in rows) {
    var cells = row.querySelectorAll('td, th');
    List items = [];
    for (var cell in cells) {
      items.add(cell.text);
    }
    GradeAverange item = GradeAverange(
        year: items[0],
        semester: int.parse(items[1]),
        number: int.parse(items[2]),
        totalgrade: double.parse(items[3]),
        averangegrade: double.parse(items[4]));
    gradedata.add(item);
  }
  return gradedata;
}

/// 解析全部成绩页的课程明细表（原 Requests.courseanlysis）
List<CourseTotal> courseanlysis(dynamic table) {
  var rows = table.querySelectorAll('tr');
  rows.removeAt(0);

  List<CourseTotal> data = [];
  for (var row in rows) {
    var cells = row.querySelectorAll('td, th');
    List items = [];
    for (var cell in cells) {
      items.add(cell.text.replaceAll(" ", ""));
    }
    CourseTotal total;
    if (items.length == 10) {
      total = CourseTotal(
          academicYear: items[0],
          courseCode: items[1],
          courseNum: items[2],
          courseName: removeParentheses(items[3]),
          courseType: items[4],
          credit: items[5].trim(),
          reexamScore: items[6].trim(),
          totalScore: items[7].trim(),
          finalScore: items[8].trim(),
          gradePoint: items[9].trim());
    } else {
      total = CourseTotal(
          academicYear: items[0],
          courseCode: items[1],
          courseNum: items[2],
          courseName: removeParentheses(items[3]),
          courseType: items[4],
          credit: items[5].trim(),
          //reexamScore: items[6].trim(),
          totalScore: items[6].trim(),
          finalScore: items[7].trim(),
          gradePoint: items[8].trim());
    }
    data.add(total);
  }
  return data;
}

/// 解析某学期成绩查询页表格（原 Requests.parseTableData）
List<CourseDataModel> parseTableData(String html) {
  List<CourseDataModel> courses = [];
  var document = parser.parse(html);
  var tableRows = document.querySelectorAll('tr');

  for (var row in tableRows) {
    var rowData = row.children;

    if (rowData.length != 9) {
      continue; // Skip rows that don't have the expected number of columns
    }

    var courseCode = rowData[1].text.trim();
    var courseName = rowData[3].text.trim();
    var courseType = rowData[4].text.trim();
    var credit = double.tryParse(rowData[5].text.trim()) ?? 0.0;
    var score = double.tryParse(rowData[7].text.trim()) ?? 0.0;
    var gradePoint = double.tryParse(rowData[8].text.trim()) ?? 0.0;

    var courseData = CourseDataModel(
      courseCode: courseCode,
      courseName: courseName,
      courseType: courseType,
      credit: credit,
      score: score,
      gradePoint: gradePoint,
    );

    courses.add(courseData);
  }

  return courses;
}
