// CookieJar 单元测试：作用域匹配 / 过期 / 摄取 / 持久化往返。
import 'package:flutter_test/flutter_test.dart';
import 'package:grade2/core/crawler/session/cookie_jar.dart';

void main() {
  group('摄取 Set-Cookie', () {
    test('host-only cookie 定位到请求 host', () {
      final jar = CookieJar();
      jar.ingest('cas.example.edu', ['CASTGC=TGT-1; Path=/; HttpOnly']);
      expect(jar.has('CASTGC'), true);
      expect(jar.value('CASTGC'), 'TGT-1');
      // 其它 host 不发送
      expect(
          jar.headerFor(Uri.parse('https://other.example.edu/')), isNull);
      expect(
          jar.headerFor(Uri.parse('https://cas.example.edu/x')),
          'CASTGC=TGT-1');
    });

    test('Domain 属性 → 子域匹配（RFC6265 §5.1.3）', () {
      final jar = CookieJar();
      jar.ingest('a.yangtzeu.edu.cn',
          ['sid=abc; Domain=.yangtzeu.edu.cn; Path=/']);
      expect(
          jar.headerFor(Uri.parse('https://b.yangtzeu.edu.cn/')), 'sid=abc');
      expect(jar.headerFor(Uri.parse('https://yangtzeu.edu.cn/')), 'sid=abc');
      expect(jar.headerFor(Uri.parse('https://evil.com/')), isNull);
    });

    test('Path 前缀匹配（RFC6265 §5.1.4）', () {
      final jar = CookieJar();
      jar.ingest('h.com', ['a=1; Path=/foo']);
      expect(jar.headerFor(Uri.parse('https://h.com/foo/bar')), 'a=1');
      expect(jar.headerFor(Uri.parse('https://h.com/foo')), 'a=1');
      expect(jar.headerFor(Uri.parse('https://h.com/foobar')), isNull);
      expect(jar.headerFor(Uri.parse('https://h.com/')), isNull);
    });

    test('Max-Age=0 → 删除同名同域', () {
      final jar = CookieJar();
      jar.ingest('h.com', ['a=1']);
      jar.ingest('h.com', ['a=1; Max-Age=0']);
      expect(jar.has('a'), false);
    });

    test('Expires 过去时间 → 不入库', () {
      final jar = CookieJar();
      jar.ingest('h.com', ['a=1; Expires=Thu, 01 Jan 1970 00:00:00 GMT']);
      expect(jar.has('a'), false);
    });

    test('同名同域覆盖', () {
      final jar = CookieJar();
      jar.ingest('h.com', ['v=1; Path=/']);
      jar.ingest('h.com', ['v=2; Path=/']);
      expect(jar.value('v'), '2');
      expect(jar.length, 1);
    });

    test('Secure cookie 不随 http 发送', () {
      final jar = CookieJar();
      jar.ingest('h.com', ['s=1; Secure']);
      expect(jar.headerFor(Uri.parse('https://h.com/')), 's=1');
      expect(jar.headerFor(Uri.parse('http://h.com/')), isNull);
    });
  });

  group('手工 set / delete / clear', () {
    test('set + delete', () {
      final jar = CookieJar();
      jar.set('semester.id', '409', domain: 'eams.example.cn');
      expect(jar.value('semester.id'), '409');
      jar.delete('semester.id', domain: 'eams.example.cn');
      expect(jar.has('semester.id'), false);
      // delete 不指定域 → 删所有同名
      jar.set('x', '1', domain: 'a.com');
      jar.set('x', '2', domain: 'b.com');
      jar.delete('x');
      expect(jar.length, 0);
    });
  });

  group('JSON 持久化往返', () {
    test('toJson/loadJson', () {
      final jar = CookieJar();
      jar.ingest('cas.example.edu', [
        'CASTGC=TGT-xyz; Domain=.example.edu; Path=/; Secure; '
            'Expires=Wed, 09 Jun 2100 10:18:14 GMT'
      ]);
      jar.set('online', '1', domain: 'portal.example.edu');
      final json = jar.toJson();
      final jar2 = CookieJar()..loadJson(json);
      expect(jar2.value('CASTGC'), 'TGT-xyz');
      expect(jar2.value('online'), '1');
      expect(
          jar2.headerFor(Uri.parse('https://sub.example.edu/')),
          contains('CASTGC=TGT-xyz'));
      // online 只在 portal host
      expect(
          jar2.headerFor(Uri.parse('https://sub.example.edu/')),
          isNot(contains('online')));
    });

    test('过期条目不入 toJson', () {
      final jar = CookieJar();
      jar.ingest('h.com', ['dead=1; Expires=Thu, 01 Jan 1970 00:00:00 GMT']);
      jar.ingest('h.com', ['alive=1']);
      expect(jar.toJson().length, 1);
    });
  });
}
