// 抽取自原 lib/topbar.dart：AnimatedStrip（L616-698）+ 私有 State、SubjectCreditsList（L701-800）

import 'package:flutter/material.dart';

class AnimatedStrip extends StatefulWidget {
  final Color color;
  final double stripeWidth;
  final double stripeHeight;
  final double spaceBetween;
  final Duration duration;

  const AnimatedStrip({
    super.key,
    required this.color,
    this.stripeWidth = 50.0,
    this.stripeHeight = 15.0,
    this.spaceBetween = 10.0,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<AnimatedStrip> createState() => _AnimatedStripState();
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
            child: SizedBox(
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
  final List courseList;
  final double size;
  const SubjectCreditsList(
      {super.key, required this.courseList, required this.size});
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
                    color: const Color.fromARGB(61, 230, 226, 226)),
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
                                    height: 1.25,
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
