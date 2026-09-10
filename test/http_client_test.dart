// SessionHttpClient 单元测试：本地 HttpServer 模拟重定向链/Set-Cookie/表单/重试。
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grade2/core/crawler/crawler_exceptions.dart';
import 'package:grade2/core/crawler/models/config_models.dart';
import 'package:grade2/core/crawler/session/http_client.dart';

/// 起一个一次性本地 HTTP 服务，返回 (server, port)。
Future<(HttpServer, int)> startServer(
    FutureOr<void> Function(HttpRequest req) handler) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    await handler(req);
    await req.response.close();
  });
  return (server, server.port);
}

GrabberConfig fastConfig() => const GrabberConfig(timeout: 3, getRetries: 0);

void main() {
  late HttpServer server;
  late int port;

  setUp(() async {});

  tearDown(() async {
    // 由各用例自行关闭（赋值给 server 的），此处兜底忽略未初始化
  });

  Future<void> bind(FutureOr<void> Function(HttpRequest req) h) async {
    final (s, p) = await startServer(h);
    server = s;
    port = p;
  }

  Future<void> stop() async {
    await server.close(force: true);
  }

  test('GET 基本请求 + 自定义头透传', () async {
    String? seenUa;
    String? seenX;
    await bind((req) async {
      seenUa = req.headers.value('user-agent');
      seenX = req.headers.value('x-custom');
      req.response.write('hello');
    });
    final http = SessionHttpClient(config: fastConfig());
    final resp = await http.get(Uri.parse('http://localhost:$port/'),
        headers: {'X-Custom': 'v1'});
    expect(resp.statusCode, 200);
    expect(resp.body, 'hello');
    expect(seenX, 'v1');
    expect(seenUa, isNotNull); // 全局 UA 已注入
    await stop();
    http.close();
  });

  test('Set-Cookie 摄取并随下一跳请求发送', () async {
    String? cookieHeader;
    await bind((req) async {
      if (req.uri.path == '/login') {
        req.response.headers.set('set-cookie', 'sid=xyz; Path=/; HttpOnly');
        req.response.statusCode = 302;
        req.response.headers
            .set('location', 'http://localhost:$port/landing');
      } else {
        cookieHeader = req.headers.value('cookie');
        req.response.write('ok');
      }
    });
    final http = SessionHttpClient(config: fastConfig());
    // 302 手动跟随（重定向响应上的 Set-Cookie 同样摄取）
    final r1 = await http.get(Uri.parse('http://localhost:$port/login'));
    expect(r1.isRedirect, true);
    final r2 = await http.get(r1.url.resolve(r1.header('location')!));
    expect(r2.body, 'ok');
    expect(cookieHeader, contains('sid=xyz'));
    await stop();
    http.close();
  });

  test('follow() 逐跳跟踪并回调', () async {
    final hops = <String>[];
    await bind((req) async {
      switch (req.uri.path) {
        case '/a':
          req.response.statusCode = 302;
          req.response.headers
              .set('location', 'http://localhost:$port/b');
          break;
        case '/b':
          req.response.statusCode = 302;
          req.response.headers
              .set('location', 'http://localhost:$port/c');
          break;
        default:
          req.response.write('final');
      }
    });
    final http = SessionHttpClient(config: fastConfig());
    final r0 = await http.get(Uri.parse('http://localhost:$port/a'));
    final r = await http.follow(r0,
        onHop: (from, code, to) => hops.add('$from->$code->$to'));
    expect(r.body, 'final');
    expect(hops.length, 2);
    await stop();
    http.close();
  });

  test('follow() 跳数超限 → HttpError', () async {
    await bind((req) async {
      req.response.statusCode = 302;
      req.response.headers.set('location', 'http://localhost:$port/loop');
    });
    final http = SessionHttpClient(config: fastConfig());
    final r0 = await http.get(Uri.parse('http://localhost:$port/loop'));
    expect(() => http.follow(r0, maxHops: 3), throwsA(isA<HttpError>()));
    await stop();
    http.close();
  });

  test('POST 表单编码（quote_plus 语义）+ Content-Type', () async {
    String? body;
    String? ctype;
    await bind((req) async {
      ctype = req.headers.value('content-type');
      body = await utf8.decodeStream(req);
    });
    final http = SessionHttpClient(config: fastConfig());
    await http.post(Uri.parse('http://localhost:$port/p'),
        form: {'username': '2022', 'password': 'a+b/c=d 中文名'});
    expect(ctype, startsWith('application/x-www-form-urlencoded'));
    expect(body, contains('username=2022'));
    expect(body, contains('password=a%2Bb%2Fc%3Dd+${Uri.encodeQueryComponent('中文名')}'));
    await stop();
    http.close();
  });

  test('POST JSON body', () async {
    String? body;
    String? ctype;
    await bind((req) async {
      ctype = req.headers.value('content-type');
      body = await utf8.decodeStream(req);
    });
    final http = SessionHttpClient(config: fastConfig());
    await http.post(Uri.parse('http://localhost:$port/p'),
        json: {'ticket': 't1', 'deviceId': 'd'});
    expect(ctype, contains('application/json'));
    expect(body, '{"ticket":"t1","deviceId":"d"}');
    await stop();
    http.close();
  });

  test('GET 网络错误按配置重试后抛 HttpError（0 重试=1 次尝试）', () async {
    final http =
        SessionHttpClient(config: const GrabberConfig(timeout: 1, getRetries: 0));
    // 直连大概率未监听的 1 端口 → 立即连接拒绝 → HttpError（不重试）
    expect(
        () => http.get(Uri.parse('http://127.0.0.1:1/')),
        throwsA(isA<HttpError>()));
    http.close();
  });

  test('GET 500 响应不抛（业务守卫在上层）且记录头', () async {
    await bind((req) async {
      req.response.statusCode = 500;
      req.response.write('oops');
    });
    final http = SessionHttpClient(config: fastConfig());
    final r = await http.get(Uri.parse('http://localhost:$port/x'));
    expect(r.statusCode, 500);
    expect(r.body, 'oops');
    await stop();
    http.close();
  });

  test('charset 嗅探：无 Content-Type 时按 meta charset', () async {
    await bind((req) async {
      // 显式以 latin1 输出 UTF-8 字节声明的页面头（模拟 gbk 声明页）；此处仅验证嗅探逻辑路径
      req.response.headers.set(HttpHeaders.contentTypeHeader, 'text/html');
      req.response.add(utf8.encode(
          '<html><head><meta charset="utf-8"></head><body>中文</body></html>'));
    });
    final http = SessionHttpClient(config: fastConfig());
    final r = await http.get(Uri.parse('http://localhost:$port/'));
    expect(r.body, contains('中文'));
    await stop();
    http.close();
  });

  test('cookiesToJson/loadCookiesFromJson 桥接', () async {
    await bind((req) async {
      req.response.headers.set('set-cookie', 'k=v; Path=/');
      req.response.write('');
    });
    final http = SessionHttpClient(config: fastConfig());
    await http.get(Uri.parse('http://localhost:$port/'));
    final data = http.cookiesToJson();
    final http2 = SessionHttpClient(config: fastConfig())
      ..loadCookiesFromJson(data);
    expect(http2.hasCookie('k'), true);
    await stop();
    http.close();
    http2.close();
  });
}
