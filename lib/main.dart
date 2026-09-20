// 应用入口。MVVM + Riverpod + Cupertino + 国际化 + 多主题：
// 1) ProviderScope 挂载
// 2) 启动载入持久化的语言/主题（appSettingsProvider.load）
// 3) CupertinoApp 注入：locale、localizationsDelegates（中简/繁/英/日/乌）、
//    按主题模式构建 CupertinoThemeData，并用 AppThemeScope 下发色板
// 4) 依认证状态路由：boot→Splash / needsLogin/needsSms→Login / authed→Home
// authed 区域用嵌套 Navigator 承载（课表首页 + 下钻模块页压栈），登出时整棵卸载。

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_settings.dart';
import 'l10n/app_strings.dart';
import 'l10n/app_theme.dart';
import 'viewmodels/auth_vm.dart';
import 'views/pages/login_page.dart';
import 'views/pages/load_page.dart';
import 'views/pages/timetable_page.dart';

const _appSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarContrastEnforced: false,
);
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(_appSystemUiOverlayStyle);

  runApp(const ProviderScope(child: GradeApp()));
}

class GradeApp extends ConsumerStatefulWidget {
  const GradeApp({super.key});

  @override
  ConsumerState<GradeApp> createState() => _GradeAppState();
}

class _GradeAppState extends ConsumerState<GradeApp> {
  @override
  void initState() {
    super.initState();
    // 载入持久化的语言/主题（读 LocalCache，完成后经 watch 重建）
    Future.microtask(() => ref.read(appSettingsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final mode = settings.theme;
    final palette = paletteFor(mode, platformBrightness);
    final brightness = brightnessFor(mode, platformBrightness);

    return AppThemeScope(
      palette: palette,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: _appSystemUiOverlayStyle,
        child: CupertinoApp(
          title: settings.locale.code == 'zh-Hant' ? 'Grade' : 'Grade',
          debugShowCheckedModeBanner: false,
          locale: settings.locale.locale,
          supportedLocales: [for (final l in supportedAppLocales) l.locale],
          localizationsDelegates: const [
            GlobalCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          theme: buildTheme(palette, brightness),
          home: _AuthGate(),
        ),
      ),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return auth.when(
      loading: () => const SplashPage(),
      error: (e, _) => SplashPage(message: '${context.l10n.appName} · $e'),
      data: (s) => switch (s.status) {
        AuthStatus.boot => const SplashPage(),
        AuthStatus.busy ||
        AuthStatus.needsLogin ||
        AuthStatus.needsSms => const LoginPage(),
        AuthStatus.authed => const AuthedHome(),
      },
    );
  }
}

/// authed 区域：嵌套 Navigator，首路由为课表首页。
class AuthedHome extends StatelessWidget {
  const AuthedHome({super.key});

  static final GlobalKey<NavigatorState> navigator =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigator,
      onGenerateRoute: (_) =>
          CupertinoPageRoute<void>(builder: (_) => const TimetablePage()),
    );
  }
}
