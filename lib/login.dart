// ignore_for_file: non_constant_identifier_names, unrelated_type_equality_checks

//import 'dart:html';
//import 'dart:io';
// import 'dart:io';
import 'package:flutter/material.dart';
//import 'package:html/parser.dart' show parse;
import 'dart:math';
import 'dart:convert';
import "package:dio/dio.dart";
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:crypto/crypto.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as htmlDom;

//import 'package:html/dom.dart' as html;
//import 'package:path_provider/path_provider.dart';
// 引入获取文件路径的包（提前安装）
//
// 引入文件下载的包
//import 'package:flutter_downloader/flutter_downloader.dart';
Future<List> getdaxuexi() async {
  Dio a = Dio();
  try {
    Response data = await a.get("http://49.235.106.67:5000/api/version");
    return data.data["daxuexi"];
  } catch (a) {
    return [];
  }
}

Future<List> getlog() async {
  Dio a = Dio();
  try {
    Response data = await a.get("http://49.235.106.67:5000/api/version");
    return data.data["log"];
  } catch (a) {
    return [];
  }
}

Future<String> getversion() async {
  Dio a = Dio();
  try {
    Response data = await a.get("http://49.235.106.67:5000/api/version");
    return data.data["version"];
  } catch (a) {
    return "2.0.0";
  }
}

Future<String> gettext() async {
  Dio a = Dio();
  try {
    Response data = await a.get("http://49.235.106.67:5000/api/version");
    return data.data["word"];
  } catch (e) {
    return "当前网络不佳";
  }
}

Future<List> getpass() async {
  Dio a = Dio();
  try {
    Response data = await a.get("http://49.235.106.67:5000/api/version");
    return data.data["pass"];
  } catch (e) {
    return ["0", "0", "0"];
  }
}

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

  @override
  String toString() {
    return 'CourseDataModel: { Course Code: $courseCode, Course Name: $courseName, Course Type: $courseType, Credit: $credit, Score: $score, Grade Point: $gradePoint }';
  }
}

class TaskActivity {
  final List<String> actTeacherId;
  final List<String> actTeacherName;
  final String courseCode;
  final String courseName;
  final String room;
  final String otherData;
  final String assistantName;

  TaskActivity(this.actTeacherId, this.actTeacherName, this.courseCode,
      this.courseName, this.room, this.otherData, this.assistantName);

  @override
  String toString() {
    return 'TaskActivity{actTeacherId: $actTeacherId, actTeacherName: $actTeacherName, courseCode: $courseCode, courseName: $courseName, room: $room, otherData: $otherData, assistantName: $assistantName}';
  }
}

class Courseresult {
  String teacherName;
  String courseName;
  String classroomNumber;
  String coursePeriod; // 53位的字符串，0表示无排课，1表示排课
  List<int> coursePosition;

  Courseresult({
    required this.teacherName,
    required this.courseName,
    required this.classroomNumber,
    required this.coursePeriod,
    required this.coursePosition,
  });

  @override
  String toString() {
    return 'Courseresult { teacherName: $teacherName, courseName: $courseName, classroomNumber: $classroomNumber, coursePeriod: $coursePeriod, coursePosition: $coursePosition }';
  }
}

class Coursesis {
  String teacherName;
  String courseName;
  String classroomNumber;
  String coursePeriod; // 53位的字符串，0表示无排课，1表示排课
  String courseTimes;
  List<int> coursePosition;
  Color color;
  Coursesis(
      {required this.teacherName,
      required this.courseName,
      required this.classroomNumber,
      required this.coursePeriod,
      required this.courseTimes,
      required this.coursePosition,
      required this.color});

  @override
  String toString() {
    return 'Coursesis { teacherName: $teacherName, courseName: $courseName, classroomNumber: $classroomNumber, coursePeriod: $coursePeriod, courseTimes: $courseTimes, coursePosition: $coursePosition }';
  }
}

class Evaluate {
  String url;
  String name;
  String course;
  String type;
  bool state;
  String id;
  Evaluate(
      {required this.url,
      required this.name,
      required this.course,
      required this.type,
      required this.state,
      required this.id});
}

class SourceAnalysis {
  List<Coursesis> Result(String Source) {
    RegExp regex =
        RegExp(r'<script.*?>(.*?)<\/script>', multiLine: true, dotAll: true);
    Iterable<Match> matches = regex.allMatches(Source);

    String prevJsCode = '';
    String lastButOneJsCode = '';

    for (Match match in matches) {
      lastButOneJsCode = prevJsCode;
      prevJsCode = match.group(1)!;
    }
    //print(lastButOneJsCode);
    List<String> structures = extractStructures(lastButOneJsCode);
    Coursesis course;
    List<Coursesis> result = [];
    structures.forEach((structure) {
      String teachersData = extractTeachersData(structure);
      List activity = extractActivityStatement(structure);
      List<int> position = extractposition(structure);
      course = Coursesis(
          teacherName: teachersData,
          courseName: activity[1],
          classroomNumber: activity[0],
          coursePeriod: activity[3],
          courseTimes: activity[4],
          coursePosition: position,
          color: const Color.fromARGB(255, 255, 255, 255));
      result.add(course);
    });
    return result;
  }

//整体结构分离
  List<String> extractStructures(String input) {
    List<String> structures = [];
    const startMarker = 'var teachers = [{id:';
    const endMarker =
        'table0.activities[index][table0.activities[index].length]=activity;';

    int startIndex = input.indexOf(startMarker);
    while (startIndex != -1) {
      int endIndex = input.indexOf(endMarker, startIndex);
      if (endIndex != -1) {
        structures
            .add(input.substring(startIndex, endIndex + endMarker.length));
        startIndex = input.indexOf(startMarker, endIndex + endMarker.length);
      } else {
        break;
      }
    }

    return structures;
  }

//提取教师名字
  String extractTeachersData(String input) {
    RegExp teachersRegExp = RegExp(r'var teachers = (\[{.*?}\]);');
    var match = teachersRegExp.firstMatch(input);

    if (match != null) {
      //String key = match.group(1)!;
      String keyword = 'name:"';

      int startIndex = input.indexOf(keyword) + keyword.length;
      int endIndex = input.indexOf('"', startIndex);
      return input.substring(startIndex, endIndex);
    }

    return "";
  }

//提取参数信息
  List extractActivityStatement(String input) {
    RegExp activityRegExp = RegExp(r'activity = new TaskActivity\((.*?)\);');
    var match = activityRegExp.firstMatch(input);
    List<String> dataList = [];
    if (match != null) {
      String data = match.group(0)!;

      RegExp dataRegExp = RegExp(r'"(.*?)"');
      Iterable<Match> matches = dataRegExp.allMatches(data);

      for (Match match in matches) {
        dataList.add(match.group(1)!);
      }

      return dataList;
    }
    return [];
  }

  List<int> extractposition(String input) {
    RegExp indexPattern =
        RegExp(r'index\s*=\s*(\d+)\s*\*\s*unitCount\s*\+\s*(\d+);');
    Match? match = indexPattern.firstMatch(input);

    if (match != null && match.groupCount == 2) {
      int index = int.parse(match.group(1)!);
      int unitCount = int.parse(match.group(2)!);
      return [index, unitCount];
    } else {
      return [];
    }
  }
}

class ExamData {
  final int id;
  final String courseName;
  final String examType;
  final String examDate;
  final String examTime;
  final String examRoom;
  final int capacity;
  final String examFormat;
  final String status;
  final bool ispass;

  ExamData({
    required this.id,
    required this.courseName,
    required this.examType,
    required this.examDate,
    required this.examTime,
    required this.examRoom,
    required this.capacity,
    required this.examFormat,
    required this.status,
    required this.ispass,
  });

  @override
  String toString() {
    return 'ExamData(id: $id, courseName: $courseName, examType: $examType, '
        'examDate: $examDate, examTime: $examTime, examRoom: $examRoom, '
        'capacity: $capacity, examFormat: $examFormat, status: $status, ispass: $ispass)';
  }
}

class Requests {
  String encryptPassword(String password, String hashkey) {
    String prefix = hashkey;
    String combinedPassword = prefix + password;
    var sha1Hash = sha1.convert(utf8.encode(combinedPassword)).toString();
    return sha1Hash;
  }

  String exHash(String webPage) {
    const String searchStr = "CryptoJS.SHA1('";
    int startIndex = webPage.indexOf(searchStr) + searchStr.length;
    int endIndex = webPage.indexOf("'", startIndex);
    return webPage.substring(startIndex, endIndex);
  }

  Future<List> Login(String account, String pass) async {
    Dio dio = Dio();
    var cookieJar = CookieJar(); // 创建一个 CookieJar 对象，用于自动管理 Cookie
    dio.interceptors.add(LogInterceptor()); // 添加一个日志拦截器，方便查看请求和响应日志
    dio.interceptors.add(CookieManager(cookieJar)); // 添加一个用于自动管理 Cookie 的拦截器
    dio.options.headers["User-Agent"] =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36 Edg/111.0.1661.51";
    Response response =
        await dio.post("http://jwc3.yangtzeu.edu.cn/eams/login.action");
    String password = encryptPassword(
        pass, exHash(response.data)); //解析第一次进入登陆页面的hash并与密码组合进行加密
    FormData data = FormData.fromMap({
      "username": account,
      "password": password,
    });
    Response callback = await dio.post(
      "http://jwc3.yangtzeu.edu.cn/eams/login.action",
      data: data,
      options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status != 500;
          }),
    ); //模拟登陆
    if (callback.data.contains("账号或密码错误")) {
      return [dio, 400];
    } else {
      return [dio, callback.statusCode];
    }
  }

  //获取计划完成情况
  Future<List> GetData(Dio dio) async {
    String url = "http://jwc3.yangtzeu.edu.cn/eams/myPlanCompl.action";

    Response call = await dio.get(url);
    List<Student> studentList = parseStudentTable(call.data);
    List<Course> courseList = parseCourseTable(call.data);
    return [studentList, courseList];
  }

  //获取课程表
  Future<List<List<Coursesis>>> GetSchedule(Dio dio, String key) async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/courseTableForStd!courseTable.action";
    String ids = await GetIds(dio);
    FormData data = FormData.fromMap({
      'ignoreHead': '1',
      'setting.kind': 'std',
      'startWeek': '',
      'semester.id': backyearid(key),
      'ids': ids
    });
    Response call = await dio.post(
      url,
      data: data,
    );
    SourceAnalysis sourceanalysis = SourceAnalysis();
    return Dispose(sourceanalysis.Result(call.data));
  }

//获取id属性
  Future<String> GetIds(Dio dio) async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/courseTableForStd.action?_=${DateTime.now().millisecondsSinceEpoch}";
    Response call = await dio.get(
      url,
    );
    RegExp regExp = RegExp(r'bg\.form\.addInput\(form,"ids","(\d+)"\);');
    Match? match = regExp.firstMatch(call.data.toString());

    if (match != null && match.groupCount >= 1) {
      String extractedNumber = match.group(1)!;
      return extractedNumber;
    } else {
      return "";
    }
  }

  Future<List<String>> GetExamIds(Dio dio) async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/stdExamTable.action?_=${DateTime.now().millisecondsSinceEpoch}";
    Response call = await dio.get(
      url,
    );

    return extractOptionValues(call.data);
  }

//获取考试安排
  Future<List<ExamData>> GetExam(Dio dio, bool mode) async {
    //debugPrint("考试源打印-经过1");
    List da = await GetExamIds(dio);
    List<ExamData> item = [];
    try {
      if (mode) {
        item = await getexamitem(dio, da[0]);
      } else {
        item = await getexamitem(dio, da[1]);
      }
    } catch (e) {
      Null;
    }
    //print(data);
    return item;
  }

  Future<List<ExamData>> getexamitem(Dio dio, String id) async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/stdExamTable!examTable.action?examBatch.id=$id";
    //debugPrint("考试源打印-经过3");
    Response examlist = await dio.get(url);
    // debugPrint(
    //     "考试源打印${examlist.toString()}++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
    var document = parser.parse(examlist.data);
    var table = document.querySelector('table'); // 直接选择第一个 <table> 元素
    //debugPrint("考试gen打印${table.toString()}");
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
      //debugPrint(examDataList.toString());
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
    //String endTime = timeParts[1];

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

  String backyearid(String name) {
    late String id;

    switch (name) {
      case "1995-1996 上学期":
        id = "2";
        break;
      case "1995-1996 下学期":
        id = "3";
        break;
      case "1996-1997 上学期":
        id = "4";
        break;
      case "1996-1997 下学期":
        id = "5";
        break;
      case "1997-1998 上学期":
        id = "6";
        break;
      case "1997-1998 下学期":
        id = "7";
        break;
      case "1998-1999 上学期":
        id = "8";
        break;
      case "1998-1999 下学期":
        id = "9";
        break;
      case "1999-2000 上学期":
        id = "10";
        break;
      case "1999-2000 下学期":
        id = "11";
        break;
      case "2000-2001 上学期":
        id = "12";
        break;
      case "2000-2001 下学期":
        id = "13";
        break;
      case "2001-2002 上学期":
        id = "14";
        break;
      case "2001-2002 下学期":
        id = "15";
        break;
      case "2002-2003 上学期":
        id = "16";
        break;
      case "2002-2003 下学期":
        id = "17";
        break;
      case "2003-2004 上学期":
        id = "18";
        break;
      case "2003-2004 下学期":
        id = "19";
        break;
      case "2004-2005 上学期":
        id = "20";
        break;
      case "2004-2005 下学期":
        id = "21";
        break;
      case "2005-2006 上学期":
        id = "22";
        break;
      case "2005-2006 下学期":
        id = "23";
        break;
      case "2006-2007 上学期":
        id = "24";
        break;
      case "2006-2007 下学期":
        id = "25";
        break;
      case "2007-2008 上学期":
        id = "26";
        break;
      case "2007-2008 下学期":
        id = "27";
        break;
      case "2008-2009 上学期":
        id = "28";
        break;
      case "2008-2009 下学期":
        id = "29";
        break;
      case "2009-2010 上学期":
        id = "30";
        break;
      case "2009-2010 下学期":
        id = "31";
        break;
      case "2010-2011 上学期":
        id = "32";
        break;
      case "2010-2011 下学期":
        id = "33";
        break;
      case "2011-2012 上学期":
        id = "34";
        break;
      case "2011-2012 下学期":
        id = "35";
        break;
      case "2012-2013 上学期":
        id = "36";
        break;
      case "2012-2013 下学期":
        id = "37";
        break;
      case "2013-2014 上学期":
        id = "38";
        break;
      case "2013-2014 下学期":
        id = "39";
        break;
      case "2014-2015 上学期":
        id = "40";
        break;
      case "2014-2015 下学期":
        id = "41";
        break;
      case "2015-2016 上学期":
        id = "42";
        break;
      case "2015-2016 下学期":
        id = "43";
        break;
      case "2016-2017 上学期":
        id = "44";
        break;
      case "2016-2017 下学期":
        id = "45";
        break;
      case "2017-2018 上学期":
        id = "46";
        break;
      case "2017-2018 下学期":
        id = "48";
        break;
      case "2018-2019 上学期":
        id = "49";
        break;
      case "2018-2019 下学期":
        id = "69";
        break;
      case "2019-2020 上学期":
        id = "89";
        break;
      case "2019-2020 下学期":
        id = "109";
        break;
      case "2020-2021 上学期":
        id = "169";
        break;
      case "2020-2021 下学期":
        id = "189";
        break;
      case "2021-2022 上学期":
        id = "209";
        break;
      case "2021-2022 下学期":
        id = "229";
        break;
      case "2022-2023 上学期":
        id = "249";
        break;
      case "2022-2023 下学期":
        id = "269";
        break;
      case "2023-2024 上学期":
        id = "289";
        break;
      case "2023-2024 下学期":
        id = "309";
        break;
      case "2024-2025 上学期":
        id = "329";
        break;
      case "2024-2025 下学期":
        id = "349";
        break;
      case "2025-2026 上学期":
        id = "369";
        break;
      case "2025-2026 下学期":
        id = "389";
        break;
      case "2026-2027 上学期":
        id = "409";
        break;
      case "2026-2027 下学期":
        id = "429";
        break;
      default:
        id = ""; // 如果没有匹配的情况，可以选择设置一个默认值
        break;
    }

    return id;
  }

  List<String> extractOptionValues(String html) {
    List<String> optionValues = [];

    // 解析HTML源码
    var document = parser.parse(html);

    // 获取所有的<option>标签
    List<htmlDom.Element> optionTags = document.getElementsByTagName('option');

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

//获取成绩
  Future<List<CourseDataModel>> Getgrade(Dio dio, String key) async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/teach/grade/course/person!search.action?semesterId=${backyearid(key)}&projectType=";
    Response call = await dio.get(url);
    List<CourseDataModel> studentList = parseTableData(call.data);
    try {
      studentList.removeAt(0);
    } catch (w) {
      Null;
    }

    for (CourseDataModel son in studentList) {
      son.courseName = son.courseName.replaceAll('（', '').replaceAll('）', '');
    }
    return studentList;
  }

//获取量化评教
  Future<List<Evaluate>> GetEvaluate(Dio dio) async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/quality/stdEvaluate.action?_=${DateTime.now().millisecondsSinceEpoch}";
    //String ids = await GetIds(dio);
    // FormData data = FormData.fromMap({
    //   'ignoreHead': '1',
    //   'semester.id': backyearid(key),
    // });
    Response call = await dio.get(
      url,
      //data: data,
    );
    // Parse the HTML content
    List<Evaluate> asc = [];
    // 解析HTML内容
    var document = parser.parse(call.data);

    // 获取表格中所有行
    var rows = document.querySelectorAll('tbody tr');

    for (var row in rows) {
      // 提取单元格信息
      var columns = row.children;

      // 提取课程名称、教师名称和链接地址
      //String label = columns[0].text;
      String courseName = columns[1].text;
      String teacher = columns[3].text;
      String type = columns[2].text;
      bool evastate;
      String link = "";
      String evaluationLessonId = "";
      try {
        link = columns[5].querySelector('a')!.attributes['href']!;
        Uri uri = Uri.parse(link);
        evaluationLessonId = uri.queryParameters['evaluationLesson.id']!;

        evastate = false;
      } catch (e) {
        link = "";
        evastate = true;
      }

      // 根据需要使用提取的信息
      asc.add(Evaluate(
          url: link,
          course: removeParentheses(courseName),
          type: type,
          name: teacher,
          state: evastate,
          id: evaluationLessonId));
    }
    return asc;
  }

  //获取提交量化评教
  Future GetSEvaluatePush(Dio dio, String key, String label, type) async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/quality/stdEvaluate!finishAnswer.action";
    //String ids = await GetIds(dio);
    FormData data = FormData.fromMap({
      "teacher.id": "",
      "semester.id": backyearid(key),
      "evaluationLesson.id": label,
      "result1_0.questionName": "教学严谨，为人师表，上课精神饱满，认真负责",
      "result1_0.content": "非常满意",
      "result1_0.score": "10",
      "result1_1.questionName": "教师遵守教学纪律，无迟到、早退、随意调停课情况",
      "result1_1.content": "非常满意",
      "result1_1.score": "10",
      "result1_2.questionName": "按时安排辅导答疑，作业布置适量，作业批改及时认真",
      "result1_2.content": "非常满意",
      "result1_2.score": "10",
      "result1_3.questionName": "备课充分，脉络清晰，重点难点突出",
      "result1_3.content": "非常满意",
      "result1_3.score": "10",
      "result1_4.questionName": "注重将知识传授、能力提升与理想信念、价值引领、家国情怀等课程思政教育有机融合",
      "result1_4.content": "非常满意",
      "result1_4.score": "10",
      "result1_5.questionName": "教材选用合理，能反映或联系学科新思想、新概念、新成果",
      "result1_5.content": "非常满意",
      "result1_5.score": "10",
      "result1_6.questionName": "课堂讲授技巧及语言表达能力好，能合理、有效运用互动式、启发式、研讨式等教学方式",
      "result1_6.content": "非常满意",
      "result1_6.score": "10",
      "result1_7.questionName": "能合理、有效使用信息化、智能化等现代教学手段",
      "result1_7.content": "非常满意",
      "result1_7.score": "10",
      "result1_8.questionName": "对该门课程感兴趣，掌握了该门课程的知识和技能",
      "result1_8.content": "非常满意",
      "result1_8.score": "10",
      "result1_9.questionName": "学习方法及解决相关问题的能力得到提高，收获大",
      "result1_9.content": "非常满意",
      "result1_9.score": "10",
      "result1Num": "10",
      "result2Num": "0"
    });
    FormData data_Practice = FormData.fromMap({
      "teacher.id": "",
      "semester.id": backyearid(key),
      "evaluationLesson.id": label,
      "result1_0.questionName": "教学严谨，为人师表，上课精神饱满，认真负责",
      "result1_0.content": "非常满意",
      "result1_0.score": "10",
      "result1_1.questionName": "课前准备充分，安全措施得当，积极巡视，认真指导，过程记录完整",
      "result1_1.content": "非常满意",
      "result1_1.score": "10",
      "result1_2.questionName": "教学目标明确，与理论课内容相衔接",
      "result1_2.content": "非常满意",
      "result1_2.score": "10",
      "result1_3.questionName": "对课堂目标、操作要点等讲解清晰，教师讲解与学生操作训练时间分配合理",
      "result1_3.content": "非常满意",
      "result1_3.score": "10",
      "result1_4.questionName": "注重将知识传授、能力提升与理想信念、价值引领、家国情怀等课程思政教育有机融合",
      "result1_4.content": "非常满意",
      "result1_4.score": "10",
      "result1_5.questionName": "将安全、职业道德教育融入教学全过程",
      "result1_5.content": "非常满意",
      "result1_5.score": "10",
      "result1_6.questionName": "讲授技巧及语言表达能力好，能合理、有效运用互动式、启发式、研讨式等教学方式",
      "result1_6.content": "非常满意",
      "result1_6.score": "10",
      "result1_7.questionName": "分组合理，实践充分，因材施教",
      "result1_7.content": "非常满意",
      "result1_7.score": "10",
      "result1_8.questionName": "突出学生的主体地位,重视实践能力和创新精神的培养，注重指导学生独立自主地进行实践实训",
      "result1_8.content": "非常满意",
      "result1_8.score": "10",
      "result1_9.questionName": "通过实践实训进一步加深了对理论知识的理解，动手能力及分析、解决问题的能力得到提高",
      "result1_9.content": "非常满意",
      "result1_9.score": "10",
      "result1Num": "10",
      "result2Num": "0"
    });
    await dio.post(
      url,
      data: type == "实践" ? data_Practice : data,
      options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! <= 500;
          }),
    );
  }

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

  List<TaskActivity> ATaskActivities(String jsSourceCode) {
    List<TaskActivity> activities = [];

    RegExp regExp = RegExp(
      r'activity = new TaskActivity\(\[([^]]*)\],\[([^]]*)\],"([^"]*)","([^"]*)","([^"]*)","([^"]*)","([^"]*)",null,null,"([^"]*)","",""\);',
      multiLine: true,
    );

    Iterable<RegExpMatch> matches = regExp.allMatches(jsSourceCode);
    for (var match in matches) {
      List<String> actTeacherId = match.group(1)!.split(',');
      List<String> actTeacherName = match.group(2)!.split(',');
      String courseCode = match.group(3)!;
      String courseName = match.group(4)!;
      String room = match.group(5)!;
      String otherData = match.group(6)!;
      String assistantName = match.group(7)!;

      TaskActivity activity = TaskActivity(actTeacherId, actTeacherName,
          courseCode, courseName, room, otherData, assistantName);
      activities.add(activity);
    }

    return activities;
  }

  int coordinateToIndex(int x, int y) {
    if (x < 0 || x >= 7 || y < 0 || y >= 8) {
      throw ArgumentError('坐标超出范围');
    }
    return y * 7 + x;
  }

//删除英文括号内和中文括号本身
  String removeParentheses(String input) {
    final regex = RegExp(r'\([^)]*\)');
    return input
        .replaceAll(regex, '')
        .trim()
        .replaceAll('（', '')
        .replaceAll('）', '');
  }

  String removespace(String input) {
    return input.replaceAll(" ", "");
  }

  List<Coursesis> updateColors(List<Coursesis> inputList) {
    List<Coursesis> resultList = [];
    Map<String, Color> colorMap = {};

    for (Coursesis model in inputList) {
      if (colorMap.containsKey(model.courseName)) {
        model.color = colorMap[model.courseName]!;
      } else {
        Color newColor = _generateRandomColor();
        while (colorMap.containsValue(newColor)) {
          newColor = _generateRandomColor();
        }
        colorMap[model.courseName] = newColor;
        model.color = newColor;
      }
      resultList.add(model);
    }

    return resultList;
  }

  Color _generateRandomColor() {
    final random = Random();
    final baseHue = random.nextDouble() * 360.0;
    final saturation = 0.5 + random.nextDouble() * 0.3;
    final lightness = 0.7 + random.nextDouble() * 0.3;

    return HSLColor.fromAHSL(1.0, baseHue, saturation, lightness).toColor();
  }

  List<List<Coursesis>> Dispose(List<Coursesis> data) {
    List<List<Coursesis>> OneYear = List.generate(21, (index) => []);

    data = updateColors(data);
    for (Coursesis course in data) {
      int tip =
          coordinateToIndex(course.coursePosition[0], course.coursePosition[1]);
      course.coursePosition[0] = tip;

      String name = removeParentheses(course.courseName);
      course.courseName = name;
      String position = removespace(course.coursePeriod);
      course.coursePeriod = position;
      for (int i = 0; i < 21; i++) {
        if (course.courseTimes[i] == '1') {
          //course.courseTimes = "";
          OneYear[i].add(course);
        }
      }
    }
    int a = 0;
    for (List<Coursesis> value in OneYear) {
      List<Coursesis> conter = List.generate(
          56,
          (index) => Coursesis(
              teacherName: "",
              courseName: "",
              classroomNumber: "",
              coursePeriod: "",
              courseTimes: "",
              coursePosition: [0, 0],
              color: Colors.white));
      for (Coursesis result in value) {
        if (result.coursePosition[0] < 56) {
          conter[result.coursePosition[0]] = result;
        } else {
          null;
        }
      }
      OneYear[a] = conter;
      a++;
    }
    OneYear.removeAt(0);
    return OneYear;
  }
}

// class SelectCourse {
//   //获取选课列表
//   Future<List<Map>> GetSelectList(Dio dio) async {
//     String url =
//         "http://jwc3.yangtzeu.edu.cn/eams/stdElectCourse.action?_=${DateTime.now().millisecondsSinceEpoch}";
//     Response response = await dio.get(url);
//     var document = parser.parse(response.data);
//     List<Map<String, String>> extractedData = [];
//     document
//         .querySelectorAll('.ajax_container > div[id^="electIndexNotice"]')
//         .forEach((container) {
//       String title = container.querySelector('h2')?.text ?? '';
//       String url = container.querySelector('a')?.attributes['href'] ?? '';
//       Map<String, String> outlineData = {
//         'title': title.split("-")[3],
//         'url': url,
//       };
//       extractedData.add(outlineData);
//     });
//     return extractedData;
//   }
// }

//日期计算器
List<String> calculateDates(int currentWeek) {
  List<String> dates = [];

  DateTime startDate = DateTime(2024, 2, 26); // 设置起始日期为 2024 年 2 月 26 日

  for (int i = 0; i < 7; i++) {
    DateTime date = startDate.add(Duration(days: (currentWeek - 1) * 7 + i));
    String dateString = '${date.month}/${date.day}';
    dates.add(dateString);
  }

  return dates;
}

int getCurrentDayOfWeek() {
  DateTime now = DateTime.now();
  int dayOfWeek = now.weekday - 1; // 星期的枚举值从1开始，我们将其映射到0~6的整数

  return dayOfWeek;
}

//课程表时间筛子
List extractColumnData(List array, int columns, int targetColumn) {
  int rows = (array.length / columns).ceil(); // 计算行数

  List columnIndexes = List.generate(
      rows, (index) => index * columns + targetColumn); // 计算目标列的索引

  List result = columnIndexes.map((index) => array[index]).toList();

  return result;
}

//课程进度
double getCurrentTimeInFloat() {
  DateTime now = DateTime.now();
  int totalMinutes = now.hour * 60 + now.minute;

  int start1 = 8 * 60;
  int end1 = 9 * 60 + 35;

  int start2 = 10 * 60 + 5;
  int end2 = 11 * 60 + 40;

  int start3 = 14 * 60;
  int end3 = 15 * 60 + 35;

  int start4 = 16 * 60 + 5;
  int end4 = 17 * 60 + 40;

  int start5 = 19 * 60;
  int end5 = 20 * 60 + 30;

  if (totalMinutes < start1) {
    return 0.0;
  } else if (totalMinutes <= end1) {
    return (totalMinutes - start1) / (end1 - start1) / 2;
  } else if (totalMinutes < start2) {
    return 0.4;
  } else if (totalMinutes <= end2) {
    return 0.4 + (totalMinutes - start2) / (end2 - start2) / 2;
  } else if (totalMinutes < start3) {
    return 0.4;
  } else if (totalMinutes <= end3) {
    return 0.4 + (totalMinutes - start3) / (end3 - start3) / 2;
  } else if (totalMinutes < start4) {
    return 0.8;
  } else if (totalMinutes <= end4) {
    return 0.8 + (totalMinutes - start4) / (end4 - start4) / 2;
  } else if (totalMinutes < start5) {
    return 0.8;
  } else if (totalMinutes <= end5) {
    return 0.8 + (totalMinutes - start5) / (end5 - start5) / 2;
  } else {
    return 1.0;
  }
}

//时间进度
double getDailyTimeProgress() {
  DateTime now = DateTime.now();
  int totalMinutes = now.hour * 60 + now.minute;

  return totalMinutes / (24 * 60);
}

//课程表钟点筛子
int getCurrentTimeSlot() {
  DateTime now = DateTime.now();
  TimeOfDay currentTime = TimeOfDay.fromDateTime(now);

  int startTimeHour = 7; // 开始时间的小时数
  int endTimeHour = 20; // 结束时间的小时数

  const int totalSlots = 8; // 时间区间总数
  int hourDiff = endTimeHour - startTimeHour; // 开始时间和结束时间之间的小时差
  int slotDuration = (hourDiff / totalSlots).floor(); // 每个时间区间的小时数

  int currentHour = currentTime.hour;
  int currentMinute = currentTime.minute;

  int currentSlot = ((currentHour - startTimeHour) * 60 + currentMinute) ~/
      (slotDuration * 60);

  return currentSlot.clamp(0, totalSlots - 1); // 将结果限制在0到totalSlots - 1之间
}

//获取青年大学习列表
Future<List> TeenStudy() async {
  List urls = [];
  String url = "https://h5.cyol.com/special/daxuexi/daxuexiall19/m.html?t=1";
  try {
    Response response = await Dio().get(url);
    var document = parser.parse(response.data);
    var scriptTags = document.querySelectorAll('script');
    var pattern = RegExp(r"location\.href='(.*?)';");
    String data = scriptTags[11].innerHtml;
    var matches = pattern.allMatches(data);

    for (var match in matches) {
      var locationHrefValue = match.group(1);
      //print('Location.href value: $locationHrefValue');
      urls.add(locationHrefValue);
    }
  } catch (e) {
    Null;
  }
  return urls;
}

String extractIdFromUrl(String url) {
  var pattern = RegExp(r"/daxuexi/(\w+)/m.html");

  var match = pattern.firstMatch(url);

  if (match != null) {
    var id = match.group(1);
    return id.toString();
  } else {
    return ""; // 如果没有匹配到，返回null或其他你认为合适的值
  }
}
// void main() async {
//   Requests lizi = Requests();
//   String page;
//   List insert = await lizi.Login("2022007923", "1234ZXCVBN@rt");
//   page = await lizi.GetData(insert[0]);
//   List<Student> studentList = parseStudentTable(page);
//   List<Course> courseList = parseCourseTable(page);
//}