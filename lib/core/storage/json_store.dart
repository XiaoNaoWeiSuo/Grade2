import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 本地 JSON 文件读写（data.json / root.json / setting.json / appwidget.json）。
class JsonStore {
  final String filename;

  JsonStore(this.filename);

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$filename');
  }

  /// 读取 JSON 文件，失败时返回空 Map。
  Future<Map<String, dynamic>> read() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      return {};
    }
  }

  Future<File> write(dynamic data) async {
    final file = await _localFile;
    return file.writeAsString(jsonEncode(data));
  }
}
