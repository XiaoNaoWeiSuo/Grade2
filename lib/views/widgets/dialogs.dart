// 抽取自原 lib/topbar.dart：showConfirmationDialog、showTextDialog（L1253-1304）

import 'package:flutter/material.dart';

//对话框确认取消
Future<bool?> showConfirmationDialog(BuildContext context, String text) async {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('提示'),
        content: Text(text),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // 返回true
            },
            child: const Text('确认'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // 返回false
            },
            child: const Text('取消'),
          ),
        ],
      );
    },
  );
}

//对话框更新提醒
Future<bool?> showTextDialog(BuildContext context, String text) async {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('提示'),
        content: Text(text),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // 返回true
            },
            child: const Text('继续登录'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // 返回false
            },
            child: const Text('获取更新'),
          ),
        ],
      );
    },
  );
}
