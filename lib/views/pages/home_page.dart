/// 主页骨架：底部导航 [课表 / 缓存 / 更多]（工程期 IndexedStack 保状态）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/auth_vm.dart';
import 'cache_page.dart';
import 'more_page.dart';
import 'timetable_page.dart';
import '../widgets/kit.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  var _index = 0;

  static const _pages = [TimetablePage(), CachePage(), MorePage()];

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider).value ?? const AuthState();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade2 工程UI'),
        actions: [
          if (auth.offline)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                  child: Icon(Icons.cloud_off, size: 18, color: Colors.grey)),
            ),
          IconButton(
            tooltip: '登出',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final ok = await confirmDialog(context,
                  title: '登出', content: '将清除本地会话令牌（保留账号簿），确定？');
              if (ok && mounted) {
                await ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: '课表',
          ),
          NavigationDestination(
            icon: const Icon(Icons.storage_outlined),
            selectedIcon: const Icon(Icons.storage),
            label: '缓存',
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: '更多',
          ),
        ],
      ),
    );
  }
}
