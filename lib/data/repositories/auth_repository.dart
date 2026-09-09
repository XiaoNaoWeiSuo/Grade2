// 抽取自原 lib/login.dart Requests.Login（L706-738）/ GetData（L741-748）：
// 登录与计划完成情况获取。唯一的网络 IO 入口，Dio 由注入的 SessionClient 提供
//（SessionClient 已内置与旧 Login 相同的 LogInterceptor、CookieManager(CookieJar)、User-Agent）。

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../core/network/session_client.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../parsers/student_parser.dart';

/// 登录结果：等价旧 Requests.Login 返回的 [dio, statusCode]，302=成功，400=账号或密码错误。
class LoginResult {
  final SessionClient client;
  final int statusCode;

  LoginResult(this.client, this.statusCode);
}

class AuthRepository {
  final SessionClient client;

  AuthRepository(this.client);

  /// 登录教务系统：302=成功，400=账号或密码错误（原 Requests.Login）
  Future<LoginResult> login(String account, String password) async {
    final dio = client.dio;
    Response response =
        await dio.post("http://jwc3.yangtzeu.edu.cn/eams/login.action");
    String encryptedPassword = _encryptPassword(
        password, _exHash(response.data)); //解析第一次进入登陆页面的hash并与密码组合进行加密
    FormData data = FormData.fromMap({
      "username": account,
      "password": encryptedPassword,
    });
    await Future.delayed(const Duration(seconds: 1));
    Response callback = await dio.post(
      "http://jwc3.yangtzeu.edu.cn/eams/login.action",
      data: data,
      options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return status != 500;
          }),
    ); //模拟登陆

    if (callback.data.contains("账号或密码错误")) {
      return LoginResult(client, 400);
    } else {
      return LoginResult(client, callback.statusCode!);
    }
  }

  /// 获取计划完成情况（原 Requests.GetData）
  Future<(List<Student>, List<Course>)> getPlanData() async {
    String url = "http://jwc3.yangtzeu.edu.cn/eams/myPlanCompl.action";

    Response call = await client.dio.get(url);
    List<Student> studentList = parseStudentTable(call.data);
    List<Course> courseList = parseCourseTable(call.data);
    return (studentList, courseList);
  }

  String _encryptPassword(String password, String hashkey) {
    String prefix = hashkey;
    String combinedPassword = prefix + password;
    var sha1Hash = sha1.convert(utf8.encode(combinedPassword)).toString();
    return sha1Hash;
  }

  String _exHash(String webPage) {
    const String searchStr = "CryptoJS.SHA1('";
    int startIndex = webPage.indexOf(searchStr) + searchStr.length;
    int endIndex = webPage.indexOf("'", startIndex);
    return webPage.substring(startIndex, endIndex);
  }
}
