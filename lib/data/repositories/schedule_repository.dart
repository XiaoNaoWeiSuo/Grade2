// 抽取自原 lib/login.dart Requests.GetSchedule（L751-768）/ GetIds（L849-864）：
// 课程表获取。唯一做网络 IO 的地方，Dio 由注入的 SessionClient 提供。

import 'package:dio/dio.dart';

import '../../core/network/session_client.dart';
import '../models/course.dart';
import '../parsers/timetable_parser.dart';

class ScheduleRepository {
  final SessionClient client;

  ScheduleRepository(this.client);

  /// 获取课程表（原 Requests.GetSchedule，semesterKey 为学期名）
  Future<List<List<Coursesis>>> getSchedule(String semesterKey) async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/courseTableForStd!courseTable.action";
    String ids = await _getIds();
    FormData data = FormData.fromMap({
      'ignoreHead': '1',
      'setting.kind': 'std',
      'startWeek': '',
      'semester.id': backyearid(semesterKey),
      'ids': ids
    });
    Response call = await client.dio.post(
      url,
      data: data,
    );
    SourceAnalysis sourceanalysis = SourceAnalysis();
    return dispose(sourceanalysis.result(call.data));
  }

  //获取id属性（原 Requests.GetIds）
  Future<String> _getIds() async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/courseTableForStd.action?_=${DateTime.now().millisecondsSinceEpoch}";
    Response call = await client.dio.get(
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
}
