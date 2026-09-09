// 抽取自原 lib/topbar.dart：loadanimation（L1155-1250）。
// 改名：loadanimation → LoadingAnimation，_MyCustomWidgetState → _LoadingAnimationState，
// MyPainter → ScheduleGridPainter（消除与 rewidget.dart MyPainter 的重名），字段 Radius_1/Radius_2 → radius1/radius2。

import 'package:flutter/material.dart';

class LoadingAnimation extends StatefulWidget {
  final double radius;
  const LoadingAnimation({super.key, required this.radius});
  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController controller1;
  late Animation<double> animation1;

  late AnimationController controller2;
  late Animation<double> animation2;

  @override
  void initState() {
    super.initState();

    controller1 =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
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
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
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
        painter: ScheduleGridPainter(animation1.value, animation2.value),
      ),
    );
  }
}

class ScheduleGridPainter extends CustomPainter {
  final double radius1;
  final double radius2;

  ScheduleGridPainter(this.radius1, this.radius2);

  @override
  void paint(Canvas canvas, Size size) {
    Paint circle1 = Paint()..color = const Color(0xff4285f4);

    Paint circle2 = Paint()..color = const Color(0xfffbbc05);

    canvas.drawCircle(Offset(size.width * .5, size.height * .5),
        size.width * radius1, circle1);

    canvas.drawCircle(Offset(size.width * .5, size.height * .5),
        size.width * radius2, circle2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
