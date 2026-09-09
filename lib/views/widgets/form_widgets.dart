// 抽取自原 lib/topbar.dart：PresetSelectionCard（L18-75）、DateTimePickerButton（L78-155）、CustomTextField（L570-614）

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_pickers/pickers.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:flutter_pickers/time_picker/model/date_mode.dart';
import 'package:flutter_pickers/time_picker/model/pduration.dart';
import 'package:flutter_pickers/time_picker/model/suffix.dart';

class PresetSelectionCard extends StatefulWidget {
  final TextEditingController controller;
  const PresetSelectionCard({super.key, required this.controller});
  @override
  PresetSelectionCardState createState() => PresetSelectionCardState();
}

class PresetSelectionCardState extends State<PresetSelectionCard> {
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
              initialValue: selectedOption,
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

  const DateTimePickerButton({super.key, required this.controller});

  @override
  DateTimePickerButtonState createState() => DateTimePickerButtonState();
}

class DateTimePickerButtonState extends State<DateTimePickerButton> {
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
          color: Colors.black.withValues(alpha: 0.05),
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

//自定义输入框
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;

  const CustomTextField({super.key, required this.controller});

  @override
  CustomTextFieldState createState() => CustomTextFieldState();
}

class CustomTextFieldState extends State<CustomTextField> {
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
