import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

/// SOS Button with 20s countdown and 3 radar arcs animation.
/// Exactly follows the specification from `SOS Button - Active (radar).svg` and `sos-radar.js`.
class SosRadarButton extends StatefulWidget {
  final bool active;
  final int seconds;
  final bool confirmed;
  final VoidCallback? onTap;
  final double size;

  const SosRadarButton({
    super.key,
    required this.active,
    this.seconds = 20,
    this.confirmed = false,
    this.onTap,
    this.size = 90,
  });

  @override
  State<SosRadarButton> createState() => _SosRadarButtonState();
}

class _SosRadarButtonState extends State<SosRadarButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radarCtrl;

  // Single static paths parsed once
  static final Path _leftSPath = parseSvgPathData(
    "M925.78,1149.14c-8.33-10.59-19.21-19.02-32.64-25.26-13.44-6.24-26.4-9.37-38.89-9.37-6.44,0-12.97.57-19.59,1.7-6.63,1.13-12.59,3.32-17.88,6.53-5.31,3.22-9.75,7.38-13.34,12.49-3.6,5.11-5.39,11.64-5.39,19.59,0,6.81,1.42,12.49,4.26,17.03,2.84,4.54,7,8.51,12.49,11.92,5.48,3.41,12.01,6.53,19.59,9.37,7.57,2.84,16.08,5.77,25.55,8.8,13.63,4.54,27.82,9.56,42.58,15.04,14.76,5.49,28.19,12.78,40.31,21.86,12.11,9.08,22.14,20.35,30.09,33.78,7.95,13.44,11.92,30.19,11.92,50.24,0,23.09-4.26,43.06-12.77,59.89-8.51,16.85-19.97,30.76-34.34,41.73-14.39,10.98-30.85,19.12-49.39,24.41-18.55,5.3-37.66,7.95-57.34,7.95-28.77,0-56.58-5.02-83.45-15.04-26.88-10.02-49.2-24.31-66.99-42.86l63.58-64.72c9.84,12.11,22.8,22.24,38.89,30.37,16.08,8.14,32.07,12.21,47.97,12.21,7.18,0,14.19-.75,21-2.27,6.81-1.51,12.77-3.97,17.88-7.38,5.11-3.41,9.17-7.95,12.21-13.62,3.02-5.68,4.54-12.49,4.54-20.44s-1.9-14-5.68-19.3c-3.79-5.3-9.18-10.12-16.18-14.48-7.01-4.35-15.71-8.32-26.11-11.92-10.41-3.59-22.24-7.47-35.48-11.64-12.87-4.16-25.46-9.08-37.75-14.76-12.3-5.68-23.28-12.96-32.93-21.86-9.65-8.89-17.41-19.68-23.28-32.36-5.87-12.68-8.8-28.1-8.8-46.27,0-22.33,4.54-41.44,13.63-57.34,9.08-15.9,21.01-28.95,35.76-39.17,14.76-10.22,31.41-17.69,49.96-22.42,18.54-4.73,37.27-7.1,56.2-7.1,22.71,0,45.89,4.17,69.54,12.49,23.65,8.33,44.37,20.63,62.16,36.9l-61.88,65.29Z",
  );

  static final Path _rightSPath = parseSvgPathData(
    "M1749.66,1149.14c-8.33-10.59-19.21-19.02-32.64-25.26-13.44-6.24-26.4-9.37-38.89-9.37-6.44,0-12.97.57-19.59,1.7-6.63,1.13-12.59,3.32-17.88,6.53-5.31,3.22-9.75,7.38-13.34,12.49-3.6,5.11-5.39,11.64-5.39,19.59,0,6.81,1.42,12.49,4.26,17.03,2.84,4.54,7,8.51,12.49,11.92,5.48,3.41,12.01,6.53,19.59,9.37,7.57,2.84,16.08,5.77,25.55,8.8,13.63,4.54,27.82,9.56,42.58,15.04,14.76,5.49,28.19,12.78,40.31,21.86,12.11,9.08,22.14,20.35,30.09,33.78,7.95,13.44,11.92,30.19,11.92,50.24,0,23.09-4.26,43.06-12.77,59.89-8.51,16.85-19.97,30.76-34.34,41.73-14.39,10.98-30.85,19.12-49.39,24.41-18.55,5.3-37.66,7.95-57.34,7.95-28.77,0-56.58-5.02-83.45-15.04-26.88-10.02-49.2-24.31-66.99-42.86l63.58-64.72c9.84,12.11,22.8,22.24,38.89,30.37,16.08,8.14,32.07,12.21,47.97,12.21,7.18,0,14.19-.75,21-2.27,6.81-1.51,12.77-3.97,17.88-7.38,5.11-3.41,9.17-7.95,12.21-13.62,3.02-5.68,4.54-12.49,4.54-20.44s-1.9-14-5.68-19.3c-3.79-5.3-9.18-10.12-16.18-14.48-7.01-4.35-15.71-8.32-26.11-11.92-10.41-3.59-22.24-7.47-35.48-11.64-12.87-4.16-25.46-9.08-37.75-14.76-12.3-5.68-23.28-12.96-32.93-21.86-9.65-8.89-17.41-19.68-23.28-32.36-5.87-12.68-8.8-28.1-8.8-46.27,0-22.33,4.54-41.44,13.63-57.34,9.08-15.9,21.01-28.95,35.76-39.17,14.76-10.22,31.41-17.69,49.96-22.42,18.54-4.73,37.27-7.1,56.2-7.1,22.71,0,45.89,4.17,69.54,12.49,23.65,8.33,44.37,20.63,62.16,36.9l-61.88,65.29Z",
  );

  static final Path _arc1Path = parseSvgPathData(
    "M609.59,794.57c-6.17-6.17-14.36-9.57-23.08-9.57h-.14c-62.09,0-120.48,24.2-164.4,68.15-43.96,43.95-68.15,102.37-68.12,164.51,0,8.72,3.4,16.92,9.57,23.08,6.17,6.16,14.36,9.56,23.08,9.56h.02c17.99,0,32.64-14.66,32.65-32.66.03-44.74,17.42-86.76,48.98-118.32,31.6-31.57,73.63-48.98,118.36-49.02h.01c17.99,0,32.63-14.64,32.64-32.64,0-8.72-3.39-16.92-9.56-23.09Z",
  );

  static final Path _arc2Path = parseSvgPathData(
    "M609.58,638.82c-6.16-6.16-14.36-9.56-23.08-9.56,0,0-.01,0-.02,0-50.38,0-99.55,9.58-146.12,28.48-48.22,19.56-91.44,48.27-128.48,85.32-37.04,37.03-65.74,80.25-85.3,128.46-18.9,46.59-28.47,95.76-28.44,146.14,0,8.72,3.4,16.92,9.57,23.09,6.17,6.16,14.36,9.56,23.07,9.56h.02c8.72,0,16.92-3.4,23.09-9.57,6.17-6.17,9.56-14.38,9.56-23.1.01-69.41,21.6-135.44,62.42-190.97,9.68-13.18,20.51-25.78,32.17-37.44,61.01-60.99,142.14-94.61,228.45-94.67h.03c8.7,0,16.89-3.39,23.05-9.55,6.17-6.17,9.56-14.37,9.57-23.09,0-8.73-3.4-16.93-9.57-23.09Z",
  );

  static final Path _arc3Path = parseSvgPathData(
    "M586.52,465.97h-.28c-71.5,0-141.26,13.59-207.33,40.39-68.47,27.77-129.89,68.55-182.53,121.21-52.62,52.61-93.38,114.01-121.14,182.49-26.83,66.15-40.42,136-40.41,207.59,0,8.72,3.39,16.93,9.55,23.09,6.16,6.16,14.35,9.55,23.07,9.55.01,0,.02,0,.03,0,8.72,0,16.91-3.4,23.08-9.56,6.17-6.17,9.56-14.36,9.55-23.07.02-63.23,12-124.82,35.61-183.05,24.45-60.3,60.39-114.42,106.83-160.87,46.48-46.47,100.62-82.43,160.91-106.88,58.23-23.62,119.81-35.59,183.02-35.59h0c17.99,0,32.65-14.64,32.66-32.63,0-18-14.64-32.66-32.64-32.67Z",
  );

  @override
  void initState() {
    super.initState();
    // 2550ms cycle time matching SVG dur="2.55s"
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2550),
    );

    if (widget.active) {
      _radarCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SosRadarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_radarCtrl.isAnimating) {
      _radarCtrl.forward(from: 0.0);
      _radarCtrl.repeat();
    } else if (!widget.active && _radarCtrl.isAnimating) {
      _radarCtrl.stop();
      _radarCtrl.reset();
    }
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double targetWidth = widget.size;
    final double targetHeight = widget.size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Opacity(
        opacity: widget.confirmed ? 0.65 : 1.0,
        child: SizedBox(
          width: targetWidth,
          height: targetHeight,
          child: AnimatedBuilder(
            animation: _radarCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _SosRadarPainter(
                  active: widget.active,
                  seconds: widget.seconds,
                  confirmed: widget.confirmed,
                  cycleProgress: _radarCtrl.value,
                  leftSPath: _leftSPath,
                  rightSPath: _rightSPath,
                  arc1Path: _arc1Path,
                  arc2Path: _arc2Path,
                  arc3Path: _arc3Path,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SosRadarPainter extends CustomPainter {
  final bool active;
  final int seconds;
  final bool confirmed;
  final double cycleProgress;
  final Path leftSPath;
  final Path rightSPath;
  final Path arc1Path;
  final Path arc2Path;
  final Path arc3Path;

  _SosRadarPainter({
    required this.active,
    required this.seconds,
    required this.confirmed,
    required this.cycleProgress,
    required this.leftSPath,
    required this.rightSPath,
    required this.arc1Path,
    required this.arc2Path,
    required this.arc3Path,
  });

  /// Calculates arc opacity matching SVG <animate> keyTimes="0; 0.08; 0.4; 0.56; 1" values="0; 1; 1; 0; 0"
  double _calcArcOpacity(double t, double beginOffset) {
    if (!active || confirmed) return 0.0;
    double localT = t - beginOffset;
    if (localT < 0.0) localT += 1.0;
    if (localT > 1.0) localT -= 1.0;

    if (localT < 0.08) {
      return (localT / 0.08).clamp(0.0, 1.0);
    } else if (localT < 0.40) {
      return 1.0;
    } else if (localT < 0.56) {
      return (1.0 - (localT - 0.40) / 0.16).clamp(0.0, 1.0);
    } else {
      return 0.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Coordinate space from SVG viewBox: 0 0 2048 2048
    final double scale = size.width / 2048.0;
    canvas.save();
    canvas.scale(scale, scale);

    final Paint arcPaint = Paint()
      ..color = const Color(0xFFD95A4B)
      ..style = PaintingStyle.fill;

    // 1. Radar Arcs (only drawn when active)
    if (active && !confirmed) {
      // Arc1: begin="0s" -> beginOffset = 0.0
      final double op1 = _calcArcOpacity(cycleProgress, 0.0);
      if (op1 > 0.01) {
        arcPaint.color = const Color(0xFFD95A4B).withValues(alpha: op1);
        canvas.drawPath(arc1Path, arcPaint);
      }

      // Arc2: begin="0.55s" -> beginOffset = 0.55 / 2.55 = ~0.2157
      final double op2 = _calcArcOpacity(cycleProgress, 0.55 / 2.55);
      if (op2 > 0.01) {
        arcPaint.color = const Color(0xFFD95A4B).withValues(alpha: op2);
        canvas.drawPath(arc2Path, arcPaint);
      }

      // Arc3: begin="1.1s" -> beginOffset = 1.1 / 2.55 = ~0.4314
      final double op3 = _calcArcOpacity(cycleProgress, 1.10 / 2.55);
      if (op3 > 0.01) {
        arcPaint.color = const Color(0xFFD95A4B).withValues(alpha: op3);
        canvas.drawPath(arc3Path, arcPaint);
      }
    }

    // 2. SOS Button Red Pill
    final Paint buttonPaint = Paint()
      ..color = const Color(0xFFD95A4B)
      ..style = PaintingStyle.fill;

    final RRect pillRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(488.9, 907.16, 1524.27, 674.87),
      const Radius.circular(337.43),
    );
    canvas.drawRRect(pillRRect, buttonPaint);

    // 3. Letters S on Left & Right
    final Paint whitePaint = Paint()
      ..color = const Color(0xFFF5F5F5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(leftSPath, whitePaint);
    canvas.drawPath(rightSPath, whitePaint);

    // 4. Center Circle Dial
    const Offset centerCircle = Offset(1255.44, 1244.6);
    const double centerRadius = 212.86;
    canvas.drawCircle(centerCircle, centerRadius, whitePaint);

    // 5. Center Content: Countdown Number (if active) or Center O Ring
    if (active) {
      final String text = seconds.toString().padLeft(2, '0');
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Color(0xFF002C3E),
            fontSize: 271,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
            letterSpacing: -2,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(centerCircle.dx - tp.width / 2.0,
            centerCircle.dy - tp.height / 2.0),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SosRadarPainter oldDelegate) {
    return oldDelegate.active != active ||
        oldDelegate.seconds != seconds ||
        oldDelegate.confirmed != confirmed ||
        oldDelegate.cycleProgress != cycleProgress;
  }
}
