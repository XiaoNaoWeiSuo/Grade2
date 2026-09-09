// 来源：lib/main.dart Loadpage（L69-258）。MVVM 迁移第二批：
// UI（入场动画）逐行保留，启动路由逻辑改为
// aboutProvider.checkUpdate + accountBookProvider.load + offlineRestoreProvider.restore。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/about_provider.dart';
import '../../viewmodels/academic_provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/offline_provider.dart';
import 'login_page.dart';
import 'main_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController initailanime;
  late Animation<double> initialanimation;
  @override
  void initState() {
    super.initState();
    load();
    initailanime = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..addStatusListener(
        (status) {},
      );
    initialanimation =
        CurvedAnimation(parent: initailanime, curve: Curves.easeOutQuart);
    initialanimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(initialanimation);
    initailanime.forward();
  }

  void load() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final bool result = await ref.read(aboutProvider.notifier).checkUpdate();
    await ref.read(accountBookProvider.notifier).load();
    final Map<String, dynamic> data = ref.read(accountBookProvider);
    if (result || data["setting"] == "ON") {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return const LoginPage(intostate: true, backlogin: true);
          },
        ),
      );
    } else {
      final OfflineResult restore =
          await ref.read(offlineRestoreProvider).restore();
      if (restore.status == OfflineStatus.ok) {
        ref.read(academicProvider.notifier).set(restore.data!);
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const MainPage();
            },
          ),
        );
      } else {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const LoginPage(intostate: true, backlogin: true);
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: initialanimation,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned(
                    child: Column(
                  children: [
                    SizedBox(
                        height: 400,
                        child: Center(
                          child: Opacity(
                            //  opacity: 0.6 * initailanime.value + 0.4,
                            opacity: initialanimation.value,
                            child: const Text(
                              "-Grade-",
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ))
                  ],
                )),
                Positioned(
                    child: Center(
                  child: SizedBox(
                      width: 400,
                      child: Transform.translate(
                          offset: Offset(80 - 80 * initialanimation.value, 0),
                          child: Opacity(
                            //  opacity: 0.6 * initailanime.value + 0.4,
                            opacity: initialanimation.value,
                            child: Image.asset("assets/data/icon.png"),
                          ))),
                ))
              ],
            );
          },
        ),
      ),
    );
  }
}
