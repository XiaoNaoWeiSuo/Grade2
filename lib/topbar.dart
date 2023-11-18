// ignore_for_file: camel_case_types, must_be_immutable, use_key_in_widget_constructors, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:flutter_pickers/time_picker/model/pduration.dart';
import 'package:flutter_pickers/time_picker/model/suffix.dart';
import 'function.dart';
import 'package:flutter_pickers/pickers.dart';
import 'package:flutter_pickers/time_picker/model/date_mode.dart';

class PresetSelectionCard extends StatefulWidget {
  TextEditingController controller = TextEditingController();
  PresetSelectionCard({required this.controller});
  @override
  _PresetSelectionCardState createState() => _PresetSelectionCardState();
}

class _PresetSelectionCardState extends State<PresetSelectionCard> {
  List<String> presetOptions = [
    '病假',
    '事假',
    '公假',
  ];
  String selectedOption = '';

  @override
  void initState() {
    super.initState();
    selectedOption = presetOptions[0];
    widget.controller.text = selectedOption;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(left: 5.0, right: 5.0),
        child: Column(
          //crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedOption,
              items: presetOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedOption = value!;
                  widget.controller.text = selectedOption;
                });
              },
              decoration: const InputDecoration(
                // filled: true,
                //fillColor: Colors.grey[200],

                border: InputBorder.none,
                contentPadding: EdgeInsets.all(0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//日期选择器
class DateTimePickerButton extends StatefulWidget {
  final TextEditingController controller;

  DateTimePickerButton({required this.controller});

  @override
  _DateTimePickerButtonState createState() => _DateTimePickerButtonState();
}

class _DateTimePickerButtonState extends State<DateTimePickerButton> {
  PDuration? selectedDateTime = PDuration();

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    double screenWidth = mediaQueryData.size.width;

    double fontsz = screenWidth * 0.045;
    return GestureDetector(
      onTap: () {
        showPickerDate(context);
      },
      child: Container(
        width: fontsz * 6.5,
        margin: const EdgeInsets.only(bottom: 5),
        height: fontsz * 1.6,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(fontsz / 2),
        ),
        child: Center(
          child: Text(
            widget.controller.text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: fontsz, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  Future<void> showPickerDate(BuildContext context) async {
    PDuration? now = PDuration.now();
    Pickers.showDatePicker(
      context,
      mode: DateMode.MDHM,
      selectDate: selectedDateTime ?? now,
      minDate: PDuration(year: 1900),
      maxDate: PDuration(year: 2100),
      suffix: Suffix.normal(),
      pickerStyle: DefaultPickerStyle(),
      onChanged: (PDuration? data) {
        HapticFeedback.lightImpact();
      },
      onConfirm: (PDuration? data) {
        if (data != null) {
          setState(() {
            selectedDateTime = data;
            List source = [
              "${selectedDateTime!.month}",
              "${selectedDateTime!.day}",
              "${selectedDateTime!.hour}",
              "${selectedDateTime!.minute}"
            ];
            for (int a = 0; a < 4; a++) {
              if (source[a].length == 1) {
                source[a] = "0${source[a]}";
              }
            }
            widget.controller.text =
                "${source[0]}-${source[1]}  ${source[2]}:${source[3]}";
          });
        }
      },
      onCancel: (bool isCancel) {},
    );
  }
}

List processArray(List inputArray) {
  List processedArray = [];

  for (int i = 0; i < inputArray.length; i += 7) {
    int endIndex = i + 7;
    List week = inputArray.sublist(i, endIndex);

    // 删除周六和周日
    week.removeAt(5); // 周六
    week.removeAt(5); // 周日

    processedArray.addAll(week);
  }

  return processedArray;
}

class widgetshow extends StatelessWidget {
  String name;
  var value;
  var fill;
  double size;
  widgetshow({required this.name, this.value, this.fill, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(left: 0, right: size / 2, top: size / 4),
        width: size * 7,
        height: size * 3,
        child: Row(children: [
          Expanded(
              child: Column(
            children: [
              Text(
                name,
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: size * 0.8, color: Colors.blue),
              ),
              Text(
                value.toString(),
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: size * 1.1,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            ],
          )),
          CircularProgressIndicator(
            value: value / fill,
            backgroundColor: const Color.fromARGB(141, 119, 133, 131),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          )
        ]));
  }
}

class ContributionGraph extends StatelessWidget {
  final List<bool> activityData;
  final double size;
  const ContributionGraph({required this.activityData, required this.size});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: size,
      runSpacing: size,
      children: List.generate(
        activityData.length,
        (index) => ActivityTile(activityLevel: activityData[index]),
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  final bool activityLevel;
  //final bool value;
  const ActivityTile({required this.activityLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      width: 15.0,
      height: 15.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _getColorForActivityLevel(activityLevel),
      ),
    );
  }

  Color _getColorForActivityLevel(bool level) {
    // Define your own color mapping based on activity levels.
    if (level) {
      return Colors.blue;
    } else {
      return const Color.fromARGB(255, 221, 124, 94);
    }
  }
}

class CalendarPage extends StatelessWidget {
  var dat;
  double iteh;

  bool colorstate;
  bool showstate;
  // final ScrollController scrollController;
  CalendarPage(
      {super.key,
      required this.colorstate,
      required this.showstate,
      // required this.scrollController,
      required this.dat,
      required this.iteh});

  void _showPopup(
      BuildContext context, size, classname, teachername, position) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Container(
              color: const Color.fromARGB(30, 118, 118, 118),
              child: Center(
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  padding: EdgeInsets.only(top: size / 7),
                  height: size * 2,
                  width: size * 3,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: size * 3,
                        color: Colors.blue,
                        child: Text(
                          classname,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: size / 4,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(teachername),
                      Text(
                        position,
                        style: TextStyle(
                            fontSize: size / 5, fontWeight: FontWeight.bold),
                      ),
                      const Expanded(child: SizedBox()),
                      ElevatedButton(
                        onPressed: () {
                          // Close the dialog
                          Navigator.of(context).pop();
                        },
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                ),
              ));
        });
  }

  @override
  Widget build(BuildContext context) {
    var data;
    double constiteh = iteh;
    if (showstate) {
      iteh = iteh / 8;
      data = dat;
    } else {
      iteh = iteh / 5;
      data = processArray(dat);
    }
    // 在这里创建你的日历 UI
    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: GridView.builder(
          // controller: scrollController,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: showstate ? 7 : 5, // Number of columns
            mainAxisExtent: iteh,
            childAspectRatio:
                showstate ? 7 / 8 : 5 / 5, // Width-to-height ratio of each cell
          ),
          itemCount: showstate
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
                          data[index].coursePeriod);
                    },
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        clipBehavior: Clip.hardEdge,
                        margin: const EdgeInsets.all(1),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: colorstate
                                ? data[index].color
                                : const Color.fromARGB(255, 255, 255, 255)),
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
                                width: iteh / 5,
                                child: Text(data[index].coursePeriod,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 5,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        fontSize: iteh / 12,
                                        color: const Color.fromARGB(
                                            255, 80, 80, 80))),
                              ),
                            ]),
                            Text(
                              data[index].teacherName,
                              style: TextStyle(
                                  fontSize: iteh / 10,
                                  color: const Color.fromARGB(255, 83, 83, 83)),
                            ),
                          ],
                        )));
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

//自定义输入框
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;

  CustomTextField({required this.controller});

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  //final bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    //double statusBarHeight = mediaQueryData.padding.top;
    double screenWidth = mediaQueryData.size.width;
    //double screenHeight = mediaQueryData.size.height;
    double fontsz = screenWidth * 0.045;
    return Container(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.only(bottom: 5),
      padding: EdgeInsets.only(left: fontsz * 0.5),
      decoration: BoxDecoration(
        color: const Color.fromARGB(31, 162, 162, 162),
        borderRadius: BorderRadius.circular(fontsz / 2),
      ),
      width: screenWidth / 1.6, // 设置输入框宽度
      height: fontsz * 2, // 设置输入框高度
      child: Center(
        child: TextField(
          textAlign: TextAlign.start,
          style: TextStyle(fontSize: fontsz * 0.9),
          controller: widget.controller,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.only(bottom: fontsz / 1.5),
            fillColor: Colors.amber,
            hintText: '',
            border: InputBorder.none, // 移除默认边框
          ),
        ),
      ),
    );
  }
}

class AnimatedStrip extends StatefulWidget {
  final Color color;
  final double stripeWidth;
  final double stripeHeight;
  final double spaceBetween;
  final Duration duration;

  const AnimatedStrip({
    Key? key,
    required this.color,
    this.stripeWidth = 50.0,
    this.stripeHeight = 15.0,
    this.spaceBetween = 10.0,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  _AnimatedStripState createState() => _AnimatedStripState();
}

class _AnimatedStripState extends State<AnimatedStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: false);

    _animation =
        Tween<double>(begin: 0, end: widget.stripeWidth + widget.spaceBetween)
            .animate(_animationController)
          ..addListener(() {
            setState(() {});
          });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          Positioned(
            left: -_animation.value,
            right:
                _animation.value - (widget.stripeWidth + widget.spaceBetween),
            child: Container(
              height: widget.stripeHeight,
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: 1000, // A large enough number to cover the screen
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: widget.spaceBetween),
                    child: Transform.rotate(
                      angle: -3.1415 / 4,
                      child: Container(
                        width: widget.stripeWidth,
                        height: widget.stripeHeight,
                        color: widget.color,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//成绩列表
class SubjectCreditsList extends StatelessWidget {
  late var courseList;
  final double size;
  SubjectCreditsList({required this.courseList, required this.size});
  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Number of columns
            mainAxisExtent: size * 5.5,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: courseList.length,
          itemBuilder: (context, index) {
            var course = courseList[index];
            return Container(
                clipBehavior: Clip.hardEdge,
                padding: EdgeInsets.only(
                    top: size / 5,
                    bottom: size / 5,
                    left: size / 3,
                    right: size / 3),
                margin: EdgeInsets.all(size / 3.5),
                // padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                    // border: Border.all(
                    //     width: 2, color: const Color.fromARGB(255, 54, 53, 53)),
                    borderRadius: BorderRadius.circular(10),
                    // boxShadow: const [
                    //   BoxShadow(
                    //     color: Color.fromARGB(255, 198, 198, 198),
                    //     offset: Offset(0.5, 2.5),
                    //     blurRadius: 5.0,
                    //   )
                    // ],
                    color: Color.fromARGB(180, 228, 227, 227)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                                color: course.score < 60
                                    ? Colors.redAccent
                                    : Colors.blueAccent,
                                borderRadius: BorderRadius.circular(size)),
                          ),
                          SizedBox(
                            width: size * 8,
                            child: Text(course.courseName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: size,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        const Color.fromARGB(255, 58, 58, 58))),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '学分:${course.credit} | 绩点:${course.gradePoint}',
                                  style: TextStyle(fontSize: size / 1.5)),
                              Text(
                                '课程类型:${course.courseType}  ',
                                style: TextStyle(fontSize: size / 1.5),
                              ),
                              Text(
                                '编号:${course.courseCode}',
                                style: TextStyle(fontSize: size / 1.5),
                              ),
                            ],
                          ),
                          const Expanded(child: SizedBox()),
                          Text(
                            "${course.score.toInt()}",
                            style: TextStyle(
                                fontSize: size * 2,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 83, 83, 83)),
                          )
                        ],
                      ),
                    ]));
          },
        ));
  }
}

class DropdownList extends StatefulWidget {
  late int startYear;
  double size;
  DropdownList({required this.startYear, required this.size});

  @override
  _DropdownListState createState() => _DropdownListState();
}

class _DropdownListState extends State<DropdownList>
    with SingleTickerProviderStateMixin {
  String selectedOption = "选择学期";
  final CounterStorage ctrlFile = CounterStorage();
  bool isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  //int currentYear = DateTime.now().year;
  List<String> semesters = [];
  late Map initdata;
  @override
  void initState() {
    super.initState();
    DateTime currentDate = DateTime.now(); // 获取当前日期时间
    int currentYear = currentDate.year; // 获取当前年份
    int currentMonth = currentDate.month; // 获取当前月份

    for (int year = widget.startYear; year <= currentYear; year++) {
      if (year == currentYear) {
        if (currentMonth >= 8 && currentMonth <= 12) {
          // 当前月份在9月到12月之间，表示存在上学期
          semesters.add('$year-${year + 1} 上学期');
        }

        if (currentMonth >= 1 && currentMonth <= 6) {
          // 当前月份在2月到6月之间，表示存在下学期
          semesters.add('$year-${year + 1} 下学期');
        }
      } else {
        semesters.add('$year-${year + 1} 上学期');
        semesters.add('$year-${year + 1} 下学期');
      }
    }

    ctrlFile.readCounter().then((value) {
      initdata = value;
      if (initdata["goal"] == "") {
        initdata["goal"] = semesters[0];
        selectedOption = semesters[0];
        ctrlFile.writeCounter(initdata);
      } else {
        selectedOption = initdata["goal"];
      }
    });

    //selectedOption = semesters[0];

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void toggleExpand() {
    setState(() {
      isExpanded = !isExpanded;
    });

    if (isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        //height: isExpanded ? widget.options.length * 50.0 : 0.0,
        width: isExpanded ? widget.size * 12 : widget.size * 9,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(widget.size / 2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: widget.size / 3,
                ),
                Text(
                  selectedOption,
                  style: TextStyle(fontSize: widget.size / 1.2),
                ),
                const Expanded(child: SizedBox()),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animation.value * 1 * 3.14,
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        size: widget.size * 1.4,
                      ),
                    );
                  },
                ),
              ],
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isExpanded ? widget.size * 8 : 0.0,
              //width: isExpanded ? widget.options.length * 50.0 : 200,
              child: Scrollbar(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: ListView.builder(
                    itemCount: semesters.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        child: Container(
                            decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius:
                                    BorderRadius.circular(widget.size / 3)),
                            margin: EdgeInsets.only(
                                left: widget.size / 3,
                                bottom: widget.size / 5,
                                right: widget.size / 3),
                            height: widget.size * 1.6,
                            child: Center(
                              child: Text(
                                semesters[index],
                                style: TextStyle(fontSize: widget.size / 1.3),
                              ),
                            )),
                        onTap: () {
                          setState(() {
                            selectedOption = semesters[index];
                            initdata["goal"] = selectedOption;
                            ctrlFile.writeCounter(initdata);
                            isExpanded = false;
                          });
                          _animationController.reverse();
                        },
                      );
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ExamList extends StatelessWidget {
  var examlist;
  ExamList({required this.examlist});
  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    double statusBarHeight = mediaQueryData.padding.top;
    double screenWidth = mediaQueryData.size.width;
    double screenHeight = mediaQueryData.size.height;
    double fontsz = screenWidth * 0.045;
    return Container(
      child: Column(children: [
        SizedBox(
          height: statusBarHeight,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.all(fontsz),
            child: Text(
              "考试安排",
              style: TextStyle(
                  fontSize: fontsz,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue),
            ),
          ),
        ),
        SizedBox(
            width: screenWidth,
            height: screenHeight * 0.75,
            // decoration: const BoxDecoration(
            //     border:
            //         Border(bottom: BorderSide(width: 2, color: Colors.black))),
            child: ListView.builder(
              itemCount: examlist.length,
              itemBuilder: (context, index) {
                // 获取当前索引处的数据模型
                var data = examlist[index];
                return Container(
                    margin: EdgeInsets.only(
                        left: fontsz / 2, right: fontsz / 2, top: fontsz / 2),
                    padding: EdgeInsets.all(fontsz / 3),
                    height: screenHeight / 10,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(fontsz),
                        // gradient: const LinearGradient(colors: [
                        //   Colors.blue,
                        //   Color.fromARGB(255, 0, 132, 226)
                        // ], begin: Alignment.bottomRight),
                        color: Colors.blue),
                    child: Row(
                      children: [
                        Container(
                            width: fontsz / 5,
                            height: fontsz * 3,
                            margin: EdgeInsets.all(fontsz / 4),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(fontsz))),
                        SizedBox(
                            width: screenWidth / 3.2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(data.courseName,
                                    maxLines: 1,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: fontsz * 0.8)),
                                Text("模式：${data.examFormat}",
                                    maxLines: 1,
                                    style: TextStyle(
                                        color: Colors.white,
                                        // fontWeight: FontWeight.w800,
                                        fontSize: fontsz * 0.7)),
                                Text("类型：${data.examType}",
                                    maxLines: 1,
                                    style: TextStyle(
                                        color: Colors.white,
                                        //fontWeight: FontWeight.w800,
                                        fontSize: fontsz * 0.75)),
                              ],
                            )),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.access_alarm,
                              color: Colors.white,
                              size: fontsz * 2.5,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  data.examDate,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: fontsz * 1.2),
                                ),
                                Text(
                                  data.examTime,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: fontsz / 1.2),
                                )
                              ],
                            )
                          ],
                        ),
                        SizedBox(
                          width: fontsz / 2,
                          //height: fontsz * 3,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.place,
                                  color: Colors.white,
                                  size: fontsz * 2,
                                ),
                                Text(data.capacity.toString(),
                                    style: TextStyle(
                                        color: Colors.white,
                                        //fontWeight: FontWeight.w800,
                                        fontSize: fontsz * 1.5,
                                        fontWeight: FontWeight.bold))
                              ],
                            ),
                            Text(
                              data.examRoom,
                              style: TextStyle(
                                  color: Colors.white, fontSize: fontsz / 1.2),
                            )
                          ],
                        ),
                        SizedBox(
                          width: fontsz,
                          //height: fontsz * 3,
                        ),
                      ],
                    ));
              },
            ))
      ]),
    );
  }
}

//定制环形圆角进度条
class CircularProgressBar extends StatelessWidget {
  final double progress;
  final double strokeWidth;
  final Color color;
  final double startAngle;
  final double endAngle;
  final double radius;
  final double beginCapRadius;
  final double endCapRadius;

  CircularProgressBar({
    required this.progress,
    this.strokeWidth = 10.0,
    this.color = Colors.blue,
    this.startAngle = 0.0,
    this.endAngle = 360.0,
    this.radius = 100.0,
    this.beginCapRadius = 0.0,
    this.endCapRadius = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CircularProgressBarPainter(
        progress: progress,
        strokeWidth: strokeWidth,
        color: color,
        startAngle: startAngle,
        endAngle: endAngle,
        radius: radius,
        beginCapRadius: beginCapRadius,
        endCapRadius: endCapRadius,
      ),
    );
  }
}

class _CircularProgressBarPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final double startAngle;
  final double endAngle;
  final double radius;
  final double beginCapRadius;
  final double endCapRadius;

  _CircularProgressBarPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.startAngle,
    required this.endAngle,
    required this.radius,
    required this.beginCapRadius,
    required this.endCapRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final startAngleRadians = startAngle * (3.1415927 / 180.0);
    final endAngleRadians = endAngle * (3.1415927 / 180.0);
    final sweepAngleRadians = (endAngle - startAngle) * (3.1415927 / 180.0);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      rect,
      startAngleRadians,
      sweepAngleRadians,
      false,
      backgroundPaint,
    );

    canvas.drawArc(
      rect,
      startAngleRadians,
      sweepAngleRadians * progress,
      false,
      progressPaint,
    );

    if (beginCapRadius > 0) {
      final beginCapPaint = Paint()..color = color;
      final beginCapCenter = Offset(
        center.dx + radius * cos(startAngleRadians),
        center.dy + radius * sin(startAngleRadians),
      );
      canvas.drawCircle(beginCapCenter, beginCapRadius, beginCapPaint);
    }

    if (endCapRadius > 0) {
      final endCapPaint = Paint()..color = color;
      final endCapCenter = Offset(
        center.dx + radius * cos(endAngleRadians),
        center.dy + radius * sin(endAngleRadians),
      );
      canvas.drawCircle(endCapCenter, endCapRadius, endCapPaint);
    }
  }

  @override
  bool shouldRepaint(_CircularProgressBarPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        strokeWidth != oldDelegate.strokeWidth ||
        color != oldDelegate.color ||
        startAngle != oldDelegate.startAngle ||
        endAngle != oldDelegate.endAngle ||
        radius != oldDelegate.radius ||
        beginCapRadius != oldDelegate.beginCapRadius ||
        endCapRadius != oldDelegate.endCapRadius;
  }
}

class loadanimation extends StatefulWidget {
  double radius;
  loadanimation({super.key, required this.radius});
  @override
  _MyCustomWidgetState createState() => _MyCustomWidgetState();
}

class _MyCustomWidgetState extends State<loadanimation>
    with TickerProviderStateMixin {
  late AnimationController controller1;
  late Animation<double> animation1;

  late AnimationController controller2;
  late Animation<double> animation2;

  @override
  void initState() {
    super.initState();

    controller1 =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    animation1 = Tween<double>(begin: .0, end: .5)
        .animate(CurvedAnimation(parent: controller1, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller1.reverse();
          controller2.forward();
        } else if (status == AnimationStatus.dismissed) {
          controller1.forward();
        }
      });

    controller2 =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    animation2 = Tween<double>(begin: .0, end: .5)
        .animate(CurvedAnimation(parent: controller2, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller2.reverse();
        } else if (status == AnimationStatus.dismissed) {
          controller2.forward();
        }
      });

    controller1.forward();
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.radius,
      width: widget.radius,
      child: CustomPaint(
        painter: MyPainter(animation1.value, animation2.value),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  final double Radius_1;
  final double Radius_2;

  MyPainter(this.Radius_1, this.Radius_2);

  @override
  void paint(Canvas canvas, Size size) {
    Paint Circle_1 = Paint()..color = Color(0xff4285f4);

    Paint Circle_2 = Paint()..color = Color(0xfffbbc05);

    canvas.drawCircle(Offset(size.width * .5, size.height * .5),
        size.width * Radius_1, Circle_1);

    canvas.drawCircle(Offset(size.width * .5, size.height * .5),
        size.width * Radius_2, Circle_2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
