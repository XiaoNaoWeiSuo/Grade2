/// 启动过渡页：会话恢复（cookie SSO）期间展示。
library;

import 'package:flutter/material.dart';

/// [message] 为空表示仍在恢复流程（转圈）；有值则展示恢复结果说明。
class SplashPage extends StatelessWidget {
  const SplashPage({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school,
                size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('Grade',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            message == null
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline)),
                  ),
          ],
        ),
      ),
    );
  }
}
