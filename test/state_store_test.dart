// 会话状态存储单元测试：原子写 / 损坏容错 / 内存实现。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grade2/core/crawler/session/state_store.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('statestore_test');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('FileSessionStateStore', () {
    test('save/load 往返（含 cookies + extra）', () async {
      final store = FileSessionStateStore('${tmp.path}/state.json');
      await store.save({
        'saved_at': 1789000000,
        'cookies': [
          {'name': 'CASTGC', 'value': 'TGT-1', 'domain': 'cas.x.cn', 'path': '/', 'secure': true, 'expires': null}
        ],
        'extra': {'device_id': 'ab' * 32, 'app_at': 1789000001},
      });
      final data = await store.load();
      expect(data, isNotNull);
      expect((data!['cookies'] as List).first,
          containsPair('name', 'CASTGC'));
      expect((data['extra'] as Map)['device_id'], 'ab' * 32);
    });

    test('缺失文件 → null', () async {
      final store = FileSessionStateStore('${tmp.path}/none.json');
      expect(await store.load(), null);
    });

    test('损坏文件 → null（视为缺失）', () async {
      final f = File('${tmp.path}/broken.json');
      await f.writeAsString('{{{');
      final store = FileSessionStateStore(f.path);
      expect(await store.load(), null);
    });

    test('clear 删除文件', () async {
      final path = '${tmp.path}/state.json';
      final store = FileSessionStateStore(path);
      await store.save({'a': 1});
      expect(await File(path).exists(), true);
      await store.clear();
      expect(await File(path).exists(), false);
      await store.clear(); // 幂等
    });

    test('save 覆盖旧内容且无 .tmp 残留', () async {
      final path = '${tmp.path}/state.json';
      final store = FileSessionStateStore(path);
      await store.save({'v': 1});
      await store.save({'v': 2});
      final data = await store.load();
      expect(data!['v'], 2);
      expect(await File('$path.tmp').exists(), false);
    });
  });

  group('MemorySessionStateStore', () {
    test('读写清', () async {
      final store = MemorySessionStateStore();
      expect(await store.load(), null);
      await store.save({'x': 1});
      expect(await store.load(), {'x': 1});
      await store.clear();
      expect(await store.load(), null);
    });
  });
}
