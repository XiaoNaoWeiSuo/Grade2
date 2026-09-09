// 抽取自原 lib/topbar.dart：CalendarPage（L261-567）。
// 原 build 中修改 widget.iteh 的副作用已移入 initState（局部字段完成计算，渲染结果不变）。

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/timetable_utils.dart';

class CalendarPage extends StatefulWidget {
  final dynamic dat;
  final double iteh;
  final bool colorstate;
  final bool showstate;
  const CalendarPage({
    super.key,
    required this.colorstate,
    required this.showstate,
    required this.dat,
    required this.iteh,
  });

  @override
  State<StatefulWidget> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late List data;
  late double iteh; // 对应原 build 中被除以 8 或 5 后的 widget.iteh
  late double constiteh; // 对应原 build 中的局部变量 constiteh（未除前的高度）

  @override
  void initState() {
    super.initState();
    constiteh = widget.iteh;
    if (widget.showstate) {
      iteh = widget.iteh / 8;
      data = widget.dat;
    } else {
      iteh = widget.iteh / 5;
      data = processArray(widget.dat);
    }
  }

  void _showPopup(BuildContext context, dynamic size, dynamic classname,
      dynamic teachername, dynamic position, dynamic interval) {
    List interlist = interval.split("");
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Container(
              color: Colors.black.withValues(alpha: 0.03),
              child: Center(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          clipBehavior: Clip.hardEdge,
                          padding: EdgeInsets.only(top: size / 7),
                          height: size * 2,
                          width: size * 3,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color:
                                  Colors.grey.shade200.withValues(alpha: 0.5)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                classname,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: size / 4,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(teachername),
                              Text(
                                position,
                                style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: size / 5,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.5)),
                                width: size * 3,
                                height: size * 3 / interlist.length,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: interlist.length - 1,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      padding: const EdgeInsets.all(1),
                                      width:
                                          size * 3 / (interlist.length - 1),
                                      //height: 10,
                                      child: Container(
                                          height:
                                              size * 3 / (interlist.length - 1),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              color: interlist[index + 1] == "0"
                                                  ? Colors.grey
                                                  : Colors.greenAccent),
                                          child: Center(
                                            child: Text(
                                              (index + 1).toString(),
                                              style: const TextStyle(
                                                  color: Colors.blueGrey,
                                                  fontSize: 10,
                                                  wordSpacing: 1,
                                                  height: 1),
                                            ),
                                          )),
                                    );
                                  },
                                ),
                              ),
                              const Expanded(child: SizedBox()),
                              TextButton(
                                onPressed: () {
                                  // Close the dialog
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  '关闭',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))));
        });
  }

  @override
  Widget build(BuildContext context) {
    // 在这里创建你的日历 UI
    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          // controller: scrollController,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.showstate ? 7 : 5, // Number of columns
            mainAxisExtent: iteh,
            // mainAxisSpacing: 1,
            // crossAxisSpacing: 1,
            childAspectRatio: widget.showstate
                ? 7 / 8
                : 5 / 5, // Width-to-height ratio of each cell
          ),
          itemCount: widget.showstate
              ? 56
              : 25, // Total number of cells (7 columns * 10 rows)
          itemBuilder: (BuildContext context, int index) {
            if (data[index].courseName != "") {
              try {
                return GestureDetector(
                    onTap: () {
                      _showPopup(
                        context,
                        constiteh / 6.5,
                        data[index].courseName,
                        data[index].teacherName,
                        data[index].coursePeriod,
                        data[index].interal,
                      );
                    },
                    onLongPress: () {
                      if (data[index].state) {
                        HapticFeedback.mediumImpact();
                        _showPopup(
                          context,
                          constiteh / 6.5,
                          data[index].sonName,
                          data[index].sonTeac,
                          data[index].sonPeriod,
                          data[index].sonInter,
                        );
                      }
                    },
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                            child: Container(
                                //duration: const Duration(milliseconds: 500),
                                //clipBehavior: Clip.hardEdge,
                                margin: const EdgeInsets.all(0.5),
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: widget.colorstate
                                        ? Border.all(
                                            width: 0.8, color: Colors.black38)
                                        : null,
                                    color: widget.colorstate
                                        ? data[index].color
                                        : const Color.fromARGB(
                                            150, 255, 255, 255)),
                                child: Column(
                                  children: [
                                    Row(children: [
                                      SizedBox(
                                        width: iteh / 8,
                                        height: iteh * 0.75,
                                        child: Text(
                                          data[index].courseName,
                                          textAlign: TextAlign.center,
                                          //maxLines: 2,
                                          //overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              height: 1.1,
                                              fontSize: iteh / 9,
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(
                                                  255, 71, 71, 71)),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 3,
                                      ),
                                      SizedBox(
                                        width: iteh / 4,
                                        height: iteh * 0.75,
                                        child: Stack(
                                          children: [
                                            data[index].state
                                                ? Align(
                                                    alignment:
                                                        Alignment.topCenter,
                                                    child: GestureDetector(
                                                        onTap: () {
                                                          _showPopup(
                                                            context,
                                                            constiteh / 6.5,
                                                            data[index]
                                                                .sonName,
                                                            data[index]
                                                                .sonTeac,
                                                            data[index]
                                                                .sonPeriod,
                                                            data[index]
                                                                .sonInter,
                                                          );
                                                        },
                                                        child: Container(
                                                          width: iteh / 4,
                                                          height: 15,
                                                          decoration: BoxDecoration(
                                                              color:
                                                                  Colors.red,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5)),
                                                          child: const Center(
                                                            child: Text(
                                                              "重修",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 9),
                                                            ),
                                                          ),
                                                        )),
                                                  )
                                                : Container(),
                                            Center(
                                              child: Text(
                                                  data[index].coursePeriod,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 5,
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                      fontSize: iteh / 13,
                                                      color:
                                                          const Color.fromARGB(
                                                              255,
                                                              110,
                                                              109,
                                                              109))),
                                            )
                                          ],
                                        ),
                                      ),
                                    ]),
                                    Text(
                                      data[index].teacherName,
                                      style: TextStyle(
                                          fontSize: iteh / 11,
                                          color: const Color.fromARGB(
                                              255, 83, 83, 83)),
                                    ),
                                  ],
                                )))));
              } catch (e) {
                return Container(
                  //margin: const EdgeInsets.all(2),
                  color: Colors.black,
                );
              }
            } else {
              return Container(
                  // //margin: const EdgeInsets.all(2),
                  //color: Colors.white,
                  );
            }
          },
        ));
  }
}
