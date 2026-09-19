import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SoloTurquoiseAnimation extends StatefulWidget {
  final double? width;
  final double? height;
  final double? size;
  final bool isHappy;
  final bool isRed;
  final bool lookUpRight;
  final VoidCallback? onTap;

  const SoloTurquoiseAnimation({
    super.key,
    this.width,
    this.height,
    this.size,
    this.isHappy = false,
    this.isRed = false,
    this.lookUpRight = false,
    this.onTap,
  });

  @override
  State<SoloTurquoiseAnimation> createState() => _SoloTurquoiseAnimationState();
}

class _SoloTurquoiseAnimationState extends State<SoloTurquoiseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const String _buttonSvgBase = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2048 2048" width="100%" height="100%">
  <g id="Shadow">
    <circle cx="1082.85" cy="1082.87" r="890.78" fill="#002c3e" opacity=".25"/>
  </g>
  <g id="Button">
    <circle cx="1023.98" cy="1024" r="890.78" fill="#0aa298"/>
    <path d="M1914.76,1024c0-43.11-3.13-85.49-9.05-126.96l-390.33-390.33-1008.16,1008.16,391.03,391.03c41.08,5.81,83.05,8.88,125.73,8.88,491.96,0,890.78-398.82,890.78-890.78Z" fill="#0a8980"/>
    <circle cx="1023.98" cy="1024" r="712.54" fill="#0cb4ab"/>
    <path d="M448.54,648.32c214.3-328,652.92-421.16,981.89-209.55-5.51-3.82-11.07-7.59-16.72-11.28-329.45-215.24-771-122.66-986.24,206.78-215.24,329.44-122.66,771,206.78,986.24,1.44.94,2.9,1.83,4.34,2.76-315.79-219.08-401.6-651.16-190.05-974.95Z" fill="#1ac7be"/>
    <path d="M1537.3,529.61c225.65,233.87,268.48,600.52,83.2,884.12-215.24,329.44-656.8,422.02-986.24,206.78-39.13-25.56-74.86-54.35-107.19-85.72,36.48,37.81,77.73,72.16,123.57,102.11,329.44,215.24,771,122.66,986.24-206.78,189.68-290.32,140.27-667.66-99.58-900.5Z" fill="#046a64"/>
    <path d="M180.22,1064.3c0-491.96,398.81-890.78,890.78-890.78,210.17,0,403.31,72.83,555.65,194.57-158.61-145.81-370.22-234.87-602.66-234.87-491.96,0-890.78,398.82-890.78,890.78,0,281.79,130.88,532.98,335.13,696.2-177.1-162.81-288.12-396.38-288.12-655.91Z" fill="#067e78"/>
  </g>
</svg>
''';

  static const String _buttonSvgRed = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2048 2048" width="100%" height="100%">
  <g id="Shadow">
    <circle cx="1082.85" cy="1082.87" r="890.78" fill="#002c3e" opacity=".25"/>
  </g>
  <g id="Button">
    <circle cx="1023.98" cy="1024" r="890.78" fill="#D95A4B"/>
    <path d="M1914.76,1024c0-43.11-3.13-85.49-9.05-126.96l-390.33-390.33-1008.16,1008.16,391.03,391.03c41.08,5.81,83.05,8.88,125.73,8.88,491.96,0,890.78-398.82,890.78-890.78Z" fill="#BB4B3D"/>
    <circle cx="1023.98" cy="1024" r="712.54" fill="#EE6A59"/>
    <path d="M448.54,648.32c214.3-328,652.92-421.16,981.89-209.55-5.51-3.82-11.07-7.59-16.72-11.28-329.45-215.24-771-122.66-986.24,206.78-215.24,329.44-122.66,771,206.78,986.24,1.44.94,2.9,1.83,4.34,2.76-315.79-219.08-401.6-651.16-190.05-974.95Z" fill="#F58A7D"/>
    <path d="M1537.3,529.61c225.65,233.87,268.48,600.52,83.2,884.12-215.24,329.44-656.8,422.02-986.24,206.78-39.13-25.56-74.86-54.35-107.19-85.72,36.48,37.81,77.73,72.16,123.57,102.11,329.44,215.24,771,122.66,986.24-206.78,189.68-290.32,140.27-667.66-99.58-900.5Z" fill="#91382D"/>
    <path d="M180.22,1064.3c0-491.96,398.81-890.78,890.78-890.78,210.17,0,403.31,72.83,555.65,194.57-158.61-145.81-370.22-234.87-602.66-234.87-491.96,0-890.78,398.82-890.78,890.78,0,281.79,130.88,532.98,335.13,696.2-177.1-162.81-288.12-396.38-288.12-655.91Z" fill="#A9483A"/>
  </g>
</svg>
''';

  static const String _happyLidsSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2048 2048" width="100%" height="100%">
  <g id="Lids-happy">
    <path d="M923.44,931.64c-18.04,0-32.67-14.63-32.67-32.67v-46.39c0-67.95-55.28-123.23-123.23-123.23s-123.23,55.28-123.23,123.23v46.39c0,18.04-14.63,32.67-32.67,32.67s-32.67-14.63-32.67-32.67v-46.39c0-103.98,84.59-188.57,188.57-188.57s188.57,84.59,188.57,188.57v46.39c0,18.04-14.63,32.67-32.67,32.67Z" fill="#024c48"/>
    <path d="M1436,931.64c-18.04,0-32.67-14.63-32.67-32.67v-46.39c0-67.95-55.28-123.23-123.23-123.23s-123.23,55.28-123.23,123.23v46.39c0,18.04-14.63,32.67-32.67,32.67s-32.67-14.63-32.67-32.67v-46.39c0-103.98,84.59-188.57,188.57-188.57s188.57,84.59,188.57,188.57v46.39c0,18.04-14.63,32.67-32.67,32.67Z" fill="#024c48"/>
  </g>
</svg>
''';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double targetWidth = widget.size ?? widget.width ?? 195.13;
    final double targetHeight = widget.size ?? widget.height ?? 195.13;

    Widget mascot = SizedBox(
      width: targetWidth,
      height: targetHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base SVG Button (Shadow & Colored Body)
          SvgPicture.string(
            widget.isRed ? _buttonSvgRed : _buttonSvgBase,
            width: targetWidth,
            height: targetHeight,
            fit: BoxFit.contain,
          ),

          // Moving & Blinking Eyes (Exact SVG SMIL Animation)
          if (!widget.isHappy)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SoloEyesPainter(
                      progress: _controller.value,
                      lookUpRight: widget.lookUpRight,
                    ),
                  );
                },
              ),
            ),

          // Happy Eyes (When checked-in / happy)
          if (widget.isHappy)
            SvgPicture.string(
              _happyLidsSvg,
              width: targetWidth,
              height: targetHeight,
              fit: BoxFit.contain,
            ),
        ],
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: mascot,
      );
    }

    return mascot;
  }
}

/// Alias for ease of use
typedef SoloTurquoiseMascot = SoloTurquoiseAnimation;
typedef SoloMascotAnimation = SoloTurquoiseAnimation;

class _Keyframe {
  final double time;
  final Offset offset;
  const _Keyframe(this.time, this.offset);
}

class _SoloEyesPainter extends CustomPainter {
  final double progress;
  final bool lookUpRight;

  _SoloEyesPainter({required this.progress, this.lookUpRight = false});

  static const List<_Keyframe> _keyframes = [
    _Keyframe(0.00, Offset(0, 0)),
    _Keyframe(0.06, Offset(-139, 0)),
    _Keyframe(0.12, Offset(0, 0)),
    _Keyframe(0.18, Offset(139, 0)),
    _Keyframe(0.24, Offset(0, 0)),
    _Keyframe(0.30, Offset(0, -139)),
    _Keyframe(0.36, Offset(0, 0)),
    _Keyframe(0.42, Offset(0, 139)),
    _Keyframe(0.48, Offset(0, 0)),
    _Keyframe(0.54, Offset(-98, -98)),
    _Keyframe(0.60, Offset(0, 0)),
    _Keyframe(0.66, Offset(98, -98)),
    _Keyframe(0.72, Offset(0, 0)),
    _Keyframe(0.78, Offset(-98, 98)),
    _Keyframe(0.84, Offset(0, 0)),
    _Keyframe(0.90, Offset(98, 98)),
    _Keyframe(0.96, Offset(0, 0)),
    _Keyframe(1.00, Offset(0, 0)),
  ];

  static const List<List<double>> _blinks = [
    [0.231, 0.240, 0.249],
    [0.471, 0.480, 0.489],
    [0.711, 0.720, 0.729],
    [0.951, 0.960, 0.969],
  ];

  Offset _getPupilOffset(double t) {
    if (lookUpRight) {
      return const Offset(98, -98);
    }
    for (int i = 0; i < _keyframes.length - 1; i++) {
      final kf1 = _keyframes[i];
      final kf2 = _keyframes[i + 1];
      if (t >= kf1.time && t <= kf2.time) {
        final double interval = kf2.time - kf1.time;
        if (interval <= 0) return kf1.offset;
        final double localT = ((t - kf1.time) / interval).clamp(0.0, 1.0);
        // SVG keySplines="0.42 0 0.58 1"
        const curve = Cubic(0.42, 0.0, 0.58, 1.0);
        final double easedT = curve.transform(localT);
        return Offset(
          kf1.offset.dx + (kf2.offset.dx - kf1.offset.dx) * easedT,
          kf1.offset.dy + (kf2.offset.dy - kf1.offset.dy) * easedT,
        );
      }
    }
    return Offset.zero;
  }

  double _getBlinkFactor(double t) {
    for (final b in _blinks) {
      final double tStart = b[0];
      final double tMid = b[1];
      final double tEnd = b[2];
      if (t >= tStart && t <= tMid) {
        return 1.0 - ((t - tStart) / (tMid - tStart));
      } else if (t > tMid && t <= tEnd) {
        return (t - tMid) / (tEnd - tMid);
      }
    }
    return 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 2048 x 2048 coordinate space from SVG viewBox
    final double scale = size.width / 2048.0;
    canvas.save();
    canvas.scale(scale, scale);

    final double blinkFactor = _getBlinkFactor(progress);
    if (blinkFactor > 0.01) {
      // Blink clip rect centered at y = 853.15, original height = 377.22
      final double clipHeight = 377.22 * blinkFactor;
      final double clipY = 853.15 - clipHeight / 2.0;
      final Rect blinkRect = Rect.fromLTWH(578.83, clipY, 889.87, clipHeight);

      canvas.save();
      canvas.clipRect(blinkRect);

      final Paint whitePaint = Paint()..color = const Color(0xFFF5F5F5);
      final Paint pupilPaint = Paint()..color = const Color(0xFF000000);

      const Offset leftEyeCenter = Offset(767.44, 853.15);
      const Offset rightEyeCenter = Offset(1280.09, 853.15);
      const double eyeRadius = 188.61;
      const double pupilRadius = 125.1;

      // Draw eye whites
      canvas.drawCircle(leftEyeCenter, eyeRadius, whitePaint);
      canvas.drawCircle(rightEyeCenter, eyeRadius, whitePaint);

      final Offset pupilOffset = _getPupilOffset(progress);

      // Left pupil clipped to left eye circle
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: leftEyeCenter, radius: eyeRadius)),
      );
      canvas.drawCircle(leftEyeCenter + pupilOffset, pupilRadius, pupilPaint);
      canvas.restore();

      // Right pupil clipped to right eye circle
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: rightEyeCenter, radius: eyeRadius)),
      );
      canvas.drawCircle(rightEyeCenter + pupilOffset, pupilRadius, pupilPaint);
      canvas.restore();

      canvas.restore(); // restore blink clip
    }

    canvas.restore(); // restore scale
  }

  @override
  bool shouldRepaint(covariant _SoloEyesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.lookUpRight != lookUpRight;
  }
}
