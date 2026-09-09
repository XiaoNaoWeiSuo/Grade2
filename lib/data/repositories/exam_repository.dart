// 抽取自原 lib/login.dart Requests.GetExam（L877-892）/ GetExamIds（L866-874）/
// getexamitem（L894-940）：考试安排获取。唯一做网络 IO 的地方，Dio 由注入的 SessionClient 提供。

import 'package:dio/dio.dart';

import '../../core/network/session_client.dart';
import '../models/exam_data.dart';
import '../parsers/exam_parser.dart';

class ExamRepository {
  final SessionClient client;

  ExamRepository(this.client);

  /// 获取考试安排（原 Requests.GetExam；bukao=true 取补考批次）
  Future<List<ExamData>> getExams(bool bukao) async {
    List da = await _getExamIds();
    List<ExamData> item = [];
    try {
      if (bukao) {
        item = await _getExamItem(da[0]);
      } else {
        item = await _getExamItem(da[1]);
      }
    } catch (e) {
      Null;
    }
    return item;
  }

  /// 获取考试批次 id（原 Requests.GetExamIds）
  Future<List<String>> _getExamIds() async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/stdExamTable.action?_=${DateTime.now().millisecondsSinceEpoch}";
    Response call = await client.dio.get(
      url,
    );

    return extractOptionValues(call.data);
  }

  /// 获取单个批次的考试列表（原 Requests.getexamitem）
  Future<List<ExamData>> _getExamItem(String id) async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/stdExamTable!examTable.action?examBatch.id=$id";
    Response examlist = await client.dio.get(url);
    return parseExamItem(examlist.data);
  }
}
