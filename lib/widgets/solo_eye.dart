import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solo_app/core/utils/app_size.dart';

class SoloLogoWidget extends StatelessWidget {
  final double size;

  const SoloLogoWidget({super.key, this.size = 70});

  @override
  Widget build(BuildContext context) {
    final scale = size / 74.0;

    return SizedBox(
      width: 278.w * scale,
      height: 130.h * scale,
      child: FittedBox(
        fit: BoxFit.contain,

        child: Image.asset(
          'assets/eye_clock_animation.gif',
          width: 281,
          height: 131,
          gaplessPlayback: true, // avoids a blank flash on rebuild
        ),
      ),
    );
  }
}