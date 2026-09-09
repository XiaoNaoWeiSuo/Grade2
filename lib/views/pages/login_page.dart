// 来源：lib/main.dart LoginPage（L260-1331）。MVVM 迁移第二批：
// UI（登录表单/账号列表/更新 PageView/入场动画）逐行保留，数据访问点替换：
// data.json 读写 → accountBookProvider；登录流程 → loginControllerProvider；
// 超时离线恢复 → offlineRestoreProvider；版本检查/更新 → aboutProvider；
// 每日一句 → ServerApi.getDailyWord；学期 → currentSemesterProvider。

import 'dart:async';
import 'dart:ui' show ImageFilter;

import "package:flutter/material.dart";
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import "package:roundcheckbox/roundcheckbox.dart";

import '../../core/network/server_api.dart';
import '../../core/utils/version_utils.dart';
import '../../viewmodels/about_provider.dart';
import '../../viewmodels/academic_provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/offline_provider.dart';
import '../../viewmodels/session_provider.dart';
import '../../views/widgets/dialogs.dart';
import '../../views/widgets/loading_animation.dart';
import 'main_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  final bool intostate;
  final bool backlogin;
  const LoginPage({super.key, required this.intostate, required this.backlogin});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  String tip = "登录长江大学账号"; // 初始文本
  bool state = false;
  bool autoLogin = false;
  bool rememberPassword = false;
  bool _isObscure = true;
  final TextEditingController _numController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  bool datedisplay = false;
  late int startYear;

  bool bukao = false;
  String tell = "...";
  //int updatepage = 0;
  PageController updatepagecheck = PageController();
  late AnimationController initailanime;
  late Animation<double> initialanimation;
  List<String> semesters = []; //学期列表
  String currentlogindate = "";
  bool loginstate = false;
  @override
  void initState() {
    super.initState();
    initailanime = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..addStatusListener(
        (status) {},
      );
    initialanimation =
        CurvedAnimation(parent: initailanime, curve: Curves.easeInOutExpo);
    initialanimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(initialanimation);
    initailanime.forward();
    ServerApi.getDailyWord().then((value) {
      tell = value;
      setState(() {});
    });

    _initAccountBook();
  }

  // 旧 initState 中读 data.json 的初始化（L315-362）
  Future<void> _initAccountBook() async {
    await ref.read(accountBookProvider.notifier).load();
    final Map<String, dynamic> initdata = ref.read(accountBookProvider);
    if (initdata["initial"] == "" && (initdata["content"] as Map).isEmpty) {
      // 文件为空：load() 已按旧逻辑写入初始结构，跳过版本检查
    } else {
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
        ref.read(currentSemesterProvider.notifier).state =
            initdata["content"][initdata["initial"]][2];
        bukao = initdata["content"][initdata["initial"]][3] == "true"
            ? true
            : false;
      }
      final bool result = await ref.read(aboutProvider.notifier).checkUpdate();
      if (result) {
        if (!mounted) return;
        bool? isaswas = await showTextDialog(context, tell);
        if (autoLogin && widget.backlogin && isaswas != null && isaswas) {
          _startLogin();
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
          _startLogin();
        }
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  void disposed() {
    initailanime.dispose();
    super.dispose();
  }

  Future<void> _startUpdate() async {
    final String res =
        await ref.read(aboutProvider.notifier).downloadAndInstallApk();
    if (!mounted) return;
    _showResMsg(res);
    updatepagecheck.animateToPage(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    setState(() {});
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
                  color: Colors.black87.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 20),
            ),
          ),
        ),
        onTap: () {
          setState(() {
            currentlogindate = option;
          });
          ref.read(accountBookProvider.notifier).setGoal(option);
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
          final Map<String, dynamic> initdata = ref.read(accountBookProvider);
          String currentedg;
          if (initdata["goal"] == "") {
            if (currentDate.month >= 1 && currentDate.month < 8) {
              // 如果当前月份在1月到7月之间，则认为是上学期
              currentedg = '$currentYear-${currentYear + 1} 上学期';
            } else {
              // 否则认为是下学期
              currentedg = '$currentYear-${currentYear + 1} 下学期';
            }
            ref.read(accountBookProvider.notifier).setGoal(currentedg);
            setState(() {
              currentlogindate = currentedg;
            });
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
        }
      });
    }
  }

  Future<void> _handleTimeout() async {
    if (!loginstate) {
      await Future.delayed(const Duration(milliseconds: 1000));
      final OfflineResult restore =
          await ref.read(offlineRestoreProvider).restore();
      if (restore.status == OfflineStatus.noAccount) {
        setState(() {
          Fluttertoast.showToast(
              msg: "您尚未登录过，请等待教务系统开放",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              fontSize: 16.0);
        });
      } else if (restore.status == OfflineStatus.ok) {
        setState(() {
          Fluttertoast.showToast(
              msg: "登录超时，切换离线模式",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              fontSize: 16.0);
        });
        ref.read(academicProvider.notifier).set(restore.data!);
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const MainPage();
            },
          ),
        );
      } else {
        setState(() {
          Fluttertoast.showToast(
              msg: "离线数据错误",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              fontSize: 16.0);
        });
      }
    } else {
      setState(() {
        Fluttertoast.showToast(
            msg: "在线模式",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
            fontSize: 16.0);
      });
    }
  }

  Future<void> _startLogin() async {
    String account = _numController.text;
    String password = _pwdController.text;

    const duration = Duration(seconds: 5); // 定义定时器的时间间隔
    Timer(duration, _handleTimeout);
    if (account != "" && password != "") {
      setState(() {
        tip = "正在尝试登陆";
        state = true;
        loginstate = false;
      });
      try {
        final outcome = await ref.read(loginControllerProvider).login(
              account: account,
              password: password,
              autoLogin: autoLogin,
              rememberPassword: rememberPassword,
              bukao: bukao,
            );
        if (outcome.wrongPassword) {
          _pwdController.clear();
          setState(() {
            tip = "账号或密码错误";
            state = false;
          });
        } else if (outcome.success) {
          loginstate = true;
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const MainPage();
              },
            ),
          );
        }
      } catch (e) {
        // 网络异常静默吞掉（旧行为：未处理异常后挂起等超时）
      }
    } else {
      setState(() {
        tip = "账号或密码为空";
      });
    }
  }

  void chioselogin(index) {
    final Map<String, dynamic> initdata = ref.read(accountBookProvider);
    setState(() {
      _numController.text = index;
      _pwdController.text = initdata["content"][index][0];
      datedisplay = true;
      startYear = int.parse(index.substring(0, 4));
      ref.read(currentSemesterProvider.notifier).state =
          initdata["content"][index][2];
      rememberPassword = true;
      autoLogin =
          initdata["content"][index][1] == "true" ? true : false;
      bukao = initdata["content"][index][3] == "true" ? true : false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> initdata = ref.watch(accountBookProvider);
    final double progressValue = ref.watch(aboutProvider).downloadProgress;
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
                    child: SizedBox(
                        height: screenHeight,
                        child: Container(
                          color: const Color.fromARGB(255, 204, 220, 221),
                          child: Image.asset(
                            "assets/data/icon.png",
                            height: screenHeight,
                          ),
                        )))),
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
                                    return Transform.translate(
                                        offset: Offset(
                                            -120 + 120 * initialanimation.value,
                                            0),
                                        child: Opacity(
                                            opacity:
                                                0.2 * initialanimation.value +
                                                    0.8,
                                            child: ClipRect(
                                                child: BackdropFilter(
                                                    filter: ImageFilter.blur(
                                                        sigmaX: 25.0,
                                                        sigmaY: 25.0),
                                                    child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .grey.shade200
                                                              .withValues(
                                                                  alpha: 0.8),
                                                          borderRadius: BorderRadius.only(
                                                              bottomRight: Radius
                                                                  .circular(
                                                                      fontsz *
                                                                          2),
                                                              topRight: Radius
                                                                  .circular(
                                                                      fontsz *
                                                                          2)),
                                                        ),
                                                        alignment:
                                                            Alignment.topLeft,
                                                        margin: EdgeInsets.only(
                                                            top: fontsz * 2),
                                                        padding: EdgeInsets.all(
                                                            fontsz),
                                                        width:
                                                            screenWidth * 0.85,
                                                        height:
                                                            screenHeight * 0.5,
                                                        child: PageView(
                                                          controller:
                                                              updatepagecheck,
                                                          physics:
                                                              const NeverScrollableScrollPhysics(),
                                                          children: [
                                                            Column(
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child:
                                                                          Text(
                                                                        tip,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              fontsz * 1.2,
                                                                          color:
                                                                              Colors.blue,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const Expanded(
                                                                        child:
                                                                            SizedBox()),
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  height:
                                                                      fontsz,
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
                                                                  onTap:
                                                                      _editingyear,
                                                                  style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: Colors
                                                                          .black
                                                                          .withValues(
                                                                              alpha:
                                                                                  0.7),
                                                                      fontSize:
                                                                          28,
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
                                                                // SizedBox(
                                                                //   height: fontsz,
                                                                // ),
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
                                                                  style:
                                                                      TextStyle(
                                                                    // fontWeight: FontWeight.w600,
                                                                    color: Colors
                                                                        .black
                                                                        .withValues(
                                                                            alpha:
                                                                                0.7),
                                                                    fontSize:
                                                                        20,
                                                                  ),
                                                                  decoration: InputDecoration(
                                                                      label: Text(
                                                                        "密码",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                fontsz),
                                                                      ),
                                                                      helperText: "password",
                                                                      suffixIcon: IconButton(
                                                                          icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                                                                          onPressed: () {
                                                                            setState(() {
                                                                              _isObscure = !_isObscure;
                                                                            });
                                                                          })),
                                                                ),
                                                                SizedBox(
                                                                  height:
                                                                      screenHeight *
                                                                          0.03,
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
                                                                                checkedColor: Colors.blue,
                                                                                uncheckedColor: Colors.transparent,
                                                                                border: Border.all(color: Colors.white, width: 3),
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
                                                                              style: TextStyle(fontSize: fontsz * 0.9, color: autoLogin ? Colors.blue : const Color.fromARGB(120, 39, 64, 176)),
                                                                            )
                                                                          ],
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              fontsz / 3,
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
                                                                                checkedColor: Colors.blue,
                                                                                uncheckedColor: Colors.transparent,
                                                                                border: Border.all(color: Colors.white, width: 3),
                                                                                isChecked: rememberPassword,
                                                                                onTap: (selected) {
                                                                                  rememberPassword = !rememberPassword;
                                                                                  setState(() {});
                                                                                }),
                                                                            SizedBox(
                                                                              width: fontsz / 2,
                                                                            ),
                                                                            Text(
                                                                              "保存账号",
                                                                              style: TextStyle(fontSize: fontsz * 0.9, color: rememberPassword ? Colors.blue : const Color.fromARGB(120, 39, 64, 176)),
                                                                            )
                                                                          ],
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              fontsz / 3,
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
                                                                                checkedColor: Colors.blue,
                                                                                uncheckedColor: Colors.transparent,
                                                                                border: Border.all(color: Colors.white, width: 3),
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
                                                                              style: TextStyle(fontSize: fontsz * 0.9, color: bukao ? Colors.blue : const Color.fromARGB(120, 39, 64, 176)),
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
                                                                                  await _startLogin();
                                                                                },
                                                                                child: state == false
                                                                                    ? Text(
                                                                                        "登录",
                                                                                        style: TextStyle(
                                                                                          color: Colors.blue,
                                                                                          fontSize: fontsz * 1.8,
                                                                                        ),
                                                                                      )
                                                                                    : LoadingAnimation(
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
                                                                      fontSize:
                                                                          20),
                                                                ),
                                                                SizedBox(
                                                                  height:
                                                                      fontsz *
                                                                          3,
                                                                ),
                                                                Text(
                                                                  "${(progressValue * 100).toStringAsFixed(1)}%",
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          75,
                                                                      color: Colors
                                                                          .blue),
                                                                ),
                                                                SizedBox(
                                                                  height:
                                                                      fontsz,
                                                                ),
                                                                ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10),
                                                                  child:
                                                                      LinearProgressIndicator(
                                                                    minHeight:
                                                                        10,
                                                                    value:
                                                                        progressValue,
                                                                  ),
                                                                ),
                                                                const Expanded(
                                                                    child:
                                                                        SizedBox()),
                                                                const Text(
                                                                  "你的更新，就是对grade开发者最大的认可。",
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .black45),
                                                                ),
                                                              ],
                                                            )
                                                          ],
                                                        ))))));
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
                                    width: screenWidth * 0.7,
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade200
                                            .withValues(alpha: 0.9)),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: Center(
                                          child: Text(
                                            currentlogindate,
                                            maxLines: 1,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black54,
                                                fontSize: 18),
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
                          //                     .withValues(alpha: 0.9)),
                          //             child: Text("wawawaw"))))
                        ],
                      ),
                    ))),
          ],
        ));
  }
}
