// 抽取自原 lib/login.dart Requests.GetEvaluate（L1210-1263）/ GetSEvaluatePush（L1266-1353）：
// 量化评教获取与提交。唯一做网络 IO 的地方，Dio 由注入的 SessionClient 提供。

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as parser;

import '../../core/network/session_client.dart';
import '../models/evaluate.dart';
import '../parsers/timetable_parser.dart' show backyearid, removeParentheses;

class EvaluateRepository {
  final SessionClient client;

  EvaluateRepository(this.client);

  /// 获取量化评教列表（原 Requests.GetEvaluate）
  Future<List<Evaluate>> getEvaluates() async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/quality/stdEvaluate.action?_=${DateTime.now().millisecondsSinceEpoch}";
    Response call = await client.dio.get(
      url,
    );
    List<Evaluate> asc = [];
    // 解析HTML内容
    var document = parser.parse(call.data);

    // 获取表格中所有行
    var rows = document.querySelectorAll('tbody tr');

    for (var row in rows) {
      // 提取单元格信息
      var columns = row.children;

      // 提取课程名称、教师名称和链接地址
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

  /// 提交量化评教（原 Requests.GetSEvaluatePush；type 为课程类型，"实践"走实训表单）
  Future<void> pushEvaluate(String key, String label, String type) async {
    String url =
        "http://jwc3.yangtzeu.edu.cn/eams/quality/stdEvaluate!finishAnswer.action";
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
    FormData dataPractice = FormData.fromMap({
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
    await client.dio.post(
      url,
      data: type == "实践" ? dataPractice : data,
      options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status! <= 500;
          }),
    );
  }
}
