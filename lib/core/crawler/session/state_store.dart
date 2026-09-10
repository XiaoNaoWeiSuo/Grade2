/// 会话状态持久化抽象（对应 Python 的 .session/state.json 读写）。
///
/// 内核只依赖本接口；UI/Riverpod 层负责选择实现：
/// - [FileSessionStateStore]：dart:io 文件（原子写），路径由调用方注入
///   （Flutter 侧可传 path_provider 的应用文档目录）
/// - [MemorySessionStateStore]：内存（测试/隐私模式）
///
/// 状态结构（原生 Map）：
/// ```json
/// {
///   "saved_at": 1789000000,          // epoch 秒
///   "cookies": [ {name, value, domain, path, secure, expires}, ... ],
///   "extra":   { "device_id": "...", "cas_at": 0, "portal_at": 0,
///                "app_at": 0, "display_name": "..." }
/// }
/// ```
library;

import 'dart:convert';
import 'dart:io';

/// 状态存储接口。load 在文件缺失/损坏时返回 null（调用方走全链路登录）。
abstract class SessionStateStore {
  Future<Map<String, Object?>?> load();
  Future<void> save(Map<String, Object?> state);
  Future<void> clear();
}

/// 文件实现：tmp + rename 原子替换（与 Python os.replace 等价）。
class FileSessionStateStore implements SessionStateStore {
  FileSessionStateStore(this.path);

  final String path;

  File get _file => File(path);

  @override
  Future<Map<String, Object?>?> load() async {
    try {
      if (!await _file.exists()) return null;
      final data = jsonDecode(await _file.readAsString());
      if (data is Map<String, Object?>) return data;
      return null;
    } on Exception {
      // 读取/解析失败（IO 错误、JSON 损坏等）一律视为缺失，走全链路登录
      return null;
    }
  }

  @override
  Future<void> save(Map<String, Object?> state) async {
    final tmp = File('$path.tmp');
    await tmp.parent.create(recursive: true);
    await tmp.writeAsString(
        const JsonEncoder.withIndent('  ').convert(state), flush: true);
    await tmp.rename(path); // 原子替换
  }

  @override
  Future<void> clear() async {
    try {
      if (await _file.exists()) await _file.delete();
    } on FileSystemException {
      // 忽略：清除是尽力而为
    }
  }
}

/// 内存实现（测试用/不落盘模式）。
class MemorySessionStateStore implements SessionStateStore {
  Map<String, Object?>? _data;

  @override
  Future<Map<String, Object?>?> load() async => _data;

  @override
  Future<void> save(Map<String, Object?> state) async => _data = state;

  @override
  Future<void> clear() async => _data = null;
}
