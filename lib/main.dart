// ignore_for_file: non_constant_identifier_names, library_private_types_in_public_api, must_be_immutable, use_build_context_synchronously, prefer_typing_uninitialized_variables, camel_case_types

//import "package:html/parser.dart";

//import "package:flutter/services.dart";
import 'dart:ffi';

import 'package:dio/dio.dart';
import "package:flutter/services.dart";
import 'package:path_provider/path_provider.dart';
import "package:roundcheckbox/roundcheckbox.dart";
import "package:flutter/material.dart";
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import "dart:io";
import 'package:install_plugin/install_plugin.dart';

import "login.dart";
import "topbar.dart";
import 'function.dart';
// import 'Adapt.dart';
// import 'dart:math';

void main() async {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Grade",
      theme: ThemeData(
        platform: TargetPlatform.android, // 或 TargetPlatform.android
      ),
      home: LoginPage(CounterStorage(), true),
    );
  }
}

class LoginPage extends StatefulWidget {
  final CounterStorage ctrlFile;
  bool intostate;
  LoginPage(this.ctrlFile, this.intostate, {super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  String tip = "使用长江大学账号"; // 初始文本
  bool state = false;
  bool autoLogin = false;
  bool rememberPassword = false;
  bool _isObscure = true;
  var session;
  String contxt = "page source";
  //String vser = "";
  final TextEditingController _numController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  bool loginState = false;
  Map initdata = {"initial": "", "content": {}, "goal": ""};
  bool datedisplay = false;
  late int startyear;
  late String enterkey;
  bool bukao = false;
  String tell = "Hi";
  // Adapt adapt = Adapt();

  late AnimationController initailanime;
  late Animation<double> initialanimation;
  @override
  void initState() {
    super.initState();

    initailanime = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1700))
      ..addStatusListener(
        (status) {},
      );
    initialanimation =
        CurvedAnimation(parent: initailanime, curve: Curves.easeOutBack);
    initialanimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(initialanimation);
    initailanime.forward();

    setState(() {
      gettext().then((value) {
        tell = value;
      });
    });

    widget.ctrlFile.readCounter().then((value) {
      if (value.isEmpty) {
        widget.ctrlFile.writeCounter(initdata);
      } else {
        initdata = value;
        if (widget.intostate) {
          _numController.text = initdata["initial"];
          datedisplay = true;
          startyear = int.parse(initdata["initial"].substring(0, 4));

          _pwdController.text = initdata["content"][initdata["initial"]][0];
          rememberPassword = true;
          autoLogin = initdata["content"][initdata["initial"]][1] == "true"
              ? true
              : false;
          enterkey = initdata["content"][initdata["initial"]][2];
          bukao = initdata["content"][initdata["initial"]][3] == "true"
              ? true
              : false;
        }
        if (autoLogin) {
          Loginact();
        }
      }
      setState(() {});
    });
  }

  void disposed() {
    initailanime.dispose();
    super.dispose();
  }

//重置年份选择器
  void _editingyear() {
    setState(() {
      datedisplay = false;
    });
  }

  void _handleInputFinished() {
    if (_numController.text != "" && isLongNumber(_numController.text)) {
      int year = int.parse(_numController.text.substring(0, 4));
      setState(() {
        if (isYearFormat(year)) {
          datedisplay = true;
          startyear = year;
        }
      });
    }
  }

  String getCurrentTime() {
    DateTime now = DateTime.now();
    String formattedTime = DateFormat('HH:mm:ss').format(now);
    return formattedTime;
  }

  Future<void> Loginact() async {
    String account = _numController.text;
    String password = _pwdController.text;
    if (account != "" && password != "") {
      Requests iTing = Requests();
      setState(() {
        tip = "正在尝试登陆";
        state = true;
      });
      while (true) {
        List netdata = await iTing.Login(account, password);
        if (netdata[1] == 302) {
          widget.ctrlFile.readCounter().then((value) {
            enterkey = value["goal"];
          });
          List maintable = await iTing.GetData(netdata[0]);
          var gradetable = await iTing.Getgrade(netdata[0], enterkey);
          var schedule = await iTing.GetSchedule(netdata[0], enterkey);
          var examlist = await iTing.GetExam(netdata[0], bukao);
          if (rememberPassword) {
            initdata["initial"] = account;
            initdata["goal"] = enterkey;
            initdata["content"][account] = [
              password,
              autoLogin.toString(),
              enterkey,
              bukao.toString()
            ];
            //initdata["goal"] = initdata["content"].length.toString();

            widget.ctrlFile.writeCounter(initdata);
          }
          try {
            SenMail(maintable[0][0].name, maintable[0][0].department,
                "登录时间${getCurrentTime()}", false);
          } catch (e) {
            Null;
          }

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return MainPage(maintable[0], maintable[1], gradetable,
                    schedule, initdata, examlist);
              },
            ),
          );

          break;
        } else if (netdata[1] == 400) {
          _pwdController.clear();
          setState(() {
            tip = "账号或密码错误";
            state = false;
          });
          break;
        }
      }
    } else {
      setState(() {
        tip = "账号或密码为空";
      });
    }
  }

  void chioselogin(index) {
    setState(() {
      _numController.text = index;
      _pwdController.text = initdata["content"][index][0];
      datedisplay = true;
      startyear = int.parse(index.substring(0, 4));
      enterkey = initdata["content"][index][2];
      rememberPassword = true;
      autoLogin = initdata["content"][index][1] == "true" ? true : false;
      bukao = initdata["content"][index][3] == "true" ? true : false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final double statusBarHeight = mediaQueryData.padding.top;
    final screenWidth = mediaQueryData.size.width;
    final screenHeight = mediaQueryData.size.height;
    double fontsz = screenWidth * 0.045;
    return Scaffold(
        body: Stack(
      children: [
        Positioned(
            //top: screenWidth,
            child: FractionallySizedBox(
                widthFactor: 2, // 宽度因子大于1，超出屏幕宽度

                //heightFactor: 1,
                child: AnimatedBuilder(
                    animation: initialanimation,
                    builder: (context, child) {
                      return Container(
                        color: const Color.fromARGB(255, 204, 220, 221),
                        child: Column(
                          //mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: screenHeight * 0.35,
                            ),
                            CircularProgressBar(
                              progress: 1.0,
                              radius: screenWidth,
                              startAngle: 90 - 25 * initialanimation.value,
                              endAngle: 90 + 25 * initialanimation.value,
                              strokeWidth: fontsz,
                              // beginCapRadius: fontsz,
                              // endCapRadius: fontsz,
                            )
                          ],
                        ),
                      );
                    }))),
        SingleChildScrollView(
            child: SizedBox(
                height: screenHeight,
                // decoration: const BoxDecoration(
                //     // shape: BoxShape.circle,
                //     color: Color.fromARGB(255, 224, 233, 235)),
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      Container(
                        height: statusBarHeight * 3,
                        //color: Colors.white,
                      ),

                      // const Text(
                      //   "长江大学计算机协会",
                      //   style: TextStyle(color: Colors.white),
                      // ),
                      Container(
                        margin: EdgeInsets.all(fontsz),
                        width: screenWidth * 0.8,
                        height: screenHeight * 0.055,
                        decoration: const BoxDecoration(
                          //color: Color.fromARGB(0, 198, 198, 198),
                          border: Border(
                              top: BorderSide(width: 2, color: Colors.white)),
                          // boxShadow: const [
                          //   BoxShadow(
                          //     color: Color.fromARGB(92, 105, 105, 105),
                          //     offset: Offset(0, 5),
                          //     blurRadius: 20.0,
                          //   )
                          // ],
                          // borderRadius:
                          //     const BorderRadius.all(Radius.circular(10))
                        ),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal, // 设置横向滚动
                          itemCount: initdata["content"].length,
                          itemBuilder: (BuildContext context, int index) {
                            return GestureDetector(
                                onTap: () => chioselogin(
                                    initdata["content"].keys.toList()[index]),
                                child: Container(
                                  padding: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 244, 255, 235),
                                      // border: Border.all(
                                      //     width: 1, color: Colors.white),
                                      borderRadius: BorderRadius.circular(5)),
                                  width: screenWidth * 0.3,
                                  margin: const EdgeInsets.only(
                                      left: 5, top: 5, bottom: 5),
                                  child: Center(
                                    child: Text(
                                      '${initdata["content"].keys.toList()[index]}',
                                      style: TextStyle(
                                          color: const Color.fromARGB(
                                              255, 51, 51, 51),
                                          fontWeight: FontWeight.w400,
                                          fontSize: fontsz),
                                    ),
                                  ),
                                ));
                          },
                        ),
                      ),
                      Container(
                          margin: EdgeInsets.all(fontsz),
                          padding: EdgeInsets.all(fontsz),
                          width: screenWidth * 0.85,
                          height: screenHeight * 0.4,
                          decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 252, 252, 252),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(35))),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      tip,
                                      style: TextStyle(
                                        fontSize: fontsz * 1.5,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: SizedBox()),
                                  // Container(
                                  //   width: screenWidth / 5,
                                  //   height: screenHeight / 18,
                                  //   clipBehavior: Clip.hardEdge,
                                  //   decoration: BoxDecoration(
                                  //       borderRadius:
                                  //           BorderRadius.circular(30)),
                                  //   child: const Image(
                                  //     fit: BoxFit.fitHeight,
                                  //     image: NetworkImage(
                                  //         "https://assets.msn.cn/weathermapdata/1/static/background/v2.0/jpg/partlysunny_day.jpg"),
                                  //   ),
                                  // )
                                ],
                              ),
                              SizedBox(
                                height: fontsz,
                              ),
                              TextField(
                                keyboardType: TextInputType.number,
                                controller: _numController,
                                onEditingComplete: _handleInputFinished,
                                onTap: _editingyear,
                                style: TextStyle(
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                    fontSize: fontsz + 3), // 文本颜色为白色
                                decoration: InputDecoration(
                                  label: Text(
                                    "学号",
                                    style: TextStyle(fontSize: fontsz),
                                  ),
                                  contentPadding: EdgeInsets.all(fontsz / 2),
                                  filled: true,
                                  // fillColor:
                                  //     Color.fromARGB(91, 155, 39, 176), // 背景颜色
                                  hintText: 'Enter account', // 提示文本
                                  hintStyle: const TextStyle(
                                      color: Colors.white), // 提示文本颜色
                                  border: OutlineInputBorder(
                                    // borderSide:
                                    //     const BorderSide(width: 2), // 边框颜色和宽度
                                    borderRadius:
                                        BorderRadius.circular(10.0), // 边框圆角
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: fontsz,
                              ),
                              TextField(
                                obscureText: _isObscure,
                                controller: _pwdController,
                                onTap: _handleInputFinished,
                                style: TextStyle(
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                    fontSize: fontsz + 3), // 文本颜色为白色
                                decoration: InputDecoration(
                                    label: Text(
                                      "密码",
                                      style: TextStyle(fontSize: fontsz),
                                    ),
                                    contentPadding: EdgeInsets.all(fontsz / 2),
                                    filled: true,
                                    // fillColor: const Color.fromARGB(
                                    //     95, 129, 129, 129), // 背景颜色

                                    hintText: 'Enter password', // 提示文本
                                    hintStyle: const TextStyle(
                                        color: Color.fromARGB(
                                            255, 87, 87, 87)), // 提示文本颜色
                                    border: OutlineInputBorder(
                                      // borderSide: const BorderSide(
                                      //     color: Colors.white,
                                      //     width: 3.0), // 边框颜色和宽度
                                      borderRadius:
                                          BorderRadius.circular(10.0), // 边框圆角
                                    ),
                                    suffixIcon: IconButton(
                                        icon: Icon(_isObscure
                                            ? Icons.visibility_off
                                            : Icons.visibility),
                                        onPressed: () {
                                          setState(() {
                                            _isObscure = !_isObscure;
                                          });
                                        })),
                              ),
                              SizedBox(
                                height: screenHeight * 0.03,
                              ),
                              Row(
                                children: [
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          RoundCheckBox(
                                              size: fontsz * 1.5,
                                              checkedWidget: Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: fontsz,
                                              ),
                                              checkedColor: Colors.purple,
                                              uncheckedColor:
                                                  const Color.fromARGB(
                                                      0, 155, 39, 176),
                                              border: Border.all(
                                                  color: const Color.fromARGB(
                                                      255, 0, 0, 0),
                                                  width: 1),
                                              isChecked: autoLogin,
                                              onTap: (selected) {
                                                autoLogin = !autoLogin;

                                                setState(() {});
                                              }),
                                          SizedBox(
                                            width: fontsz / 2,
                                          ),
                                          Text(
                                            "自动登录",
                                            style: TextStyle(
                                                fontSize: fontsz * 0.9,
                                                color: autoLogin
                                                    ? Colors.purple
                                                    : const Color.fromARGB(
                                                        120, 155, 39, 176)),
                                          )
                                        ],
                                      ),
                                      SizedBox(
                                        height: fontsz / 3,
                                      ),
                                      Row(
                                        children: [
                                          RoundCheckBox(
                                              size: fontsz * 1.5,
                                              checkedWidget: Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: fontsz,
                                              ),
                                              checkedColor: Colors.purple,
                                              uncheckedColor:
                                                  const Color.fromARGB(
                                                      255, 255, 255, 255),
                                              border: Border.all(
                                                  color: const Color.fromARGB(
                                                      255, 24, 24, 24),
                                                  width: 1),
                                              isChecked: rememberPassword,
                                              onTap: (selected) {
                                                rememberPassword =
                                                    !rememberPassword;
                                                setState(() {});
                                              }),
                                          SizedBox(
                                            width: fontsz / 2,
                                          ),
                                          Text(
                                            "保存账号",
                                            style: TextStyle(
                                                fontSize: fontsz * 0.9,
                                                color: rememberPassword
                                                    ? Colors.purple
                                                    : const Color.fromARGB(
                                                        120, 155, 39, 176)),
                                          )
                                        ],
                                      ),
                                      SizedBox(
                                        height: fontsz / 3,
                                      ),
                                      Row(
                                        children: [
                                          RoundCheckBox(
                                              size: fontsz * 1.5,
                                              checkedWidget: Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: fontsz,
                                              ),
                                              checkedColor: Colors.purple,
                                              uncheckedColor:
                                                  const Color.fromARGB(
                                                      255, 255, 255, 255),
                                              border: Border.all(
                                                  color: const Color.fromARGB(
                                                      255, 24, 24, 24),
                                                  width: 1),
                                              isChecked: bukao,
                                              onTap: (selected) {
                                                bukao = !bukao;
                                                setState(() {});
                                              }),
                                          SizedBox(
                                            width: fontsz / 2,
                                          ),
                                          Text(
                                            "查看补考",
                                            style: TextStyle(
                                                fontSize: fontsz * 0.9,
                                                color: bukao
                                                    ? Colors.purple
                                                    : const Color.fromARGB(
                                                        120, 155, 39, 176)),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                  Expanded(
                                      child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: TextButton(
                                              onPressed: () async {
                                                await Loginact();
                                              },
                                              child: state == false
                                                  ? Text(
                                                      "登录",
                                                      style: TextStyle(
                                                        color: Colors.purple,
                                                        fontSize: fontsz * 1.8,
                                                      ),
                                                    )
                                                  : loadanimation(
                                                      radius: fontsz * 3,
                                                    ))))
                                ],
                              ),
                            ],
                          )),
                      datedisplay
                          ? DropdownList(
                              startYear: startyear,
                              size: fontsz,
                            )
                          : Container(),
                    ],
                  ),
                ))),
      ],
    ));
  }
}

class MainPage extends StatefulWidget {
  var topdata;
  var listdata;
  var otherdata;
  var schedule;
  var userlist;
  var examlist;

  MainPage(this.topdata, this.listdata, this.otherdata, this.schedule,
      this.userlist, this.examlist,
      {super.key});
  Appdata appsetting = Appdata();
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _labelstate = 0;
  int number = 2;
  late double statusBarHeight;
  late double screenWidth;
  late double screenHeight;
  late double fontsz;
  CounterStorage ctrlFile = CounterStorage();
  var datalist;
  bool blurstate = false;
  bool itemcolorstate = false;
  var imagetip = "";
  String Imagepath = "";
  bool blur = false;
  Color dateColor = Colors.lightBlueAccent;
  Color timeColor = Colors.lightBlueAccent;
  Color bgColor = Colors.orange.withOpacity(0.6);
  Map initdata = {};
  int currentWeek = 1;
  late String teacherName;
  late final PageController _classpagecontroller;
  late final PageController _exampagecontroller;
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
      _labelstate = index;
      _pageController.jumpToPage(
        index,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    load();

    formattedDate = DateFormat('M/d').format(currentDate);
    _ChatLoadAnimaController = AnimationController(
        duration: const Duration(milliseconds: 2500), vsync: this);
    _ChatLoadAnima = CurvedAnimation(
        parent: _ChatLoadAnimaController, curve: Curves.easeOutBack);
    _ChatLoadAnima =
        Tween<double>(begin: 0.0, end: 1.0).animate(_ChatLoadAnima);
    _ChatLoadAnimaController.forward();

    DateTime startDate = DateTime(2023, 8, 28);
    // 获取当前日期

    // 计算当前日期与起始日期之间的差距（天数）
    Duration difference = currentDate.difference(startDate);
    // 计算当前是第几周
    currentWeek = (difference.inDays ~/ 7) + 1;
    teacherName = "$currentWeek";
    date = calculateDates(int.parse(teacherName));
    _classpagecontroller = PageController(initialPage: currentWeek - 1);
    widget.appsetting.readCounter().then((value) {
      if (value.isEmpty) {
        //此处原本是供设置文件进行数据初始化，但是设置页本身也有数据初始化，故保留其中一个
        // widget.appsetting.writeCounter(initdata);
      } else {
        initdata = value;
        dateColor = Color(int.parse(initdata["weekbarcolor"], radix: 16));
        timeColor = Color(int.parse(initdata["timebarcolor"], radix: 16));
        bgColor = Color(int.parse(initdata["bgcolor"], radix: 16));
        Imagepath = initdata["classimage"];
        itemcolorstate = initdata["itemcolorstate"] == "true" ? true : false;
        blur = initdata["blur"] == "true" ? true : false;
      }
      setState(() {});
    });
    ctrlFile.readCounter().then((value) {
      datalist = value;
      setState(() {
        number = datalist["content"].length;
      });
    });

    currentscdule = extractColumnData(
        widget.schedule[currentWeek - 1], 7, getCurrentDayOfWeek());
    currentclass = currentscdule[getCurrentTimeSlot()];
    for (int x = 0; x < 8; x++) {
      if (currentscdule[x].courseName != "") {
        todaytotalclass += 1;
      }
    }
  }

  @override
  void dispose() {
    _ChatLoadAnimaController.dispose();

    super.dispose();
  }

  void load() async {
    dayword = await gettext();
  }

  void backlogin(String account) async {
    datalist["initial"] = account;
    ctrlFile.writeCounter(datalist);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return LoginPage(CounterStorage(), true);
        },
      ),
    );
  }

  void addaccount() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return LoginPage(CounterStorage(), false);
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
    final mediaQueryData = MediaQuery.of(context);
    statusBarHeight = mediaQueryData.padding.top;
    screenWidth = mediaQueryData.size.width;
    screenHeight = mediaQueryData.size.height;
    fontsz = screenWidth * 0.045;
    double displayWidth = MediaQuery.of(context).size.width;
    return WillPopScope(
        // 禁用返回按钮
        onWillPop: () async => false,
        child: Scaffold(
            bottomNavigationBar: Container(
              margin: EdgeInsets.all(displayWidth * .05),
              height: displayWidth * .155,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.1),
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
                                ? Colors.blueAccent.withOpacity(.2)
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
                                        ? '${listOfStrings[index]}'
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
                  setState(() {
                    _labelstate = index;
                  });
                },
                children: [classPage(), HomoPage(), ExamPage(), updatePage()],
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
                          Container(
                              height: screenHeight,
                              color: Colors.white,
                              child: Imagepath != ""
                                  ? Image.file(
                                      File(Imagepath),
                                      fit: BoxFit.cover,
                                    )
                                  : const SizedBox()),
                          Center(
                              child: blur
                                  ?
                                  // decoration: BoxDecoration(
                                  //     borderRadius: BorderRadius.circular(fontsz)),
                                  ClipRect(
                                      //使图片模糊区域仅在子组件区域中
                                      child: BackdropFilter(
                                        //背景过滤器
                                        filter: ImageFilter.blur(
                                            sigmaX: 50.0,
                                            sigmaY: 50.0), //设置图片模糊度
                                        child: Opacity(
                                          //悬浮的内容
                                          opacity: 0.1,
                                          child: Container(
                                            height: screenHeight,
                                            width: screenWidth,
                                            color: Colors.grey.shade200,
                                          ),
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
                                                      : Colors.black
                                                          .withOpacity(0.65),
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
                                child: PageView.builder(
                                  controller: _classpagecontroller,
                                  onPageChanged: (index) => {
                                    setState(() {
                                      teacherName = "${index + 1}";
                                      date = calculateDates(
                                          int.parse(teacherName));
                                    })
                                  },
                                  itemCount: widget.schedule.length, // 你的页面数量
                                  itemBuilder: (context, index) {
                                    return Container(
                                        clipBehavior: Clip.hardEdge,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: CalendarPage(
                                          colorstate: itemcolorstate,
                                          dat: widget.schedule[index],
                                          iteh: screenHeight * 0.7,
                                          showstate: classstate,
                                        ));
                                    // 创建日历页面
                                  },
                                ),
                              ),
                              AnimatedBuilder(
                                  animation: _ChatLoadAnima,
                                  builder: (context, child) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          //margin: EdgeInsets.only(top: 0),
                                          width: screenWidth /
                                              1.9 *
                                              _ChatLoadAnima.value,
                                          height: fontsz * 2,
                                          decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                  colors: [
                                                    Color.fromARGB(
                                                        255, 9, 136, 240),
                                                    Color.fromARGB(
                                                        255, 52, 129, 245)
                                                  ],
                                                  begin: Alignment.bottomRight),
                                              borderRadius: BorderRadius.only(
                                                  topRight: Radius.circular(
                                                      fontsz / 2),
                                                  bottomRight: Radius.circular(
                                                      fontsz / 2))),
                                          child: Center(
                                            child: Text(
                                              dayword,
                                              style: TextStyle(
                                                  fontSize: fontsz * 0.7,
                                                  height: 1.1,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        const Expanded(child: SizedBox()),
                                        Transform.rotate(
                                            angle: _ChatLoadAnima.value * 6,
                                            child: GestureDetector(
                                              child: Container(
                                                  margin: EdgeInsets.only(
                                                      right: fontsz / 2),
                                                  height: fontsz * 3.5,
                                                  width: fontsz * 3,
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.settings,
                                                      size: fontsz * 2,
                                                      color: Colors.blue,
                                                    ),
                                                  )),
                                              onTap: () async {
                                                final result =
                                                    await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                  builder: (context) {
                                                    return MyImagePicker();
                                                  },
                                                ));
                                                if (result != null &&
                                                    result is ResultObject) {
                                                  setState(() {
                                                    dateColor =
                                                        result.dateColor;
                                                    timeColor =
                                                        result.timeColor;
                                                    bgColor = result.bgColor;
                                                    Imagepath =
                                                        result.stringValue;
                                                    blur = result.boolValue;
                                                    itemcolorstate =
                                                        result.itemcolorstate;
                                                  });
                                                }
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
                          SizedBox(
                            width: fontsz,
                            //width: screenWidth * 0.7,
                            height: screenHeight * 0.05,
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

                                        minHeight: fontsz / 2.5, // 设置进度条的最小高度
                                        backgroundColor:
                                            Colors.grey[300], // 设置进度条的背景颜色
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                timeColor.withOpacity(
                                                    0.5)), // 设置进度条的前景颜色
                                      ),
                                    ),
                                  ),
                                ),
                                MediaQuery.removePadding(
                                    context: context,
                                    removeTop: true,
                                    child: ListView.builder(
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
                                                              .withOpacity(
                                                                  0)))),
                                          width: fontsz,
                                          height: screenHeight *
                                              0.7 /
                                              (classstate ? 8 : 5),
                                          //color: Colors.white,
                                          child: Center(
                                            child: Container(
                                              width: fontsz * 0.7,
                                              height: fontsz * 0.7,
                                              decoration: BoxDecoration(
                                                  color: timeColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          fontsz)),
                                            ),
                                          ),
                                        );
                                      },
                                    ))
                              ]))
                        ],
                      )),
                  const Expanded(child: SizedBox()),
                  Column(
                      //crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: screenWidth / 4,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Colors.blue,
                                Color.fromARGB(255, 114, 167, 233)
                              ], begin: Alignment.bottomCenter),
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(fontsz),
                                  bottomLeft: Radius.circular(fontsz))),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                            width: screenWidth / 4,
                            height: screenHeight / 4.5,
                            margin: EdgeInsets.only(top: fontsz),
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Colors.blue,
                                  Color.fromARGB(255, 114, 167, 233)
                                ], begin: Alignment.bottomCenter),
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(fontsz),
                                    bottomLeft: Radius.circular(fontsz))),
                            child: Column(
                              children: [
                                Text(
                                  "今日课程",
                                  style: TextStyle(
                                      fontSize: fontsz * 0.9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal),
                                ),
                                SizedBox(
                                  width: screenWidth / 4,
                                  height: screenHeight / 6,
                                  child: MediaQuery.removePadding(
                                      context: context,
                                      removeTop: true,
                                      child: ListView.builder(
                                        itemCount: 8,
                                        itemBuilder: (context, index) {
                                          if (currentscdule[index].courseName ==
                                              "") {
                                            return Container(
                                              height: 2,
                                              color: Colors.orange,
                                              margin: EdgeInsets.only(
                                                  top: 2,
                                                  bottom: 2,
                                                  left: fontsz,
                                                  right: fontsz),
                                            );
                                          } else {
                                            return Container(
                                                margin: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            fontsz / 4)),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      currentscdule[index]
                                                          .courseName,
                                                      overflow: TextOverflow
                                                          .ellipsis, // 超出一行时使用省略号表示
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                          fontSize:
                                                              fontsz * 0.8,
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                      currentscdule[index]
                                                          .coursePeriod,
                                                      style: TextStyle(
                                                          fontSize:
                                                              fontsz * 0.65),
                                                    ),
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
                                        fontWeight: FontWeight.normal))
                              ],
                            )),
                        // SizedBox(
                        //   height: screenHeight * 0.1,
                        // ),

                        Container(
                          width: screenWidth / 4,
                          height: screenHeight / 5,
                          margin:
                              EdgeInsets.only(top: fontsz, bottom: fontsz * 3),
                          // decoration: BoxDecoration(
                          //     gradient: const LinearGradient(colors: [
                          //       Colors.blue,
                          //       Color.fromARGB(255, 114, 167, 233)
                          //     ], begin: Alignment.bottomCenter),
                          //     borderRadius: BorderRadius.only(
                          //         topLeft: Radius.circular(fontsz),
                          //         bottomLeft: Radius.circular(fontsz))),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal, // 设置横向滚动
                            itemCount: widget.userlist["content"].length,
                            itemBuilder: (BuildContext context, int index) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  //const Expanded(child: SizedBox()),
                                  GestureDetector(
                                    onTap: () => backlogin(widget
                                        .userlist["content"].keys
                                        .toList()[index]),
                                    child: Container(
                                      margin:
                                          EdgeInsets.only(right: fontsz / 4),
                                      width: fontsz,
                                      padding: EdgeInsets.all(fontsz * 0.1),
                                      decoration: BoxDecoration(
                                          gradient:
                                              const LinearGradient(colors: [
                                            Colors.blue,
                                            Color.fromARGB(255, 69, 142, 230)
                                          ], begin: Alignment.bottomCenter),
                                          // border: Border.all(
                                          //     width: 1, color: Colors.white),
                                          borderRadius: BorderRadius.circular(
                                              fontsz / 4)),
                                      // width: 45,
                                      //margin: const EdgeInsets.only(top: 5),
                                      child: Text(
                                        '${widget.userlist["content"].keys.toList()[index]}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontFamily: "Roboto",
                                            color: Colors.white,
                                            fontSize: fontsz * 0.8,
                                            height: 0.95),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          deleteAsk = true;
                                          currentdelete = widget
                                              .userlist["content"].keys
                                              .toList()[index];
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 3),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(fontsz),
                                            color: deleteAsk
                                                ? widget.userlist["content"]
                                                            .keys
                                                            .toList()[index] ==
                                                        currentdelete
                                                    ? Colors.red
                                                    : Colors.blue
                                                : Colors.blue),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: fontsz,
                                        ),
                                      )),
                                ],
                              );
                            },
                          ),
                        ),

                        Container(
                            width: screenWidth / 4,
                            decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: fontsz),
                                ],
                                color: Colors.white,
                                // border: Border.all(
                                //     width: 1, color: Colors.white),
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(fontsz),
                                    bottomLeft: Radius.circular(fontsz))),
                            // width: 45,
                            //margin: const EdgeInsets.only(top: 5),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    _classpagecontroller.jumpToPage(
                                      currentWeek - 1,
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.only(left: fontsz / 3),
                                    margin: EdgeInsets.only(
                                      top: fontsz / 3,
                                      left: fontsz / 3,
                                    ),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(fontsz),
                                            bottomLeft:
                                                Radius.circular(fontsz)),
                                        color: Colors.black.withOpacity(0.08)),
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
                                                  fontSize: fontsz * 0.8,
                                                  color: Colors.blue),
                                            ),
                                            Text(
                                              "定位课表到今天",
                                              style: TextStyle(
                                                  fontSize: fontsz / 2.2,
                                                  color: Colors.black
                                                      .withOpacity(0.5)),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (context) {
                                        return AutherPage(
                                            name: widget.topdata[0].name,
                                            campus:
                                                widget.topdata[0].department,
                                            code: widget.topdata[0].studentId);
                                      },
                                    ));
                                  },
                                  child: Container(
                                    padding: EdgeInsets.only(left: fontsz / 3),
                                    margin: EdgeInsets.only(
                                      top: fontsz / 3,
                                      left: fontsz / 3,
                                    ),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(fontsz),
                                            bottomLeft:
                                                Radius.circular(fontsz)),
                                        color: Colors.black.withOpacity(0.08)),
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
                                                  fontSize: fontsz * 0.8,
                                                  color: Colors.blue),
                                            ),
                                            Text(
                                              "    建议与更新    ",
                                              style: TextStyle(
                                                  fontSize: fontsz / 2.2,
                                                  color: Colors.black
                                                      .withOpacity(0.5)),
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
                                    padding: EdgeInsets.only(left: fontsz / 3),
                                    margin: EdgeInsets.only(
                                        top: fontsz / 3,
                                        left: fontsz / 3,
                                        bottom: fontsz / 3),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(fontsz),
                                            bottomLeft:
                                                Radius.circular(fontsz)),
                                        color: Colors.black.withOpacity(0.08)),
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
                                                  fontSize: fontsz * 0.8,
                                                  color: Colors.blue),
                                            ),
                                            Text(
                                              "显示周末或关闭",
                                              style: TextStyle(
                                                  fontSize: fontsz / 2.2,
                                                  color: Colors.black
                                                      .withOpacity(0.5)),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ))
                      ]),
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
                            color: Colors.black.withOpacity(0.1),
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
                              child: Icon(
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

                                  widget.userlist["content"]
                                      .remove(currentdelete);
                                  datalist["content"].remove(currentdelete);
                                  ctrlFile.writeCounter(datalist);
                                });
                              },
                              child: Icon(
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
            child: widget.examlist.length == 0
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
                            borderRadius: BorderRadius.circular(fontsz / 2)),
                        child: Text(
                          "本学期暂无考试安排",
                          style:
                              TextStyle(fontSize: fontsz, color: Colors.white),
                        ),
                      )
                    ],
                  )
                : ExamList(examlist: widget.examlist)

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

  Widget HomoPage() {
    List<bool> datalist = [];
    for (var num in widget.listdata) {
      if (num.isPassed == "是") {
        datalist.add(true);
      } else {
        datalist.add(false);
      }
    }
    int pubulicsession = 0;
    int pravitesession = 0;
    for (int a = 0; a < widget.otherdata.length; a++) {
      if (widget.otherdata[a].courseType == "公选") {
        pubulicsession += 1;
      } else {
        pravitesession += 1;
      }
    }
    return WillPopScope(
        // 禁用返回按钮
        onWillPop: () async => false,
        child: Scaffold(
          body: Center(
            child: Container(
              decoration: const BoxDecoration(
                  //color: Color.fromARGB(255, 207, 84, 84),
                  ),
              //padding: const EdgeInsets.all(10),
              // decoration:
              //     const BoxDecoration(color: Color.fromARGB(255, 255, 255, 255)),
              child: Column(
                children: [
                  SizedBox(
                    height: statusBarHeight,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      margin: EdgeInsets.all(fontsz / 3),
                      padding: EdgeInsets.all(fontsz / 3),
                      decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(30))),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                margin:
                                    const EdgeInsets.only(left: 5, right: 5),
                                width: 4,
                                height: fontsz * 3,
                                decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(5)),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.topdata[0].name,
                                    style: TextStyle(
                                        fontSize: fontsz,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue),
                                    textAlign: TextAlign.left,
                                  ),
                                  // const SizedBox(
                                  //   width: 5,
                                  // ),
                                  Text(
                                    widget.topdata[0].studentId,
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: fontsz * 0.7,
                                        color: Colors.blue),
                                  ),
                                  // const SizedBox(
                                  //   width: 5,
                                  // ),
                                  Text(
                                    widget.topdata[0].department,
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: fontsz * 0.7,
                                        color: Colors.blue),
                                  )
                                ],
                              ),
                              Row(
                                children: [
                                  widgetshow(
                                    name: "GPA",
                                    value: widget.topdata[0].gpa,
                                    fill: 10,
                                    size: fontsz,
                                  ),
                                  widgetshow(
                                    name: "Credits",
                                    value: widget.topdata[0].earnedCredits,
                                    fill: widget.topdata[0].requiredCredits,
                                    size: fontsz,
                                  )
                                ],
                              ),
                            ],
                          ),
                          Text(
                            "培养计划预览",
                            style: TextStyle(
                                color: Colors.blue, fontSize: fontsz * 0.8),
                          ),
                          ContributionGraph(
                            activityData: datalist,
                            size: fontsz / 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: fontsz,
                    width: screenWidth * 0.7,
                    decoration: const BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "已考【公选：$pubulicsession",
                          style: const TextStyle(color: Colors.white),
                        ),
                        SizedBox(
                          width: fontsz,
                        ),
                        Text(
                          "必修：$pravitesession】",
                          style: const TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                      child: Container(
                    decoration: const BoxDecoration(
                        border: Border(
                            top: BorderSide(width: 3, color: Colors.blue))),
                    // width: screenWidth * 0.95,
                    // height: screenHeight * 0.5,
                    child: (pravitesession + pubulicsession) == 0
                        ? Column(
                            children: [
                              SizedBox(
                                height: fontsz * 3,
                              ),
                              SizedBox(
                                height: screenWidth * 0.6,
                                width: screenWidth,
                                child: Image.asset('assets/data/icon.png'),
                              ),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 194, 194, 194),
                                    borderRadius:
                                        BorderRadius.circular(fontsz / 2)),
                                child: Text(
                                  "本学期暂无考试成绩",
                                  style: TextStyle(
                                      fontSize: fontsz, color: Colors.white),
                                ),
                              )
                            ],
                          )
                        : SubjectCreditsList(
                            courseList: widget.otherdata,
                            size: fontsz,
                          ),
                  ))
                ],
              ),
            ),
          ),
        ));
  }
}

class MyImagePicker extends StatefulWidget {
  final Appdata appsetting = Appdata();

  MyImagePicker({super.key});
  @override
  _MyImagePickerState createState() => _MyImagePickerState();
}

class _MyImagePickerState extends State<MyImagePicker> {
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedImage;
  String Imagepath = "";
  bool blur = false;
  bool isUse = false;
  bool itemcolorstate = false;
  Map initdata = {
    "classimage": "",
    "blur": "false",
    "weekbarcolor": "",
    "timebarcolor": "",
    "bgcolor": "",
    "itemcolorstate": "false"
  };

  Color dateColor = Colors.lightBlueAccent;
  Color timeColor = Colors.lightBlueAccent;
  Color bgColor = Colors.orange.withOpacity(0.6);
  @override
  void initState() {
    super.initState();
    widget.appsetting.readCounter().then((value) {
      if (value.isEmpty) {
        initdata["weekbarcolor"] = dateColor.value.toRadixString(16);
        initdata["timebarcolor"] = timeColor.value.toRadixString(16);
        initdata["bgcolor"] = bgColor.value.toRadixString(16);

        widget.appsetting.writeCounter(initdata);
      } else {
        initdata = value;

        dateColor = Color(int.parse(initdata["weekbarcolor"], radix: 16));
        timeColor = Color(int.parse(initdata["timebarcolor"], radix: 16));
        bgColor = Color(int.parse(initdata["bgcolor"], radix: 16));
        itemcolorstate = initdata["itemcolorstate"] == "true" ? true : false;
        Imagepath = initdata["classimage"];
        isUse = Imagepath == "" ? false : true;
        blur = initdata["blur"] == "true" ? true : false;
      }
      setState(() {});
    });
  }

  void _pickImage() async {
    _pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    Imagepath = _pickedImage!.path;
    isUse = Imagepath == "" ? false : true;
    if (_pickedImage != null) {
      initdata["classimage"] = _pickedImage!.path.toString();
      widget.appsetting.writeCounter(initdata);
      setState(() {
        // 使用setState来更新状态，触发界面刷新
      });
    }
  }

  _blurchange() {
    blur = !blur;
    initdata["blur"] = blur.toString();
    widget.appsetting.writeCounter(initdata);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    //double statusBarHeight = mediaQueryData.padding.top;
    double screenWidth = mediaQueryData.size.width;
    double screenHeight = mediaQueryData.size.height;
    double fontsz = screenWidth * 0.045;
    return Scaffold(
      appBar: AppBar(
        title: const Text('课程表设置'),
        foregroundColor: Colors.blue,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(
                context,
                ResultObject(Imagepath, blur, dateColor, timeColor, bgColor,
                    itemcolorstate)); // 传递参数并返回
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(fontsz),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "课程表背景",
              style: TextStyle(fontSize: fontsz, color: Colors.blue),
            ),
            Stack(
              children: [
                Center(
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    height: screenHeight / 5,
                    width: screenWidth * 0.9,
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 230, 230, 230),
                        borderRadius: BorderRadius.circular(fontsz)),
                    child: Imagepath != ""
                        ? Image.file(
                            File(Imagepath),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 201, 201, 201),
                                borderRadius: BorderRadius.circular(fontsz)),
                            width: screenWidth * 0.9,
                            height: screenHeight / 5,
                          ),
                  ),
                ),
                Center(
                    child: blur
                        ? Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(fontsz)),
                            child: ClipRect(
                              //使图片模糊区域仅在子组件区域中
                              child: BackdropFilter(
                                //背景过滤器
                                filter: ImageFilter.blur(
                                    sigmaX: 50.0, sigmaY: 50.0), //设置图片模糊度
                                child: Opacity(
                                  //悬浮的内容
                                  opacity: 0.1,
                                  child: Container(
                                    height: screenHeight / 5,
                                    width: screenWidth * 0.9,
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container())
              ],
            ),
            SizedBox(height: fontsz / 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                RoundCheckBox(
                  onTap: (selected) {
                    isUse = !isUse;
                    Imagepath = "";

                    initdata["classimage"] = Imagepath;
                    initdata["blur"] = blur.toString();
                    widget.appsetting.writeCounter(initdata);
                    setState(() {});
                  },
                  size: fontsz * 1.4,
                  isChecked: isUse,
                ),
                Text(isUse ? "启用" : "已删除",
                    style: TextStyle(fontSize: fontsz / 1.2)),
                const Expanded(child: SizedBox()),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('选择图片'),
                ),
                SizedBox(
                  width: fontsz,
                ),
                RoundCheckBox(
                  onTap: (selected) {
                    _blurchange();
                  },
                  size: fontsz * 1.4,
                  isChecked: blur,
                ),
                Text(
                  "亚克力遮罩",
                  style: TextStyle(fontSize: fontsz / 1.2),
                ),
              ],
            ),
            SizedBox(
              height: fontsz,
            ),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(fontsz)),
              child: Row(
                children: [
                  Expanded(
                      child: Column(
                    children: [
                      Text(
                        "日期标尺色",
                        style: TextStyle(
                            fontSize: fontsz * 0.7, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () async {
                          dateColor = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return ColorPickerDialog(initialColor: dateColor);
                            },
                          );
                          initdata["weekbarcolor"] =
                              dateColor.value.toRadixString(16);
                          widget.appsetting.writeCounter(initdata);
                          setState(() {});
                        },
                        child: Container(
                          margin: EdgeInsets.all(fontsz / 3),
                          width: fontsz * 3,
                          height: fontsz * 3,
                          decoration: BoxDecoration(
                              color: dateColor,
                              borderRadius: BorderRadius.circular(fontsz * 2)),
                        ),
                      )
                    ],
                  )),
                  Expanded(
                      child: Column(
                    children: [
                      Text(
                        "时间标尺色",
                        style: TextStyle(
                            fontSize: fontsz * 0.7, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () async {
                          timeColor = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return ColorPickerDialog(initialColor: timeColor);
                            },
                          );
                          initdata["timebarcolor"] =
                              timeColor.value.toRadixString(16);
                          widget.appsetting.writeCounter(initdata);
                          setState(() {});
                        },
                        child: Container(
                          margin: EdgeInsets.all(fontsz / 3),
                          width: fontsz * 3,
                          height: fontsz * 3,
                          decoration: BoxDecoration(
                              color: timeColor,
                              borderRadius: BorderRadius.circular(fontsz * 2)),
                        ),
                      )
                    ],
                  )),
                  Expanded(
                      child: Column(
                    children: [
                      Text(
                        "背景主题色",
                        style: TextStyle(
                            fontSize: fontsz * 0.7, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () async {
                          bgColor = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return ColorPickerDialog(initialColor: bgColor);
                            },
                          );
                          initdata["bgcolor"] = bgColor.value.toRadixString(16);
                          widget.appsetting.writeCounter(initdata);
                          setState(() {});
                        },
                        child: Container(
                          margin: EdgeInsets.all(fontsz / 3),
                          width: fontsz * 3,
                          height: fontsz * 3,
                          decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(fontsz * 2)),
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
            Text(
              "单元格颜色",
              style: TextStyle(fontSize: fontsz * 0.7, color: Colors.blue),
            ),
            SizedBox(
                //decoration: const BoxDecoration(color: Colors.black12),
                height: fontsz * 2,
                child: Row(
                  //crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: RoundCheckBox(
                        onTap: (selected) {
                          itemcolorstate = !itemcolorstate;
                          initdata["itemcolorstate"] =
                              itemcolorstate.toString();
                          widget.appsetting.writeCounter(initdata);
                          setState(() {});
                        },
                        size: fontsz * 1.4,
                        isChecked: itemcolorstate,
                      ),
                    ),
                    SizedBox(
                      width: fontsz,
                    ),
                    Expanded(
                      child: RoundCheckBox(
                        onTap: (selected) {
                          itemcolorstate = !itemcolorstate;
                          initdata["itemcolorstate"] =
                              itemcolorstate.toString();
                          widget.appsetting.writeCounter(initdata);
                          setState(() {});
                        },
                        size: fontsz * 1.4,
                        isChecked: !itemcolorstate,
                      ),
                    )
                  ],
                )),
            SizedBox(
              height: fontsz,
              child: Row(
                children: const [
                  Expanded(
                      child: Align(
                    alignment: Alignment.topCenter,
                    child: Text("区分色"),
                  )),
                  Expanded(
                      child: Align(
                    alignment: Alignment.topCenter,
                    child: Text("极简白"),
                  ))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const ColorPickerDialog({super.key, required this.initialColor});

  @override
  _ColorPickerDialogState createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择颜色'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _selectedColor,
          onColorChanged: (color) {
            setState(() {
              _selectedColor = color;
            });
          },
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            // 返回选中的颜色值
            Navigator.pop(context, _selectedColor);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class AutherPage extends StatefulWidget {
  final String name;
  final String campus;
  final String code;
  AutherPage({required this.name, required this.campus, required this.code});

  @override
  _Auther createState() => _Auther();
}

class _Auther extends State<AutherPage> {
  TextEditingController advicecontrol = TextEditingController();

  String versionserive = "";
  String updateurl = "";
  String versionapp = "";
  double _progressValue = 0.0;
  //bool state = false;
  // late String versionText;
  Dio dio = Dio();
  String apkUrl = "http://49.235.106.67/arm64-v8a.apk";
  String downloadMessage = "";
  String logtext = "";
  String logdate = "";
  @override
  void initState() {
    load();
  }

  load() async {
    versionserive = await getversion();
    versionapp = await getVersionapp();
    List source = await getlog();
    logtext = source[1];
    logdate = source[0];
    setState(() {});
  }

  Future<void> _startUpdate() async {
    var appDocDir = await getTemporaryDirectory();
    String savePath = appDocDir.path + "/new_version.apk";
    String fileUrl = "http://49.235.106.67/arm64-v8a.apk";

    await Dio().download(fileUrl, savePath, onReceiveProgress: (count, total) {
      setState(() {
        _progressValue = count / total;
      });
    });

    final res = await InstallPlugin.install(savePath);
    _showResMsg(
        "Install apk ${res['isSuccess'] == true ? 'success' : 'fail:${res['errorMessage'] ?? ''}'}");
    setState(() {
      _progressValue = 0.0;
    });
  }

  void _showResMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // void _showPopup(BuildContext context, size, state) {
  //   showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return Container(
  //             color: const Color.fromARGB(30, 118, 118, 118),
  //             child: Center(
  //                 child: ));
  //       });
  // }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    double statusBarHeight = mediaQueryData.padding.top;
    double screenWidth = mediaQueryData.size.width;
    double screenHeight = mediaQueryData.size.height;
    double fontsz = screenWidth * 0.045;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          title: const Text("关于"),
        ),
        body: Padding(
          padding: EdgeInsets.all(statusBarHeight / 2),
          child: Column(
            children: [
              Container(
                  padding: const EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: Colors.yellow[700], // 选择黄金色
                    borderRadius: BorderRadius.circular(5.0),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.yellow.withOpacity(0.5), // 添加一点深色投影
                    //     spreadRadius: 2,
                    //     blurRadius: 4,
                    //     offset: const Offset(0, 2),
                    //   ),
                    // ],
                  ),
                  child: const Text(
                    '长江大学武汉校区计算机学会',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.0,
                    ),
                  )),
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 214, 214, 214),
                    borderRadius: BorderRadius.circular(fontsz)),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(fontsz / 2),
                      clipBehavior: Clip.hardEdge,
                      width: screenWidth / 5.5,
                      height: screenWidth / 5.5,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(screenWidth / 3)),
                      child: Image.asset(
                        'assets/data/icon.png',
                        fit: BoxFit.cover,
                      ),
                      // child: Image(image: kWebNumPadMap),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Grade2",
                          style:
                              TextStyle(fontSize: fontsz, color: Colors.white),
                        ),
                        SizedBox(
                          height: fontsz,
                        ),
                        Text(
                          " v.$versionapp",
                          style: TextStyle(
                              fontSize: fontsz / 1.5, color: Colors.white),
                        ),
                      ],
                    ),
                    const Expanded(child: SizedBox()),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "小脑萎缩",
                          style:
                              TextStyle(fontSize: fontsz, color: Colors.white),
                        ),
                        Text(
                          "联系我 ",
                          style: TextStyle(
                              fontSize: fontsz / 1.5, color: Colors.white),
                        ),
                        Text(
                          "3517049357",
                          style: TextStyle(
                              fontSize: fontsz / 1.5, color: Colors.white),
                        )
                      ],
                    ),
                    Container(
                      clipBehavior: Clip.hardEdge,
                      width: screenWidth / 5.5,
                      height: screenWidth / 5.5,
                      decoration: BoxDecoration(
                          color: Colors.lightBlueAccent,
                          borderRadius: BorderRadius.circular(screenWidth / 3)),
                      child: Image.asset(
                        'assets/data/profile.jpg',
                      ),
                      // child: Image(image: kWebNumPadMap),
                    ),
                  ],
                ),
              ),
              Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.only(left: 3),
                  // decoration: const BoxDecoration(
                  //     border: Border(
                  //         left: BorderSide(
                  //             width: 2,
                  //             color: Color.fromARGB(255, 152, 209, 255)))),
                  child: Column(
                    children: [
                      Text(
                        logtext,
                        style: const TextStyle(
                            color: Color.fromARGB(255, 86, 86, 86)),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text("_$logdate"),
                      )
                    ],
                  )),
              Container(
                padding: EdgeInsets.only(left: fontsz / 4),
                decoration: BoxDecoration(
                    border: Border.all(
                        width: 2, color: Colors.blue.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(fontsz / 1.3)),
                //height: screenHeight / 8,
                child: SingleChildScrollView(
                  child: TextField(
                    cursorHeight: fontsz * 1.1,
                    controller: advicecontrol,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(0),
                      border: InputBorder.none, // 设置边框为none，即消除边框
                      hintText: "编辑反馈",
                    ),
                  ),
                ),
              ),

              GestureDetector(
                onTap: () {
                  if (advicecontrol.text != "") {
                    SenMail(
                        widget.name, widget.campus, advicecontrol.text, true);
                    const snackBar = SnackBar(
                      content: Text('发送成功'), // 显示的消息文本
                      duration: Duration(seconds: 2), // 持续时间，单位为秒
                    );
                    if (advicecontrol.text == "2022007915") {
                      const snackBar = SnackBar(
                        content: Text('恶心的骗子'), // 显示的消息文本
                        duration: Duration(seconds: 2), // 持续时间，单位为秒
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  } else {
                    const snackBar = SnackBar(
                      content: Text('内容不能为空'), // 显示的消息文本
                      duration: Duration(seconds: 2), // 持续时间，单位为秒
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                },
                child: Container(
                    margin: EdgeInsets.all(fontsz / 2),
                    width: fontsz * 8,
                    height: fontsz * 2,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(fontsz / 2),
                    ),
                    child: Center(
                      child: Text(
                        "发送反馈给开发者",
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: fontsz * 0.8,
                            decoration: TextDecoration.none,
                            color: Colors.blue),
                      ),
                    )),
              ),
              Container(
                  // width: fontsz * 15,
                  // height: fontsz * 10,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color.fromARGB(255, 202, 238, 228)),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: fontsz / 2),
                            decoration: BoxDecoration(
                                //color: Colors.green,
                                borderRadius: BorderRadius.circular(5)),
                            child: Text(
                              " 最新版本:  $versionserive",
                              style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: fontsz,
                                  decoration: TextDecoration.none,
                                  color: Colors.black.withOpacity(0.7)),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                                //color: Colors.blue,
                                borderRadius: BorderRadius.circular(5)),
                            child: Text(
                              " 当前版本:  $versionapp",
                              style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: fontsz,
                                  decoration: TextDecoration.none,
                                  color: Colors.black.withOpacity(0.7)),
                            ),
                          ),
                        ],
                      ),
                      const Expanded(child: SizedBox()),
                      _progressValue == 0
                          ? GestureDetector(
                              onTap: _startUpdate,
                              child: Container(
                                  width: fontsz * 5,
                                  height: fontsz * 2,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.05),
                                    borderRadius:
                                        BorderRadius.circular(fontsz / 4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "同步更新",
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: fontsz * 0.8,
                                          decoration: TextDecoration.none,
                                          color: Colors.blue),
                                    ),
                                  )),
                            )
                          : Row(
                              children: [
                                CircularProgressIndicator(
                                  value: _progressValue,
                                ),
                                SizedBox(
                                  width: statusBarHeight / 2,
                                )
                              ],
                            )
                    ],
                  )),
              // Align(
              //   alignment: Alignment.centerLeft,
              //   child: Text(
              //     "  反馈建议",
              //     style: TextStyle(fontSize: fontsz),
              //   ),
              // ),
            ],
          ),
        ));
  }
}

class updatePage extends StatefulWidget {
  const updatePage({super.key});
  @override
  _updatepage createState() => _updatepage();
}

class _updatepage extends State<updatePage> with TickerProviderStateMixin {
  // late AnimationController _ChatLoadAnimaController;
  // late Animation<double> _ChatLoadAnima;
  late AnimationController _ChatExpandAnimaController;
  late Animation<double> _ChatExpandAnima;
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
  List urls = [];
  String selectedLocation = "1";
  @override
  void initState() {
    super.initState();

    _ChatExpandAnimaController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _ChatExpandAnima = CurvedAnimation(
        parent: _ChatExpandAnimaController, curve: Curves.easeOutBack);
    _ChatExpandAnima =
        Tween<double>(begin: 0.0, end: 1.0).animate(_ChatExpandAnima);

    TeenStudy().then((value) {
      urls = value;
    });
  }

  @override
  void dispose() {
    //_ChatLoadAnimaController.dispose();
    _ChatExpandAnimaController.dispose();
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
        Container(
            margin: EdgeInsets.all(fontsz),
            padding: EdgeInsets.all(fontsz / 2),
            width: screenWidth,
            height: fontsz * 6,
            decoration: BoxDecoration(
              color: Colors.blue,
              //border: Border.all(width: 1, color: Colors.white),
              borderRadius: BorderRadius.circular(fontsz * 0.8),
              //boxShadow: [BoxShadow(color: Colors.grey, blurRadius: fontsz)]
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  children: [
                    Image.asset(
                      'assets/data/daxuexi.png',
                      fit: BoxFit.cover,
                      height: fontsz * 3,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "\"形式主义\"大学习截图",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: fontsz * 1.1),
                        ),
                        Text(
                          "(第${urls.length}期)",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: fontsz * 0.7),
                        ),
                      ],
                    ),
                    Text(
                      " 生成青年大学习完成页面,用于仅收集截图的班级\n(无后台记录)",
                      style: TextStyle(
                          height: 1.15,
                          color: const Color.fromARGB(255, 237, 236, 236),
                          fontSize: fontsz * 0.75),
                    ),
                    GestureDetector(
                        onTap: () async {
                          List data = [];
                          try {
                            data.add("2023年第${urls.length}期");
                            data.add(
                                "https://h5.cyol.com/special/daxuexi/${extractIdFromUrl(urls[urls.length - 1])}/images/end.jpg");
                          } catch (e) {
                            data = await getdaxuexi();
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DaxuexiPage(
                                      data: data,
                                    )),
                          );
                        },
                        child: Container(
                            //alignment: Alignment.centerRight,
                            margin: EdgeInsets.only(left: screenWidth / 2),
                            width: fontsz * 4.5,
                            height: fontsz * 1.6,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(fontsz / 2)),
                            child: Center(
                              child: Text(
                                "点击生成",
                                //textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.blue, fontSize: fontsz * 0.8),
                              ),
                            )))
                  ],
                ),
              ],
            )),
        AnimatedContainer(
            clipBehavior: Clip.hardEdge,
            curve: Curves.easeInOutBack,
            margin: EdgeInsets.only(left: fontsz, right: fontsz),
            duration: const Duration(milliseconds: 700),
            height: isvacationExpanded ? fontsz * 20 : fontsz * 3,
            padding: EdgeInsets.only(left: fontsz * .7),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(fontsz),
                boxShadow: [
                  BoxShadow(
                      color: const Color.fromARGB(255, 236, 236, 236),
                      blurRadius: fontsz)
                ]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      "今日校园",
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: fontsz),
                    ),
                    Text(
                      "请假条生成",
                      style: TextStyle(color: Colors.blue, fontSize: fontsz),
                    ),
                    const Expanded(child: SizedBox()),
                    GestureDetector(
                      onTap: () {
                        if (!isvacationExpanded) {
                          _ChatExpandAnimaController.forward();
                        } else {
                          _ChatExpandAnimaController.reverse();
                        }
                        setState(() {
                          isvacationExpanded = !isvacationExpanded;
                        });
                      },
                      child: Container(
                          margin: EdgeInsets.all(fontsz / 2),
                          width: fontsz * 6,
                          height: fontsz * 2,
                          //padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(fontsz / 2),
                          ),
                          child: Center(
                              child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "编辑假条",
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: fontsz * 0.8,
                                    decoration: TextDecoration.none,
                                    color: Colors.blue),
                              ),
                              AnimatedBuilder(
                                  animation: _ChatExpandAnima,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                        angle: _ChatExpandAnima.value * -3.14,
                                        child: Icon(
                                          Icons.keyboard_arrow_up,
                                          size: fontsz * 1.5,
                                          color: const Color.fromARGB(
                                              255, 114, 114, 114),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "请假原因：",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: fontsz * 0.9,
                              decoration: TextDecoration.none,
                              color: Colors.black87),
                        ),
                        CustomTextField(controller: reasonController),
                        //TextField()
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "发起位置：",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: fontsz * 0.9,
                              decoration: TextDecoration.none,
                              color: Colors.black87),
                        ),
                        Row(
                          children: [
                            Radio<String>(
                              value: '1',
                              groupValue: selectedLocation,
                              onChanged: (String? value) {
                                setState(() {
                                  selectedLocation = value!;
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
                              groupValue: selectedLocation,
                              onChanged: (String? value) {
                                setState(() {
                                  selectedLocation = value!;
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
                              groupValue: selectedLocation,
                              onChanged: (String? value) {
                                setState(() {
                                  selectedLocation = value!;
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
                          "起始时间：",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: fontsz * 0.9,
                              decoration: TextDecoration.none,
                              color: Colors.black87),
                        ),
                        DateTimePickerButton(controller: startdatecontroller),
                        Text(
                          "  “请假开始时间”",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: fontsz * 0.8,
                              decoration: TextDecoration.none,
                              color: Colors.black26),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "结束时间：",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: fontsz * 0.9,
                              decoration: TextDecoration.none,
                              color: Colors.black87),
                        ),
                        DateTimePickerButton(controller: enddatecontroller),
                        Text(
                          "  “请假结束时间”",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: fontsz * 0.8,
                              decoration: TextDecoration.none,
                              color: Colors.black26),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "审核时间：",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: fontsz * 0.9,
                              decoration: TextDecoration.none,
                              color: Colors.black87),
                        ),
                        DateTimePickerButton(controller: checkdatecontroller),
                        Text(
                          "  “辅导员审核时间”",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: fontsz * 0.8,
                              decoration: TextDecoration.none,
                              color: Colors.black26),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "我叫：",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: fontsz * 0.9,
                              decoration: TextDecoration.none,
                              color: Colors.black87),
                        ),
                        SizedBox(
                          width: fontsz * 4,
                          child: CustomTextField(controller: myname),
                        ),
                        Text(
                          " 辅导员：",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: fontsz * 0.9,
                              decoration: TextDecoration.none,
                              color: Colors.black87),
                        ),
                        SizedBox(
                          width: fontsz * 4,
                          child: CustomTextField(controller: teacher),
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
                              color: !leave ? Colors.black87 : Colors.blue),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "请假类型：",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: fontsz * 0.9,
                              decoration: TextDecoration.none,
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
                                    builder: (context) => vacationPage(
                                        reason: reasonController.text,
                                        position: selectedLocation,
                                        StartDate: startdatecontroller.text,
                                        EndDate: enddatecontroller.text,
                                        CheckDate: checkdatecontroller.text,
                                        MyName: myname.text,
                                        Teacher: teacher.text,
                                        leave: leave,
                                        type: type.text)),
                              );
                            },
                            child: Container(
                                //alignment: Alignment.centerRight,
                                margin:
                                    EdgeInsets.only(left: screenWidth / 4.5),
                                width: fontsz * 4.5,
                                height: fontsz * 2,
                                decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius:
                                        BorderRadius.circular(fontsz * 0.7)),
                                child: Center(
                                  child: Text(
                                    "点击生成",
                                    //textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: fontsz * 0.8),
                                  ),
                                )))
                      ],
                    )
                  ],
                )),
              ],
            )),
      ],
    ));
  }
}

class DaxuexiPage extends StatelessWidget {
  List data;
  DaxuexiPage({
    required this.data,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    double statusBarHeight = mediaQueryData.padding.top;
    double screenWidth = mediaQueryData.size.width;
    double screenHeight = mediaQueryData.size.height;
    double fontsz = screenWidth * 0.045;
    return Scaffold(
        body: Column(
      children: [
        Container(
          padding: EdgeInsets.all(fontsz / 2),
          color: const Color.fromARGB(255, 218, 217, 217),
          width: screenWidth,
          height: statusBarHeight + fontsz * 2.5,
          child: Column(
            children: [
              SizedBox(
                height: statusBarHeight,
              ),
              //Expanded(child: SizedBox()),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.close,
                      size: fontsz * 1.5,
                    ),
                  ),
                  Expanded(
                      child: Center(
                    child: Text(
                      "“青年大学习”${data[0]}",
                      style: TextStyle(fontSize: fontsz * 1),
                    ),
                  )),
                  Icon(
                    Icons.more_horiz,
                    size: fontsz * 1.5,
                  )
                ],
              )
            ],
          ),
        ),
        Expanded(
            child: Image.network(
          data[1],
          fit: BoxFit.fill,
        ))
      ],
    ));
  }
}

class vacationPage extends StatefulWidget {
  String reason;
  String position;
  String StartDate;
  String EndDate;
  String CheckDate;
  String MyName;
  String Teacher;
  bool leave;
  String type;
  vacationPage(
      {required this.reason,
      required this.position,
      required this.StartDate,
      required this.EndDate,
      required this.CheckDate,
      required this.MyName,
      required this.Teacher,
      required this.leave,
      required this.type,
      super.key});
  @override
  State<vacationPage> createState() => _vacationState();
}

class _vacationState extends State<vacationPage> with TickerProviderStateMixin {
  //ture表示是AI的消息

  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _controller;

  late int hours, mins;
  late String totaltime;
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    // _controller = AnimationController(
    //   vsync: this,
    //   duration: const Duration(seconds: 3), // 动画持续时间为3秒
    // )..repeat(reverse: false); // 重复播放动画，只正向播放

    if (widget.StartDate != "" && widget.EndDate != "") {
      int days =
          (int.parse(widget.EndDate[3]) * 10 + int.parse(widget.EndDate[4])) -
              (int.parse(widget.StartDate[3]) * 10 +
                  int.parse(widget.StartDate[4]));

      hours =
          (int.parse(widget.EndDate[7]) * 10 + int.parse(widget.EndDate[8])) -
              (int.parse(widget.StartDate[7]) * 10 +
                  int.parse(widget.StartDate[8]));

      if (hours < 0) {
        hours = hours + 24;
        days -= 1;
        hours = hours + days * 24;
      }
      mins =
          (int.parse(widget.EndDate[10]) * 10 + int.parse(widget.EndDate[11])) -
              (int.parse(widget.StartDate[10]) * 10 +
                  int.parse(widget.StartDate[11]));
      if (mins < 0) {
        mins = mins + 60;
        hours -= 1;
      }
    } else {
      hours = 0;
      mins = 0;
    }
    // //页面进入动画
    // _animationController = AnimationController(
    //     vsync: this, duration: const Duration(milliseconds: 2000));
    // _animation =
    //     CurvedAnimation(parent: _animationController, curve: Curves.decelerate);
    // _animation = Tween<double>(
    //   begin: 0.0,
    //   end: 1.0,
    // ).animate(_animation);
    // _animationController.forward();
    // // 监听ListView滚动位置变化
  }

  @override
  void dispose() {
    //_animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    final double statusBarHeight = mediaQueryData.padding.top;
    final double screenWidth = mediaQueryData.size.width;
    final double screenHeight = mediaQueryData.size.height;
    final double ItemSize = screenWidth * 0.05;
    var keyboardSize = MediaQuery.of(context).viewInsets.bottom;
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
                          width: 1, color: Colors.grey.withOpacity(0.25)))),
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
                      //color: Colors.blue,
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
            //padding: EdgeInsets.all(2),
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
                    "如何销假？",
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
              //mainAxisAlignment: MainAxisAlignment.center,
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
                  child: AnimatedStrip(
                    color: Colors.white,
                    duration: Duration(milliseconds: 1000),
                    stripeHeight: 20,
                    // stripeWidth: ItemSize * 1.2,
                    // spaceBetween: ItemSize * 1.2,
                  ),
                )
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: ItemSize * 1.2, top: ItemSize * 0.7),
            child: Column(
              //mainAxisAlignment: MainAxisAlignment.start,
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
                      widget.type,
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
                      widget.leave ? "是" : "否",
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
                color: Colors.black.withOpacity(0.05),
                border: Border(
                    top: BorderSide(
                        width: 0.5, color: Colors.grey.withOpacity(0.2)),
                    bottom: BorderSide(
                        width: 0.5, color: Colors.grey.withOpacity(0.2)))),
          ),
          Container(
              padding: EdgeInsets.only(
                  left: ItemSize * 1.2,
                  right: ItemSize * 1.2,
                  top: ItemSize * 0.2,
                  bottom: ItemSize * 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "我的 请假申请",
                    style: TextStyle(
                        height: 1.8,
                        fontSize: ItemSize * 0.8,
                        color: Colors.black87),
                  ),
                  Row(
                    //crossAxisAlignment: CrossAxisAlignment.center,
                    //mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            //mainAxisAlignment: MainAxisAlignment.start,
                            //crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "开始时间：",
                                style: TextStyle(
                                    height: 1.6,
                                    fontSize: ItemSize * 0.7,
                                    color: Colors.black45),
                              ),
                              Text(
                                widget.StartDate,
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
                                widget.EndDate,
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
                            color: Colors.blue.withOpacity(0.1),
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
                      widget.reason,
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
                      widget.position == "1"
                          ? "湖北省武汉市蔡甸区连通路"
                          : (widget.position == "2"
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
                color: Colors.black.withOpacity(0.05),
                border: Border(
                    top: BorderSide(
                        width: 0.5, color: Colors.grey.withOpacity(0.2)),
                    bottom: BorderSide(
                        width: 0.5, color: Colors.grey.withOpacity(0.2)))),
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
                        "${widget.MyName} - 发起申请",
                        style: TextStyle(
                            height: 1.6,
                            fontSize: ItemSize * 0.7,
                            color: Colors.black54),
                      )),
                      Text(
                        widget.StartDate,
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
                            "一级：${widget.Teacher} - 审批",
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
                        widget.CheckDate,
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
                        // decoration: BoxDecoration(
                        //     border: Border.all(
                        //         width: 1.5,
                        //         color:
                        //             const Color.fromARGB(255, 108, 226, 112)),
                        //     borderRadius: BorderRadius.circular(ItemSize)),
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
                                      //height: 1.6,
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
                  color: Colors.black.withOpacity(0.05),
                  border: Border(
                      top: BorderSide(
                          width: 0.5, color: Colors.grey.withOpacity(0.2)),
                      bottom: BorderSide(
                          width: 0.5, color: Colors.grey.withOpacity(0.2)))),
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
          // Container(
          //   height: ItemSize,
          //   width: screenWidth,
          //   color: Colors.black.withOpacity(0.01),
          // ),
        ],
      ),
    );
  }
}
