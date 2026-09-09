// 来源：lib/main.dart EvaluatePage（L3639-3783）。MVVM 迁移第二批：
// UI（AppBar 按钮组/列表条目布局）逐行保留，数据访问点替换：
// 评教列表 → evaluateProvider（watch），提交 → evaluateProvider.notifier 的
// submitAll / submitOne；不再直接修改页面入参列表。

import "package:flutter/material.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/evaluate.dart';
import '../../viewmodels/evaluate_provider.dart';
import '../../views/widgets/dialogs.dart';

class EvaluatePage extends ConsumerStatefulWidget {
  const EvaluatePage({super.key});

  @override
  ConsumerState<EvaluatePage> createState() => _EvaluatePageState();
}

class _EvaluatePageState extends ConsumerState<EvaluatePage> {
  @override
  Widget build(BuildContext context) {
    final List<Evaluate> evaluatedata =
        ref.watch(evaluateProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
          title: Row(
        children: [
          const Text("量化评教"),
          const Expanded(child: SizedBox()),
          TextButton(
              onPressed: () {
                showTextDialog(context, "功能尚在开发，敬请期待。");
              },
              child: const Text(
                "生成截图 ",
                style: TextStyle(color: Colors.white),
              )),
          TextButton(
              onPressed: () async {
                bool? result =
                    await showConfirmationDialog(context, '确定提交全部量化评教为“非常满意”？');
                if (result != null && result) {
                  await ref.read(evaluateProvider.notifier).submitAll();
                  setState(() {});
                }
              },
              child: const Text(
                " 全部“非常满意”",
                style: TextStyle(color: Colors.yellow),
              ))
        ],
      )),
      body: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: ListView.builder(
            itemCount: evaluatedata.length,
            itemBuilder: (context, index) {
              final Evaluate item = evaluatedata[index];
              return Container(
                height: 50,
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.all(5),
                // decoration: BoxDecoration(color: Colors.white, boxShadow: [
                //   BoxShadow(color: Colors.black12, blurRadius: 5)
                // ]),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${item.course}",
                          style: const TextStyle(
                              color: Colors.black, fontSize: 15),
                        ),
                        Row(
                          children: [
                            Text(
                              "${item.type}",
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 12),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              "${item.name}",
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 12),
                            ),
                          ],
                        )
                      ],
                    ),
                    const Expanded(child: SizedBox()),
                    item.state
                        ? Container(
                            margin: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.check,
                              color: Colors.blue,
                            ),
                          )
                        : TextButton(
                            onPressed: () async {
                              bool? result = await showConfirmationDialog(
                                  context, "确认提交为全部非常满意？");
                              if (result != null && result) {
                                await ref
                                    .read(evaluateProvider.notifier)
                                    .submitOne(item);
                              }
                              setState(() {});
                            },
                            child: const Text(
                              "好评",
                              style:
                                  TextStyle(color: Colors.blue, fontSize: 15),
                            ),
                          )
                  ],
                ),
              );
            },
          )),
    );
  }
}
