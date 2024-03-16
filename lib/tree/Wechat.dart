import 'package:flutter/material.dart';

class FakeWechat extends StatefulWidget {
  const FakeWechat({super.key});

  @override
  State<StatefulWidget> createState() => FakeWechatState();
}

class FakeWechatState extends State<FakeWechat> {
  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    double statusBarHeight = mediaQueryData.padding.top;
    double screenWidth = mediaQueryData.size.width;
    double fontsz = screenWidth * 0.045;
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Container(
              height: statusBarHeight,
              color: const Color.fromRGBO(237, 237, 237, 1.0),
            ),
            Container(
              height: fontsz * 3,
              decoration: const BoxDecoration(
                  color: Color.fromRGBO(237, 237, 237, 1.0),
                  border: Border(
                      bottom: BorderSide(width: 0.1, color: Colors.black12))),
              child: Row(
                children: [],
              ),
            )
          ],
        ),
      ),
    );
  }
}
