// 来源：lib/main.dart updatePage（L2626-3637）。MVVM 迁移第二批：
// UI（请假条卡片/评教入口）逐行保留，数据访问点替换：
// 功能开关 → ServerApi.getFeatureSwitches；评教列表 → evaluateProvider。
// 已按迁移要求删除："青年大学习"卡片及其全部相关内容、聊天页入口卡片、
// 评教局部字段（列表改由 evaluateProvider 提供）、注释掉的二维码功能。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/server_api.dart';
import '../../viewmodels/evaluate_provider.dart';
import '../../views/widgets/form_widgets.dart';
import 'evaluate_page.dart';
import 'vacation_page.dart';

class ToolsPage extends ConsumerStatefulWidget {
  const ToolsPage({super.key});

  @override
  ConsumerState<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends ConsumerState<ToolsPage>
    with TickerProviderStateMixin {
  late AnimationController _expandAnimController;
  late Animation<double> _expandAnim;
  late AnimationController initialController;
  late Animation<double> initialAnimation;
  bool isvacationExpanded = false;
  bool leave = false;
  //输入框批量
  TextEditingController reasonController = TextEditingController();

  TextEditingController startdatecontroller = TextEditingController();
  TextEditingController enddatecontroller = TextEditingController();
  TextEditingController checkdatecontroller = TextEditingController();

  TextEditingController myname = TextEditingController();
  TextEditingController teacher = TextEditingController();

  TextEditingController type = TextEditingController();
  String selectedLocation = "1";
  List passstate = ["1", "1", "1"];

  @override
  void initState() {
    super.initState();
    try {
      ServerApi.getFeatureSwitches().then((value) {
        passstate = value;
        setState(() {});
      });
      initialController = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 700));
      initialAnimation = CurvedAnimation(
          parent: initialController, curve: Curves.easeInOutCubic);
      initialAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(initialAnimation);
      initialController.forward();

      _expandAnimController = AnimationController(
          duration: const Duration(milliseconds: 600), vsync: this);
      _expandAnim = CurvedAnimation(
          parent: _expandAnimController, curve: Curves.easeOutBack);
      _expandAnim =
          Tween<double>(begin: 0.0, end: 1.0).animate(_expandAnim);
    } catch (e) {
      Null;
    }
  }

  @override
  void dispose() {
    initialController.dispose();
    //_ChatLoadAnimaController.dispose();
    _expandAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext content) {
    final mediaQueryData = MediaQuery.of(context);
    double statusBarHeight = mediaQueryData.padding.top;
    double screenWidth = mediaQueryData.size.width;
    //double screenHeight = mediaQueryData.size.height;
    double fontsz = screenWidth * 0.045;
    return Scaffold(
        body: Column(
      children: [
        SizedBox(
          height: statusBarHeight,
        ),
        AnimatedBuilder(
          animation: initialAnimation,
          builder: (context, child) {
            return Expanded(
              child: Opacity(
                  opacity: 0.5 + 0.5 * initialAnimation.value,
                  child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: ListView(
                        children: [
                          SizedBox(
                            height: 50 - 50 * initialAnimation.value,
                          ),
                          AnimatedContainer(
                              clipBehavior: Clip.hardEdge,
                              curve: Curves.bounceOut,
                              margin:
                                  EdgeInsets.only(left: fontsz, right: fontsz),
                              duration: const Duration(milliseconds: 900),
                              height:
                                  isvacationExpanded ? fontsz * 20 : fontsz * 3,
                              //padding: EdgeInsets.only(left: fontsz * .7),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(fontsz),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color.fromARGB(
                                            255, 236, 236, 236),
                                        blurRadius: fontsz)
                                  ]),
                              child: Stack(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "   今日校园",
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: fontsz),
                                          ),
                                          Text(
                                            "请假条生成",
                                            style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: fontsz),
                                          ),
                                          const Expanded(child: SizedBox()),
                                          GestureDetector(
                                            onTap: () {
                                              if (!isvacationExpanded) {
                                                _expandAnimController
                                                    .forward();
                                              } else {
                                                _expandAnimController
                                                    .reverse();
                                              }
                                              setState(() {
                                                isvacationExpanded =
                                                    !isvacationExpanded;
                                              });
                                            },
                                            child: Container(
                                                margin:
                                                    EdgeInsets.all(fontsz / 2),
                                                width: fontsz * 6,
                                                height: fontsz * 2,
                                                //padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          fontsz / 2),
                                                ),
                                                child: Center(
                                                    child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "编辑假条",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontSize:
                                                              fontsz * 0.8,
                                                          decoration:
                                                              TextDecoration
                                                                  .none,
                                                          color: Colors.blue),
                                                    ),
                                                    AnimatedBuilder(
                                                        animation:
                                                            _expandAnim,
                                                        builder:
                                                            (context, child) {
                                                          return Transform
                                                              .rotate(
                                                                  angle: _expandAnim
                                                                          .value *
                                                                      -3.14,
                                                                  child: Icon(
                                                                    Icons
                                                                        .keyboard_arrow_up,
                                                                    size:
                                                                        fontsz *
                                                                            1.5,
                                                                    color: const Color
                                                                        .fromARGB(
                                                                        255,
                                                                        114,
                                                                        114,
                                                                        114),
                                                                  ));
                                                        })
                                                  ],
                                                ))),
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                          child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "    请假原因：",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: fontsz * 0.9,
                                                    decoration:
                                                        TextDecoration.none,
                                                    color: Colors.black87),
                                              ),
                                              CustomTextField(
                                                  controller: reasonController),
                                              //TextField()
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                "    发起位置：",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: fontsz * 0.9,
                                                    decoration:
                                                        TextDecoration.none,
                                                    color: Colors.black87),
                                              ),
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: '1',
                                                    groupValue:
                                                        selectedLocation,
                                                    onChanged: (String? value) {
                                                      setState(() {
                                                        selectedLocation =
                                                            value!;
                                                        //widget.controller.text = selectedLocation!;
                                                      });
                                                    },
                                                  ),
                                                  const Text('武区'),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: '2',
                                                    groupValue:
                                                        selectedLocation,
                                                    onChanged: (String? value) {
                                                      setState(() {
                                                        selectedLocation =
                                                            value!;
                                                        // widget.controller.text = selectedLocation!;
                                                      });
                                                    },
                                                  ),
                                                  const Text('东区'),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: '3',
                                                    groupValue:
                                                        selectedLocation,
                                                    onChanged: (String? value) {
                                                      setState(() {
                                                        selectedLocation =
                                                            value!;
                                                        // widget.controller.text = selectedLocation!;
                                                      });
                                                    },
                                                  ),
                                                  const Text('西区'),
                                                ],
                                              ),
                                              //TextField()
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                "    起始时间：",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: fontsz * 0.9,
                                                    decoration:
                                                        TextDecoration.none,
                                                    color: Colors.black87),
                                              ),
                                              DateTimePickerButton(
                                                  controller:
                                                      startdatecontroller),
                                              Text(
                                                "  “请假开始时间”",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: fontsz * 0.8,
                                                    decoration:
                                                        TextDecoration.none,
                                                    color: Colors.black26),
                                              )
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                "    结束时间：",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: fontsz * 0.9,
                                                    decoration:
                                                        TextDecoration.none,
                                                    color: Colors.black87),
                                              ),
                                              DateTimePickerButton(
                                                  controller:
                                                      enddatecontroller),
                                              Text(
                                                "  “请假结束时间”",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: fontsz * 0.8,
                                                    decoration:
                                                        TextDecoration.none,
                                                    color: Colors.black26),
                                              )
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                "    审核时间：",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: fontsz * 0.9,
                                                    decoration:
                                                        TextDecoration.none,
                                                    color: Colors.black87),
                                              ),
                                              DateTimePickerButton(
                                                  controller:
                                                      checkdatecontroller),
                                              Text(
                                                "  “辅导员审核时间”",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: fontsz * 0.8,
                                                    decoration:
                                                        TextDecoration.none,
                                                    color: Colors.black26),
                                              )
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                "    我叫：",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: fontsz * 0.9,
                                                    decoration:
                                                        TextDecoration.none,
                                                    color: Colors.black87),
                                              ),
                                              SizedBox(
                                                width: fontsz * 4,
                                                child: CustomTextField(
                                                    controller: myname),
                                              ),
                                              Text(
                                                " 辅导员：",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: fontsz * 0.9,
                                                    decoration:
                                                        TextDecoration.none,
                                                    color: Colors.black87),
                                              ),
                                              SizedBox(
                                                width: fontsz * 4,
                                                child: CustomTextField(
                                                    controller: teacher),
                                              ),
                                              Checkbox(
                                                value: leave,
                                                onChanged: (value) {
                                                  setState(() {
                                                    leave = value!;
                                                  });
                                                },
                                              ),
                                              Text(
                                                "离校",
                                                style: TextStyle(
                                                    color: !leave
                                                        ? Colors.black87
                                                        : Colors.blue),
                                              )
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                "    请假类型：",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: fontsz * 0.9,
                                                    decoration:
                                                        TextDecoration.none,
                                                    color: Colors.black87),
                                              ),
                                              SizedBox(
                                                width: screenWidth / 5,
                                                child: PresetSelectionCard(
                                                  controller: type,
                                                ),
                                              ),
                                              GestureDetector(
                                                  onTap: () async {
                                                    //List data = await getdaxuexi();
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) => VacationPage(
                                                              reason:
                                                                  reasonController
                                                                      .text,
                                                              position:
                                                                  selectedLocation,
                                                              StartDate:
                                                                  startdatecontroller
                                                                      .text,
                                                              EndDate:
                                                                  enddatecontroller
                                                                      .text,
                                                              CheckDate:
                                                                  checkdatecontroller
                                                                      .text,
                                                              MyName:
                                                                  myname.text,
                                                              Teacher:
                                                                  teacher.text,
                                                              leave: leave,
                                                              type: type.text)),
                                                    );
                                                  },
                                                  child: Container(
                                                      //alignment: Alignment.centerRight,
                                                      margin: EdgeInsets.only(
                                                          left: screenWidth /
                                                              4.5),
                                                      width: fontsz * 4.5,
                                                      height: fontsz * 2,
                                                      decoration: BoxDecoration(
                                                          color: Colors.blue,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      fontsz *
                                                                          0.7)),
                                                      child: Center(
                                                        child: Text(
                                                          "点击生成",
                                                          //textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize:
                                                                  fontsz * 0.8),
                                                        ),
                                                      )))
                                            ],
                                          )
                                        ],
                                      )),
                                    ],
                                  ),
                                  passstate[1] == "0"
                                      ? Container(
                                          clipBehavior: Clip.hardEdge,
                                          height: isvacationExpanded
                                              ? fontsz * 20
                                              : fontsz * 3,
                                          width: screenWidth - fontsz * 2,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withValues(alpha: 0.4),
                                            borderRadius:
                                                BorderRadius.circular(fontsz),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "功能暂时关闭",
                                              style: TextStyle(
                                                  shadows: [
                                                    BoxShadow(
                                                        color: Colors.black45,
                                                        blurRadius: fontsz)
                                                  ],
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        )
                                      : Container()
                                ],
                              )),
                          SizedBox(
                            child: Stack(children: [
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    await ref
                                        .read(evaluateProvider.notifier)
                                        .load();
                                    if (!mounted) return;
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return const EvaluatePage();
                                        },
                                      ),
                                    );
                                  } catch (e) {
                                    Fluttertoast.showToast(
                                        msg: "Grade当前为离线模式，无法使用",
                                        toastLength: Toast.LENGTH_SHORT,
                                        gravity: ToastGravity.CENTER,
                                        timeInSecForIosWeb: 1,
                                        backgroundColor: Colors.blue,
                                        textColor: Colors.white,
                                        fontSize: 16.0);
                                  }
                                  //setState(() {});
                                },
                                child: Container(
                                    margin: EdgeInsets.all(fontsz),
                                    padding: EdgeInsets.all(fontsz / 4),
                                    //  width: screenWidth,
                                    height: fontsz * 3,
                                    decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius:
                                            BorderRadius.circular(fontsz)),
                                    child: const Center(
                                      child: Text(
                                        "快 捷 量 化 评 教(在线模式)",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      ),
                                    )),
                              ),
                              passstate[2] == "0"
                                  ? Container(
                                      margin: EdgeInsets.all(fontsz),
                                      padding: EdgeInsets.all(fontsz / 4),
                                      width: screenWidth,
                                      height: fontsz * 3,
                                      decoration: BoxDecoration(
                                          color:
                                              Colors.black.withValues(alpha: 0.4),
                                          borderRadius:
                                              BorderRadius.circular(fontsz)),
                                      child: Center(
                                        child: Text(
                                          "功能暂时关闭",
                                          style: TextStyle(
                                              shadows: [
                                                BoxShadow(
                                                    color: Colors.black45,
                                                    blurRadius: fontsz)
                                              ],
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    )
                                  : Container()
                            ]),
                          ),
                          SizedBox(
                            height: 50 - 50 * initialAnimation.value,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final Uri url = Uri.parse(
                                      'https://www.cac.gov.cn/2023-07/13/c_1690898327029107.htm');
                                  if (!await launchUrl(url)) {
                                    throw Exception('Could not launch $url');
                                  }
                                },
                                child: Container(
                                  margin: EdgeInsets.only(left: fontsz),
                                  width: 300,
                                  height: 30,
                                  decoration: BoxDecoration(
                                      border: Border.all(width: 0),
                                      color: Colors.black,
                                      borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10))),
                                  child: const Center(
                                    child: Text(
                                      "《生成式人工智能服务管理暂行办法》",
                                      style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 15),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // AnimatedContainer(
                          //   duration: Duration(milliseconds: 500),
                          //   margin: EdgeInsets.symmetric(horizontal: fontsz),
                          //   padding: EdgeInsets.all(fontsz / 2),
                          //   width: screenWidth,
                          //   height: screenWidth / 3,
                          //   decoration: BoxDecoration(
                          //       color: Colors.amber,
                          //       boxShadow: [
                          //         BoxShadow(
                          //             color: const Color.fromARGB(
                          //                 255, 236, 236, 236),
                          //             blurRadius: fontsz)
                          //       ],
                          //       borderRadius: BorderRadius.circular(fontsz)),
                          //   child: Row(
                          //     children: [
                          //       Expanded(
                          //           child: Container(
                          //         padding: const EdgeInsets.all(5),
                          //         decoration: BoxDecoration(
                          //             color: Colors.white,
                          //             border: Border.all(
                          //                 width: 1, color: Colors.black12),
                          //             borderRadius: BorderRadius.circular(10)),
                          //         height: screenWidth / 2,
                          //         child: TextField(
                          //           onEditingComplete: () => setState(() {}),
                          //           controller: qrcodect,
                          //           maxLines: null,
                          //           style: const TextStyle(
                          //               height: 1, fontSize: 14),
                          //           decoration: const InputDecoration(
                          //             isDense: true,
                          //             border: InputBorder.none,
                          //             enabledBorder: InputBorder.none,
                          //             focusedBorder: InputBorder.none,
                          //             errorBorder: InputBorder.none,
                          //             disabledBorder: InputBorder.none,
                          //             contentPadding: EdgeInsets.zero,
                          //             //helperText: "输入内容转换为二维码",
                          //           ),
                          //         ),
                          //       )),
                          //       RepaintBoundary(
                          //           key: globalKey,
                          //           child: Container(
                          //               color: Colors.white,
                          //               child: QrImageView(
                          //                 data: qrcodect.text,
                          //                 version: QrVersions.auto,
                          //                 eyeStyle: const QrEyeStyle(
                          //                   color: Colors.black,
                          //                 ),
                          //                 dataModuleStyle:
                          //                     const QrDataModuleStyle(
                          //                   color: Colors.black,
                          //                   dataModuleShape: QrDataModuleShape
                          //                       .circle, // 将二维码点设置为圆形
                          //                 ),
                          //                 size: screenWidth * 0.3,
                          //               ))),
                          //     ],
                          //   ),
                          // ),
                          SizedBox(
                            height: 50 - 50 * initialAnimation.value,
                          ),
                          SizedBox(
                            height: fontsz,
                          ),
                          Center(
                            child: SizedBox(
                                width: screenWidth * 0.8,
                                height: screenWidth * 0.4,
                                child: Column(
                                  children: [
                                    Text(
                                      "一些功能的解释",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: fontsz * 0.65,
                                          color: Colors.grey),
                                    ),
                                    Text(
                                      "功能暂时关闭：由于功能敏感性等原因而导致功能暂时性停用",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: fontsz * 0.65,
                                          color: Colors.grey),
                                    ),
                                    Text(
                                      "“一键差评”：Grade2一直是为爱发电的状态,此功能可能会导致学校的反对,此举不利于grade2的生存",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: fontsz * 0.65,
                                          color: Colors.grey),
                                    ),
                                    Text(
                                      "大家有好的创意功能想法可以与我联系或反馈\nVX:xiaonaoweisuo003",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: fontsz * 0.65,
                                          color: Colors.green),
                                    ),
                                  ],
                                )),
                          ),
                        ],
                      ))),
            );
          },
        )
      ],
    ));
  }
}
