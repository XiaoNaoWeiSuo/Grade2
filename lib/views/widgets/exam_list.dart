// 抽取自原 lib/topbar.dart：ExamList（L802-1025）。
// 改动：原内部跳转 AutherPage 改为回调 onOpenAbout()；removeYear 改从 core/utils/version_utils.dart 引入。

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/utils/version_utils.dart';

class ExamList extends StatelessWidget {
  final List examlist;
  final VoidCallback onOpenAbout;
  const ExamList(
      {super.key, required this.examlist, required this.onOpenAbout});
  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    double statusBarHeight = mediaQueryData.padding.top;
    double screenWidth = mediaQueryData.size.width;
    double screenHeight = mediaQueryData.size.height;
    double fontsz = screenWidth * 0.045;
    return Column(children: [
      SizedBox(
        height: statusBarHeight,
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
            padding: EdgeInsets.all(fontsz),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "考试安排 ",
                  style: TextStyle(
                      fontSize: fontsz,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue),
                ),
                RichText(
                    text: TextSpan(children: [
                  const TextSpan(
                    text: "请在考试期间前往",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                  ),
                  TextSpan(
                    text: "\"关于\"",
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        onOpenAbout();
                      },
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueAccent),
                  ),
                  const TextSpan(
                    text: "关闭离线模式",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                  )
                ]))
              ],
            )),
      ),
      Expanded(
          child: SizedBox(
              width: screenWidth,
              // height: screenHeight * 0.75,
              // decoration: const BoxDecoration(
              //     border:
              //         Border(bottom: BorderSide(width: 2, color: Colors.black))),
              child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: ListView.builder(
                    itemCount: examlist.length,
                    itemBuilder: (context, index) {
                      // 获取当前索引处的数据模型
                      var data = examlist[index];
                      return Container(
                          margin: EdgeInsets.only(
                            // left: fontsz / 2,
                            right: fontsz / 2,
                          ),
                          //padding: EdgeInsets.all(fontsz / 3),
                          height: screenHeight / 10,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(fontsz / 2),
                              // gradient: const LinearGradient(colors: [
                              //   Colors.blue,
                              //   Color.fromARGB(255, 0, 132, 226)
                              // ], begin: Alignment.bottomRight),
                              color: Colors.transparent),
                          child: Row(
                            children: [
                              Container(
                                  width: fontsz * 0.7,
                                  height: fontsz * 0.7,
                                  margin: EdgeInsets.only(
                                      right: fontsz / 2, left: fontsz / 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(fontsz),
                                    color: data.ispass
                                        ? Colors.black38
                                        : Colors.blue,
                                    // borderRadius:
                                    //     BorderRadius.circular(fontsz)
                                  )),
                              SizedBox(
                                  width: screenWidth / 3.2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(data.courseName,
                                          maxLines: 1,
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w800,
                                              fontSize: fontsz * 0.8)),
                                      Text("模式：${data.examFormat}",
                                          maxLines: 1,
                                          style: TextStyle(
                                              color: Colors.black54,
                                              // fontWeight: FontWeight.w800,
                                              fontSize: fontsz * 0.7)),
                                      Text("类型：${data.examType}",
                                          maxLines: 1,
                                          style: TextStyle(
                                              color: Colors.black54,
                                              //fontWeight: FontWeight.w800,
                                              fontSize: fontsz * 0.75)),
                                    ],
                                  )),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.access_alarm,
                                    color: data.ispass
                                        ? Colors.green.withValues(alpha: 0.3)
                                        : Colors.green.withValues(alpha: 0.8),
                                    size: fontsz * 2,
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        removeYear(data.examDate),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                            fontSize: fontsz * 1.2),
                                      ),
                                      Text(
                                        data.examTime,
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: fontsz / 1.2),
                                      )
                                    ],
                                  )
                                ],
                              ),
                              const Expanded(
                                  child: SizedBox(
                                      //width: fontsz / 2,
                                      //height: fontsz * 3,
                                      )),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text(data.capacity.toString(),
                                          style: TextStyle(
                                              color: data.ispass
                                                  ? Colors.blue
                                                      .withValues(alpha: 0.5)
                                                  : Colors.blue,
                                              //fontWeight: FontWeight.w800,
                                              fontSize: fontsz * 1.5,
                                              fontWeight: FontWeight.bold)),
                                      Icon(
                                        Icons.place,
                                        color: Colors.white,
                                        shadows: [
                                          BoxShadow(
                                              color: data.ispass
                                                  ? Colors.black12
                                                  : Colors.black38,
                                              blurRadius: fontsz * 2.5)
                                        ],
                                        size: fontsz * 2.5,
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets.fromLTRB(4, 2, 4, 2),
                                    decoration: BoxDecoration(
                                        color: data.ispass
                                            ? Colors.black
                                                .withValues(alpha: 0.3)
                                            : Colors.black,
                                        borderRadius: BorderRadius.circular(3)),
                                    child: Text(
                                      data.examRoom,
                                      style: const TextStyle(
                                          //backgroundColor: Colors.black,
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ));
                    },
                  ))))
    ]);
  }
}
