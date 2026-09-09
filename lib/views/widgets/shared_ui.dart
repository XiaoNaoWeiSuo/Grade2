// 抽取自原 lib/rewidget.dart：Polygonal（L241-332）+ _PolygonalPainter、SizeTransitionRe（L333-357）、
// AnimCard（L358-417）+ _AnimCardState、CardItem（L418-476）、RandomGeometricShapes（L477-499）+
// GeometricShapesPainter（L500-580）、MyPainter（L143-232，改名 ShapesPainter）。
// 改动：enum Type 遮蔽 dart:core，改名 ShapeType。

import 'dart:math';

import 'package:flutter/material.dart';

enum ShapeType {
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
  final ShapeType type; // 五角星or五边形
  final bool isFill; // 是否填充
  final Color color; // 颜色

  const Polygonal(
      {super.key,
      this.size = 80,
      this.bigR,
      this.smallR,
      this.count = 3,
      this.type = ShapeType.angle,
      this.isFill = false,
      this.color = Colors.black87});

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
  final ShapeType type; // 五角星or五边形
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
    if (type == ShapeType.angle || type == ShapeType.all) {
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
    if (type == ShapeType.side || type == ShapeType.all) {
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
                alignment: const Alignment(-1.0, 0.0),
                child: page,
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

  const AnimCard(this.color, this.num, this.numEng, this.content, {super.key});

  @override
  State<AnimCard> createState() => _AnimCardState();
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
            margin: const EdgeInsets.only(right: 20, left: 20, top: 200),
            height: 180,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2), blurRadius: 30)
              ],
              color: Colors.grey.shade200.withValues(alpha: 1.0),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: const Center(
                child: Icon(Icons.favorite,
                    color: Color(0xffFF6594), size: 70)),
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
  final dynamic onTap;

  const CardItem(this.color, this.num, this.numEng, this.content, this.onTap,
      {super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25),
        height: 220,
        width: width,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: const Color(0xffFF6594).withValues(alpha: 0.2),
                blurRadius: 25),
          ],
          color: color.withValues(alpha: 1.0),
          borderRadius: const BorderRadius.all(
            Radius.circular(30),
          ),
        ),
        child: const Padding(
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
                '对不起宝宝，我爱你，我盼望一切重归于好，我想和你在一起。',
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
    );
  }
}

class RandomGeometricShapes extends StatelessWidget {
  final double width;
  final double height;
  final int shapeCount;

  const RandomGeometricShapes({
    super.key,
    required this.width,
    required this.height,
    required this.shapeCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: GeometricShapesPainter(shapeCount),
      ),
    );
  }
}

class GeometricShapesPainter extends CustomPainter {
  final int shapeCount;
  final Random random = Random();

  GeometricShapesPainter(this.shapeCount);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < shapeCount; i++) {
      _drawRandomShape(canvas, size);
    }
  }

  void _drawRandomShape(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromRGBO(
          random.nextInt(256), random.nextInt(256), random.nextInt(256), 1)
      ..style = PaintingStyle.fill;

    final shapeType = random.nextInt(3); // 0: Circle, 1: Rectangle, 2: Polygon
    switch (shapeType) {
      case 0:
        _drawRandomCircle(canvas, size, paint);
        break;
      case 1:
        _drawRandomRectangle(canvas, size, paint);
        break;
      case 2:
        _drawRandomPolygon(canvas, size, paint);
        break;
    }
  }

  void _drawRandomCircle(Canvas canvas, Size size, Paint paint) {
    final radius = random.nextDouble() * 50;
    final center = Offset(
      random.nextDouble() * size.width,
      random.nextDouble() * size.height,
    );
    canvas.drawCircle(center, radius, paint);
  }

  void _drawRandomRectangle(Canvas canvas, Size size, Paint paint) {
    final width = random.nextDouble() * 100;
    final height = random.nextDouble() * 100;
    final topLeft = Offset(
      random.nextDouble() * (size.width - width),
      random.nextDouble() * (size.height - height),
    );
    final rect = Rect.fromLTWH(topLeft.dx, topLeft.dy, width, height);
    canvas.drawRect(rect, paint);
  }

  void _drawRandomPolygon(Canvas canvas, Size size, Paint paint) {
    final sides = random.nextInt(5) + 3; // 3 to 7 sides
    final radius = random.nextDouble() * 50;
    final center = Offset(
      random.nextDouble() * size.width,
      random.nextDouble() * size.height,
    );

    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (2 * pi * i) / sides;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// 原 rewidget.dart 的 MyPainter（圆弧绘制），改名 ShapesPainter 以消除重名。
class ShapesPainter extends CustomPainter {
  final double firstAngle;
  final double secondAngle;
  final double thirdAngle;
  final double fourthAngle;
  final double fifthAngle;

  ShapesPainter(
    this.firstAngle,
    this.secondAngle,
    this.thirdAngle,
    this.fourthAngle,
    this.fifthAngle,
  );

  @override
  void paint(Canvas canvas, Size size) {
    Paint myArc = Paint()
      ..color = const Color(0xff00A2FF)
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
