// 抽取自原 lib/login.dart Evaluate（L372-387）：量化评教模型，行为保持不变。

/// 评教模型
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
