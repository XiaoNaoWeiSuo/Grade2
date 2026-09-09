import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

/// 教务系统登录会话：持有带 CookieJar 的 Dio 实例。
/// 登录成功后由 SessionNotifier 创建并保存（替代旧的全局 netdata[0]）。
class SessionClient {
  final Dio dio;

  SessionClient() : dio = _createDio();

  static Dio _createDio() {
    final Dio dio = Dio();
    dio.interceptors.add(LogInterceptor());
    dio.interceptors.add(CookieManager(CookieJar()));
    dio.options.headers["User-Agent"] =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36 Edg/111.0.1661.51";
    return dio;
  }
}
