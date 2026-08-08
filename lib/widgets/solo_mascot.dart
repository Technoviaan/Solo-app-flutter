import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/app_size.dart';

class SoloMascot extends StatefulWidget {
  const SoloMascot({super.key});

  @override
  State<SoloMascot> createState() => _SoloMascotState();
}

class _SoloMascotState extends State<SoloMascot> {

  int frame = 0;
  Timer? _timer;

  final List<String> frames = [
    "assets/images/eye_center.png",
    "assets/images/eye_right.png",
    "assets/images/eye_left.png",
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3000), (timer) {
      if (mounted) {
        setState(() {
          frame = (frame + 1) % frames.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final size = AppSize.w(280);

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Image.asset(
          frames[frame],
          key: ValueKey(frames[frame]),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}