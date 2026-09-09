// 迁移自 lib/tree/pages.dart：HomoPage（L1909-2667，改名 GradeOverviewPage，无构造参数）。
// 旧构造参数到 provider 的映射（initState 一次性读取）：
// - topdata → academicProvider.students（旧页面内未使用，仅登记映射）
// - listdata → academicProvider.planCourses（isPassed 统计）
// - otherdata → academicProvider.grades（本学期成绩、类型统计、成绩卡片列表）
// - allgradelist → [academicProvider.gradeAverages, academicProvider.courseTotals]
// - userlist/initdata → accountBookProvider（本页面未直接使用）
// 已删除原 L2501-2650 注释掉的废弃布局代码块；
// anysi1/anysi2 内存统计、双页切换/PageController 等逻辑与 UI 逐行保持不变。

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/course.dart';
import '../../data/models/grade.dart';
import '../../viewmodels/academic_provider.dart';
import '../widgets/info_widgets.dart';
import 'about_page.dart';

class GradeOverviewPage extends ConsumerStatefulWidget {
  const GradeOverviewPage({super.key});

  @override
  ConsumerState<GradeOverviewPage> createState() => _GradeOverviewPageState();
}

class _GradeOverviewPageState extends ConsumerState<GradeOverviewPage>
    with TickerProviderStateMixin {
  List<bool> datalist = [];
  int pubulicsession = 0;
  int pravitesession = 0;
  int othersession = 0;
  late AnimationController initailanime;
  late Animation<double> initialanimation;
  PageController homopagectl = PageController();
  int basepage = 0;

  late final List<Course> listdata; // 旧 widget.listdata
  late final List<CourseDataModel> otherdata; // 旧 widget.otherdata
  late final List<GradeAverange> gradeAverages; // 旧 allgradelist[0]
  late final List<CourseTotal> courseTotals; // 旧 allgradelist[1]

  @override
  void initState() {
    super.initState();
    final academic = ref.read(academicProvider)!;
    listdata = academic.planCourses;
    otherdata = academic.grades;
    gradeAverages = academic.gradeAverages;
    courseTotals = academic.courseTotals;
    initailanime = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..addStatusListener(
        (status) {},
      );
    initialanimation =
        CurvedAnimation(parent: initailanime, curve: Curves.easeOutQuint);
    initialanimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(initialanimation);
    initailanime.forward();

    if (otherdata.length == 0) {
      basepage = 1;
      anysi2();
    } else {
      basepage = 0;
      anysi1();
    }
    homopagectl = PageController(initialPage: basepage);
  }

  void anysi2() {
    pubulicsession = 0;
    pravitesession = 0;
    othersession = 0;
    for (var item in courseTotals) {
      switch (item.courseType) {
        case "必修":
          pravitesession += 1;
          break;
        case "公选":
          pubulicsession += 1;
          break;
        default:
          othersession += 1;
      }
    }
  }

  void anysi1() {
    pubulicsession = 0;
    pravitesession = 0;
    othersession = 0;
    for (var num in listdata) {
      if (num.isPassed == "是") {
        datalist.add(true);
      } else {
        datalist.add(false);
      }
    }
    for (int a = 0; a < otherdata.length; a++) {
      if (otherdata[a].courseType == "公选") {
        pubulicsession += 1;
      } else if (otherdata[a].courseType == "必修") {
        pravitesession += 1;
      } else {
        othersession += 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final double statusBarHeight = mediaQueryData.padding.top;
    final screenWidth = mediaQueryData.size.width;
    double fontsz = screenWidth * 0.045;
    return PopScope(
        // 禁用返回按钮
        canPop: false,
        child: Scaffold(
            body: AnimatedBuilder(
                animation: initialanimation,
                builder: (context, child) {
                  return Stack(children: [
                    Column(
                      children: [
                        SizedBox(
                          height: statusBarHeight,
                        ),
                        Container(
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border.symmetric(
                                    horizontal: BorderSide(
                                        color: Colors.black, width: 0.5))),
                            height: fontsz * 5,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.2,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                          height: fontsz,
                                          child: const Center(
                                              child: Text(
                                            "门        数",
                                            style: TextStyle(
                                                color: Colors.black54),
                                          ))),
                                      SizedBox(height: fontsz - 1),
                                      SizedBox(
                                          height: fontsz,
                                          child: const Center(
                                              child: Text(
                                            "总  学  分",
                                            style: TextStyle(
                                                color: Colors.black54),
                                          ))),
                                      SizedBox(height: fontsz - 1),
                                      SizedBox(
                                          height: fontsz,
                                          child: const Center(
                                              child: Text(
                                            "平均绩点",
                                            style: TextStyle(
                                                color: Colors.black54),
                                          ))),
                                    ],
                                  ),
                                ),
                                Expanded(
                                    child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 8,
                                  itemBuilder: (context, index) {
                                    if (gradeAverages.length > index) {
                                      return Container(
                                        decoration: const BoxDecoration(
                                            border: Border(
                                                left: BorderSide(
                                                    width: 1,
                                                    color: Colors.blueAccent))),
                                        width: screenWidth * 0.1,
                                        height: fontsz * 6,
                                        child: Column(
                                          children: [
                                            SizedBox(
                                                height: fontsz,
                                                child: Center(
                                                    child: Text(
                                                        "${gradeAverages[index].number}"))),
                                            SizedBox(height: fontsz - 1),
                                            SizedBox(
                                                height: fontsz,
                                                child: Center(
                                                    child: Text(
                                                        "${gradeAverages[index].totalgrade}"))),
                                            SizedBox(height: fontsz - 1),
                                            SizedBox(
                                                height: fontsz,
                                                child: Center(
                                                    child: Text(
                                                        "${gradeAverages[index].averangegrade}"))),
                                          ],
                                        ),
                                      );
                                    } else {
                                      return Container(
                                        decoration: const BoxDecoration(
                                            border: Border(
                                                left: BorderSide(
                                                    width: 1,
                                                    color: Colors.black12))),
                                        width: screenWidth * 0.1,
                                        height: 20,
                                      );
                                    }
                                  },
                                ))
                              ],
                            )),
                        Container(
                          margin: const EdgeInsets.all(5),
                          height: fontsz * 2,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  height: fontsz * 2,
                                  width: screenWidth * 0.6,
                                  decoration: const BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          bottomLeft: Radius.circular(10))),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        color: const Color.fromARGB(
                                            255, 224, 78, 68),
                                      ),
                                      Text(
                                        "公选:$pubulicsession  ",
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        color: const Color.fromARGB(
                                            255, 222, 213, 47),
                                      ),
                                      Text(
                                        "必修:$pravitesession  ",
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        color: const Color.fromARGB(
                                            255, 68, 164, 224),
                                      ),
                                      Text(
                                        "其它:$othersession",
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ],
                                  )),
                              GestureDetector(
                                  onTap: () {
                                    basepage = basepage == 1 ? 0 : 1;
                                    homopagectl.animateToPage(basepage,
                                        duration: Durations.medium1,
                                        curve: Curves.easeInQuint);
                                    setState(() {
                                      if (basepage == 1) {
                                        anysi2();
                                      } else {
                                        anysi1();
                                      }
                                    });
                                  },
                                  child: Container(
                                    height: fontsz * 2,
                                    width: fontsz * 3,
                                    decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(10),
                                            bottomRight: Radius.circular(10)),
                                        color:
                                            Colors.black.withValues(alpha: 0.1)),
                                    child: Icon(
                                      const IconData(0xe647,
                                          fontFamily: "GradeIcon"),
                                      size: fontsz * 1.5,
                                      color: Colors.blue,
                                    ),
                                  ))
                            ],
                          ),
                        ),
                        Expanded(
                            child: PageView(
                          controller: homopagectl,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            otherdata.length == 0
                                ? Column(children: [
                                    SizedBox(
                                      height: fontsz * 3,
                                    ),
                                    SizedBox(
                                      height: screenWidth * 0.6,
                                      width: screenWidth,
                                      child:
                                          Image.asset('assets/data/icon.png'),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              255, 194, 194, 194),
                                          borderRadius: BorderRadius.circular(
                                              fontsz / 4)),
                                      child: Text(
                                        "本学期暂无考试成绩",
                                        style: TextStyle(
                                            fontSize: fontsz,
                                            color: Colors.white,
                                            height: 1),
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(children: [
                                        const TextSpan(
                                          text: "请前往",
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey),
                                        ),
                                        TextSpan(
                                          text: "\"关于\"",
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.push(context,
                                                  MaterialPageRoute(
                                                builder: (context) {
                                                  return const AboutPage();
                                                },
                                              ));
                                            },
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blueAccent),
                                        ),
                                        const TextSpan(
                                          text: "检查并开启\"在线模式\"",
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey),
                                        )
                                      ]),
                                    )
                                  ])
                                : SubjectCreditsList(
                                    courseList: otherdata,
                                    size: fontsz,
                                  ),
                            Container(
                              margin: const EdgeInsets.only(
                                  left: 20, right: 20, top: 10),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 228, 226, 226),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: fontsz * 2,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: (screenWidth - 40) * 0.1,
                                          child: const Center(
                                              child: Icon(
                                            Icons.local_offer,
                                            color: Colors.black54,
                                            size: 18,
                                          )),
                                        ),
                                        SizedBox(
                                          width: (screenWidth - 40) * 0.45,
                                          child: const Center(
                                            child: Text(
                                              "课程",
                                              style: TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: (screenWidth - 40) * 0.15,
                                          child: const Center(
                                            child: Text(
                                              "绩点",
                                              style: TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: (screenWidth - 40) * 0.15,
                                          child: const Center(
                                            child: Text(
                                              "学分",
                                              style: TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: (screenWidth - 40) * 0.15,
                                          child: const Center(
                                            child: Text("最终",
                                                style: TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                      child: MediaQuery.removePadding(
                                          context: context,
                                          removeTop: true,
                                          removeBottom: true,
                                          child: Scrollbar(
                                            child: ListView.builder(
                                              itemCount: courseTotals.length,
                                              itemBuilder: (context, index) {
                                                return SizedBox(
                                                  height: fontsz * 2,
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width:
                                                            (screenWidth - 40),
                                                        child: Row(
                                                          children: [
                                                            SizedBox(
                                                              width:
                                                                  (screenWidth -
                                                                          40) *
                                                                      0.1,
                                                              child: Center(
                                                                child:
                                                                    Container(
                                                                  width: 10,
                                                                  height: 10,
                                                                  color: courseTotals[
                                                                              index]
                                                                          .courseType ==
                                                                      "必修"
                                                                      ? const Color
                                                                          .fromARGB(
                                                                          255,
                                                                          222,
                                                                          213,
                                                                          47)
                                                                      : courseTotals[index].courseType ==
                                                                              "公选"
                                                                          ? const Color
                                                                              .fromARGB(
                                                                              255,
                                                                              224,
                                                                              78,
                                                                              68)
                                                                          : const Color
                                                                              .fromARGB(
                                                                              255,
                                                                              68,
                                                                              164,
                                                                              224),
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                width:
                                                                    (screenWidth -
                                                                            40) *
                                                                        0.45,
                                                                child: Center(
                                                                  child: Text(
                                                                    courseTotals[
                                                                            index]
                                                                        .courseName,
                                                                    maxLines: 1,
                                                                    style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w600,
                                                                        fontSize:
                                                                            14,
                                                                        color: Colors
                                                                            .black
                                                                            .withValues(
                                                                                alpha:
                                                                                    0.7),
                                                                        height:
                                                                            1.2),
                                                                  ),
                                                                )),
                                                            SizedBox(
                                                              width:
                                                                  (screenWidth -
                                                                          40) *
                                                                      0.15,
                                                              child: Center(
                                                                child: Text(
                                                                  "${courseTotals[index].gradePoint}",
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: Colors
                                                                          .black54),
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  (screenWidth -
                                                                          40) *
                                                                      0.15,
                                                              child: Center(
                                                                child: Text(
                                                                  "${courseTotals[index].credit}",
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: Colors
                                                                          .black54),
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  (screenWidth -
                                                                          40) *
                                                                      0.15,
                                                              child: Center(
                                                                child: Text(
                                                                  "${courseTotals[index].finalScore}",
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: Colors
                                                                          .black54),
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          )))
                                ],
                              ),
                            )
                          ],
                        ))
                      ],
                    ),
                  ]);
                })));
  }
}
