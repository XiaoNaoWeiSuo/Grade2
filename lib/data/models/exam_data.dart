// 抽取自原 lib/login.dart ExamData（L429-491）：考试安排模型，字段/构造/序列化行为保持不变。

/// 考试模型
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
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': courseName,
      'examType': examType,
      'examDate': examDate,
      'examTime': examTime,
      'examRoom': examRoom,
      'capacity': capacity,
      'examFormat': examFormat,
      'status': status,
      'ispass': ispass,
    };
  }

  factory ExamData.fromJson(Map<String, dynamic> json) {
    return ExamData(
      id: json['id'],
      courseName: json['courseName'],
      examType: json['examType'],
      examDate: json['examDate'],
      examTime: json['examTime'],
      examRoom: json['examRoom'],
      capacity: json['capacity'],
      examFormat: json['examFormat'],
      status: json['status'],
      ispass: json['ispass'],
    );
  }

  @override
  String toString() {
    return 'ExamData(id: $id, courseName: $courseName, examType: $examType, '
        'examDate: $examDate, examTime: $examTime, examRoom: $examRoom, '
        'capacity: $capacity, examFormat: $examFormat, status: $status, ispass: $ispass)';
  }
}
