// LocalCache 单元测试：读写/TTL/删除/命名空间/统计/清空（临时目录，不碰真实数据）。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grade2/core/storage/local_cache.dart';

void main() {
  late Directory tmp;
  late LocalCache cache;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('localcache_test');
    cache = LocalCache(baseDir: tmp.path);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('基础读写', () {
    test('write/read 往返（原生类型）', () async {
      await cache.write('timetable', 'table_std_409', {
        'courses': [
          {'name': '高数', 'day': 1, 'unit': 1, 'weeks': {'list': [1, 2, 3]}}
        ],
        'unit_count': 12,
      });
      final v = await cache.read('timetable', 'table_std_409');
      expect(v, isA<Map<String, Object?>>());
      expect(
          ((v as Map)['courses'] as List).first, containsPair('name', '高数'));
      // 键不存在 → fallback
      expect(
          await cache.readAs<int>('timetable', 'table_std_409x', 12), 12);
    });

    test('read 不存在的键 → null', () async {
      expect(await cache.read('ns', 'nope'), null);
      expect(await cache.readAs<String>('ns', 'nope', 'fallback'), 'fallback');
    });

    test('类型不符 → fallback', () async {
      await cache.write('ns', 'k', '字符串');
      expect(await cache.readAs<int>('ns', 'k', -1), -1);
    });

    test('remove 返回是否确有删除', () async {
      await cache.write('ns', 'k', 1);
      expect(await cache.remove('ns', 'k'), true);
      expect(await cache.remove('ns', 'k'), false);
    });
  });

  group('TTL 过期', () {
    test('未过期可读，过期视为不存在（含条目包装）', () async {
      await cache.write('ns', 'k1', 'v1', ttlSeconds: 60);
      expect(await cache.read('ns', 'k1'), 'v1');
      expect((await cache.readEntry('ns', 'k1'))?['exp'], isNotNull);

      await cache.write('ns', 'k2', 'v2', ttlSeconds: -1); // 立即过期
      expect(await cache.read('ns', 'k2'), null);
      expect(await cache.readEntry('ns', 'k2'), null);
    });

    test('无 TTL 条目 exp 为 null', () async {
      await cache.write('ns', 'perm', 'x');
      expect((await cache.readEntry('ns', 'perm'))?['exp'], null);
    });
  });

  group('命名空间管理', () {
    test('namespaces / keys / dump', () async {
      await cache.write('auth', 'accounts', [1, 2]);
      await cache.write('auth', 'last', '2022007923');
      await cache.write('timetable', 't', 'x');
      expect(await cache.namespaces(), ['auth', 'timetable']);
      expect(await cache.keys('auth'), ['accounts', 'last']);
      final dump = await cache.dump('auth');
      expect(dump.keys.length, 2);
    });

    test('clearNs / clearAll', () async {
      await cache.write('a', 'k', 1);
      await cache.write('b', 'k', 2);
      await cache.clearNs('a');
      expect(await cache.namespaces(), ['b']);
      await cache.clearAll();
      expect(await cache.namespaces(), isEmpty);
      expect(await cache.read('b', 'k'), null);
    });

    test('损坏文件视为空', () async {
      await File('${tmp.path}/broken.json').writeAsString('{not json');
      expect(await cache.read('broken', 'k'), null);
      expect(await cache.namespaces(), ['broken']);
    });
  });

  group('统计', () {
    test('stats 字节数与条目数', () async {
      await cache.write('ns', 'k1', 'value');
      await cache.write('ns', 'k2', 'value2');
      final st = await cache.stats();
      expect(st['entries'], 2);
      expect(st['bytes'], greaterThan(0));
      expect((st['per_ns'] as Map)['ns'], 2);
    });
  });
}
