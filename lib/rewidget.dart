import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CicleloadPage extends StatefulWidget {
  @override
  _CicleloadState createState() => _CicleloadState();
}

class _CicleloadState extends State<CicleloadPage>
    with TickerProviderStateMixin {
  late AnimationController firstController;
  late Animation<double> firstAnimation;

  late AnimationController secondController;
  late Animation<double> secondAnimation;

  late AnimationController thirdController;
  late Animation<double> thirdAnimation;

  late AnimationController fourthController;
  late Animation<double> fourthAnimation;

  late AnimationController fifthController;
  late Animation<double> fifthAnimation;

  @override
  void initState() {
    super.initState();

    firstController =
        AnimationController(vsync: this, duration: Duration(seconds: 6));
    firstAnimation = Tween<double>(begin: -pi, end: pi).animate(firstController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          firstController.repeat();
        } else if (status == AnimationStatus.dismissed) {
          firstController.forward();
        }
      });

    secondController =
        AnimationController(vsync: this, duration: Duration(seconds: 3));
    secondAnimation =
        Tween<double>(begin: -pi, end: pi).animate(secondController)
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              secondController.repeat();
            } else if (status == AnimationStatus.dismissed) {
              secondController.forward();
            }
          });

    thirdController =
        AnimationController(vsync: this, duration: Duration(seconds: 2));
    thirdAnimation = Tween<double>(begin: -pi, end: pi).animate(thirdController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          thirdController.repeat();
        } else if (status == AnimationStatus.dismissed) {
          thirdController.forward();
        }
      });

    fourthController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1500));
    fourthAnimation =
        Tween<double>(begin: -pi, end: pi).animate(fourthController)
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              fourthController.repeat();
            } else if (status == AnimationStatus.dismissed) {
              fourthController.forward();
            }
          });

    fifthController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    fifthAnimation = Tween<double>(begin: -pi, end: pi).animate(fifthController)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          fifthController.repeat();
        } else if (status == AnimationStatus.dismissed) {
          fifthController.forward();
        }
      });

    firstController.forward();
    secondController.forward();
    thirdController.forward();
    fourthController.forward();
    fifthController.forward();
  }

  @override
  void dispose() {
    firstController.dispose();
    secondController.dispose();
    thirdController.dispose();
    fourthController.dispose();
    fifthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff272727),
      body: Center(
        child: Container(
          height: 100,
          width: 100,
          child: CustomPaint(
            painter: MyPainter(
              firstAnimation.value,
              secondAnimation.value,
              thirdAnimation.value,
              fourthAnimation.value,
              fifthAnimation.value,
            ),
          ),
        ),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  final double firstAngle;
  final double secondAngle;
  final double thirdAngle;
  final double fourthAngle;
  final double fifthAngle;

  MyPainter(
    this.firstAngle,
    this.secondAngle,
    this.thirdAngle,
    this.fourthAngle,
    this.fifthAngle,
  );

  @override
  void paint(Canvas canvas, Size size) {
    Paint myArc = Paint()
      ..color = Color(0xff00A2FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTRB(
        0,
        0,
        size.width,
        size.height,
      ),
      firstAngle,
      2,
      false,
      myArc,
    );
    canvas.drawArc(
      Rect.fromLTRB(
        size.width * .1,
        size.height * .1,
        size.width * .9,
        size.height * .9,
      ),
      secondAngle,
      2,
      false,
      myArc,
    );
    canvas.drawArc(
      Rect.fromLTRB(
        size.width * .2,
        size.height * .2,
        size.width * .8,
        size.height * .8,
      ),
      thirdAngle,
      2,
      false,
      myArc,
    );
    canvas.drawArc(
      Rect.fromLTRB(
        size.width * .3,
        size.height * .3,
        size.width * .7,
        size.height * .7,
      ),
      fourthAngle,
      2,
      false,
      myArc,
    );
    canvas.drawArc(
      Rect.fromLTRB(
        size.width * .4,
        size.height * .4,
        size.width * .6,
        size.height * .6,
      ),
      fifthAngle,
      2,
      false,
      myArc,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

enum Type {
  angle, // 角
  side, // 边
  all, // 都有
}

/// 角 边 型
class Polygonal extends StatelessWidget {
  final double size; // 组件大小
  final double? bigR; // 大圆半径
  final double? smallR; // 小圆半径
  final int count; // 几边形
  final Type type; // 五角星or五边形
  final bool isFill; // 是否填充
  final Color color; // 颜色

  const Polygonal(
      {Key? key,
      this.size = 80,
      this.bigR,
      this.smallR,
      this.count = 3,
      this.type = Type.angle,
      this.isFill = false,
      this.color = Colors.black87})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PolygonalPainter(bigR, smallR,
          color: color, count: count, type: type, isFill: isFill),
    );
  }
}

class _PolygonalPainter extends CustomPainter {
  final double? bigR;
  final double? smallR;
  final int count; // 几边形
  final Type type; // 五角星or五边形
  final bool isFill; // 是否填充
  final Color color; // 颜色
  _PolygonalPainter(this.bigR, this.smallR,
      {required this.count,
      required this.type,
      required this.isFill,
      required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width / 2, size.height / 2);
    Paint paint2 = Paint()
      ..color = color
      ..strokeJoin = StrokeJoin.round
      ..style = isFill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2;
    double r = bigR ?? size.width / 2 / 2;
    double r2 = smallR ?? size.width / 2 / 2 - 12;
    // 将圆等分
    Path path = Path();
    canvas.rotate(pi / count + pi / 2 * 3);
    path.moveTo(r * cos(pi / count), r * sin(pi / count));

    /// 绘制角
    if (type == Type.angle || type == Type.all) {
      for (int i = 2; i <= count * 2; i++) {
        if (i.isEven) {
          path.lineTo(r2 * cos(pi / count * i), r2 * sin(pi / count * i));
        } else {
          path.lineTo(r * cos(pi / count * i), r * sin(pi / count * i));
        }
      }
      path.close();
      canvas.drawPath(path, paint2);
    }

    /// 绘制边
    if (type == Type.side || type == Type.all) {
      path.reset();
      path.moveTo(r * cos(pi / count), r * sin(pi / count));
      for (int i = 2; i <= count * 2; i++) {
        if (i.isOdd) {
          path.lineTo(r * cos(pi / count * i), r * sin(pi / count * i));
        }
      }
      path.close();
      canvas.drawPath(path, paint2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
