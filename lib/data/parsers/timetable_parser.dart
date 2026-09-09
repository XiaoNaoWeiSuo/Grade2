// 抽取自原 lib/login.dart：SourceAnalysis（L554-690）、Dispose 课表后处理（L1598-1652）、
// updateColors 颜色分配（L1557-1587）、backyearid 学期名→ID 硬编码 switch（原 Requests 内，L963-1165）。
// 全部为纯解析/纯处理逻辑，无 IO、无网络。原 Dispose/Result 按命名规范改为 dispose/result。

import 'dart:math';

import 'package:flutter/material.dart';

import '../models/course.dart';

/// 课表页面 JS 源码解析（原 Requests.SourceAnalysis）
class SourceAnalysis {
  /// 从页面源码解析出课程列表（原 Result）
  List<Coursesis> result(String source) {
    RegExp regex =
        RegExp(r'<script.*?>(.*?)<\/script>', multiLine: true, dotAll: true);
    Iterable<Match> matches = regex.allMatches(source);

    String prevJsCode = '';
    String lastButOneJsCode = '';

    for (Match match in matches) {
      lastButOneJsCode = prevJsCode;
      prevJsCode = match.group(1)!;
    }
    List<String> structures = extractStructures(lastButOneJsCode);
    Coursesis course;
    List<Coursesis> result = [];
    for (String structure in structures) {
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
          state: false,
          color: const Color.fromARGB(255, 255, 255, 255),
          interal: activity[4].substring(0, 20));
      result.add(course);
    }

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

  //化简00001110000...   [4,6]
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

/// 学期名→学期ID 的硬编码映射（原 Requests.backyearid）
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

//删除英文括号内和中文括号本身
//（原 Requests.removeParentheses，供课表/成绩/考试/评教解析共用）
String removeParentheses(String input) {
  final regex = RegExp(r'\([^)]*\)');
  return input
      .replaceAll(regex, '')
      .trim()
      .replaceAll('（', '')
      .replaceAll('）', '');
}

String _removespace(String input) {
  return input.replaceAll(" ", "");
}

String _xorMerge(String str1, String str2) {
  if (str1.length != str2.length) {
    throw ArgumentError('输入的两个字符串长度不相等');
  }
  List<String> result = [];
  for (int i = 0; i < str1.length; i++) {
    result.add(str1[i] == "1" || str2[i] == "1" ? '1' : '0');
  }
  return result.join('');
}

int _coordinateToIndex(int x, int y) {
  if (x < 0 || x >= 7 || y < 0 || y >= 8) {
    throw ArgumentError('坐标超出范围');
  }
  return y * 7 + x;
}

/// 颜色分配（原 Requests.updateColors）：同名课程分配同一颜色，并合并周次串
List<Coursesis> updateColors(List<Coursesis> inputList) {
  List<Coursesis> resultList = [];
  Map<String, Color> colorMap = {};
  Map<String, String>? weekmap = {};
  for (Coursesis model in inputList) {
    if (weekmap[model.courseName] == null) {
      weekmap[model.courseName] = model.interal;
    } else {
      weekmap[model.courseName] =
          _xorMerge(weekmap[model.courseName]!, model.interal);
    }
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
  List<Coursesis> finallist = [];
  for (Coursesis model in resultList) {
    model.interal = weekmap[model.courseName]!;
    finallist.add(model);
  }

  return finallist;
}

Color _generateRandomColor() {
  final random = Random();
  final baseHue = random.nextDouble() * 360.0;
  final saturation = 0.5 + random.nextDouble() * 0.3;
  final lightness = 0.7 + random.nextDouble() * 0.3;

  return HSLColor.fromAHSL(1.0, baseHue, saturation, lightness).toColor();
}

/// 课表后处理（原 Requests.Dispose）：坐标换算、名称清理并按周拆分为 20 周 × 56 格
List<List<Coursesis>> dispose(List<Coursesis> data) {
  List<List<Coursesis>> oneYear = List.generate(21, (index) => []);
  data = updateColors(data);
  for (Coursesis course in data) {
    int tip =
        _coordinateToIndex(course.coursePosition[0], course.coursePosition[1]);
    course.coursePosition[0] = tip;
    String name = removeParentheses(course.courseName);
    course.courseName = name;
    String position = _removespace(course.coursePeriod);
    course.coursePeriod = position;
    //创建20个空周
    for (int i = 0; i < 21; i++) {
      if (course.courseTimes[i] == '1') {
        oneYear[i].add(course);
      }
    }
  }
  int a = 0;
  for (List<Coursesis> value in oneYear) {
    List<Coursesis> conter = List.generate(
        56,
        (index) => Coursesis(
            teacherName: "",
            courseName: "",
            classroomNumber: "",
            coursePeriod: "",
            courseTimes: "",
            coursePosition: [0, 0],
            color: Colors.white,
            state: false,
            interal: ""));
    for (Coursesis result in value) {
      if (result.coursePosition[0] < 56) {
        if (conter[result.coursePosition[0]].courseName == "") {
          conter[result.coursePosition[0]] = result;
        } else {
          conter[result.coursePosition[0]].state = true;
          conter[result.coursePosition[0]].sonName = result.courseName;
          conter[result.coursePosition[0]].sonInter = result.interal;
          conter[result.coursePosition[0]].sonPeriod = result.coursePeriod;
          conter[result.coursePosition[0]].sonTeac = result.teacherName;
        }
      } else {
        null;
      }
    }
    oneYear[a] = conter;
    a++;
  }
  oneYear.removeAt(0);
  return oneYear;
}
