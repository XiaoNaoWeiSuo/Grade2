/// 本地缓存管理工具（lib/core 内核层，纯 dart:io + dart:convert 实现）。
///
/// ## 定位
/// - 为业务数据（课表/成绩/学籍等）提供"离线可用"的本地持久化：
///   在线时由 ViewModel 写入，离线/未登录时直接读出渲染。
/// - 与爬虫内核的 [FileSessionStateStore]（会话 cookie）相互独立：
///   会话状态只存令牌，业务数据走本工具。
///
/// ## 数据形状（原生类型）
/// - 值必须是 JSON 可序列化类型：`String/int/double/bool/null/List/Map`。
/// - 键为非空字符串；命名空间（namespace）= 一个独立 JSON 文件，建议按
///   业务域划分（`auth` / `timetable` / `meta` …）。
///
/// ## 存储格式
/// 每个命名空间一个文件：`<baseDir>/<ns>.json`，内容：
/// ```json
/// {
///   "课程表key": {"v": <业务值>, "exp": 1789000000},
///   "无TTL的key": {"v": <业务值>, "exp": null}
/// }
/// ```
/// - `v` 业务值原样存储；`exp` 为过期 epoch 秒（null = 永不过期）。
/// - 读取时过期即视为不存在（惰性删除，写入时清理）。
///
/// ## 线程模型
/// 单 isolate 事件循环内串行调用；所有方法异步返回（文件 IO）。
library;

import 'dart:convert';
import 'dart:io';

/// 本地 KV 缓存（命名空间 = 单 JSON 文件，原子写）。
class LocalCache {
  LocalCache({required this.baseDir});

  /// 缓存根目录（由组装层注入 path_provider 的应用目录）。
  final String baseDir;

  // ---------------- 基础读写 ----------------

  /// 读取业务值。键不存在 / 已过期 / 值类型不符 → null。
  Future<Object?> read(String ns, String key) async {
    final e = await readEntry(ns, key);
    return e?['v'];
  }

  /// 读取带类型期待的值（类型不符返回 [fallback]）。
  Future<T> readAs<T>(String ns, String key, T fallback) async {
    final v = await read(ns, key);
    return v is T ? v : fallback;
  }

  /// 写入业务值。[ttlSeconds] 提供时到期自动失效（null = 永久）。
  Future<void> write(String ns, String key, Object? value,
      {int? ttlSeconds}) async {
    final map = await _loadNs(ns);
    map[key] = {
      'v': value,
      'exp': ttlSeconds == null
          ? null
          : DateTime.now().millisecondsSinceEpoch ~/ 1000 + ttlSeconds,
    };
    await _saveNs(ns, map);
  }

  /// 读取原始条目（含 v/exp 包装，缓存管理工具用）。
  Future<Map<String, Object?>?> readEntry(String ns, String key) async {
    final map = await _loadNs(ns);
    final e = map[key];
    if (e is! Map) return null;
    final exp = e['exp'];
    if (exp is int &&
        exp <= DateTime.now().millisecondsSinceEpoch ~/ 1000) {
      return null; // 已过期视为不存在
    }
    return {'v': e['v'], 'exp': exp};
  }

  /// 删除单个键。返回是否确有删除。
  Future<bool> remove(String ns, String key) async {
    final map = await _loadNs(ns);
    final existed = map.containsKey(key);
    if (existed) {
      map.remove(key);
      await _saveNs(ns, map);
    }
    return existed;
  }

  // ---------------- 命名空间管理 ----------------

  /// 全部命名空间（扫描目录下的 *.json 文件名）。
  Future<List<String>> namespaces() async {
    final dir = Directory(baseDir);
    if (!await dir.exists()) return [];
    final out = <String>[];
    await for (final f in dir.list()) {
      if (f is File && f.path.endsWith('.json')) {
        out.add(f.uri.pathSegments.last.replaceAll(RegExp(r'\.json$'), ''));
      }
    }
    out.sort();
    return out;
  }

  /// 命名空间下全部键。
  Future<List<String>> keys(String ns) async {
    final map = await _loadNs(ns);
    final out = map.keys.map((k) => k.toString()).toList()..sort();
    return out;
  }

  /// 命名空间原始内容快照（key → {v, exp}，缓存工具展示用）。
  Future<Map<String, Object?>> dump(String ns) async =>
      Map<String, Object?>.of(await _loadNs(ns));

  /// 清空单个命名空间（删除文件）。
  Future<void> clearNs(String ns) async {
    final f = _nsFile(ns);
    if (await f.exists()) await f.delete();
  }

  /// 清空全部缓存。
  Future<void> clearAll() async {
    for (final ns in await namespaces()) {
      await clearNs(ns);
    }
  }

  /// 缓存占用空间（字节）与条目数统计（缓存工具展示用）。
  Future<Map<String, Object?>> stats() async {
    var bytes = 0;
    var entries = 0;
    final per = <String, int>{};
    for (final ns in await namespaces()) {
      final f = _nsFile(ns);
      final len = await f.length();
      bytes += len;
      final n = (await _loadNs(ns)).length;
      per[ns] = n;
      entries += n;
    }
    return {'bytes': bytes, 'entries': entries, 'per_ns': per};
  }

  // ---------------- 内部 ----------------

  File _nsFile(String ns) => File('$baseDir/$ns.json');

  Future<Map<String, Object?>> _loadNs(String ns) async {
    final f = _nsFile(ns);
    try {
      if (!await f.exists()) return <String, Object?>{};
      final data = jsonDecode(await f.readAsString());
      if (data is Map<String, Object?>) return data;
      return <String, Object?>{};
    } on Exception {
      // 读取/解析失败（IO 错误、JSON 损坏等）视为空命名空间
      return <String, Object?>{};
    }
  }

  Future<void> _saveNs(String ns, Map<String, Object?> map) async {
    final f = _nsFile(ns);
    await f.parent.create(recursive: true);
    // 惰性清理：保存时顺带剔除过期条目
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    map.removeWhere((_, e) {
      final exp = e is Map ? e['exp'] : null;
      return exp is int && exp <= now;
    });
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(
        const JsonEncoder.withIndent('  ').convert(map), flush: true);
    await tmp.rename(f.path); // 原子替换
  }
}
