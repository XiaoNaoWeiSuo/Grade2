// 迁移自 lib/tree/pages.dart：LOVEPage（L2669-2689，改名 LovePage）。
// UI 逐行保持不变，AnimCard 改从 ../widgets/shared_ui.dart 导入。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/shared_ui.dart';

class LovePage extends StatelessWidget {
  const LovePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('none'),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: AnimCard(
        Color(0xffFF6594),
        '',
        '',
        '',
      ),
    );
  }
}
