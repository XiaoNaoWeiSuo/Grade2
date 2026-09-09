// 应用入口。MVVM 重构后本文件只负责：
// 1) 系统状态栏/导航栏样式  2) ProviderScope 挂载  3) MaterialApp 配置。
// 页面见 lib/views/pages/，状态见 lib/viewmodels/，数据见 lib/data/。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'views/pages/load_page.dart';

void main() async {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: MyApp()));

  if (Platform.isAndroid) {
    SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Grade",
      theme: ThemeData(
        platform: TargetPlatform.android, // 或 TargetPlatform.android
      ),
      home: const SplashPage(),
    );
  }
}
