// 迁移自 lib/tree/pages.dart：vacationPage（L1014-1768，改名 VacationPage）。
// 构造参数与旧页面完全一致；纯展示页面（日期时长解析保留在页面内），无 provider 交互。
// UI（布局/颜色/文本）逐行保持不变；旧 initState 中已注释掉的入场动画代码未搬运。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/info_widgets.dart';

class VacationPage extends ConsumerWidget {
  final String reason;
  final String position;
  final String StartDate;
  final String EndDate;
  final String CheckDate;
  final String MyName;
  final String Teacher;
  final bool leave;
  final String type;
  const VacationPage({
    required this.reason,
    required this.position,
    required this.StartDate,
    required this.EndDate,
    required this.CheckDate,
    required this.MyName,
    required this.Teacher,
    required this.leave,
    required this.type,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQueryData = MediaQuery.of(context);
    final double statusBarHeight = mediaQueryData.padding.top;
    final double screenWidth = mediaQueryData.size.width;
    final double screenHeight = mediaQueryData.size.height;
    final double ItemSize = screenWidth * 0.05;

    // 旧 _vacationState.initState 的日期时长解析（展示逻辑，保留在页面内）
    int hours = 0;
    int mins = 0;
    if (StartDate != "" && EndDate != "") {
      int days = (int.parse(EndDate[3]) * 10 + int.parse(EndDate[4])) -
          (int.parse(StartDate[3]) * 10 + int.parse(StartDate[4]));

      hours = (int.parse(EndDate[7]) * 10 + int.parse(EndDate[8])) -
          (int.parse(StartDate[7]) * 10 + int.parse(StartDate[8]));

      if (hours < 0) {
        hours = hours + 24;
        days -= 1;
        hours = hours + days * 24;
      }
      mins = (int.parse(EndDate[10]) * 10 + int.parse(EndDate[11])) -
          (int.parse(StartDate[10]) * 10 + int.parse(StartDate[11]));
      if (mins < 0) {
        mins = mins + 60;
        hours -= 1;
      }
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
              width: screenWidth,
              padding: EdgeInsets.only(left: ItemSize * 0.7, right: ItemSize),
              height: ItemSize * 4.5,
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          width: 1,
                          color: Colors.grey.withValues(alpha: 0.25)))),
              child: Column(
                children: [
                  SizedBox(
                    height: statusBarHeight * 1.4,
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: ItemSize * 1.2,
                        ),
                      ),
                      Expanded(
                          child: Center(
                        child: Text(
                          "请假详情",
                          style: TextStyle(
                              fontSize: ItemSize * 0.9,
                              fontWeight: FontWeight.w900),
                        ),
                      )),
                    ],
                  )
                ],
              )),
          Row(
            children: [
              Container(
                  width: screenWidth / 4,
                  height: ItemSize * 2.3,
                  margin: EdgeInsets.only(
                      left: screenWidth / 8, right: screenWidth / 8),
                  decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(width: 3, color: Colors.blue))),
                  child: Center(
                    child: Text(
                      "请假信息",
                      style: TextStyle(
                          fontSize: ItemSize * 0.85,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold),
                    ),
                  )),
              Container(
                  width: screenWidth / 4,
                  height: ItemSize * 2.3,
                  margin: EdgeInsets.only(
                      left: screenWidth / 8, right: screenWidth / 8),
                  child: Center(
                    child: Text(
                      "核验二维码",
                      style: TextStyle(
                          fontSize: ItemSize * 0.85,
                          color: const Color.fromARGB(255, 121, 120, 120),
                          fontWeight: FontWeight.normal),
                    ),
                  )),
            ],
          ),
          Container(
            width: screenWidth,
            height: ItemSize * 1.2,
            color: const Color.fromARGB(255, 251, 160, 42),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.help,
                    color: Colors.white,
                    size: ItemSize,
                  ),
                  const Text(
                    "如何销假 ？",
                    style: TextStyle(color: Colors.white),
                  )
                ],
              ),
            ),
          ),
          Container(
            width: screenWidth,
            height: screenHeight / 7.5,
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
              Color.fromARGB(255, 75, 166, 96),
              Color.fromARGB(255, 100, 214, 129)
            ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Expanded(child: SizedBox()),
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: ItemSize,
                    ),
                    Text(
                      "审 批 已 通 过",
                      style: TextStyle(
                          height: 1.6,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          fontSize: ItemSize * 1),
                    ),
                    Expanded(
                        child: Text(
                      "       个人信息 >",
                      style: TextStyle(
                          height: 1.6,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          fontSize: ItemSize * 0.8),
                    )),
                  ],
                ),
                Text(
                  "正在休假中",
                  style: TextStyle(color: Colors.white, fontSize: ItemSize * 2),
                ),
                const Expanded(child: SizedBox()),
                SizedBox(
                  width: screenWidth,
                  height: 20,
                  child: const AnimatedStrip(
                    color: Colors.white,
                    duration: Duration(milliseconds: 1000),
                    stripeHeight: 20,
                  ),
                )
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: ItemSize * 1.2, top: ItemSize * 0.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "请假类型：",
                      style: TextStyle(
                          fontSize: ItemSize * 0.65, color: Colors.black45),
                    ),
                    Text(
                      type,
                      style: TextStyle(
                          fontSize: ItemSize * 0.65, color: Colors.black54),
                    ),
                    SizedBox(
                      width: screenWidth / 5,
                    ),
                    Text(
                      "需要离校：",
                      style: TextStyle(
                          fontSize: ItemSize * 0.65, color: Colors.black45),
                    ),
                    Text(
                      leave ? "是" : "否",
                      style: TextStyle(
                          fontSize: ItemSize * 0.65, color: Colors.black54),
                    )
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "销假规则：",
                      style: TextStyle(
                          height: 1.8,
                          fontSize: ItemSize * 0.65,
                          color: Colors.black45),
                    ),
                    Text(
                      "离校请假需要销假，非离校请假无需销假",
                      style: TextStyle(
                          height: 1.8,
                          fontSize: ItemSize * 0.65,
                          color: Colors.orange),
                    ),
                    Text(
                      " 查看 >",
                      style: TextStyle(
                          height: 1.8,
                          fontSize: ItemSize * 0.65,
                          color: Colors.blue),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "实际休假时间：",
                      style: TextStyle(
                          height: 1.8,
                          fontSize: ItemSize * 0.65,
                          color: Colors.black45),
                    ),
                    Text(
                      "-",
                      style: TextStyle(
                          height: 1.8,
                          fontSize: ItemSize * 0.65,
                          color: Colors.black54),
                    ),
                  ],
                )
              ],
            ),
          ),
          Container(
            width: screenWidth,
            height: ItemSize * 0.7,
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                border: Border(
                    top: BorderSide(
                        width: 0.5, color: Colors.grey.withValues(alpha: 0.2)),
                    bottom: BorderSide(
                        width: 0.5,
                        color: Colors.grey.withValues(alpha: 0.2)))),
          ),
          Container(
              padding: EdgeInsets.only(
                  left: ItemSize * 1.2,
                  right: ItemSize * 1.2,
                  top: ItemSize * 0.2,
                  bottom: ItemSize * 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "我的 请假申请",
                    style: TextStyle(
                        height: 1.8,
                        fontSize: ItemSize * 0.8,
                        color: Colors.black87),
                  ),
                  Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "开始时间：",
                                style: TextStyle(
                                    height: 1.6,
                                    fontSize: ItemSize * 0.7,
                                    color: Colors.black45),
                              ),
                              Text(
                                StartDate,
                                style: TextStyle(
                                    height: 1.6,
                                    fontWeight: FontWeight.w800,
                                    fontSize: ItemSize * 0.7,
                                    color: Colors.black54),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "结束时间：",
                                style: TextStyle(
                                    height: 1.6,
                                    fontSize: ItemSize * 0.7,
                                    color: Colors.black45),
                              ),
                              Text(
                                EndDate,
                                style: TextStyle(
                                    height: 1.6,
                                    fontWeight: FontWeight.w800,
                                    fontSize: ItemSize * 0.7,
                                    color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Expanded(child: SizedBox()),
                      Container(
                        width: ItemSize * 6,
                        height: ItemSize * 1.6,
                        decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(width: 0.7, color: Colors.blue)),
                        child: Center(
                          child: Text(
                            "$hours小时$mins分钟",
                            style: TextStyle(
                                height: 1.6,
                                fontWeight: FontWeight.w800,
                                fontSize: ItemSize * 0.8,
                                color: Colors.blue),
                          ),
                        ),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        "审批流程：",
                        style: TextStyle(
                            height: 1.6,
                            fontSize: ItemSize * 0.7,
                            color: Colors.black45),
                      ),
                      Text(
                        "共1步",
                        style: TextStyle(
                            height: 1.6,
                            fontSize: ItemSize * 0.7,
                            color: Colors.black54),
                      ),
                      Text(
                        " 查看 >",
                        style: TextStyle(
                            height: 1.6,
                            fontSize: ItemSize * 0.65,
                            color: Colors.blue),
                      ),
                    ],
                  ),
                  Row(children: [
                    Text(
                      "请假原因：",
                      style: TextStyle(
                          height: 1.6,
                          fontSize: ItemSize * 0.7,
                          color: Colors.black45),
                    ),
                    Text(
                      reason,
                      style: TextStyle(
                          height: 1.6,
                          fontSize: ItemSize * 0.7,
                          color: Colors.black54),
                    ),
                  ]),
                  Row(children: [
                    Text(
                      "发起位置：",
                      style: TextStyle(
                          height: 1.6,
                          fontSize: ItemSize * 0.7,
                          color: Colors.black45),
                    ),
                    Text(
                      position == "1"
                          ? "湖北省武汉市蔡甸区连通路"
                          : (position == "2"
                              ? "湖北省荆州市长江大学东校区"
                              : "湖北省荆州市长江大学西校区"),
                      style: TextStyle(
                          height: 1.6,
                          fontSize: ItemSize * 0.7,
                          color: Colors.blue),
                    ),
                  ]),
                  Row(children: [
                    Text(
                      "抄送人：",
                      style: TextStyle(
                          height: 1.6,
                          fontSize: ItemSize * 0.7,
                          color: Colors.black45),
                    ),
                    Text(
                      "   无",
                      style: TextStyle(
                          height: 1.6,
                          fontSize: ItemSize * 0.7,
                          color: Colors.black54),
                    ),
                  ]),
                  Row(children: [
                    Text(
                      "宿舍信息：",
                      style: TextStyle(
                          height: 1.6,
                          fontSize: ItemSize * 0.7,
                          color: Colors.black45),
                    ),
                    Text(
                      "-",
                      style: TextStyle(
                          height: 1.6,
                          fontSize: ItemSize * 0.7,
                          color: Colors.black54),
                    ),
                  ]),
                  Text(
                    "本人承诺填写的信息真实有效，并对本次提交请假申请的信息真实性负责。",
                    style: TextStyle(
                        height: 1.8,
                        fontSize: ItemSize * 0.65,
                        color: Colors.orange),
                  ),
                ],
              )),
          Container(
            width: screenWidth,
            height: ItemSize * 0.7,
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                border: Border(
                    top: BorderSide(
                        width: 0.5, color: Colors.grey.withValues(alpha: 0.2)),
                    bottom: BorderSide(
                        width: 0.5,
                        color: Colors.grey.withValues(alpha: 0.2)))),
          ),
          Container(
              padding: EdgeInsets.only(
                  left: ItemSize * 1.2,
                  right: ItemSize * 1.2,
                  top: ItemSize * 0.2,
                  bottom: ItemSize * 0.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "审批流程记录",
                    style: TextStyle(
                        height: 1.8,
                        fontSize: ItemSize * 0.8,
                        color: Colors.black87),
                  ),
                  Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: ItemSize * 0.6),
                        width: ItemSize * 1.1,
                        height: ItemSize * 1.1,
                        decoration: BoxDecoration(
                            border: Border.all(width: 1.5, color: Colors.blue),
                            borderRadius: BorderRadius.circular(ItemSize)),
                      ),
                      Expanded(
                          child: Text(
                        "$MyName - 发起申请",
                        style: TextStyle(
                            height: 1.6,
                            fontSize: ItemSize * 0.7,
                            color: Colors.black54),
                      )),
                      Text(
                        StartDate,
                        style: TextStyle(
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            fontSize: ItemSize * 0.7,
                            color: Colors.black26),
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(right: ItemSize * 0.8),
                    width: ItemSize * 1.2,
                    height: ItemSize,
                    child: Center(
                      child: Container(
                        width: 1.5,
                        height: ItemSize * 0.8,
                        color: Colors.black12,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: ItemSize * 0.6),
                        width: ItemSize * 1.1,
                        height: ItemSize * 1.1,
                        decoration: BoxDecoration(
                            border: Border.all(
                                width: 1.5,
                                color:
                                    const Color.fromARGB(255, 108, 226, 112)),
                            borderRadius: BorderRadius.circular(ItemSize)),
                      ),
                      Expanded(
                          child: Row(
                        children: [
                          Text(
                            "一级：$Teacher - 审批",
                            style: TextStyle(
                                height: 1.6,
                                fontSize: ItemSize * 0.7,
                                color: Colors.black54),
                          ),
                          Text(
                            "通过",
                            style: TextStyle(
                                height: 1.6,
                                fontSize: ItemSize * 0.7,
                                color:
                                    const Color.fromARGB(255, 108, 226, 112)),
                          ),
                          Text(
                            "(正常处理)",
                            style: TextStyle(
                                height: 1.6,
                                fontSize: ItemSize * 0.7,
                                color: Colors.black54),
                          )
                        ],
                      )),
                      Text(
                        CheckDate,
                        style: TextStyle(
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            fontSize: ItemSize * 0.7,
                            color: Colors.black26),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: ItemSize * 0.6),
                        width: ItemSize * 1.1,
                        height: ItemSize * 1.1,
                      ),
                      Expanded(
                          child: Container(
                              margin: EdgeInsets.only(
                                  top: ItemSize / 3, bottom: ItemSize / 2),
                              height: ItemSize * 1.5,
                              decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 242, 244, 245),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      width: 1.5, color: Colors.black12)),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  " 审批意见：无",
                                  style: TextStyle(
                                      fontSize: ItemSize * 0.7,
                                      color: Colors.black45),
                                ),
                              )))
                    ],
                  )
                ],
              )),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  border: Border(
                      top: BorderSide(
                          width: 0.5,
                          color: Colors.grey.withValues(alpha: 0.2)),
                      bottom: BorderSide(
                          width: 0.5,
                          color: Colors.grey.withValues(alpha: 0.2)))),
            ),
          ),
          SizedBox(
            height: ItemSize * 2.5,
            width: screenWidth,
            child: Row(
              children: [
                Expanded(
                    child: Container(
                  decoration: const BoxDecoration(
                      border: Border(
                          right:
                              BorderSide(width: 0.5, color: Colors.black12))),
                  child: Center(
                    child: Text(
                      "转发",
                      style: TextStyle(
                          height: 1.6,
                          fontSize: ItemSize * 0.9,
                          color: Colors.black54),
                    ),
                  ),
                )),
                Expanded(
                    child: SizedBox(
                  child: Center(
                    child: Text(
                      "申请续假",
                      style: TextStyle(
                          height: 1.6,
                          fontSize: ItemSize * 0.9,
                          color: Colors.black54),
                    ),
                  ),
                )),
                Expanded(
                    child: Container(
                  decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 100, 156, 252)),
                  child: Center(
                    child: Text(
                      "提前结束",
                      style: TextStyle(
                          height: 1.6,
                          fontSize: ItemSize * 0.9,
                          color: Colors.white),
                    ),
                  ),
                ))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
