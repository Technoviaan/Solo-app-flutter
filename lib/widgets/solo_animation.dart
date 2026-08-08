import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/app_size.dart';

class SoloAnimation extends StatefulWidget {
  const SoloAnimation({super.key});

  @override
  State<SoloAnimation> createState() => _SoloAnimationState();
}

class _SoloAnimationState extends State<SoloAnimation> {

  int frame = 0;

  final frames = [
    "assets/images/helloImage/eye_straight.png",
    "assets/images/helloImage/eye_left.png",
    "assets/images/helloImage/eye_down.png",
    "assets/images/helloImage/eye_close.png",
  ];

  @override
  void initState() {
    super.initState();

    Timer.periodic(
      const Duration(milliseconds: 900),
          (timer) {

        setState(() {
          frame = (frame + 1) % frames.length;
        });

      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final size = AppSize.w(200);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),

      child: Image.asset(
        frames[frame],
        key: ValueKey(frames[frame]),
        width: size,
      ),
    );
  }
}