// 迁移自 lib/tree/pages.dart：AutherPage（L532-1013，改名 AboutPage，无构造参数）。
// 数据访问点替换：
// - 版本号/更新日志：aboutProvider（checkUpdate + loadUpdateLog），替代旧的手写版本
//   请求与本地版本比较；版本号显示用 remoteVersion/localVersion。
// - APK 下载安装：aboutProvider.downloadAndInstallApk() + downloadProgress，
//   SnackBar 显示返回消息。
// - 在线模式开关：accountBookProvider 的 data.json setting 键（ON/OFF）。
// - 反馈邮件：aboutProvider.sendFeedback(...)，name/campus 从 academicProvider
//   取当前学生，无登录数据时回退旧 const 调用点的占位值，account 沿用旧调用传空串。
// - 彩蛋跳转改为 LovePage。
// UI（布局/颜色/文本）逐行保持不变；已删除旧代码中声明未使用的
// updateurl/apkUrl/downloadMessage/dio 字段与注释掉的废弃弹窗代码。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../viewmodels/about_provider.dart';
import '../../viewmodels/academic_provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../widgets/shared_ui.dart';
import 'love_page.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  TextEditingController advicecontrol = TextEditingController();
  final Uri url = Uri.parse('https://github.com/XiaoNaoWeiSuo/Grade2');
  bool isonline = false;
  bool _updateDone = false;
  int caculatelove = 0;

  @override
  void initState() {
    super.initState();
    ref.read(aboutProvider.notifier).checkUpdate();
    ref.read(aboutProvider.notifier).loadUpdateLog();
    _loadOnlineState();
  }

  /// 旧 initState 读文件同步在线模式开关（先 load 再读 setting）
  Future<void> _loadOnlineState() async {
    await ref.read(accountBookProvider.notifier).load();
    if (mounted) {
      setState(() {
        isonline = ref.read(accountBookProvider)["setting"] == "ON";
      });
    }
  }

  Future<void> _launchUrl() async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _startUpdate() async {
    setState(() {
      _updateDone = false;
    });
    final String message =
        await ref.read(aboutProvider.notifier).downloadAndInstallApk();
    _showResMsg(message);
    setState(() {
      _updateDone = true; // 安装流程结束后进度归零，重新显示"同步更新"按钮
    });
  }

  void _showResMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    double statusBarHeight = mediaQueryData.padding.top;
    double screenWidth = mediaQueryData.size.width;
    double fontsz = screenWidth * 0.045;
    final about = ref.watch(aboutProvider);
    // 旧 load() 的 logtext/logdate 处理（source[1]/source[0]），
    // 远端日志未返回或失败时保持空白显示（不崩溃）
    final List<dynamic> source = about.updateLog;
    final String logtext = source.length > 1 ? "${source[1]}" : "";
    final String logdate = source.isNotEmpty ? "${source[0]}" : "";
    final double progressValue = _updateDone ? 0.0 : about.downloadProgress;
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          title: Row(
            children: [
              const Text("关于"),
              const Expanded(child: SizedBox()),
              GestureDetector(
                onTap: _launchUrl,
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      const Text(
                        "开源仓库  ",
                        style: TextStyle(fontSize: 15, color: Colors.black45),
                      ),
                      Icon(
                        const IconData(0xe85a, fontFamily: "GradeIcon"),
                        color: Colors.black,
                        size: fontsz * 1.5,
                      )
                    ],
                  ),
                ),
              ),
            ],
          )),
      body: SingleChildScrollView(
          child: Padding(
        padding: EdgeInsets.symmetric(horizontal: statusBarHeight / 2),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      border: Border.all(
                        color: Colors.blueAccent,
                      ),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10))),
                  child: const Text(
                    "我是开发者",
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                  ),
                )
              ],
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  border: Border.all(
                    color: Colors.blueAccent,
                  ),
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                      topRight: Radius.circular(15))),
              child: Row(
                children: [
                  Container(
                    clipBehavior: Clip.hardEdge,
                    width: screenWidth / 6,
                    height: screenWidth / 6,
                    decoration: BoxDecoration(
                        color: Colors.lightBlueAccent,
                        borderRadius: BorderRadius.circular(screenWidth / 3)),
                    child: Image.asset(
                      'assets/data/profile.jpg',
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "小 脑 萎 缩",
                        style: TextStyle(fontSize: fontsz, color: Colors.white),
                      ),
                      Text(
                        "3517${caculatelove}49357",
                        style: TextStyle(
                            fontSize: fontsz / 1.5, color: Colors.black),
                      ),
                      Text(
                        "\"悟已往之不谏知来者之可追\"",
                        style: TextStyle(
                            fontSize: fontsz / 1.5, color: Colors.black54),
                      ),
                    ],
                  ),
                  const Expanded(child: SizedBox()),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        caculatelove += 1;
                      });
                    },
                    onLongPress: () {
                      if (caculatelove == 430) {
                        Navigator.push(context, SizeTransitionRe(LovePage()));
                      }
                    },
                    child: const Icon(
                      Icons.tag_faces,
                      size: 60,
                      color: Colors.black12,
                    ),
                  )
                ],
              ),
            ),
            Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5),
                        bottomLeft: Radius.circular(15),
                        topRight: Radius.circular(5),
                        bottomRight: Radius.circular(15))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                        controller: advicecontrol,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          hintText: "点击编辑你的建议或反馈",
                          hintStyle: TextStyle(color: Colors.black87),
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Row(
                        children: [
                          const Expanded(
                              child: Center(
                            child: Text(
                              "Grade有哪些设计不合理之处或bug?",
                              style: TextStyle(color: Colors.black54),
                            ),
                          )),
                          GestureDetector(
                            onTap: () {
                              if (advicecontrol.text != "") {
                                final academic = ref.read(academicProvider);
                                final String name =
                                    academic != null && academic.students.isNotEmpty
                                        ? academic.students[0].name
                                        : "关于跳转";
                                final String campus =
                                    academic != null && academic.students.isNotEmpty
                                        ? academic.students[0].department
                                        : "none";
                                ref.read(aboutProvider.notifier).sendFeedback(
                                    name: name,
                                    campus: campus,
                                    content: advicecontrol.text,
                                    account: "");
                                const snackBar = SnackBar(
                                  content: Text('发送成功'), // 显示的消息文本
                                  duration: Duration(seconds: 2), // 持续时间，单位为秒
                                );
                                if (advicecontrol.text == "2022007915") {
                                  const snackBar = SnackBar(
                                    content: Text('恶心的骗子'), // 显示的消息文本
                                    duration: Duration(seconds: 2), // 持续时间，单位为秒
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                }
                                if (advicecontrol.text == "2022008048") {
                                  Fluttertoast.showToast(
                                      msg: "噢，这是我未来的女朋友",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                      timeInSecForIosWeb: 3,
                                      backgroundColor: Colors.blue,
                                      textColor: Colors.white,
                                      fontSize: 16.0);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                }
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
                              } else {
                                const snackBar = SnackBar(
                                  content: Text('内容不能为空'), // 显示的消息文本
                                  duration: Duration(seconds: 2), // 持续时间，单位为秒
                                );
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
                              }
                            },
                            child: Container(
                                width: fontsz * 4,
                                height: fontsz * 2,
                                padding: const EdgeInsets.all(2),
                                child: Center(
                                  child: Text(
                                    "发送反馈",
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: fontsz * 0.8,
                                        decoration: TextDecoration.none,
                                        color: Colors.blue),
                                  ),
                                )),
                          ),
                        ],
                      )
                    ])),
            Container(
              margin: const EdgeInsets.only(bottom: 3),
              height: fontsz * 3,
              padding: EdgeInsets.only(left: fontsz, right: fontsz),
              decoration: const BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(15), bottom: Radius.circular(5))),
              child: Row(
                children: [
                  const Text(
                    "在线模式(Online Mode)",
                    style: TextStyle(
                        color: Colors.black54,
                        height: 2,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                  const Expanded(child: SizedBox()),
                  Switch(
                      value: isonline,
                      onChanged: (value) {
                        setState(() {
                          isonline = value;
                        });
                        ref.read(accountBookProvider.notifier).setOnlineMode(value);
                        debugPrint(ref.read(accountBookProvider).toString());
                      })
                ],
              ),
            ),
            Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(5), bottom: Radius.circular(15)),
                    color: Color.fromARGB(255, 202, 238, 228)),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: fontsz / 2),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5)),
                          child: Text(
                            " 最新版本:  ${about.remoteVersion}",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: fontsz,
                                decoration: TextDecoration.none,
                                color: Colors.green),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5)),
                          child: Text(
                            " 当前版本:  ${about.localVersion}",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: fontsz,
                                decoration: TextDecoration.none,
                                color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const Expanded(child: SizedBox()),
                    progressValue == 0
                        ? GestureDetector(
                            onTap: _startUpdate,
                            child: Container(
                                width: fontsz * 5,
                                height: fontsz * 2,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.05),
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
                                value: progressValue,
                              ),
                              SizedBox(
                                width: statusBarHeight / 2,
                              )
                            ],
                          )
                  ],
                )),

            Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.only(left: 3),
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
          ],
        ),
      )),
    );
  }
}
