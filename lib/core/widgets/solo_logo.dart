import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable SOLO logo widget used across all pages.
/// S (navy) + O (teal circle) + L (navy) + O (green circle)
class SoloLogo extends StatelessWidget {
  final double? height;
  final double? width;

  const SoloLogo({
    super.key,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // S
        SvgPicture.asset(
          'assets/svg/s.svg',
          height: 28,
          colorFilter: const ColorFilter.mode(Color(0xFF002C3E), BlendMode.srcIn),
        ),
        // O → teal circle
        Container(
          width: 28.45,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: const BoxDecoration(
            color: Color(0xFF0CB4AB),
            shape: BoxShape.circle,
          ),
        ),
        // L
        SvgPicture.asset(
          'assets/svg/L.svg',
          height: 28,
          colorFilter: const ColorFilter.mode(Color(0xFF002C3E), BlendMode.srcIn),
        ),
        // O → lime green circle
        Container(
          width: 28.45,
          height: 28,
          margin: const EdgeInsets.only(left: 1),
          decoration: const BoxDecoration(
            color: Color(0xFFB5D43C),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );

    if (height != null || width != null) {
      return SizedBox(
        height: height,
        width: width,
        child: FittedBox(
          fit: BoxFit.contain,
          child: logo,
        ),
      );
    }

    return logo;
  }
}
