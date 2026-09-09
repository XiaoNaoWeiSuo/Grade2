// 抽取自原 lib/login.dart L1655-1761 与 lib/topbar.dart processArray（L157-172）：
// 课表/学期相关的纯计算工具，无 IO、无网络。

import '../../data/models/course.dart';

/// 学期起始日（第一周周一）
final DateTime semesterStartDate = DateTime(2024, 2, 26);

/// 由学期起始日计算当前是第几周（1 起）
int computeCurrentWeek([DateTime? now]) {
  final DateTime date = now ?? DateTime.now();
  return (date.difference(semesterStartDate).inDays ~/ 7) + 1;
}

/// 日期计算器：返回某周的 "M/d" 日期列表（原 calculateDates）
List<String> calculateDates(int currentWeek) {
  List<String> dates = [];
  for (int i = 0; i < 7; i++) {
    DateTime date =
        semesterStartDate.add(Duration(days: (currentWeek - 1) * 7 + i));
    String dateString = '${date.month}/${date.day}';
    dates.add(dateString);
  }
  return dates;
}

/// 今天是本周第几天（0=周一 ~ 6=周日）（原 getCurrentDayOfWeek）
int getCurrentDayOfWeek() {
  DateTime now = DateTime.now();
  return now.weekday - 1;
}

/// 课程表时间筛子：按列提取（原 extractColumnData）
List extractColumnData(List array, int columns, int targetColumn) {
  int rows = (array.length / columns).ceil();
  List columnIndexes =
      List.generate(rows, (index) => index * columns + targetColumn);
  List result = columnIndexes.map((index) => array[index]).toList();
  return result;
}

/// 课程进度（原 getCurrentTimeInFloat）
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

/// 时间进度（原 getDailyTimeProgress）
double getDailyTimeProgress() {
  DateTime now = DateTime.now();
  int totalMinutes = now.hour * 60 + now.minute;
  return totalMinutes / (24 * 60);
}

/// 课程表钟点筛子：当前所处的时间段序号（原 getCurrentTimeSlot）
int getCurrentTimeSlot() {
  DateTime now = DateTime.now();

  int startTimeHour = 7; // 开始时间的小时数
  int endTimeHour = 20; // 结束时间的小时数

  const int totalSlots = 8; // 时间区间总数
  int hourDiff = endTimeHour - startTimeHour;
  int slotDuration = (hourDiff / totalSlots).floor();

  int currentHour = now.hour;
  int currentMinute = now.minute;

  int currentSlot = ((currentHour - startTimeHour) * 60 + currentMinute) ~/
      (slotDuration * 60);

  return currentSlot.clamp(0, totalSlots - 1);
}

/// 剔除课表数组中的周末课程（原 topbar.dart processArray）
List processArray(List inputArray) {
  List<Coursesis> filteredList = [];
  for (int i = 0; i < inputArray.length; i++) {
    int column = i % 7;
    if (column < 5) {
      filteredList.add(inputArray[i]);
    }
  }
  return filteredList;
}
