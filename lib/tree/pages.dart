// ignore_for_file: library_private_types_in_public_api, must_be_immutable, camel_case_types

import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:install_plugin/install_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roundcheckbox/roundcheckbox.dart';
import 'package:url_launcher/url_launcher.dart';

import '../function.dart';
import '../login.dart';
import '../topbar.dart';

class MyImagePicker extends StatefulWidget {
  final CounterStorage appsetting = CounterStorage(filename: "setting.json");

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

  Color dateColor = const Color.fromARGB(255, 0, 0, 0);
  Color timeColor = const Color.fromARGB(255, 2, 32, 45);
  Color bgColor = const Color.fromARGB(255, 171, 232, 255).withOpacity(0.6);
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
                            height: screenHeight / 5,
                            width: screenWidth * 0.9,
                            //clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(fontsz)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(fontsz),
                              // borderRadius: BorderRadius.only(
                              //     topRight: Radius.circular(fontsz),
                              //     topLeft: Radius.circular(fontsz)),
                              //使图片模糊区域仅在子组件区域中
                              child: BackdropFilter(
                                //背景过滤器
                                filter: ImageFilter.blur(
                                    sigmaX: 25.0, sigmaY: 25.0), //设置图片模糊度
                                child: Container(
                                  height: screenHeight,
                                  width: screenWidth,
                                  color: Colors.grey.shade200.withOpacity(0.8),
                                ),
                              ),
                            ),
                          )
                        : Container()),
                Column(
                  children: [
                    Text(
                      "课程表背景",
                      style: TextStyle(
                          fontSize: fontsz,
                          color: Colors.white,
                          shadows: const [
                            BoxShadow(color: Colors.black, blurRadius: 20)
                          ]),
                    ),
                    SizedBox(
                      width: screenWidth * 0.9,
                      height: screenHeight / 9,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: fontsz,
                        ),
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
                          onTap: (selected) {
                            isUse = !isUse;
                            Imagepath = "";
                            initdata["classimage"] = Imagepath;
                            initdata["blur"] = blur.toString();
                            widget.appsetting.writeCounter(initdata);
                            setState(() {});
                          },
                          isChecked: isUse,
                        ),
                        Text("  启用背景  ",
                            style: TextStyle(
                                fontSize: fontsz * 0.9,
                                color: Colors.white,
                                shadows: const [
                                  BoxShadow(color: Colors.black, blurRadius: 20)
                                ])),
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
                          onTap: (selected) {
                            _blurchange();
                          },
                          isChecked: blur,
                        ),
                        Text(
                          "  亚克力遮罩  ",
                          style: TextStyle(
                              fontSize: fontsz * 0.9,
                              color: Colors.white,
                              shadows: const [
                                BoxShadow(color: Colors.black, blurRadius: 20)
                              ]),
                        ),
                        const Expanded(child: SizedBox()),
                        TextButton(
                          // style: ButtonStyle(
                          //     backgroundColor:
                          //         MaterialStatePropertyAll(Colors.amber)),
                          onPressed: _pickImage,
                          child: Text(
                            '选择图片',
                            style: TextStyle(
                                fontSize: fontsz * 0.9,
                                color: const Color.fromARGB(255, 183, 219, 247),
                                shadows: const [
                                  BoxShadow(color: Colors.black, blurRadius: 10)
                                ]),
                          ),
                        ),
                        SizedBox(
                          width: fontsz,
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
            //SizedBox(height: fontsz / 2),
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
                              border: Border.all(color: Colors.white, width: 3),
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
                              border: Border.all(color: Colors.white, width: 3),
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
                              border: Border.all(color: Colors.white, width: 3),
                              color: bgColor,
                              borderRadius: BorderRadius.circular(fontsz * 2)),
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: fontsz),
              padding: EdgeInsets.symmetric(
                  vertical: fontsz / 2, horizontal: fontsz),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(fontsz),
                  border: Border.all(color: Colors.black54, width: 5)),
              child: Column(children: [
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
                  child: const Row(
                    children: [
                      Expanded(
                          child: Align(
                        alignment: Alignment.topCenter,
                        child: Text("区分色"),
                      )),
                      Expanded(
                          child: Align(
                        alignment: Alignment.topCenter,
                        child: Text("亚克力白"),
                      ))
                    ],
                  ),
                )
              ]),
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
  const AutherPage(
      {super.key,
      required this.name,
      required this.campus,
      required this.code});

  @override
  _Auther createState() => _Auther();
}

class _Auther extends State<AutherPage> {
  TextEditingController advicecontrol = TextEditingController();
  final Uri url = Uri.parse('https://github.com/XiaoNaoWeiSuo/Grade2');
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
    super.initState();
    load();
  }

  Future<void> _launchUrl() async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
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
    double fontsz = screenWidth * 0.045;
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          title: Row(
            children: [
              const Text("关于"),
              const Expanded(child: SizedBox()),
              const Text(
                "开源仓库",
                style: TextStyle(fontSize: 15, color: Colors.black45),
              ),
              IconButton(
                  onPressed: _launchUrl,
                  icon: Icon(
                    const IconData(0xe85a, fontFamily: "GradeIcon"),
                    color: Colors.black,
                    size: fontsz * 1.5,
                  ))
            ],
          )),
      body: SingleChildScrollView(
          child: Padding(
        padding: EdgeInsets.all(statusBarHeight / 2),
        child: Column(
          children: [
            Container(
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color: Colors.yellow[800], // 选择黄金色
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
                        style: TextStyle(fontSize: fontsz, color: Colors.white),
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
                        style: TextStyle(fontSize: fontsz, color: Colors.white),
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
                  border:
                      Border.all(width: 2, color: Colors.blue.withOpacity(0.5)),
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
                    hintText: " 编辑问题反馈或功能建议",
                  ),
                ),
              ),
            ),

            GestureDetector(
              onTap: () {
                if (advicecontrol.text != "") {
                  SenMail(
                      widget.name, widget.campus, advicecontrol.text, true, "");
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
      )),
    );
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
  late int hours, mins;
  late String totaltime;
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
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
                  child: const AnimatedStrip(
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

class HomoPage extends StatefulWidget {
  final List listdata;
  final List otherdata;
  final List topdata;
  final List allgradelist;
  const HomoPage(
      {super.key,
      required this.listdata,
      required this.otherdata,
      required this.topdata,
      required this.allgradelist});
  @override
  State<StatefulWidget> createState() => HomoPageState();
}

class HomoPageState extends State<HomoPage> with TickerProviderStateMixin {
  List<bool> datalist = [];
  int pubulicsession = 0;
  int pravitesession = 0;
  int othersession = 0;
  late AnimationController initailanime;
  late Animation<double> initialanimation;
  bool isexpanded = false;
  PageController homopagectl = PageController();
  int basepage = 0;
  @override
  void initState() {
    super.initState();
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

    if (widget.otherdata.length == 0) {
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
    for (var item in widget.allgradelist[1]) {
      switch (item.courseType) {
        case "必修":
          pravitesession += 1;
          break;
        case "选修":
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
    for (var num in widget.listdata) {
      if (num.isPassed == "是") {
        datalist.add(true);
      } else {
        datalist.add(false);
      }
    }
    for (int a = 0; a < widget.otherdata.length; a++) {
      if (widget.otherdata[a].courseType == "公选") {
        pubulicsession += 1;
      } else if (widget.otherdata[a].courseType == "必修") {
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
    final screenHeight = mediaQueryData.size.height;
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
                        // Align(
                        //   alignment: Alignment.center,
                        //   child: Container(
                        //     margin: EdgeInsets.all(fontsz / 3),
                        //     padding: EdgeInsets.all(fontsz / 3),
                        //     decoration: const BoxDecoration(
                        //         borderRadius: BorderRadius.all(Radius.circular(30))),
                        //     child: Column(
                        //       children: [
                        //         Row(
                        //           children: [
                        //             Container(
                        //               margin:
                        //                   const EdgeInsets.only(left: 5, right: 5),
                        //               width: 4,
                        //               height: fontsz * 2,
                        //               decoration: BoxDecoration(
                        //                   color: Colors.blue,
                        //                   borderRadius: BorderRadius.circular(5)),
                        //             ),
                        //             Column(
                        //               crossAxisAlignment: CrossAxisAlignment.start,
                        //               children: [
                        //                 Text(
                        //                   widget.topdata[0].name,
                        //                   style: TextStyle(
                        //                       fontSize: fontsz,
                        //                       fontWeight: FontWeight.bold,
                        //                       color: Colors.blue),
                        //                   textAlign: TextAlign.left,
                        //                 ),
                        //                 Text(
                        //                   widget.topdata[0].department,
                        //                   style: TextStyle(
                        //                       fontWeight: FontWeight.normal,
                        //                       fontSize: fontsz * 0.7,
                        //                       color: Colors.blue),
                        //                 )
                        //               ],
                        //             ),
                        //             // Row(
                        //             //   children: [
                        //             //     widgetshow(
                        //             //       name: "GPA",
                        //             //       value: widget.topdata[0].gpa,
                        //             //       fill: 10,
                        //             //       size: fontsz,
                        //             //     ),
                        //             //     widgetshow(
                        //             //       name: "Credits",
                        //             //       value: widget.topdata[0].earnedCredits,
                        //             //       fill: widget.topdata[0].requiredCredits,
                        //             //       size: fontsz,
                        //             //     )
                        //             //   ],
                        //             // ),
                        //           ],
                        //         ),
                        //         // Text(
                        //         //   "培养计划预览",
                        //         //   style: TextStyle(
                        //         //       color: Colors.blue, fontSize: fontsz * 0.8),
                        //         // ),
                        //         // ContributionGraph(
                        //         //   activityData: datalist,
                        //         //   size: fontsz / 10,
                        //         // ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        SizedBox(
                            height: fontsz * 6,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.2,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                          height: fontsz * 2,
                                          child: const Center(
                                              child: Text(
                                            "门        数",
                                            style: TextStyle(
                                                color: Colors.black54),
                                          ))),
                                      SizedBox(
                                          height: fontsz * 2,
                                          child: const Center(
                                              child: Text(
                                            "总  学  分",
                                            style: TextStyle(
                                                color: Colors.black54),
                                          ))),
                                      SizedBox(
                                          height: fontsz * 2,
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
                                    if (widget.allgradelist[0].length > index) {
                                      return Container(
                                        // margin: EdgeInsets.only(
                                        //     left: initailanime.value),
                                        // // padding: EdgeInsets.all(1),
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
                                                height: fontsz * 2,
                                                child: Center(
                                                    child: Text(
                                                        "${widget.allgradelist[0][index].number}"))),
                                            SizedBox(
                                                height: fontsz * 2,
                                                child: Center(
                                                    child: Text(
                                                        "${widget.allgradelist[0][index].totalgrade}"))),
                                            SizedBox(
                                                height: fontsz * 2,
                                                child: Center(
                                                    child: Text(
                                                        "${widget.allgradelist[0][index].averangegrade}"))),
                                          ],
                                        ),
                                      );
                                    } else {
                                      return Container(
                                        //padding: EdgeInsets.all(1),
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
                          // padding: EdgeInsets.all(5),
                          margin: const EdgeInsets.all(5),
                          height: fontsz * 2,
                          //width: screenWidth * 0.7,
                          // decoration: const BoxDecoration(
                          //     color: Colors.blue,
                          //     borderRadius: BorderRadius.only(
                          //         topLeft: Radius.circular(8),
                          //         topRight: Radius.circular(8))),
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
                                      Text(
                                        "公选:$pubulicsession  |  ",
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      // SizedBox(
                                      //   width: fontsz,
                                      // ),
                                      Text(
                                        "必修:$pravitesession  |  ",
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      // SizedBox(
                                      //   width: fontsz,
                                      // ),
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
                                        color: Colors.black.withOpacity(0.1)),
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
                            child: Container(
                                decoration: const BoxDecoration(
                                    border: Border(
                                        top: BorderSide(
                                            width: 3, color: Colors.blue))),
                                // width: screenWidth * 0.95,
                                // height: screenHeight * 0.5,
                                child: PageView(
                                  controller: homopagectl,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    widget.otherdata.length == 0
                                        ? Column(
                                            children: [
                                              SizedBox(
                                                height: fontsz * 3,
                                              ),
                                              SizedBox(
                                                height: screenWidth * 0.6,
                                                width: screenWidth,
                                                child: Image.asset(
                                                    'assets/data/icon.png'),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
                                                        255, 194, 194, 194),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            fontsz / 4)),
                                                child: Text(
                                                  "本学期暂无考试成绩",
                                                  style: TextStyle(
                                                      fontSize: fontsz,
                                                      color: Colors.white,
                                                      height: 1),
                                                ),
                                              )
                                            ],
                                          )
                                        : SubjectCreditsList(
                                            courseList: widget.otherdata,
                                            size: fontsz,
                                          ),
                                    MediaQuery.removePadding(
                                        context: context,
                                        removeTop: true,
                                        child: Scrollbar(
                                          child: ListView.builder(
                                            itemCount:
                                                widget.allgradelist[1].length,
                                            itemBuilder: (context, index) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.all(3),
                                                margin:
                                                    const EdgeInsets.fromLTRB(
                                                        5, 5, 5, 0),
                                                decoration: const BoxDecoration(
                                                    //color: Colors.white,
                                                    border: Border(
                                                        bottom: BorderSide(
                                                            width: 1,
                                                            color: Colors
                                                                .black12))),
                                                height: fontsz * 3,
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: screenWidth * 0.6,
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                widget
                                                                    .allgradelist[
                                                                        1]
                                                                        [index]
                                                                    .courseName,
                                                                maxLines: 1,
                                                                style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize:
                                                                        fontsz,
                                                                    color: Colors
                                                                        .black
                                                                        .withOpacity(
                                                                            0.7),
                                                                    height:
                                                                        1.2),
                                                              ),
                                                            ],
                                                          ),
                                                          const Expanded(
                                                              child:
                                                                  SizedBox()),
                                                          Row(
                                                            children: [
                                                              Text("类别:",
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .black54,
                                                                      fontSize:
                                                                          fontsz *
                                                                              0.7,
                                                                      height:
                                                                          1)),
                                                              Text(
                                                                  "${widget.allgradelist[1][index].courseType}",
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          fontsz *
                                                                              0.7,
                                                                      height:
                                                                          1)),
                                                              Text(
                                                                "  序号:",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black54,
                                                                    fontSize:
                                                                        fontsz *
                                                                            0.7,
                                                                    height: 1),
                                                              ),
                                                              Text(
                                                                "${widget.allgradelist[1][index].courseNum}",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        fontsz *
                                                                            0.7,
                                                                    height: 1),
                                                              ),
                                                              Text(
                                                                "  绩点:",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black54,
                                                                    fontSize:
                                                                        fontsz *
                                                                            0.7,
                                                                    height: 1),
                                                              ),
                                                              Text(
                                                                " ${widget.allgradelist[1][index].gradePoint}",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .blue,
                                                                    fontSize:
                                                                        fontsz *
                                                                            0.9,
                                                                    height: 1),
                                                              )
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Column(
                                                          children: [
                                                            Row(
                                                              children: [
                                                                SizedBox(
                                                                  height:
                                                                      fontsz,
                                                                  child: Text(
                                                                    "  学分:",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black54,
                                                                        fontSize:
                                                                            fontsz *
                                                                                0.7,
                                                                        height:
                                                                            1),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height:
                                                                        fontsz,
                                                                    child: Text(
                                                                      " ${widget.allgradelist[1][index].credit}",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .blue,
                                                                          fontSize: fontsz *
                                                                              0.8,
                                                                          height:
                                                                              1),
                                                                    ))
                                                              ],
                                                            ),
                                                            Row(
                                                              children: [
                                                                SizedBox(
                                                                    height:
                                                                        fontsz,
                                                                    child: Text(
                                                                      "  补考:",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .black54,
                                                                          fontSize: fontsz *
                                                                              0.7,
                                                                          height:
                                                                              1),
                                                                    )),
                                                                SizedBox(
                                                                    height:
                                                                        fontsz,
                                                                    child: Text(
                                                                      " ${widget.allgradelist[1][index].reexamScore}",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .blue,
                                                                          fontSize: fontsz *
                                                                              0.8,
                                                                          height:
                                                                              1),
                                                                    ))
                                                              ],
                                                            )
                                                          ],
                                                        ),
                                                        Column(
                                                          children: [
                                                            Row(
                                                              children: [
                                                                SizedBox(
                                                                    height:
                                                                        fontsz,
                                                                    child: Text(
                                                                      "  总评:",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .black54,
                                                                          fontSize: fontsz *
                                                                              0.7,
                                                                          height:
                                                                              1),
                                                                    )),
                                                                SizedBox(
                                                                    height:
                                                                        fontsz,
                                                                    child: Text(
                                                                      " ${widget.allgradelist[1][index].totalScore}",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .blue,
                                                                          fontSize: fontsz *
                                                                              0.8,
                                                                          height:
                                                                              1),
                                                                    ))
                                                              ],
                                                            ),
                                                            Row(
                                                              children: [
                                                                SizedBox(
                                                                    height:
                                                                        fontsz,
                                                                    child: Text(
                                                                      "  最终:",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .black54,
                                                                          fontSize: fontsz *
                                                                              0.7,
                                                                          height:
                                                                              1),
                                                                    )),
                                                                SizedBox(
                                                                    height:
                                                                        fontsz,
                                                                    child: Text(
                                                                      " ${widget.allgradelist[1][index].finalScore}",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .blue,
                                                                          fontSize: fontsz *
                                                                              0.8,
                                                                          height:
                                                                              1),
                                                                    ))
                                                              ],
                                                            )
                                                          ],
                                                        )
                                                      ],
                                                    )
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ))
                                  ],
                                )))
                      ],
                    ),
                  ]);
                })));
  }
}
