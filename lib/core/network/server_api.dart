import 'package:dio/dio.dart';

/// 应用服务端（版本检查 / 更新日志 / 每日一句）。
class ServerApi {
  static const String baseUrl = 'http://49.235.106.67:5000';

  /// 远端最新版本号，失败返回 "2.0.0"。
  static Future<String> getRemoteVersion() async {
    Dio dio = Dio();
    try {
      Response data = await dio.get("$baseUrl/api/version");
      return data.data["version"];
    } catch (a) {
      return "2.0.0";
    }
  }

  /// 远端更新日志，失败返回空列表。
  static Future<List> getUpdateLog() async {
    Dio dio = Dio();
    try {
      Response data = await dio.get("$baseUrl/api/version");
      return data.data["log"];
    } catch (a) {
      return [];
    }
  }

  /// 每日一句，失败返回占位文案。
  static Future<String> getDailyWord() async {
    Dio dio = Dio();
    try {
      Response data = await dio.get("$baseUrl/api/version");
      return data.data["word"];
    } catch (e) {
      return "当前网络不佳";
    }
  }

  /// 工具页功能开关（旧 login.dart getpass），形如 ["1","1","1"]，
  /// "0" 表示对应卡片显示"功能暂时关闭"。失败返回全开。
  static Future<List> getFeatureSwitches() async {
    Dio dio = Dio();
    try {
      Response data = await dio.get("$baseUrl/api/version");
      return data.data["pass"];
    } catch (e) {
      return ["1", "1", "1"];
    }
  }
}
