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

class SizeTransitionRe extends PageRouteBuilder {
  final Widget page;

  SizeTransitionRe(this.page)
      : super(
          pageBuilder: (context, animation, anotherAnimation) => page,
          transitionDuration: const Duration(milliseconds: 1000),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, anotherAnimation, child) {
            animation = CurvedAnimation(
                curve: Curves.fastLinearToSlowEaseIn,
                parent: animation,
                reverseCurve: Curves.fastOutSlowIn);
            return Align(
              alignment: Alignment.bottomCenter,
              child: SizeTransition(
                sizeFactor: animation,
                child: page,
                axisAlignment: 0,
              ),
            );
          },
        );
}

class AnimCard extends StatefulWidget {
  final Color color;
  final String num;
  final String numEng;
  final String content;

  const AnimCard(this.color, this.num, this.numEng, this.content);

  @override
  _AnimCardState createState() => _AnimCardState();
}

class _AnimCardState extends State<AnimCard> {
  var padding = 150.0;
  var bottomPadding = 0.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedPadding(
          padding: EdgeInsets.only(top: padding, bottom: bottomPadding),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.fastLinearToSlowEaseIn,
          child: CardItem(
            widget.color,
            widget.num,
            widget.numEng,
            widget.content,
            () {
              setState(() {
                padding = padding == 0 ? 150.0 : 0.0;
                bottomPadding = bottomPadding == 0 ? 150 : 0.0;
              });
            },
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: EdgeInsets.only(right: 20, left: 20, top: 200),
            height: 180,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30)
              ],
              color: Colors.grey.shade200.withOpacity(1.0),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Center(
                child: Icon(Icons.favorite,
                    color: Color(0xffFF6594).withOpacity(1.0), size: 70)),
          ),
        ),
      ],
    );
  }
}

class CardItem extends StatelessWidget {
  final Color color;
  final String num;
  final String numEng;
  final String content;
  final onTap;

  CardItem(this.color, this.num, this.numEng, this.content, this.onTap);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return GestureDetector(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 25),
        height: 220,
        width: width,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Color(0xffFF6594).withOpacity(0.2), blurRadius: 25),
          ],
          color: color.withOpacity(1.0),
          borderRadius: BorderRadius.all(
            Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Tap it',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                '   我们还在冷战呢，不想说话。',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
