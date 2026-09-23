// 应用入口。MVVM + Riverpod + Cupertino + 国际化 + 多主题：
// 1) ProviderScope 挂载
// 2) 启动载入持久化的语言/主题（appSettingsProvider.load）
// 3) CupertinoApp 注入：locale、localizationsDelegates（中简/繁/英/日/乌）、
//    按主题模式构建 CupertinoThemeData，并用 AppThemeScope 与 AppL10nScope 全局注入
// 4) 依认证状态瞬时直达路由：无闪屏/flash页面，直接根据认证态渲染 Home / Login
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
      child: AppL10nScope(
        strings: AppStrings(settings.locale.code),
        locale: settings.locale,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: _appSystemUiOverlayStyle,
          child: CupertinoApp(
            title: 'Grade',
            debugShowCheckedModeBanner: false,
            locale: settings.locale.locale,
            supportedLocales: [for (final l in supportedAppLocales) l.locale],
            localizationsDelegates: const [
              GlobalCupertinoLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            theme: buildTheme(palette, brightness),
            builder: (context, child) {
              return Directionality(
                textDirection: settings.locale.isRtl
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const _AuthGate(),
          ),
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
      loading: () => const _BootContainer(),
      error: (e, _) => const LoginPage(),
      data: (s) => switch (s.status) {
        AuthStatus.boot => const _BootContainer(),
        AuthStatus.busy ||
        AuthStatus.needsLogin ||
        AuthStatus.needsSms => const LoginPage(),
        AuthStatus.authed => const AuthedHome(),
      },
    );
  }
}

/// 启动瞬态容器（无冗余动画与闪屏，无缝秒开）
class _BootContainer extends StatelessWidget {
  const _BootContainer();

  @override
  Widget build(BuildContext context) {
    final p = AppThemeScope.of(context);
    return CupertinoPageScaffold(
      backgroundColor: p.bg,
      child: const SizedBox.expand(),
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
