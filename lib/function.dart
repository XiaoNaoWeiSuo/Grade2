// import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:open_file/open_file.dart';
// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/services.dart' show rootBundle;

// 获取存储卡的路径
// Future<void> update() async {
//   final directory = await getExternalStorageDirectory();
//   String _localPath = directory!.path;

//   await FlutterDownloader.enqueue(
//     // 远程的APK地址（注意：安卓9.0以上后要求用https）
//     url: "http://49.235.106.67/arm64-v8a.apk",
//     // 下载保存的路径
//     savedDir: _localPath,
//     // 是否在手机顶部显示下载进度（仅限安卓）
//     showNotification: true,
//     // 是否允许下载完成点击打开文件（仅限安卓）
//     openFileFromNotification: true,
//   );
//   OpenFile.open("$_localPath/arm64-v8a.apk");
// }

Future<String> getVersionapp() async {
  try {
    String jsonString = await rootBundle.loadString('assets/data/version.json');
    var json = jsonDecode(jsonString);
    return json["version"];
  } catch (e) {
    return '2.0.0';
  }
}

//年份格式判断
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

//页面传参模型
class ResultObject {
  final String stringValue;
  final bool boolValue;
  final Color dateColor;
  final Color timeColor;
  final Color bgColor;
  final bool itemcolorstate;
  ResultObject(this.stringValue, this.boolValue, this.dateColor, this.timeColor,
      this.bgColor, this.itemcolorstate);
}

//数据文件读写类
class CounterStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/data.json');
  }

  Future<Map<String, dynamic>> readCounter() async {
    try {
      final file = await _localFile;
      // Read the file
      final contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      // If encountering an error, return 0
      return {};
    }
  }

  Future<File> writeCounter(var counter) async {
    final file = await _localFile;
    // Write the file
    return file.writeAsString(jsonEncode(counter));
  }
}

class Appdata {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/setting.json');
  }

  Future<Map<String, dynamic>> readCounter() async {
    try {
      final file = await _localFile;
      // Read the file
      final contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      // If encountering an error, return 0
      return {};
    }
  }

  Future<File> writeCounter(var counter) async {
    final file = await _localFile;
    // Write the file
    return file.writeAsString(jsonEncode(counter));
  }
}

void SenMail(String name, String campus, String content, bool state,
    String account) async {
  Dio a = Dio();

  final client = SmtpClient('neverouo.bug', isLogEnabled: true);
  try {
    await client.connectToServer('smtp.163.com', 465,
        isSecure: true); //这是QQ SMTP对应的地址，不需要更改
    await client.ehlo();
    if (client.serverInfo.supportsAuth(AuthMechanism.plain)) {
      await client.authenticate(
          'm15218765700@163.com', 'JTWBGLGBOICYHVOX', AuthMechanism.plain);
    } else if (client.serverInfo.supportsAuth(AuthMechanism.login)) {
      await client.authenticate(
          'm15218765700@163.com', 'JTWBGLGBOICYHVOX', AuthMechanism.login);
    } else {
      return;
    }
    String version = await getVersionapp();
    if (!state) {
      try {
        await a.get(
            "http://49.235.106.67:5000/api/log/$account/$campus/$name/$version/");
      } catch (e) {
        Null;
      }
    }
    final builder = MessageBuilder.prepareMultipartAlternativeMessage();
    builder.from = [
      MailAddress((state ? 'Grade用户反馈' : "Grade用户登录"), 'm15218765700@163.com')
    ];
    builder.to = [MailAddress('小脑萎缩', 'xiaonaoweisu@qq.com')];
    builder.subject = "$campus:$name";
    builder.addTextPlain("版本：$version\n$content");
    final mimeMessage = builder.buildMimeMessage();
    await client.sendMessage(mimeMessage);
  } on SmtpException {
    Null;
  }
}

bool isVersionGreaterThan(String version1, String version2) {
  List<int> v1Parts = version1.split('.').map(int.parse).toList();
  List<int> v2Parts = version2.split('.').map(int.parse).toList();
  // 比较每个部分的数字
  for (int i = 0; i < v1Parts.length && i < v2Parts.length; i++) {
    if (v1Parts[i] < v2Parts[i]) {
      return false; // 版本1 <= 版本2
    } else if (v1Parts[i] > v2Parts[i]) {
      return true; // 版本1 > 版本2
    }
  }

  return v1Parts.length > v2Parts.length;
}

//去除头部年份
String removeYear(String inputString) {
  final regex = RegExp(r'^\d{4}-');
  return inputString.replaceAll(regex, '');
}
