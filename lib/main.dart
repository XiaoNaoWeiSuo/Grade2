// ignore_for_file: use_build_context_synchronously, must_be_immutable, library_private_types_in_public_api, prefer_typing_uninitialized_variables

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import "package:flutter/services.dart";

import 'package:path_provider/path_provider.dart';
import "package:roundcheckbox/roundcheckbox.dart";
import "package:flutter/material.dart";
import 'package:intl/intl.dart';
import 'dart:ui';
import "dart:io";
import 'package:install_plugin/install_plugin.dart';

import "login.dart";
import "topbar.dart";
import 'function.dart';
import 'tree/pages.dart';

List netdata = [];

String enterkey = "";
void main() async {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
  if (Platform.isAndroid) {
    SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
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
      home: LoginPage(CounterStorage(), true, true),
    );
  }
}

class LoginPage extends StatefulWidget {
  final CounterStorage ctrlFile;
  bool intostate;
  bool backlogin;
  LoginPage(this.ctrlFile, this.intostate, this.backlogin, {super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  String tip = "登录长江大学账号"; // 初始文本

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
  late int startYear;

  bool bukao = false;
  String tell = "...";
  // Adapt adapt = Adapt();
  //int updatepage = 0;
  PageController updatepagecheck = PageController();
  late AnimationController initailanime;
  late Animation<double> initialanimation;
  List<String> semesters = []; //学期列表
  String currentlogindate = "";
  @override
  void initState() {
    super.initState();

    initailanime = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..addStatusListener(
        (status) {},
      );
    initialanimation =
        CurvedAnimation(parent: initailanime, curve: Curves.easeOutCubic);
    initialanimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(initialanimation);
    initailanime.forward();

    gettext().then((value) {
      tell = value;
      setState(() {});
    });

    widget.ctrlFile.readCounter().then((value) {
      if (value.isEmpty) {
        widget.ctrlFile.writeCounter(initdata);
      } else {
        initdata = value;
        currentlogindate = initdata["goal"];
        if (widget.intostate) {
          _numController.text = initdata["initial"];

          datedisplay = true;
          startYear = int.parse(initdata["initial"].substring(0, 4));

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
        getversion().then((value) {
          getVersionapp().then((value2) async {
            bool result = isVersionGreaterThan(value, value2);
            if (result) {
              bool? isaswas = await showTextDialog(context, tell);
              if (autoLogin && widget.backlogin && isaswas != null && isaswas) {
                Loginact();
              } else if (isaswas != null && !isaswas) {
                updatepagecheck.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
                _startUpdate();
              }
            } else {
              if (autoLogin && widget.backlogin) {
                Loginact();
              }
            }
          });
        });
      }
      setState(() {});
    });
  }

  void disposed() {
    initailanime.dispose();
    super.dispose();
  }

  double _progressValue = 0.0;
  Future<void> _startUpdate() async {
    var appDocDir = await getTemporaryDirectory();
    String savePath = "${appDocDir.path}/new_version.apk";
    String fileUrl = "http://49.235.106.67/arm64-v8a.apk";

    await Dio().download(fileUrl, savePath, onReceiveProgress: (count, total) {
      setState(() {
        _progressValue = count / total;
      });
    });

    final res = await InstallPlugin.install(savePath);
    _showResMsg(
        "Install apk ${res['isSuccess'] == true ? 'success' : 'fail:${res['errorMessage'] ?? ''}'}");
    updatepagecheck.animateToPage(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    setState(() {
      _progressValue = 0.0;
    });
  }

  void _showResMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

//重置年份选择器
  void _editingyear() {
    setState(() {
      datedisplay = false;
    });
  }

  void _handleInputFinished(bool change) {
    final CounterStorage ctrlFile = CounterStorage();
    GestureDetector buildCustomItem(String option) {
      return GestureDetector(
        child: Container(
          decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(option.contains("上") ? 20 : 5),
                topRight: Radius.circular(option.contains("下") ? 20 : 5),
                bottomLeft: Radius.circular(option.contains("上") ? 20 : 5),
                bottomRight: Radius.circular(option.contains("下") ? 20 : 5),
              )),
          //height: 20,
          child: Center(
            child: Text(
              option,
              style: TextStyle(
                  color: Colors.black87.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 20),
            ),
          ),
        ),
        onTap: () {
          setState(() {
            currentlogindate = option;
            initdata["goal"] = option;
            ctrlFile.writeCounter(initdata);
          });
          // 处理选中选项的逻辑
          //
          //

          //  print('Selected: $option');
          Navigator.pop(context); // 关闭底部菜单
        },
      );
    }

    if (_numController.text != "" && isLongNumber(_numController.text)) {
      int year = int.parse(_numController.text.substring(0, 4));
      setState(() {
        if (isYearFormat(year)) {
          datedisplay = true;
          startYear = year;

          DateTime currentDate = DateTime.now(); // 获取当前日期时间
          int currentYear = currentDate.year; // 获取当前年份
          int currentMonth = currentDate.month; // 获取当前月份

          semesters = []; //学期列表重置
          for (int year = startYear; year <= currentYear; year++) {
            if (year == currentYear) {
              if (currentMonth >= 8) {
                // 当前月份在8月到12月之间，表示存在上学期
                semesters.add('$currentYear-${currentYear + 1} 上学期');
              }
            } else {
              semesters.add('$year-${year + 1} 上学期');
              semesters.add('$year-${year + 1} 下学期');
            }
          }
          ctrlFile.readCounter().then((value) {
            initdata = value;
            String currentedg;
            if (initdata["goal"] == "") {
              if (currentDate.month >= 1 && currentDate.month < 8) {
                // 如果当前月份在1月到7月之间，则认为是上学期
                currentedg = '$currentYear-${currentYear + 1} 上学期';
              } else {
                // 否则认为是下学期
                currentedg = '$currentYear-${currentYear + 1} 下学期';
              }
              initdata["goal"] = currentedg;
              setState(() {
                currentlogindate = currentedg;
              });
              // selectedOption = currentedg;
              ctrlFile.writeCounter(initdata);
              showModalBottomSheet(
                context: context,
                builder: (BuildContext builder) {
                  return SizedBox(
                    height: 300.0,
                    child: ListView.builder(
                      itemCount: semesters.length,
                      itemBuilder: (context, index) {
                        return buildCustomItem(semesters[index]);
                      },
                    ),
                  );
                },
              );
            } else {
              if (change) {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext builder) {
                    return Container(
                      padding: const EdgeInsets.only(
                          bottom: 20, top: 10, left: 10, right: 10),
                      height: 260.0,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 设置列数为2
                                crossAxisSpacing: 3.0, // 调整为较小的值
                                mainAxisSpacing: 5.0, // 调整为较小的值
                                mainAxisExtent: 50),
                        itemCount: semesters.length,
                        itemBuilder: (context, index) {
                          // return Container(
                          //   height: 10,
                          //   color: Colors.red,
                          // );
                          return buildCustomItem(semesters[index]);
                        },
                      ),
                    );
                  },
                );
              }
              // selectedOption = initdata["goal"];
            }
          });
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
        netdata = await iTing.Login(account, password);
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
                "登录时间${getCurrentTime()}", false, account);
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
      startYear = int.parse(index.substring(0, 4));
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
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned(
                //top: screenWidth,
                child: FractionallySizedBox(
                    widthFactor: 2, // 宽度因子大于1，超出屏幕宽度

                    heightFactor: 1,
                    child: AnimatedBuilder(
                        animation: initialanimation,
                        builder: (context, child) {
                          return SizedBox(
                              height: screenHeight,
                              child: Container(
                                color: const Color.fromARGB(255, 204, 220, 221),
                                child: Image.asset(
                                  "assets/data/icon.png",
                                  height: screenHeight,
                                ),
                                // child: Column(
                                //   //mainAxisAlignment: MainAxisAlignment.center,
                                //   children: [
                                //     SizedBox(
                                //       height: screenHeight * 0.35,
                                //     ),
                                //     CircularProgressBar(
                                //       progress: 1.0,
                                //       radius: screenWidth,
                                //       startAngle: 90 - 25 * initialanimation.value,
                                //       endAngle: 90 + 25 * initialanimation.value,
                                //       strokeWidth: fontsz,
                                //       // beginCapRadius: fontsz,
                                //       // endCapRadius: fontsz,
                                //     )
                                //   ],
                                // ),
                              ));
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
                            height: statusBarHeight,
                            //color: Colors.white,
                            // child: Text("账号列"),
                          ),
                          const Text(
                            "账号列表-Account List",
                            style: TextStyle(color: Colors.blue),
                          ),
                          Container(
                            //margin: EdgeInsets.all(fontsz),
                            width: screenWidth * 0.8,
                            height: screenHeight * 0.055,
                            decoration: const BoxDecoration(
                              //color: Color.fromARGB(0, 198, 198, 198),
                              border: Border(
                                  top: BorderSide(
                                      width: 2, color: Colors.white)),
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
                                    onTap: () => chioselogin(initdata["content"]
                                        .keys
                                        .toList()[index]),
                                    child: Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              255, 244, 255, 235),
                                          // border: Border.all(
                                          //     width: 1, color: Colors.white),
                                          borderRadius:
                                              BorderRadius.circular(5)),
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
                          Row(
                            children: [
                              AnimatedBuilder(
                                  animation: initialanimation,
                                  builder: (context, child) {
                                    return ClipRect(
                                        child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 25.0, sigmaY: 25.0),
                                            child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200
                                                      .withOpacity(0.8),
                                                  borderRadius:
                                                      BorderRadius.only(
                                                          bottomRight:
                                                              Radius.circular(
                                                                  fontsz * 2),
                                                          topRight:
                                                              Radius.circular(
                                                                  fontsz * 2)),
                                                ),
                                                //clipBehavior: Clip.hardEdge,
                                                alignment: Alignment.topLeft,
                                                margin: EdgeInsets.only(
                                                    top: fontsz * 2),
                                                padding: EdgeInsets.all(fontsz),
                                                width: screenWidth *
                                                    0.85 *
                                                    initialanimation.value,
                                                height: screenHeight * 0.5,
                                                child: PageView(
                                                  controller: updatepagecheck,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  children: [
                                                    Column(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Align(
                                                              alignment: Alignment
                                                                  .centerLeft,
                                                              child: Text(
                                                                tip,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      fontsz *
                                                                          1.2,
                                                                  color: Colors
                                                                      .blue,
                                                                ),
                                                              ),
                                                            ),
                                                            const Expanded(
                                                                child:
                                                                    SizedBox()),
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
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          controller:
                                                              _numController,
                                                          onEditingComplete:
                                                              () {
                                                            _handleInputFinished(
                                                                false);
                                                          },
                                                          onTap: _editingyear,
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.7),
                                                              fontSize: 28,
                                                              fontFamily:
                                                                  "Consolas"),
                                                          decoration: InputDecoration(
                                                              label: Text(
                                                                "学号",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        fontsz),
                                                              ),
                                                              helperText: "account"
                                                              // contentPadding:
                                                              //     EdgeInsets.all(fontsz / 2),
                                                              //filled: true,
                                                              // fillColor:
                                                              //     Color.fromARGB(91, 155, 39, 176), // 背景颜色
                                                              // hintText:
                                                              //     'Enter account', // 提示文本
                                                              // hintStyle: const TextStyle(
                                                              //     color:
                                                              //         Colors.white), // 提示文本颜色
                                                              // border: OutlineInputBorder(
                                                              //   // borderSide:
                                                              //   //     const BorderSide(width: 2), // 边框颜色和宽度
                                                              //   borderRadius:
                                                              //       BorderRadius.circular(
                                                              //           10.0), // 边框圆角
                                                              // ),
                                                              ),
                                                        ),
                                                        SizedBox(
                                                          height: fontsz,
                                                        ),
                                                        TextField(
                                                          obscureText:
                                                              _isObscure,
                                                          obscuringCharacter:
                                                              "◍",
                                                          controller:
                                                              _pwdController,
                                                          onTap: () {
                                                            _handleInputFinished(
                                                                false);
                                                          },
                                                          style: TextStyle(
                                                            // fontWeight: FontWeight.w600,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.7),
                                                            fontSize: 26,
                                                          ),
                                                          decoration: InputDecoration(
                                                              label: Text(
                                                                "密码",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        fontsz),
                                                              ),
                                                              helperText: "password",
                                                              // contentPadding:
                                                              //     EdgeInsets.all(
                                                              //         fontsz / 2),
                                                              // filled: true,
                                                              // fillColor: const Color.fromARGB(
                                                              //     95, 129, 129, 129), // 背景颜色

                                                              // hintText:
                                                              //     'Enter password', // 提示文本
                                                              // hintStyle: const TextStyle(
                                                              //     color: Color.fromARGB(
                                                              //         255,
                                                              //         87,
                                                              //         87,
                                                              //         87)), // 提示文本颜色
                                                              // border: OutlineInputBorder(
                                                              //   // borderSide: const BorderSide(
                                                              //   //     color: Colors.white,
                                                              //   //     width: 3.0), // 边框颜色和宽度
                                                              //   borderRadius:
                                                              //       BorderRadius.circular(
                                                              //           10.0), // 边框圆角
                                                              // ),
                                                              suffixIcon: IconButton(
                                                                  icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                                                                  onPressed: () {
                                                                    setState(
                                                                        () {
                                                                      _isObscure =
                                                                          !_isObscure;
                                                                    });
                                                                  })),
                                                        ),
                                                        SizedBox(
                                                          height: screenHeight *
                                                              0.03,
                                                        ),
                                                        Row(
                                                          children: [
                                                            Column(
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    RoundCheckBox(
                                                                        size: fontsz *
                                                                            1.5,
                                                                        checkedWidget:
                                                                            Icon(
                                                                          Icons
                                                                              .check,
                                                                          color:
                                                                              Colors.white,
                                                                          size:
                                                                              fontsz,
                                                                        ),
                                                                        checkedColor:
                                                                            Colors
                                                                                .blue,
                                                                        uncheckedColor:
                                                                            Colors
                                                                                .transparent,
                                                                        border: Border.all(
                                                                            color: Colors
                                                                                .white,
                                                                            width:
                                                                                3),
                                                                        isChecked:
                                                                            autoLogin,
                                                                        onTap:
                                                                            (selected) {
                                                                          autoLogin =
                                                                              !autoLogin;

                                                                          setState(
                                                                              () {});
                                                                        }),
                                                                    SizedBox(
                                                                      width:
                                                                          fontsz /
                                                                              2,
                                                                    ),
                                                                    Text(
                                                                      "自动登录",
                                                                      style: TextStyle(
                                                                          fontSize: fontsz *
                                                                              0.9,
                                                                          color: autoLogin
                                                                              ? Colors.blue
                                                                              : const Color.fromARGB(120, 39, 64, 176)),
                                                                    )
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  height:
                                                                      fontsz /
                                                                          3,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    RoundCheckBox(
                                                                        size: fontsz *
                                                                            1.5,
                                                                        checkedWidget:
                                                                            Icon(
                                                                          Icons
                                                                              .check,
                                                                          color:
                                                                              Colors.white,
                                                                          size:
                                                                              fontsz,
                                                                        ),
                                                                        checkedColor:
                                                                            Colors
                                                                                .blue,
                                                                        uncheckedColor:
                                                                            Colors
                                                                                .transparent,
                                                                        border: Border.all(
                                                                            color: Colors
                                                                                .white,
                                                                            width:
                                                                                3),
                                                                        isChecked:
                                                                            rememberPassword,
                                                                        onTap:
                                                                            (selected) {
                                                                          rememberPassword =
                                                                              !rememberPassword;
                                                                          setState(
                                                                              () {});
                                                                        }),
                                                                    SizedBox(
                                                                      width:
                                                                          fontsz /
                                                                              2,
                                                                    ),
                                                                    Text(
                                                                      "保存账号",
                                                                      style: TextStyle(
                                                                          fontSize: fontsz *
                                                                              0.9,
                                                                          color: rememberPassword
                                                                              ? Colors.blue
                                                                              : const Color.fromARGB(120, 39, 64, 176)),
                                                                    )
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  height:
                                                                      fontsz /
                                                                          3,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    RoundCheckBox(
                                                                        size: fontsz *
                                                                            1.5,
                                                                        checkedWidget:
                                                                            Icon(
                                                                          Icons
                                                                              .check,
                                                                          color:
                                                                              Colors.white,
                                                                          size:
                                                                              fontsz,
                                                                        ),
                                                                        checkedColor:
                                                                            Colors
                                                                                .blue,
                                                                        uncheckedColor:
                                                                            Colors
                                                                                .transparent,
                                                                        border: Border.all(
                                                                            color: Colors
                                                                                .white,
                                                                            width:
                                                                                3),
                                                                        isChecked:
                                                                            bukao,
                                                                        onTap:
                                                                            (selected) {
                                                                          bukao =
                                                                              !bukao;
                                                                          setState(
                                                                              () {});
                                                                        }),
                                                                    SizedBox(
                                                                      width:
                                                                          fontsz /
                                                                              2,
                                                                    ),
                                                                    Text(
                                                                      "查看补考",
                                                                      style: TextStyle(
                                                                          fontSize: fontsz *
                                                                              0.9,
                                                                          color: bukao
                                                                              ? Colors.blue
                                                                              : const Color.fromARGB(120, 39, 64, 176)),
                                                                    )
                                                                  ],
                                                                )
                                                              ],
                                                            ),
                                                            Expanded(
                                                                child: Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            10),
                                                                    child: TextButton(
                                                                        onPressed: () async {
                                                                          await Loginact();
                                                                        },
                                                                        child: state == false
                                                                            ? Text(
                                                                                "登录",
                                                                                style: TextStyle(
                                                                                  color: Colors.blue,
                                                                                  fontSize: fontsz * 1.8,
                                                                                ),
                                                                              )
                                                                            : loadanimation(
                                                                                radius: fontsz * 3,
                                                                              ))))
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      children: [
                                                        const Text(
                                                          "更新(Update)",
                                                          style: TextStyle(
                                                              fontSize: 20),
                                                        ),
                                                        SizedBox(
                                                          height: fontsz * 3,
                                                        ),
                                                        Text(
                                                          "${(_progressValue * 100).toStringAsFixed(1)}%",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 75,
                                                                  color: Colors
                                                                      .blue),
                                                        ),
                                                        SizedBox(
                                                          height: fontsz,
                                                        ),
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          child:
                                                              LinearProgressIndicator(
                                                            minHeight: 10,
                                                            value:
                                                                _progressValue,
                                                          ),
                                                        ),
                                                        const Expanded(
                                                            child: SizedBox()),
                                                        const Text(
                                                          "你的更新，就是对grade开发者最大的认可。",
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .black45),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                ))));
                                  })
                            ],
                          ),
                          AnimatedBuilder(
                            animation: initialanimation,
                            builder: (context, child) {
                              return SizedBox(
                                height: fontsz * 5 -
                                    fontsz * 4 * initialanimation.value,
                              );
                            },
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                                child: Container(
                                    width: screenWidth * 0.65,
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade200
                                            .withOpacity(0.9)),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: Center(
                                          child: Text(
                                            currentlogindate,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black54,
                                                fontSize: 20),
                                          ),
                                        )),
                                        TextButton(
                                            onPressed: () {
                                              _handleInputFinished(true);
                                            },
                                            child: const Text(
                                              "选择学期",
                                              style: TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 16),
                                            ))
                                      ],
                                    ))),
                          ),
                          const Expanded(child: SizedBox()),
                          Container(
                            margin: EdgeInsets.only(bottom: fontsz),
                            child: const Text(
                              "#Grade2 | @XiaoNaoWeiSuo | 2024",
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                          // ClipRRect(
                          //     borderRadius: BorderRadius.circular(15),
                          //     child: BackdropFilter(
                          //         filter: ImageFilter.blur(
                          //             sigmaX: 5.0, sigmaY: 5.0),
                          //         child: Container(
                          //             width: screenWidth * 0.65,
                          //             decoration: BoxDecoration(
                          //                 color: Colors.grey.shade200
                          //                     .withOpacity(0.9)),
                          //             child: Text("wawawaw"))))
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
  Color dateColor = const Color.fromARGB(255, 0, 0, 0);
  Color timeColor = const Color.fromARGB(255, 2, 32, 45);
  Color bgColor = const Color.fromARGB(255, 171, 232, 255).withOpacity(0.6);
  Map initdata = {};
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
    load();
    formattedDate = DateFormat('M/d').format(currentDate);
    _ChatLoadAnimaController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    _ChatLoadAnima = CurvedAnimation(
        parent: _ChatLoadAnimaController, curve: Curves.bounceOut);
    _ChatLoadAnima =
        Tween<double>(begin: 0.0, end: 1.0).animate(_ChatLoadAnima);
    _ChatLoadAnimaController.forward();

    DateTime startDate = DateTime.now().isAfter(DateTime(2024, 2, 26))
        ? DateTime(2024, 2, 26)
        : DateTime(2023, 8, 28);
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
    //debugPrint(currentWeek.toString());

    //当时间间隔超过表格周数时，会出现严重的索引溢出bug,导致grade2软件崩溃
    if (currentWeek > widget.schedule.length) {
      currentscdule = extractColumnData(
          widget.schedule[widget.schedule.length - 1],
          7,
          getCurrentDayOfWeek());
    } else {
      currentscdule = extractColumnData(
          widget.schedule[currentWeek - 1], 7, getCurrentDayOfWeek());
    }
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
          return LoginPage(CounterStorage(), true, false);
        },
      ),
    );
  }

  void addaccount() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return LoginPage(CounterStorage(), false, false);
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
                              clipBehavior: Clip.hardEdge,
                              height: screenHeight,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(fontsz)),
                              //color: Colors.white,
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
                                  //公告栏
                                  animation: _ChatLoadAnima,
                                  builder: (context, child) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          //margin: EdgeInsets.only(top: 0),
                                          width: screenWidth /
                                              1.9 *
                                              _ChatLoadAnima.value,
                                          // height: fontsz * 2,
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
                                                  fontSize: fontsz * 0.75,
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
                                                  height: fontsz * 3,
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
                  Column(
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
                                color: bgColor,
                                // gradient: const LinearGradient(colors: [
                                //   Colors.blue,
                                //   Color.fromARGB(255, 114, 167, 233)
                                // ], begin: Alignment.bottomCenter),
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
                                              color: Colors.grey,
                                              margin: EdgeInsets.only(
                                                  top: 2,
                                                  bottom: 2,
                                                  left: fontsz,
                                                  right: fontsz),
                                            );
                                          } else {
                                            return Container(
                                                margin: const EdgeInsets.all(2),
                                                // decoration: BoxDecoration(
                                                //     color: Colors.white,
                                                //     borderRadius:
                                                //         BorderRadius.circular(
                                                //             fontsz / 4)),
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
                                                          color: Colors.black54,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                      currentscdule[index]
                                                          .coursePeriod,
                                                      style: TextStyle(
                                                          color: Colors.black87,
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
                            child: MediaQuery.removePadding(
                              context: context,
                              removeTop: true,
                              child: ListView.builder(
                                //scrollDirection: Axis.horizontal, // 设置横向滚动
                                itemCount: widget.userlist["content"].length,
                                itemBuilder: (BuildContext context, int index) {
                                  return GestureDetector(
                                    onLongPress: () {
                                      //删除账号
                                      setState(() {
                                        HapticFeedback.lightImpact();
                                        deleteAsk = true;
                                        currentdelete = widget
                                            .userlist["content"].keys
                                            .toList()[index];
                                      });
                                    },
                                    onTap: () => backlogin(widget
                                        .userlist["content"].keys
                                        .toList()[index]),
                                    child: Container(
                                      margin:
                                          EdgeInsets.only(bottom: fontsz / 4),
                                      //width: fontsz,
                                      // padding: EdgeInsets.all(fontsz * 0.1),
                                      decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: fontsz / 2),
                                          ],
                                          color: deleteAsk
                                              ? widget.userlist["content"].keys
                                                          .toList()[index] ==
                                                      currentdelete
                                                  ? Colors.red
                                                  : Colors.white
                                              : Colors.white,
                                          borderRadius: BorderRadius.only(
                                              topLeft:
                                                  Radius.circular(fontsz / 4),
                                              bottomLeft:
                                                  Radius.circular(fontsz / 4))),
                                      // width: 45,
                                      //margin: const EdgeInsets.only(top: 5),
                                      child: Text(
                                        '${widget.userlist["content"].keys.toList()[index]}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          //fontFamily: "Roboto",
                                          color: Colors.blue,
                                          fontSize: fontsz * 0.9,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
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
                                padding: EdgeInsets.only(left: fontsz / 2),
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
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(fontsz),
                                        bottomLeft: const Radius.circular(10)),
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
                                        campus: widget.topdata[0].department,
                                        code: widget.topdata[0].studentId);
                                  },
                                ));
                              },
                              child: Container(
                                width: screenWidth / 4,
                                padding: EdgeInsets.only(left: fontsz / 2),
                                margin: EdgeInsets.only(
                                  top: fontsz / 3,
                                  //left: fontsz / 3,
                                ),
                                decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: fontsz / 2)
                                    ],
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        bottomLeft: Radius.circular(10)),
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
                                width: screenWidth / 4,
                                padding: EdgeInsets.only(left: fontsz / 2),
                                margin: EdgeInsets.only(
                                  top: fontsz / 3,
                                  //left: fontsz / 3,
                                ),
                                decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: fontsz / 2)
                                    ],
                                    borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(10),
                                        bottomLeft: Radius.circular(fontsz)),
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
                        )
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

                                  widget.userlist["content"]
                                      .remove(currentdelete);
                                  datalist["content"].remove(currentdelete);
                                  ctrlFile.writeCounter(datalist);
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
    return PopScope(
        // 禁用返回按钮
        canPop: false,
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
  List passstate = ["1", "1", "1"];
  List evaluate = [];
  bool teensource = false;

  late List<Map> selectcourselist = [{}];
  @override
  void initState() {
    super.initState();
    try {
      getpass().then((value) {
        passstate = value;
        setState(() {});
      });
      _ChatExpandAnimaController = AnimationController(
          duration: const Duration(milliseconds: 600), vsync: this);
      _ChatExpandAnima = CurvedAnimation(
          parent: _ChatExpandAnimaController, curve: Curves.easeOutBack);
      _ChatExpandAnima =
          Tween<double>(begin: 0.0, end: 1.0).animate(_ChatExpandAnima);
      TeenStudy().then((value) {
        urls = value;
        setState(() {});
      });
      SelectCourse().GetSelectList(netdata[0]).then((value) {
        selectcourselist = value;
        setState(() {});
      });
    } catch (e) {
      Null;
    }
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
        Expanded(
            child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: ListView(
                  children: [
                    Container(
                        margin: EdgeInsets.all(fontsz),
                        padding: EdgeInsets.all(fontsz / 2),
                        //width: screenWidth,
                        height: fontsz * 6,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          //border: Border.all(width: 1, color: Colors.white),
                          borderRadius: BorderRadius.circular(fontsz * 0.8),
                          //boxShadow: [BoxShadow(color: Colors.grey, blurRadius: fontsz)]
                        ),
                        child: Stack(
                          children: [
                            Row(
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
                                              fontSize: fontsz),
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
                                      " 生成青年大学习完成页面,用于仅收集\n截图的班级(无后台记录)",
                                      style: TextStyle(
                                          height: 1.1,
                                          color: const Color.fromARGB(
                                              255, 237, 236, 236),
                                          fontSize: fontsz * 0.75),
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: fontsz,
                                          height: fontsz,
                                          child: Checkbox(
                                            checkColor: Colors.orange,
                                            value: teensource,
                                            onChanged: (value) {
                                              setState(() {
                                                teensource = !teensource;
                                              });
                                            },
                                          ),
                                        ),
                                        Text(
                                          "  备用源",
                                          //textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: fontsz * 0.8),
                                        ),
                                        //const Expanded(child: SizedBox()),
                                        GestureDetector(
                                            onTap: () async {
                                              List data = [];
                                              if (!teensource) {
                                                data.add(
                                                    "2023年第${urls.length}期");
                                                data.add(
                                                    "https://h5.cyol.com/special/daxuexi/${extractIdFromUrl(urls[urls.length - 1])}/images/end.jpg");
                                              } else {
                                                data = await getdaxuexi();
                                              }
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        DaxuexiPage(
                                                          data: data,
                                                        )),
                                              );
                                            },
                                            child: Container(
                                                //alignment: Alignment.centerRight,
                                                margin: EdgeInsets.only(
                                                    left: screenWidth / 4),
                                                width: fontsz * 4.5,
                                                height: fontsz * 1.6,
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            fontsz / 2)),
                                                child: Center(
                                                  child: Text(
                                                    "点击生成",
                                                    //textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: Colors.blue,
                                                        fontSize: fontsz * 0.8),
                                                  ),
                                                )))
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                            passstate[0] == "0"
                                ? Container(
                                    width: screenWidth,
                                    height: fontsz * 6,
                                    decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius:
                                            BorderRadius.circular(fontsz / 2)),
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
                    AnimatedContainer(
                        clipBehavior: Clip.hardEdge,
                        curve: Curves.bounceOut,
                        margin: EdgeInsets.only(left: fontsz, right: fontsz),
                        duration: const Duration(milliseconds: 900),
                        height: isvacationExpanded ? fontsz * 20 : fontsz * 3,
                        //padding: EdgeInsets.only(left: fontsz * .7),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(fontsz),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      const Color.fromARGB(255, 236, 236, 236),
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
                                          color: Colors.blue, fontSize: fontsz),
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
                                          isvacationExpanded =
                                              !isvacationExpanded;
                                        });
                                      },
                                      child: Container(
                                          margin: EdgeInsets.all(fontsz / 2),
                                          width: fontsz * 6,
                                          height: fontsz * 2,
                                          //padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(
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
                                                    fontSize: fontsz * 0.8,
                                                    decoration:
                                                        TextDecoration.none,
                                                    color: Colors.blue),
                                              ),
                                              AnimatedBuilder(
                                                  animation: _ChatExpandAnima,
                                                  builder: (context, child) {
                                                    return Transform.rotate(
                                                        angle: _ChatExpandAnima
                                                                .value *
                                                            -3.14,
                                                        child: Icon(
                                                          Icons
                                                              .keyboard_arrow_up,
                                                          size: fontsz * 1.5,
                                                          color: const Color
                                                              .fromARGB(255,
                                                              114, 114, 114),
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
                                              fontWeight: FontWeight.normal,
                                              fontSize: fontsz * 0.9,
                                              decoration: TextDecoration.none,
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
                                          "    起始时间：",
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: fontsz * 0.9,
                                              decoration: TextDecoration.none,
                                              color: Colors.black87),
                                        ),
                                        DateTimePickerButton(
                                            controller: startdatecontroller),
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
                                          "    结束时间：",
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: fontsz * 0.9,
                                              decoration: TextDecoration.none,
                                              color: Colors.black87),
                                        ),
                                        DateTimePickerButton(
                                            controller: enddatecontroller),
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
                                          "    审核时间：",
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: fontsz * 0.9,
                                              decoration: TextDecoration.none,
                                              color: Colors.black87),
                                        ),
                                        DateTimePickerButton(
                                            controller: checkdatecontroller),
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
                                          "    我叫：",
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: fontsz * 0.9,
                                              decoration: TextDecoration.none,
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
                                              fontWeight: FontWeight.normal,
                                              fontSize: fontsz * 0.9,
                                              decoration: TextDecoration.none,
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
                                                        reason: reasonController
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
                                                        MyName: myname.text,
                                                        Teacher: teacher.text,
                                                        leave: leave,
                                                        type: type.text)),
                                              );
                                            },
                                            child: Container(
                                                //alignment: Alignment.centerRight,
                                                margin: EdgeInsets.only(
                                                    left: screenWidth / 4.5),
                                                width: fontsz * 4.5,
                                                height: fontsz * 2,
                                                decoration: BoxDecoration(
                                                    color: Colors.blue,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            fontsz * 0.7)),
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
                            ),
                            passstate[1] == "0"
                                ? Container(
                                    clipBehavior: Clip.hardEdge,
                                    height: isvacationExpanded
                                        ? fontsz * 20
                                        : fontsz * 3,
                                    width: screenWidth - fontsz * 2,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
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
                      // width: screenWidth,
                      //height: fontsz * 3,
                      child: Stack(children: [
                        GestureDetector(
                          onTap: () async {
                            Requests functico = Requests();
                            try {
                              evaluate = await functico.GetEvaluate(netdata[0]);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return EvaluatePage(
                                      evaluatedata: evaluate,
                                    );
                                  },
                                ),
                              );
                            } catch (e) {
                              Null;
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
                                  borderRadius: BorderRadius.circular(fontsz)),
                              child: const Center(
                                child: Text(
                                  "快 捷 量 化 评 教",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                              )),

                          //,const Expanded(child: SizedBox())
                        ),
                        passstate[2] == "0"
                            ? Container(
                                margin: EdgeInsets.all(fontsz),
                                padding: EdgeInsets.all(fontsz / 4),
                                width: screenWidth,
                                height: fontsz * 3,
                                decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
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
                    // SizedBox(
                    //   // width: screenWidth,
                    //   //height: fontsz * 3,
                    //   child: Stack(children: [
                    //     Container(
                    //         margin:
                    //             EdgeInsets.only(left: fontsz, right: fontsz),
                    //         padding: EdgeInsets.only(
                    //             left: fontsz / 2,
                    //             right: fontsz / 2,
                    //             top: fontsz / 2),
                    //         //  width: screenWidth,
                    //         height: selectcourselist.isNotEmpty
                    //             ? selectcourselist.length * fontsz * 4 -
                    //                 fontsz / 2
                    //             : fontsz * 3,
                    //         decoration: BoxDecoration(
                    //             color: Colors.blue,
                    //             borderRadius: BorderRadius.circular(fontsz)),
                    //         child: selectcourselist.isNotEmpty
                    //             ? MediaQuery.removePadding(
                    //                 context: context,
                    //                 removeTop: true,
                    //                 child: ListView.builder(
                    //                   itemCount: selectcourselist.length,
                    //                   itemBuilder: (context, index) {
                    //                     return Container(
                    //                         margin: EdgeInsets.only(
                    //                             bottom: fontsz / 2),
                    //                         height: fontsz * 3,
                    //                         decoration: BoxDecoration(
                    //                             color: Colors.white,
                    //                             borderRadius:
                    //                                 BorderRadius.circular(
                    //                                     fontsz / 2)),
                    //                         child: Row(
                    //                           children: [
                    //                             Expanded(
                    //                               child: Center(
                    //                                 child: Text(
                    //                                   selectcourselist[index]
                    //                                           ["title"]
                    //                                       .toString(),
                    //                                   //selectcourselist.toString(),
                    //                                   style: const TextStyle(
                    //                                       fontSize: 20,
                    //                                       fontWeight:
                    //                                           FontWeight.w600),
                    //                                 ),
                    //                               ),
                    //                             ),
                    //                             TextButton(
                    //                                 onPressed: () {},
                    //                                 child: const Text(
                    //                                   "开选",
                    //                                   style: TextStyle(
                    //                                       fontSize: 18),
                    //                                 ))
                    //                           ],
                    //                         ));
                    //                   },
                    //                 ))
                    //             : const Center(
                    //                 child: Text(
                    //                   "=====================",
                    //                   style: TextStyle(
                    //                       color: Colors.white, fontSize: 20),
                    //                 ),
                    //               )),

                    //     //,const Expanded(child: SizedBox())

                    //     Container()
                    //   ]),
                    // ),
                    Center(
                      child: SizedBox(
                          width: screenWidth * 0.8,
                          height: screenWidth * 0.4,
                          // decoration:
                          //     const BoxDecoration(color: Color.fromARGB(31, 123, 123, 123)),
                          child: Column(
                            children: [
                              Text(
                                "一些功能的解释",
                                style: TextStyle(
                                    fontSize: fontsz * 0.65,
                                    color: Colors.grey),
                              ),
                              Text(
                                "备用源：当Teen大学习与当前最新期不匹配时，可尝试使用备用源生成",
                                style: TextStyle(
                                    fontSize: fontsz * 0.65,
                                    color: Colors.grey),
                              ),
                              Text(
                                "功能暂时关闭：由于功能敏感性等原因而导致功能暂时性停用",
                                style: TextStyle(
                                    fontSize: fontsz * 0.65,
                                    color: Colors.grey),
                              ),
                              Text(
                                "关于“一键差评”：Grade2一直是为爱发电的状态,此功能可能会导致学校的反对,此举不利于grade2的生存",
                                style: TextStyle(
                                    fontSize: fontsz * 0.65,
                                    color: Colors.grey),
                              ),
                              Text(
                                "大家有好的创意功能想法可以与我联系或反馈\nVX:xiaonaoweisuo003",
                                style: TextStyle(
                                    fontSize: fontsz * 0.65,
                                    color: Colors.green),
                              ),
                            ],
                          )),
                    )
                  ],
                )))
      ],
    ));
  }
}

class EvaluatePage extends StatefulWidget {
  List evaluatedata;
  EvaluatePage({super.key, required this.evaluatedata});
  @override
  State<EvaluatePage> createState() => _EvaluatePageState();
}

class _EvaluatePageState extends State<EvaluatePage> {
  @override
  Widget build(BuildContext context) {
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
                  for (int index = 0;
                      index < widget.evaluatedata.length;
                      index++) {
                    if (!widget.evaluatedata[index].state) {
                      Requests functico = Requests();
                      //await _showConfirmationDialog(context);
                      await functico.GetSEvaluatePush(
                          netdata[0],
                          enterkey,
                          widget.evaluatedata[index].id,
                          widget.evaluatedata[index].type);
                      widget.evaluatedata =
                          await functico.GetEvaluate(netdata[0]);
                      setState(() {});
                    }
                  }
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
            itemCount: widget.evaluatedata.length,
            itemBuilder: (context, index) {
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
                          "${widget.evaluatedata[index].course}",
                          style: const TextStyle(
                              color: Colors.black, fontSize: 15),
                        ),
                        Row(
                          children: [
                            Text(
                              "${widget.evaluatedata[index].type}",
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 12),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              "${widget.evaluatedata[index].name}",
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 12),
                            ),
                          ],
                        )
                      ],
                    ),
                    const Expanded(child: SizedBox()),
                    widget.evaluatedata[index].state
                        ? Container(
                            margin: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.check,
                              color: Colors.blue,
                            ),
                          )
                        : TextButton(
                            onPressed: () async {
                              Requests functico = Requests();
                              bool? result = await showConfirmationDialog(
                                  context, "确认提交为全部非常满意？");
                              if (result != null && result) {
                                await functico.GetSEvaluatePush(
                                    netdata[0],
                                    enterkey,
                                    widget.evaluatedata[index].id,
                                    widget.evaluatedata[index].type);
                                widget.evaluatedata =
                                    await functico.GetEvaluate(netdata[0]);
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
