// 抽取自原 lib/login.dart Requests.GetExam / getexamitem / extractOptionValues 内的解析逻辑
//（L866-961、L1167-1189）：纯解析函数，无 IO、无网络。

import 'package:html/parser.dart' as parser;

import '../models/exam_data.dart';
import 'timetable_parser.dart' show removeParentheses;

/// 提取考试批次下拉框 <option> 的 value（原 Requests.extractOptionValues）
List<String> extractOptionValues(String html) {
  List<String> optionValues = [];

  // 解析HTML源码
  var document = parser.parse(html);

  // 获取所有的<option>标签
  var optionTags = document.getElementsByTagName('option');

  // 遍历<option>标签，提取value值
  for (var optionTag in optionTags) {
    var value = optionTag.attributes['value'];

    // 只提取符合条件的<option>标签的value值
    if (value != null && value.isNotEmpty) {
      optionValues.add(value);
    }
  }
  if (optionValues.length == 1) {
    optionValues.add(optionValues[0]);
  }
  return optionValues;
}

/// 解析考试安排表格（原 Requests.getexamitem 的 HTML 解析部分），结果按考试时间升序
List<ExamData> parseExamItem(String html) {
  var document = parser.parse(html);
  var table = document.querySelector('table'); // 直接选择第一个 <table> 元素
  List<ExamData> examDataList = [];
  if (table != null) {
    var rows = table.querySelectorAll('tr');
    for (var row in rows) {
      var cells = row.querySelectorAll('td');
      if (cells.length >= 10) {
        // 假设表格至少有10个单元格
        var data = cells.map((cell) => cell.text.trim()).toList();

        examDataList.add(ExamData(
            id: int.parse(data[0]),
            courseName: removeParentheses(data[1]),
            examType: data[2],
            examDate: (data[3].contains("未安排") ? "2000-00-00" : data[3]),
            examTime: (data[4].contains("未安排") ? "0:00~0:00" : data[4]),
            examRoom: data[5],
            capacity: int.parse(data[6].contains("未安排") ? "00" : data[6]),
            examFormat: data[7],
            status: data[8],
            ispass: _parseDateTime(
              (data[3].contains("未安排") ? "2000-00-00" : data[3]),
              (data[4].contains("未安排") ? "0:00~0:00" : data[4]),
            ).isBefore(DateTime.now())));
      }
    }
  } else {
    return [];
  }
  examDataList.sort((a, b) {
    DateTime dateTimeA = _parseDateTime(a.examDate, a.examTime);
    DateTime dateTimeB = _parseDateTime(b.examDate, b.examTime);

    return dateTimeA.compareTo(dateTimeB);
  });
  return examDataList;
}

DateTime _parseDateTime(String date, String time) {
  List<String> timeParts = time.split('~');
  String startTime = timeParts[0];

  List<String> dateParts = date.split('-');
  int year = int.parse(dateParts[0]);
  int month = int.parse(dateParts[1]);
  int day = int.parse(dateParts[2]);

  DateTime dateTime = DateTime(year, month, day);
  DateTime startTimeDateTime = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      int.parse(startTime.split(':')[0]),
      int.parse(startTime.split(':')[1]));

  return startTimeDateTime;
}
