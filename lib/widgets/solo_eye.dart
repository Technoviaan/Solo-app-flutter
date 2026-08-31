import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solo_app/core/utils/app_size.dart';

class SoloLogoWidget extends StatelessWidget {
  final double size;

  const SoloLogoWidget({super.key, this.size = 70});

  @override
  Widget build(BuildContext context) {
    final scale = size / 74.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 400.w * scale,
          height: 130.h * scale,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Image.asset(
              'assets/eye_clock_animation.gif',
              gaplessPlayback: true,
            ),
          ),
        ),
      ],
    );
  }
}