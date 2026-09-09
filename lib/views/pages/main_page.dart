// 来源：lib/main.dart MainPage（L1333-2624）。MVVM 迁移第二批：
// UI（课表 tab 内联布局/底部导航/PopScope/动画）逐行保留，数据访问点替换：
// 学业数据 → academicProvider；data.json → accountBookProvider；
// setting.json 外观 → settingsProvider（build 内 watch 同步，替代旧页面回传机制）；
// 当前周计算 → timetable_utils.computeCurrentWeek；每日一句 → ServerApi.getDailyWord。
// 成绩/考试/工具 tab 分别改为 GradeOverviewPage / ExamList(+AboutPage) / ToolsPage。

import 'dart:ui' as ui
    show Codec, FrameInfo, Image, ImageFilter, ImmutableBuffer, instantiateImageCodecWithSize;

import 'package:flutter/gestures.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/server_api.dart';
import '../../core/utils/timetable_utils.dart';
import '../../data/models/app_settings.dart';
import '../../viewmodels/academic_provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/settings_provider.dart';
import '../../views/widgets/calendar_grid.dart';
import '../../views/widgets/exam_list.dart';
import '../../views/widgets/shared_ui.dart';
import 'about_page.dart';
import 'appearance_page.dart';
import 'grade_overview_page.dart';
import 'login_page.dart';
import 'tools_page.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int number = 2;
  late double statusBarHeight;
  late double screenWidth;
  late double screenHeight;
  late double fontsz;
  late List schedule;
  late List examlist;
  bool blurstate = false;
  bool itemcolorstate = false;
  var imagetip = "";
  String Imagepath = "";
  bool blur = false;
  Color dateColor = const Color.fromARGB(255, 0, 0, 0);
  Color timeColor = const Color.fromARGB(255, 2, 32, 45);
  Color bgColor =
      const Color.fromARGB(255, 171, 232, 255).withValues(alpha: 0.6);
  int currentWeek = 1;
  late String teacherName;
  late final PageController _classpagecontroller;
  //late final PageController _exampagecontroller;
  DateTime currentDate = DateTime.now();
  late AnimationController _ChatLoadAnimaController;
  late Animation<double> _ChatLoadAnima;
  late List<String> date;
  late var currentclass;
  late List currentscdule;
  late String formattedDate;
  int todaytotalclass = 0;

  String dayword = "";
  void _buttonstate(int index) {
    setState(() {
      _pageController.jumpToPage(
        index,
      );
    });
  }

  @override
  void initState() {
    super.initState();

    formattedDate = DateFormat('M/d').format(currentDate);
    _ChatLoadAnimaController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _ChatLoadAnima = CurvedAnimation(
        parent: _ChatLoadAnimaController, curve: Curves.easeInOutExpo);
    _ChatLoadAnima =
        Tween<double>(begin: 0.0, end: 1.0).animate(_ChatLoadAnima);
    _ChatLoadAnimaController.forward();
    // 学业数据快照（登录或离线恢复时已写入）
    final data = ref.read(academicProvider)!;
    schedule = data.schedule;
    examlist = data.exams;
    currentWeek = computeCurrentWeek();
    teacherName = "$currentWeek";
    date = calculateDates(int.parse(teacherName));
    _classpagecontroller = PageController(initialPage: currentWeek - 1);
    ref.read(settingsProvider.notifier).load();
    final Map<String, dynamic> datalist = ref.read(accountBookProvider);
    setState(() {
      number = datalist["content"].length;
    });
    // debugPrint("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa============" +
    //     currentWeek.toString());

    //当时间间隔超过表格周数时，会出现严重的索引溢出bug,导致grade2软件崩溃
    if (currentWeek > schedule.length) {
      currentscdule = extractColumnData(
          schedule[schedule.length - 1], 7, getCurrentDayOfWeek());
    } else {
      currentscdule =
          extractColumnData(schedule[currentWeek - 1], 7, getCurrentDayOfWeek());
    }
    currentclass = currentscdule[getCurrentTimeSlot()];

    for (int x = 0; x < 8; x++) {
      if (currentscdule[x].courseName != "") {
        todaytotalclass += 1;
      }
    }

    load();
  }

  @override
  void dispose() {
    _ChatLoadAnimaController.dispose();

    super.dispose();
  }

  void load() async {
    dayword = await ServerApi.getDailyWord();
  }

  void backlogin(String account) async {
    await ref.read(accountBookProvider.notifier).selectAccount(account);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const LoginPage(intostate: true, backlogin: false);
        },
      ),
    );
  }

  void addaccount() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const LoginPage(intostate: false, backlogin: false);
        },
      ),
    );
  }

  List<IconData> listOfIcons = [
    Icons.grid_4x4,
    Icons.assessment,
    Icons.assignment,
    Icons.person_rounded,
  ];

  List<String> listOfStrings = [
    ' 课 程',
    ' 成 绩',
    ' 考 试',
    ' 其 它',
  ];
  List<String> weekday = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];

  var currentIndex = 0;
  bool classstate = false;
  @override
  Widget build(BuildContext context) {
    // 外观设置同步（旧 MyImagePicker 回传机制的替代：外观页修改后经 provider 即时生效）
    final AppSettings settings = ref.watch(settingsProvider);
    dateColor = settings.dateColor;
    timeColor = settings.timeColor;
    bgColor = settings.bgColor;
    Imagepath = settings.classImage;
    itemcolorstate = settings.itemColorState;
    blur = settings.blur;
    final mediaQueryData = MediaQuery.of(context);
    statusBarHeight = mediaQueryData.padding.top;
    screenWidth = mediaQueryData.size.width;
    screenHeight = mediaQueryData.size.height;
    fontsz = screenWidth * 0.045;
    double displayWidth = MediaQuery.of(context).size.width;
    return PopScope(
        // 禁用返回按钮
        canPop: false,
        child: Scaffold(
            bottomNavigationBar: Container(
              margin: EdgeInsets.all(displayWidth * .05),
              height: displayWidth * .155,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
                borderRadius: BorderRadius.circular(50),
              ),
              child: ListView.builder(
                itemCount: 4,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: displayWidth * .02),
                itemBuilder: (context, index) => InkWell(
                  onTap: () {
                    setState(() {
                      currentIndex = index;
                      _buttonstate(index);
                      HapticFeedback.lightImpact();
                    });
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        curve: Curves.fastLinearToSlowEaseIn,
                        width: index == currentIndex
                            ? displayWidth * .32
                            : displayWidth * .18,
                        alignment: Alignment.center,
                        child: AnimatedContainer(
                          duration: const Duration(seconds: 1),
                          curve: Curves.fastLinearToSlowEaseIn,
                          height:
                              index == currentIndex ? displayWidth * .12 : 0,
                          width: index == currentIndex ? displayWidth * .32 : 0,
                          decoration: BoxDecoration(
                            color: index == currentIndex
                                ? Colors.blueAccent.withValues(alpha: .2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        curve: Curves.fastLinearToSlowEaseIn,
                        width: index == currentIndex
                            ? displayWidth * .31
                            : displayWidth * .18,
                        alignment: Alignment.center,
                        child: Stack(
                          children: [
                            Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(seconds: 1),
                                  curve: Curves.fastLinearToSlowEaseIn,
                                  width: index == currentIndex
                                      ? displayWidth * .13
                                      : 0,
                                ),
                                AnimatedOpacity(
                                  opacity: index == currentIndex ? 1 : 0,
                                  duration: const Duration(seconds: 1),
                                  curve: Curves.fastLinearToSlowEaseIn,
                                  child: Text(
                                    index == currentIndex
                                        ? listOfStrings[index]
                                        : '',
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(seconds: 1),
                                  curve: Curves.fastLinearToSlowEaseIn,
                                  width: index == currentIndex
                                      ? displayWidth * .03
                                      : 20,
                                ),
                                Icon(
                                  listOfIcons[index],
                                  size: displayWidth * .076,
                                  color: index == currentIndex
                                      ? Colors.blueAccent
                                      : Colors.black26,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: Stack(children: [
              PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {});
                },
                children: [
                  classPage(),
                  const GradeOverviewPage(),
                  ExamPage(),
                  const ToolsPage()
                ],
              ),
            ])));
  }

  void classchange(String name) {
    setState(() {
      teacherName = name;
    });
  }

  bool deleteAsk = false;
  String currentdelete = "";

  Widget classPage() {
    final Map<String, dynamic> userlist = ref.watch(accountBookProvider);
    // double currentDayPercentage = getCurrentDayPercentage();
    // if (currentDayPercentage > (8 / 24)) {
    //   currentDayPercentage -= (8 / 24);
    // }
    double w5 = getCurrentTimeInFloat();
    double w8 = getDailyTimeProgress();
    return Scaffold(
        body: Container(
      decoration: const BoxDecoration(),
      child: Column(
        children: [
          Container(
            width: screenWidth,
            height: statusBarHeight,
            color: bgColor,
          ),
          Stack(
            children: [
              Row(
                children: [
                  Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.only(
                              //topRight: Radius.circular(fontsz),
                              bottomRight: Radius.circular(fontsz * 2))),
                      width: screenWidth * 0.7,
                      height: screenHeight * 0.83,
                      child: Stack(
                        children: [
                          RandomGeometricShapes(
                              width: screenWidth * 0.7,
                              height: screenHeight * 0.83,
                              shapeCount: 10),
                          Container(
                              clipBehavior: Clip.hardEdge,
                              height: screenHeight,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(fontsz),
                                topRight: Radius.circular(fontsz),
                              )),
                              child: Imagepath != ""
                                  ? _BackgroundImage(path: Imagepath)
                                  : const SizedBox()),
                          Center(
                              child: blur
                                  ?
                                  // decoration: BoxDecoration(
                                  //     borderRadius: BorderRadius.circular(fontsz)),
                                  ClipRRect(
                                      borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(fontsz),
                                          topLeft: Radius.circular(fontsz)),
                                      //使图片模糊区域仅在子组件区域中
                                      child: BackdropFilter(
                                        //背景过滤器
                                        filter: ui.ImageFilter.blur(
                                            sigmaX: 25.0,
                                            sigmaY: 25.0), //设置图片模糊度
                                        child: Container(
                                          height: screenHeight,
                                          width: screenWidth,
                                          color: Colors.grey.shade200
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    )
                                  : Container()),
                          Column(
                            children: [
                              SizedBox(
                                width: screenWidth * 0.7,
                                height: screenHeight * 0.05,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: classstate ? 7 : 5,
                                  itemBuilder: (context, index) {
                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 1000),
                                      decoration: formattedDate == date[index]
                                          ? BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              boxShadow: const [
                                                  BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: 3)
                                                ])
                                          : const BoxDecoration(),
                                      width: screenWidth *
                                          0.7 /
                                          (classstate ? 7 : 5),
                                      child: Column(children: [
                                        Text(
                                          weekday[index],
                                          style: TextStyle(
                                              color:
                                                  formattedDate == date[index]
                                                      ? Colors.blue
                                                      : dateColor,
                                              fontSize: fontsz * 0.9,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          date[index],
                                          style: TextStyle(
                                              color: dateColor,
                                              fontSize: fontsz * 0.65,
                                              fontWeight: FontWeight.normal),
                                        )
                                      ]),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                width: screenWidth * 0.7,
                                height: screenHeight * 0.7,
                                child: AnimatedBuilder(
                                  animation: _ChatLoadAnima,
                                  builder: (context, child) {
                                    return Transform.translate(
                                        offset: Offset(
                                            0, 50 - 50 * _ChatLoadAnima.value),
                                        child: Opacity(
                                            opacity:
                                                0.6 * _ChatLoadAnima.value +
                                                    0.4,
                                            child: PageView.builder(
                                              controller: _classpagecontroller,
                                              onPageChanged: (index) => {
                                                setState(() {
                                                  teacherName = "${index + 1}";
                                                  date = calculateDates(
                                                      int.parse(teacherName));
                                                })
                                              },
                                              itemCount:
                                                  schedule.length, // 你的页面数量
                                              itemBuilder: (context, index) {
                                                return Container(
                                                    clipBehavior: Clip.hardEdge,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: CalendarPage(
                                                      colorstate:
                                                          itemcolorstate,
                                                      dat: schedule[index],
                                                      iteh: screenHeight * 0.7,
                                                      showstate: classstate,
                                                    ));
                                                // 创建日历页面
                                              },
                                            )));
                                  },
                                ),
                              ),
                              AnimatedBuilder(
                                  //公告栏
                                  animation: _ChatLoadAnima,
                                  builder: (context, child) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Transform.translate(
                                            offset: Offset(
                                                -100 +
                                                    100 * _ChatLoadAnima.value,
                                                0),
                                            child: Opacity(
                                                opacity: 1,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(3),
                                                  //margin: EdgeInsets.only(top: 0),
                                                  width: screenWidth / 1.9,
                                                  // height: fontsz * 2,
                                                  decoration: const BoxDecoration(
                                                      boxShadow: [
                                                        BoxShadow(
                                                            color:
                                                                Colors.black12,
                                                            blurRadius: 10)
                                                      ],
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                              topRight: Radius
                                                                  .circular(7),
                                                              bottomRight:
                                                                  Radius
                                                                      .circular(
                                                                          7))),
                                                  child: Center(
                                                    child: Text(
                                                      dayword,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          height: 1.1,
                                                          color: dateColor),
                                                    ),
                                                  ),
                                                ))),
                                        const Expanded(child: SizedBox()),
                                        Transform.scale(
                                            scale: _ChatLoadAnima.value,
                                            child: GestureDetector(
                                              child: Container(
                                                  margin: EdgeInsets.only(
                                                      right: fontsz / 2),
                                                  height: fontsz * 3,
                                                  width: fontsz * 3,
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.settings,
                                                      size: fontsz * 2,
                                                      color: Colors.white,
                                                      shadows: const [
                                                        BoxShadow(
                                                            color:
                                                                Colors.black12,
                                                            blurRadius: 10)
                                                      ],
                                                    ),
                                                  )),
                                              onTap: () async {
                                                await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                  builder: (context) {
                                                    return const AppearancePage();
                                                  },
                                                ));
                                              },
                                            ))
                                      ],
                                    );
                                  })
                            ],
                          )
                        ],
                      )),
                  SizedBox(
                      height: screenHeight * 0.83,
                      width: fontsz,
                      //color: Colors.blue,
                      child: Column(
                        children: [
                          //Text("$"),
                          Container(
                            width: fontsz,
                            //width: screenWidth * 0.7,
                            height: screenHeight * 0.05,
                            decoration: BoxDecoration(color: bgColor),
                            child: Container(
                              width: fontsz,
                              //width: screenWidth * 0.7,
                              height: screenHeight * 0.05,
                              decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 255, 251, 254),
                                  border:
                                      Border.all(width: 0, color: Colors.white),
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(fontsz))),
                            ),
                          ),
                          SizedBox(
                              width: fontsz,
                              //width: screenWidth * 0.7,
                              height: screenHeight * 0.7,
                              child: Stack(children: [
                                Center(
                                  child: RotatedBox(
                                    quarterTurns: 1, // 将进度条旋转90度，使其变为垂直方向
                                    child: Container(
                                      clipBehavior: Clip.hardEdge,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(fontsz)),
                                      child: LinearProgressIndicator(
                                        value: classstate
                                            ? w8
                                            : w5, // 设置进度条的值，范围为0.0到1.0
                                        minHeight: fontsz * 0.3, // 设置进度条的最小高度
                                        backgroundColor:
                                            Colors.grey[300], // 设置进度条的背景颜色
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                timeColor.withValues(
                                                    alpha: 0.5)), // 设置进度条的前景颜色
                                      ),
                                    ),
                                  ),
                                ),
                                MediaQuery.removePadding(
                                    context: context,
                                    removeTop: true,
                                    child: ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: classstate ? 8 : 5,
                                      itemBuilder: (context, index) {
                                        return AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          decoration: BoxDecoration(
                                              border: Border(
                                                  top: index != 0
                                                      ? BorderSide(
                                                          width: 2,
                                                          color: timeColor)
                                                      : BorderSide(
                                                          width: 0,
                                                          color: Colors.black
                                                              .withValues(
                                                                  alpha: 0)))),
                                          width: fontsz,
                                          margin: EdgeInsets.only(
                                              right: fontsz * 0.35),
                                          height: screenHeight *
                                              0.7 /
                                              (classstate ? 8 : 5),
                                          //color: Colors.white,
                                        );
                                      },
                                    ))
                              ]))
                        ],
                      )),
                  const Expanded(child: SizedBox()),
                  AnimatedBuilder(
                    animation: _ChatLoadAnima,
                    builder: (context, child) {
                      return Transform.translate(
                          offset: Offset(80 - 80 * _ChatLoadAnima.value, 0),
                          child: Opacity(
                              opacity: 0.6 * _ChatLoadAnima.value + 0.4,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      //margin: EdgeInsets.only(top: fontsz),
                                      width: screenWidth / 4,
                                      decoration: BoxDecoration(
                                          color: bgColor,
                                          // gradient: const LinearGradient(colors: [
                                          //   Colors.blue,
                                          //   Color.fromARGB(255, 114, 167, 233)
                                          // ], begin: Alignment.bottomCenter),
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(fontsz),
                                              bottomLeft:
                                                  Radius.circular(fontsz / 3))),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "week",
                                            style: TextStyle(
                                              fontSize: fontsz,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            teacherName,
                                            style: TextStyle(
                                                fontSize: fontsz * 3.5,
                                                color: Colors.white,
                                                shadows: const [
                                                  BoxShadow(
                                                      color: Colors.black26,
                                                      blurRadius: 25,
                                                      offset: Offset(0, 10))
                                                ],
                                                fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                        width: screenWidth / 4,
                                        height: screenHeight / 4.4,
                                        margin:
                                            EdgeInsets.only(top: fontsz / 4),
                                        decoration: BoxDecoration(
                                            color: bgColor,
                                            // gradient: const LinearGradient(colors: [
                                            //   Colors.blue,
                                            //   Color.fromARGB(255, 114, 167, 233)
                                            // ], begin: Alignment.bottomCenter),
                                            borderRadius: BorderRadius.only(
                                                topLeft:
                                                    Radius.circular(fontsz / 3),
                                                bottomLeft:
                                                    Radius.circular(fontsz))),
                                        child: Column(
                                          children: [
                                            Text(
                                              "今日课程",
                                              style: TextStyle(
                                                  fontSize: fontsz * 0.8,
                                                  height: 1.5,
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.normal),
                                            ),
                                            SizedBox(
                                              width: screenWidth / 4,
                                              height: screenHeight / 6,
                                              child: MediaQuery.removePadding(
                                                  context: context,
                                                  removeTop: true,
                                                  child: ListView.builder(
                                                    itemCount: 8,
                                                    itemBuilder:
                                                        (context, index) {
                                                      if (currentscdule[index]
                                                              .courseName ==
                                                          "") {
                                                        return Container(
                                                          height: 2,
                                                          color: Colors.black,
                                                          margin:
                                                              EdgeInsets.only(
                                                                  top: 2,
                                                                  bottom: 2,
                                                                  left: fontsz,
                                                                  right:
                                                                      fontsz),
                                                        );
                                                      } else {
                                                        return Container(
                                                            margin:
                                                                const EdgeInsets
                                                                    .all(2),
                                                            // decoration: BoxDecoration(
                                                            //     color: Colors.white,
                                                            //     borderRadius:
                                                            //         BorderRadius.circular(
                                                            //             fontsz / 4)),
                                                            child: Column(
                                                              children: [
                                                                Text(
                                                                  currentscdule[
                                                                          index]
                                                                      .courseName,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis, // 超出一行时使用省略号表示
                                                                  maxLines: 1,
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          fontsz *
                                                                              0.8,
                                                                      color: Colors
                                                                          .black54,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                )
                                                              ],
                                                            ));
                                                      }
                                                    },
                                                  )),
                                            ),
                                            Text("共$todaytotalclass节",
                                                style: TextStyle(
                                                    fontSize: fontsz * 0.9,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.normal))
                                          ],
                                        )),
                                    // SizedBox(
                                    //   height: screenHeight * 0.1,
                                    // ),
                                    Container(
                                        width: screenWidth / 4,
                                        height: screenHeight / 4.5,
                                        margin: EdgeInsets.only(
                                            top: fontsz, bottom: fontsz * 2),
                                        // decoration: BoxDecoration(
                                        //     gradient: const LinearGradient(colors: [
                                        //       Colors.blue,
                                        //       Color.fromARGB(255, 114, 167, 233)
                                        //     ], begin: Alignment.bottomCenter),
                                        //     borderRadius: BorderRadius.only(
                                        //         topLeft: Radius.circular(fontsz),
                                        //         bottomLeft: Radius.circular(fontsz))),
                                        child: Stack(
                                          children: [
                                            const Center(
                                              child: Text(
                                                "↑账号列表\n点击切换\n长按删除\n添加账号↓",
                                                style: TextStyle(
                                                    color: Colors.black45),
                                              ),
                                            ),
                                            MediaQuery.removePadding(
                                              context: context,
                                              removeTop: true,
                                              child: ListView.builder(
                                                //scrollDirection: Axis.horizontal, // 设置横向滚动
                                                itemCount:
                                                    userlist["content"].length,
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  return GestureDetector(
                                                    onLongPress: () {
                                                      //删除账号
                                                      setState(() {
                                                        HapticFeedback
                                                            .lightImpact();
                                                        deleteAsk = true;
                                                        currentdelete =
                                                            userlist["content"]
                                                                        .keys
                                                                        .toList()[
                                                                    index];
                                                      });
                                                    },
                                                    onTap: () => backlogin(
                                                        userlist["content"]
                                                            .keys
                                                            .toList()[index]),
                                                    child: Container(
                                                      margin: EdgeInsets.only(
                                                          bottom: fontsz / 4),
                                                      //width: fontsz,
                                                      // padding: EdgeInsets.all(fontsz * 0.1),
                                                      decoration: BoxDecoration(
                                                          boxShadow: [
                                                            BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withValues(
                                                                        alpha:
                                                                            0.1),
                                                                blurRadius:
                                                                    fontsz / 2),
                                                          ],
                                                          color: deleteAsk
                                                              ? userlist["content"].keys
                                                                              .toList()[
                                                                          index] ==
                                                                      currentdelete
                                                                  ? Colors.red
                                                                  : Colors.white
                                                              : Colors.white,
                                                          borderRadius: BorderRadius.only(
                                                              topLeft: Radius
                                                                  .circular(
                                                                      fontsz /
                                                                          4),
                                                              bottomLeft: Radius
                                                                  .circular(
                                                                      fontsz /
                                                                          4))),
                                                      // width: 45,
                                                      //margin: const EdgeInsets.only(top: 5),
                                                      child: Text(
                                                        '${userlist["content"].keys.toList()[index]}',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          //fontFamily: "Roboto",
                                                          color: Colors.blue,
                                                          fontSize:
                                                              fontsz * 0.9,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          ],
                                        )),
                                    Column(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            _classpagecontroller.jumpToPage(
                                              currentWeek - 1,
                                            );
                                          },
                                          child: Container(
                                            width: screenWidth / 4,
                                            padding: EdgeInsets.only(
                                                left: fontsz / 2),
                                            // margin: EdgeInsets.only(
                                            //   top: fontsz / 3,
                                            //   //left: fontsz / 3,
                                            // ),
                                            decoration: BoxDecoration(
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: fontsz / 2)
                                                ],
                                                borderRadius:
                                                    const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(15),
                                                        bottomLeft:
                                                            Radius.circular(
                                                                10)),
                                                color: Colors.white),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.adjust,
                                                  color: Colors.blue,
                                                ),
                                                Column(
                                                  children: [
                                                    Text(
                                                      "复  位",
                                                      style: TextStyle(
                                                          fontSize:
                                                              fontsz * 0.8,
                                                          color: Colors.blue),
                                                    ),
                                                    Text(
                                                      "定位课表到今天",
                                                      style: TextStyle(
                                                          fontSize:
                                                              fontsz / 2.2,
                                                          color: Colors.black
                                                              .withValues(
                                                                  alpha: 0.5)),
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(context,
                                                MaterialPageRoute(
                                              builder: (context) {
                                                return const AboutPage();
                                              },
                                            ));
                                          },
                                          child: Container(
                                            width: screenWidth / 4,
                                            padding: EdgeInsets.only(
                                                left: fontsz / 2),
                                            margin: EdgeInsets.only(
                                              top: fontsz / 4,
                                              //left: fontsz / 3,
                                            ),
                                            decoration: BoxDecoration(
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: fontsz / 2)
                                                ],
                                                borderRadius:
                                                    const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(10),
                                                        bottomLeft:
                                                            Radius.circular(
                                                                10)),
                                                color: Colors.white),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.layers,
                                                  color: Colors.blue,
                                                ),
                                                Column(
                                                  children: [
                                                    Text(
                                                      "关  于",
                                                      style: TextStyle(
                                                          fontSize:
                                                              fontsz * 0.8,
                                                          color: Colors.blue),
                                                    ),
                                                    Text(
                                                      "    建议与更新    ",
                                                      style: TextStyle(
                                                          fontSize:
                                                              fontsz / 2.2,
                                                          color: Colors.black
                                                              .withValues(
                                                                  alpha: 0.5)),
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              classstate = !classstate;
                                            });
                                          },
                                          child: Container(
                                            width: screenWidth / 4,
                                            padding: EdgeInsets.only(
                                                left: fontsz / 2),
                                            margin: EdgeInsets.only(
                                              top: fontsz / 4,
                                              //left: fontsz / 3,
                                            ),
                                            decoration: BoxDecoration(
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: fontsz / 2)
                                                ],
                                                borderRadius:
                                                    const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(10),
                                                        bottomLeft:
                                                            Radius.circular(
                                                                15)),
                                                color: Colors.white),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.apps,
                                                  color: Colors.blue,
                                                ),
                                                Column(
                                                  children: [
                                                    Text(
                                                      "模  式",
                                                      style: TextStyle(
                                                          fontSize:
                                                              fontsz * 0.8,
                                                          color: Colors.blue),
                                                    ),
                                                    Text(
                                                      "显示周末或关闭",
                                                      style: TextStyle(
                                                          fontSize:
                                                              fontsz / 2.2,
                                                          color: Colors.black
                                                              .withValues(
                                                                  alpha: 0.5)),
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  ])));
                    },
                  ),
                ],
              ),
              Positioned(
                  child: Align(
                alignment: Alignment.bottomRight,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuint,
                  margin: EdgeInsets.only(top: screenHeight * 0.59),
                  width: deleteAsk ? screenWidth * 0.5 : screenWidth * 0.15,
                  height: deleteAsk ? fontsz * 3 : fontsz * 2.8,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(fontsz),
                          bottomLeft: Radius.circular(fontsz)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: fontsz),
                      ]),
                  child: deleteAsk
                      ? Row(
                          children: [
                            Text(
                              "   确定删除？  ",
                              style: TextStyle(fontSize: fontsz),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  deleteAsk = false;
                                  currentdelete == "";
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(
                              width: fontsz,
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  deleteAsk = false;

                                  ref
                                      .read(accountBookProvider.notifier)
                                      .removeAccount(currentdelete);
                                });
                              },
                              child: const Icon(
                                Icons.check,
                                color: Colors.blue,
                              ),
                            )
                          ],
                        )
                      : IconButton(
                          onPressed: addaccount,
                          icon: const Icon(Icons.add),
                          color: Colors.blue,
                          iconSize: fontsz * 2,
                        ),
                ),
              ))
            ],
          )
        ],
      ),
    ));
  }

  Widget ExamPage() {
    return Scaffold(
        body: Container(
            decoration: const BoxDecoration(
                // gradient: RadialGradient(
                //   center: Alignment.center,
                //   radius: 1.2,
                //   colors: [bgColor, const Color.fromARGB(255, 0, 0, 0)],
                // ),
                ),
            child: examlist.length == 0
                ? Column(
                    children: [
                      SizedBox(
                        height: fontsz * 10,
                      ),
                      SizedBox(
                        height: screenWidth * 0.6,
                        width: screenWidth,
                        child: Image.asset('assets/data/icon.png'),
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 194, 194, 194),
                            borderRadius: BorderRadius.circular(fontsz / 4)),
                        child: Text(
                          "本学期暂无考试安排",
                          style: TextStyle(
                              fontSize: fontsz, color: Colors.white, height: 1),
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
                                Navigator.push(context, MaterialPageRoute(
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
                    ],
                  )
                : ExamList(
                    examlist: examlist,
                    onOpenAbout: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AboutPage())),
                  )

            // Positioned(
            //     child: Align(
            //         alignment: Alignment.topCenter,
            //         child: Container(
            //           width: screenWidth / 2,
            //           height: screenHeight / 20,
            //           margin: EdgeInsets.only(top: statusBarHeight * 3),
            //           color: Colors.white,
            //         )))
            ));
  }
}

/// 旧代码 `Image.file(File(path))` 的等价渲染（仅用 dart:ui 解码本地图片，
/// 页面保持不引入 dart:io）。显示效果与 Image.file(fit: BoxFit.cover) 一致。
class _BackgroundImage extends StatefulWidget {
  final String path;
  const _BackgroundImage({required this.path});
  @override
  State<_BackgroundImage> createState() => _BackgroundImageState();
}

class _BackgroundImageState extends State<_BackgroundImage> {
  late final Future<ui.Image> _image = _decode(widget.path);

  static Future<ui.Image> _decode(String path) async {
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromFilePath(path);
    final ui.Codec codec = await ui.instantiateImageCodecWithSize(buffer);
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _image,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }
        return RawImage(image: snapshot.data, fit: BoxFit.cover);
      },
    );
  }
}
