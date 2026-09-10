// 应用入口。MVVM + Riverpod 组装：
// 1) 系统状态栏样式  2) ProviderScope 挂载
// 3) 依认证状态路由：boot→Splash / needsLogin→Login / authed→Home。
// 页面见 lib/views/pages/，状态见 lib/viewmodels/，内核见 lib/core/。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'viewmodels/auth_vm.dart';
import 'views/pages/home_page.dart';
import 'views/pages/load_page.dart';
import 'views/pages/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ProviderScope(child: GradeApp()));
}

class GradeApp extends ConsumerWidget {
  const GradeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return MaterialApp(
      title: 'Grade',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: auth.when(
        loading: () => const SplashPage(),
        error: (e, _) => SplashPage(message: '启动失败: $e'),
        data: (s) => switch (s.status) {
          AuthStatus.boot => const SplashPage(),
          AuthStatus.busy ||
          AuthStatus.needsLogin ||
          AuthStatus.needsSms =>
            const LoginPage(),
          AuthStatus.authed => const HomePage(),
        },
      ),
    );
  }
}
