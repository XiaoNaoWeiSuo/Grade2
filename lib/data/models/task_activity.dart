// 抽取自原 lib/login.dart TaskActivity（L282-300）：课表 JS 解析的模型中间件，行为保持不变。

/// 模型中间件
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
