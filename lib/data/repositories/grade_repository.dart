// 抽取自原 lib/login.dart Requests.Getgrade（L1192-1207）/ GetAllGrade（L771-780）：
// 成绩获取。唯一做网络 IO 的地方，Dio 由注入的 SessionClient 提供。

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as parser;

import '../../core/network/session_client.dart';
import '../models/course.dart';
import '../models/grade.dart';
import '../parsers/grade_parser.dart';
import '../parsers/timetable_parser.dart';

class GradeRepository {
  final SessionClient client;

  GradeRepository(this.client);

  //获取成绩（原 Requests.Getgrade，semesterKey 为学期名）
  Future<List<CourseDataModel>> getSemesterGrade(String semesterKey) async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/teach/grade/course/person!search.action?semesterId=${backyearid(semesterKey)}&projectType=";
    Response call = await client.dio.get(url);
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

  /// 获取所有成绩（原 Requests.GetAllGrade）
  Future<(List<GradeAverange>, List<CourseTotal>)> getAllGrade() async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/teach/grade/course/person!historyCourseGrade.action?projectType=MAJOR";
    Response call = await client.dio.post(url);
    // 解析HTML
    var document = parser.parse(call.data);
    // 找到所有的table标签
    var tables = document.querySelectorAll('table');
    return (gradeanlysis(tables[0]), courseanlysis(tables[1]));
  }
}
