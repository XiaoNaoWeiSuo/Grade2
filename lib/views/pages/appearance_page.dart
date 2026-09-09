// 迁移自 lib/tree/pages.dart：MyImagePicker（L23-485，改名 AppearancePage）+
// ColorPickerDialog（L487-530，类名保留）。
// 数据访问点替换：旧页面自读写 setting.json 并在退出时回传结果对象的组合，
// 改为读写 settingsProvider（update 会持久化并通知所有监听者），退出改为普通 pop()。
// UI（布局/颜色/动画/文本）逐行保持不变。
// 注：本地图库选中的背景图需要 dart:io 的 File/Image.file 做展示（无任何数据读写）。

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roundcheckbox/roundcheckbox.dart';

import '../../data/models/app_settings.dart';
import '../../viewmodels/settings_provider.dart';

class AppearancePage extends ConsumerStatefulWidget {
  const AppearancePage({super.key});

  @override
  ConsumerState<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends ConsumerState<AppearancePage> {
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedImage;
  String Imagepath = "";
  bool blur = false;
  bool isUse = false;
  bool itemcolorstate = false;

  Color dateColor = const Color.fromARGB(255, 0, 0, 0);
  Color timeColor = const Color.fromARGB(255, 2, 32, 45);
  Color bgColor =
      const Color.fromARGB(255, 171, 232, 255).withValues(alpha: 0.6);

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    Imagepath = settings.classImage;
    isUse = Imagepath == "" ? false : true;
    blur = settings.blur;
    itemcolorstate = settings.itemColorState;
    dateColor = settings.dateColor;
    timeColor = settings.timeColor;
    bgColor = settings.bgColor;
  }

  /// 每次修改颜色/背景/模糊后整体持久化（替代旧页面拼 Map 写文件）
  void _persistSettings() {
    ref.read(settingsProvider.notifier).update(AppSettings(
          dateColor: dateColor,
          timeColor: timeColor,
          bgColor: bgColor,
          classImage: Imagepath,
          itemColorState: itemcolorstate,
          blur: blur,
        ));
  }

  void _pickImage() async {
    _pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    Imagepath = _pickedImage!.path;
    isUse = Imagepath == "" ? false : true;
    if (_pickedImage != null) {
      _persistSettings();
      setState(() {
        // 使用setState来更新状态，触发界面刷新
      });
    }
  }

  void _blurchange() {
    blur = !blur;
    _persistSettings();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
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
              Navigator.pop(context);
            },
          ),
        ),
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop) {
              Navigator.pop(context);
            }
          },
          child: Padding(
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
                                    color: const Color.fromARGB(
                                        255, 201, 201, 201),
                                    borderRadius:
                                        BorderRadius.circular(fontsz)),
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
                                    borderRadius:
                                        BorderRadius.circular(fontsz)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(fontsz),
                                  //使图片模糊区域仅在子组件区域中
                                  child: BackdropFilter(
                                    //背景过滤器
                                    filter: ImageFilter.blur(
                                        sigmaX: 25.0, sigmaY: 25.0), //设置图片模糊度
                                    child: Container(
                                      height: screenHeight,
                                      width: screenWidth,
                                      color: Colors.grey.shade200
                                          .withValues(alpha: 0.8),
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
                                _persistSettings();
                                setState(() {});
                              },
                              isChecked: isUse,
                            ),
                            Text("  启用背景  ",
                                style: TextStyle(
                                    fontSize: fontsz * 0.9,
                                    color: Colors.white,
                                    shadows: const [
                                      BoxShadow(
                                          color: Colors.black, blurRadius: 20)
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
                                    BoxShadow(
                                        color: Colors.black, blurRadius: 20)
                                  ]),
                            ),
                            const Expanded(child: SizedBox()),
                            TextButton(
                              onPressed: _pickImage,
                              child: Text(
                                '选择图片',
                                style: TextStyle(
                                    fontSize: fontsz * 0.9,
                                    color: const Color.fromARGB(
                                        255, 183, 219, 247),
                                    shadows: const [
                                      BoxShadow(
                                          color: Colors.black, blurRadius: 10)
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
                              final Color? picked = await showDialog<Color>(
                                context: context,
                                builder: (BuildContext context) {
                                  return ColorPickerDialog(
                                      initialColor: dateColor);
                                },
                              );
                              if (picked != null) {
                                dateColor = picked;
                                _persistSettings();
                                setState(() {});
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.all(fontsz / 3),
                              width: fontsz * 3,
                              height: fontsz * 3,
                              decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  color: dateColor,
                                  borderRadius:
                                      BorderRadius.circular(fontsz * 2)),
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
                              final Color? picked = await showDialog<Color>(
                                context: context,
                                builder: (BuildContext context) {
                                  return ColorPickerDialog(
                                      initialColor: timeColor);
                                },
                              );
                              if (picked != null) {
                                timeColor = picked;
                                _persistSettings();
                                setState(() {});
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.all(fontsz / 3),
                              width: fontsz * 3,
                              height: fontsz * 3,
                              decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  color: timeColor,
                                  borderRadius:
                                      BorderRadius.circular(fontsz * 2)),
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
                              final Color? picked = await showDialog<Color>(
                                context: context,
                                builder: (BuildContext context) {
                                  return ColorPickerDialog(
                                      initialColor: bgColor);
                                },
                              );
                              if (picked != null) {
                                bgColor = picked;
                                _persistSettings();
                                setState(() {});
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.all(fontsz / 3),
                              width: fontsz * 3,
                              height: fontsz * 3,
                              decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  color: bgColor,
                                  borderRadius:
                                      BorderRadius.circular(fontsz * 2)),
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
                      style:
                          TextStyle(fontSize: fontsz * 0.7, color: Colors.blue),
                    ),
                    SizedBox(
                        height: fontsz * 2,
                        child: Row(
                          //crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: RoundCheckBox(
                                onTap: (selected) {
                                  itemcolorstate = !itemcolorstate;
                                  _persistSettings();
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
                                  _persistSettings();
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
        ));
  }
}

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const ColorPickerDialog({super.key, required this.initialColor});

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
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
