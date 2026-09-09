import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 读取本地 assets 中的应用版本号。
Future<String> getVersionapp() async {
  try {
    String jsonString = await rootBundle.loadString('assets/data/version.json');
    var json = jsonDecode(jsonString);
    return json["version"];
  } catch (e) {
    return '2.0.0';
  }
}

/// 比较 version1 是否大于 version2（语义化版本 a.b.c）。
bool isVersionGreaterThan(String version1, String version2) {
  List<int> v1Parts = version1.split('.').map(int.parse).toList();
  List<int> v2Parts = version2.split('.').map(int.parse).toList();
  for (int i = 0; i < v1Parts.length && i < v2Parts.length; i++) {
    if (v1Parts[i] < v2Parts[i]) {
      return false;
    } else if (v1Parts[i] > v2Parts[i]) {
      return true;
    }
  }
  return v1Parts.length > v2Parts.length;
}

/// 年份格式判断。
bool isYearFormat(int year) {
  final currentYear = DateTime.now().year;
  if (year <= 0 || year > currentYear) {
    return false;
  }
  return true;
}

bool isLongNumber(String str) {
  if (str.length <= 4) {
    return false;
  }
  try {
    int.parse(str);
    return true;
  } catch (e) {
    return false;
  }
}

/// 去除字符串头部的 "yyyy-" 年份前缀。
String removeYear(String inputString) {
  final regex = RegExp(r'^\d{4}-');
  return inputString.replaceAll(regex, '');
}
