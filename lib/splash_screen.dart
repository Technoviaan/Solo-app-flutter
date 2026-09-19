import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solo_app/home/checkin/notification_service.dart';
import 'package:solo_app/home/home_page.dart';
import 'package:solo_app/subscription/subscription_page.dart';
import 'package:solo_app/loginWithNumber/login_page.dart';
import 'package:solo_app/loginWithNumber/name_onboarding_page.dart';
import 'package:solo_app/loginWithNumber/email_page.dart';
import 'package:solo_app/core/storage/token_storage.dart';
import 'package:solo_app/core/utils/app_size.dart';
import 'package:solo_app/core/deeplink/deep_link_service.dart';
import 'package:solo_app/subscription/subscription_api.dart';
import 'package:solo_app/subscription/payment_result_page.dart';

// solo_logo_animated.dart
//
// SOLO-Logo-Animated.svg ka 1:1 Flutter port (blinking eyes + ghadi ke hands).
// Values (paths, colors, keyTimes, keySplines, durations) seedha SVG se generate hui hain.
//
// pubspec.yaml:
//   dependencies:
//     path_drawing: ^1.0.1
//
// Use:
//   const SoloLogoAnimated(width: 260)                    // tight crop (default)
//   const SoloLogoAnimated(width: 260, cropToLogo: false) // original 2048x2048 viewBox
//
// Background transparent hai (SVG jaisa) — brand blue ke upar rakhna.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_drawing/path_drawing.dart';

class SoloLogoAnimated extends StatefulWidget {
  const SoloLogoAnimated({super.key, this.width, this.cropToLogo = true});

  /// Null ho to parent ki available width use hoti hai; height aspect ratio se aati hai.
  final double? width;

  /// true = logo ke around tight box, false = original SVG viewBox (0 0 2048 2048).
  final bool cropToLogo;

  @override
  State<SoloLogoAnimated> createState() => _SoloLogoAnimatedState();
}

class _SoloLogoAnimatedState extends State<SoloLogoAnimated>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _seconds = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    // Alag-alag loops (13.44s / 2.5s / 30s) ke liye ek hi continuous clock.
    _ticker = createTicker((elapsed) {
      _seconds.value = elapsed.inMicroseconds / 1000000.0;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.cropToLogo ? _G.cropBox : _G.fullBox;
    Widget logo = AspectRatio(
      aspectRatio: box.width / box.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Static layer ek baar rasterize hoti hai, har frame repaint nahi.
          RepaintBoundary(child: CustomPaint(painter: _StaticPainter(box))),
          RepaintBoundary(
            child: CustomPaint(painter: _AnimatedPainter(box, _seconds)),
          ),
        ],
      ),
    );
    if (widget.width != null) {
      logo = SizedBox(width: widget.width, child: logo);
    }
    return logo;
  }
}

// ───────────────────────── painters ─────────────────────────

/// SVG viewBox -> widget size (preserveAspectRatio = xMidYMid meet).
void _applyViewBox(Canvas canvas, Size size, Rect box) {
  final s = math.min(size.width / box.width, size.height / box.height);
  canvas.translate(
    (size.width - box.width * s) / 2,
    (size.height - box.height * s) / 2,
  );
  canvas.scale(s, s);
  canvas.translate(-box.left, -box.top);
}

class _StaticPainter extends CustomPainter {
  _StaticPainter(this.box);
  final Rect box;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _applyViewBox(canvas, size, box);
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
    for (final shape in _G.staticShapes) {
      paint.color = shape.color;
      canvas.drawPath(shape.path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StaticPainter old) => old.box != box;
}

class _AnimatedPainter extends CustomPainter {
  _AnimatedPainter(this.box, this.seconds) : super(repaint: seconds);
  final Rect box;
  final ValueNotifier<double> seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds.value;
    canvas.save();
    _applyViewBox(canvas, size, box);
    _paintEyes(canvas, t);
    _paintClock(canvas, t);
    canvas.restore();
  }

  void _paintEyes(Canvas canvas, double t) {
    final u = (t % _G.eyeLoopSec) / _G.eyeLoopSec;

    // Blink = clip rect ki y/height linear animate hoti hai.
    final blinkY = _sample(u, _G.blinkTimes, _G.blinkY);
    final blinkH = _sample(u, _G.blinkTimes, _G.blinkH);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(_G.blinkX, blinkY, _G.blinkW, blinkH));

    final white = Paint()
      ..isAntiAlias = true
      ..color = _G.eyeWhite;
    canvas.drawPath(_G.eyeLPath, white);
    canvas.drawPath(_G.eyeRPath, white);

    // Pupils: spline (0.42 0 0.58 1) easing, apni eye ke circle se clipped.
    final py = _sample(u, _G.pupilTimes, _G.pupilY, eased: true);
    final lx = _sample(u, _G.pupilTimes, _G.pupilLX, eased: true);
    final rx = _sample(u, _G.pupilTimes, _G.pupilRX, eased: true);
    final black = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF000000);

    canvas.save();
    canvas.clipPath(_G.eyeLPath);
    canvas.drawCircle(Offset(lx, py), _G.pupilR, black);
    canvas.restore();

    canvas.save();
    canvas.clipPath(_G.eyeRPath);
    canvas.drawCircle(Offset(rx, py), _G.pupilR, black);
    canvas.restore();

    canvas.restore();
  }

  void _paintClock(Canvas canvas, double t) {
    const twoPi = math.pi * 2;
    final minuteAngle = (t % 2.5) / 2.5 * twoPi; // 2.5s / turn
    final hourAngle = (t % 30.0) / 30.0 * twoPi; // 30s / turn

    _drawHand(canvas, minuteAngle, _G.minuteRRect, _G.minuteTx, _G.minuteTy,
        _G.minuteRot, _G.minuteColor);
    _drawHand(canvas, hourAngle, _G.hourRRect, _G.hourTx, _G.hourTy,
        _G.hourRot, _G.hourColor);

    // Center dots (hands ke upar), apne transform ke saath.
    canvas.save();
    canvas.translate(_G.dotTx, _G.dotTy);
    canvas.rotate(_G.dotRot * math.pi / 180);
    final c = Offset(_G.dotCx, _G.dotCy);
    canvas.drawCircle(c, _G.dotBigR, Paint()..isAntiAlias = true..color = _G.dotBigColor);
    canvas.drawCircle(c, _G.dotSmallR, Paint()..isAntiAlias = true..color = _G.dotSmallColor);
    canvas.restore();
  }

  void _drawHand(Canvas canvas, double angle, RRect rrect, double tx, double ty,
      double rotDeg, Color color) {
    canvas.save();
    // <animateTransform type="rotate" from="0 cx cy" to="360 cx cy">
    canvas.translate(_G.clockCx, _G.clockCy);
    canvas.rotate(angle);
    canvas.translate(-_G.clockCx, -_G.clockCy);
    // rect ka apna transform="translate(tx ty) rotate(deg)"
    canvas.translate(tx, ty);
    canvas.rotate(rotDeg * math.pi / 180);
    canvas.drawRRect(rrect, Paint()..isAntiAlias = true..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AnimatedPainter old) =>
      old.box != box || old.seconds != seconds;
}

// ───────────────────────── keyframe sampling (SMIL) ─────────────────────────

const Cubic _ease = Cubic(0.42, 0.0, 0.58, 1.0); // keySplines="0.42 0 0.58 1"

/// SMIL keyTimes/values sampler. [u] 0..1. calcMode=linear by default,
/// [eased] = true => calcMode="spline" with keySplines 0.42 0 0.58 1.
double _sample(double u, List<double> times, List<double> vals,
    {bool eased = false}) {
  if (u <= times.first) return vals.first;
  if (u >= times.last) return vals.last;
  var i = 0;
  while (i < times.length - 2 && u >= times[i + 1]) {
    i++;
  }
  final span = times[i + 1] - times[i];
  var f = span <= 0 ? 1.0 : (u - times[i]) / span;
  if (eased) f = _ease.transform(f);
  return vals[i] + (vals[i + 1] - vals[i]) * f;
}

// ───────────────────────── geometry (SVG se generated) ─────────────────────────

class _Shape {
  _Shape.path(String d, this.color) : path = parseSvgPathData(d);
  _Shape.circle(double cx, double cy, double r, this.color)
      : path = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

  final Path path;
  final Color color;
}

class _G {
  static const Rect fullBox = Rect.fromLTRB(0, 0, 2048, 2048);
  static const Rect cropBox = Rect.fromLTRB(37, 513, 2010, 1420);

  // Draw order = SVG order (button -> clock face -> S / L / tagline).
  static final List<_Shape> staticShapes = <_Shape>[
    _Shape.circle(779.44, 855.17, 329.31, Color(0xFF0AA298)),
    _Shape.path(r'M1108.75,855.17c0-15.94-1.16-31.6-3.34-46.94l-144.3-144.3-372.71,372.71,144.56,144.56c15.19,2.15,30.7,3.28,46.48,3.28,181.87,0,329.31-147.44,329.31-329.31Z', Color(0xFF0A8980)),
    _Shape.circle(779.44, 855.17, 263.42, Color(0xFF0CB4AB)),
    _Shape.path(r'M566.7,716.28c79.22-121.26,241.38-155.7,363-77.47-2.04-1.41-4.09-2.81-6.18-4.17-121.79-79.57-285.03-45.35-364.6,76.45-79.57,121.79-45.35,285.03,76.45,364.6.53.35,1.07.68,1.61,1.02-116.74-80.99-148.47-240.73-70.26-360.43Z', Color(0xFF1AC7BE)),
    _Shape.path(r'M969.2,672.4c83.42,86.46,99.25,222.01,30.76,326.85-79.57,121.79-242.81,156.02-364.6,76.45-14.46-9.45-27.68-20.09-39.63-31.69,13.49,13.98,28.73,26.68,45.68,37.75,121.79,79.57,285.03,45.35,364.6-76.45,70.12-107.33,51.85-246.83-36.81-332.91Z', Color(0xFF046A64)),
    _Shape.path(r'M467.51,870.06c0-181.87,147.44-329.31,329.31-329.31,77.7,0,149.1,26.93,205.42,71.93-58.64-53.9-136.87-86.83-222.8-86.83-181.87,0-329.31,147.44-329.31,329.31,0,104.18,48.39,197.04,123.89,257.38-65.47-60.19-106.51-146.54-106.51-242.48Z', Color(0xFF067E78)),
    _Shape.circle(1743.42, 931.1, 253.89, Color(0xFFB5D43C)),
    _Shape.path(r'M342.45,817.25c-9.93-12.63-22.92-22.68-38.94-30.13-16.03-7.45-31.49-11.17-46.38-11.17-7.68,0-15.47.68-23.36,2.03-7.9,1.35-15.01,3.96-21.33,7.79-6.33,3.84-11.63,8.8-15.91,14.9-4.29,6.09-6.43,13.88-6.43,23.36,0,8.12,1.69,14.9,5.08,20.31,3.38,5.41,8.35,10.16,14.9,14.22,6.54,4.06,14.33,7.79,23.36,11.18,9.02,3.38,19.18,6.89,30.47,10.49,16.25,5.42,33.18,11.41,50.79,17.94,17.6,6.55,33.62,15.24,48.08,26.07,14.44,10.83,26.41,24.27,35.89,40.29,9.48,16.03,14.22,36.01,14.22,59.93,0,27.54-5.08,51.36-15.24,71.44-10.16,20.09-23.82,36.68-40.96,49.77-17.16,13.1-36.8,22.8-58.91,29.12-22.12,6.32-44.92,9.48-68.39,9.48-34.31,0-67.49-5.99-99.54-17.94-32.06-11.96-58.69-29-79.9-51.12l75.84-77.19c11.73,14.45,27.19,26.52,46.38,36.22,19.18,9.71,38.26,14.56,57.22,14.56,8.57,0,16.93-.9,25.05-2.71,8.13-1.8,15.24-4.74,21.33-8.8,6.1-4.06,10.94-9.48,14.56-16.25,3.61-6.77,5.42-14.9,5.42-24.38s-2.27-16.7-6.77-23.02c-4.52-6.32-10.95-12.07-19.3-17.27-8.36-5.18-18.74-9.92-31.15-14.22-12.42-4.29-26.52-8.91-42.32-13.88-15.35-4.96-30.36-10.83-45.03-17.61-14.68-6.77-27.76-15.46-39.27-26.07-11.51-10.6-20.77-23.47-27.76-38.6-7-15.12-10.5-33.52-10.5-55.19,0-26.63,5.42-49.43,16.25-68.39,10.83-18.96,25.05-34.53,42.66-46.72,17.61-12.19,37.47-21.1,59.59-26.75,22.11-5.64,44.46-8.46,67.04-8.46,27.08,0,54.73,4.97,82.95,14.9,28.21,9.93,52.92,24.61,74.15,44.01l-73.81,77.87Z', Color(0xFFF5F5F5)),
    _Shape.path(r'M1167.02,1172.07v-479.41h116.46v378.52h185.54v100.89h-302Z', Color(0xFFF5F5F5)),
    _Shape.path(r'M152.67,1272.25l-32.58,62.76v35.7h-16.15v-35.7l-32.72-62.76h17.99l22.81,48.31,22.81-48.31h17.85Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M173.64,1366.95c-5.95-3.35-10.62-8.07-14.02-14.17-3.4-6.09-5.1-13.15-5.1-21.18s1.75-14.97,5.24-21.11c3.49-6.14,8.26-10.86,14.31-14.17,6.04-3.3,12.8-4.96,20.26-4.96s14.21,1.65,20.26,4.96c6.04,3.31,10.81,8.03,14.31,14.17,3.49,6.14,5.24,13.17,5.24,21.11s-1.8,14.97-5.38,21.11c-3.59,6.14-8.48,10.89-14.66,14.24-6.19,3.35-13.01,5.03-20.47,5.03s-14.02-1.68-19.97-5.03ZM205.3,1354.98c3.63-1.98,6.59-4.96,8.85-8.93,2.27-3.97,3.4-8.78,3.4-14.45s-1.09-10.46-3.26-14.38c-2.17-3.92-5.05-6.87-8.64-8.85-3.59-1.98-7.46-2.98-11.62-2.98s-8,.99-11.55,2.98c-3.54,1.98-6.35,4.94-8.43,8.85-2.08,3.92-3.12,8.71-3.12,14.38,0,8.41,2.15,14.9,6.45,19.48,4.3,4.58,9.7,6.87,16.22,6.87,4.15,0,8.05-.99,11.69-2.97Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M320.82,1292.65v78.06h-16.15v-9.21c-2.55,3.21-5.88,5.74-9.99,7.58-4.11,1.84-8.48,2.76-13.1,2.76-6.14,0-11.64-1.28-16.5-3.83-4.87-2.55-8.69-6.33-11.47-11.33-2.79-5.01-4.18-11.05-4.18-18.13v-45.9h16.01v43.49c0,6.99,1.75,12.35,5.24,16.08,3.49,3.73,8.26,5.6,14.31,5.6s10.84-1.86,14.38-5.6c3.54-3.73,5.31-9.09,5.31-16.08v-43.49h16.15Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M364.81,1294.71c3.92-2.22,8.57-3.33,13.95-3.33v16.72h-4.11c-6.33,0-11.12,1.61-14.38,4.82-3.26,3.21-4.89,8.78-4.89,16.72v41.08h-16.15v-78.06h16.15v11.33c2.36-3.97,5.5-7.06,9.42-9.28Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M490.18,1278.27c7.88,4.02,13.98,9.78,18.27,17.28,4.3,7.51,6.45,16.27,6.45,26.28s-2.15,18.7-6.45,26.07c-4.3,7.37-10.39,13.01-18.27,16.93-7.89,3.92-17.07,5.88-27.55,5.88h-32.16v-98.46h32.16c10.48,0,19.67,2.01,27.55,6.02ZM489.12,1348.18c6.14-6.23,9.21-15.02,9.21-26.35s-3.07-20.35-9.21-26.77c-6.14-6.42-14.97-9.63-26.49-9.63h-16.01v72.11h16.01c11.52,0,20.35-3.12,26.49-9.35Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M533.24,1310.5c3.26-6.04,7.7-10.74,13.32-14.1,5.62-3.35,11.83-5.03,18.63-5.03,6.14,0,11.5,1.2,16.08,3.61,4.58,2.41,8.24,5.41,10.98,8.99v-11.33h16.29v78.06h-16.29v-11.62c-2.74,3.68-6.47,6.75-11.19,9.21-4.72,2.45-10.11,3.68-16.15,3.68-6.71,0-12.84-1.72-18.42-5.17-5.57-3.45-9.99-8.26-13.25-14.45-3.26-6.19-4.89-13.2-4.89-21.04s1.63-14.78,4.89-20.83ZM588.92,1317.58c-2.22-3.97-5.12-6.99-8.71-9.07-3.59-2.08-7.46-3.12-11.62-3.12s-8.03,1.02-11.62,3.04c-3.59,2.03-6.49,5.01-8.71,8.92-2.22,3.92-3.33,8.57-3.33,13.95s1.11,10.11,3.33,14.17c2.22,4.06,5.15,7.15,8.78,9.28,3.63,2.12,7.48,3.19,11.55,3.19s8.03-1.04,11.62-3.12c3.59-2.08,6.49-5.12,8.71-9.14,2.22-4.01,3.33-8.71,3.33-14.1s-1.11-10.06-3.33-14.02Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M630.64,1279.33c-1.98-1.98-2.97-4.44-2.97-7.37s.99-5.38,2.97-7.37c1.98-1.98,4.44-2.97,7.37-2.97s5.24.99,7.22,2.97c1.98,1.98,2.98,4.44,2.98,7.37s-.99,5.38-2.98,7.37c-1.98,1.98-4.39,2.97-7.22,2.97s-5.38-.99-7.37-2.97ZM645.94,1292.65v78.06h-16.15v-78.06h16.15Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M683.34,1265.88v104.83h-16.15v-104.83h16.15Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M780.52,1292.65l-47.88,114.75h-16.72l15.87-37.97-30.74-76.78h17.99l21.96,59.5,22.81-59.5h16.72Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M830.87,1295.34c4.49-7.65,10.58-13.62,18.27-17.92,7.7-4.3,16.13-6.44,25.29-6.44,10.48,0,19.81,2.57,27.98,7.72,8.17,5.15,14.1,12.44,17.78,21.89h-19.41c-2.55-5.19-6.09-9.07-10.62-11.62-4.53-2.55-9.78-3.83-15.72-3.83-6.52,0-12.33,1.47-17.42,4.39-5.1,2.93-9.09,7.13-11.97,12.61-2.88,5.48-4.32,11.85-4.32,19.13s1.44,13.65,4.32,19.12c2.88,5.48,6.87,9.7,11.97,12.68,5.1,2.97,10.91,4.46,17.42,4.46,5.95,0,11.19-1.28,15.72-3.83,4.53-2.55,8.07-6.42,10.62-11.62h19.41c-3.68,9.45-9.61,16.72-17.78,21.82-8.17,5.1-17.5,7.65-27.98,7.65-9.26,0-17.71-2.15-25.36-6.45-7.65-4.3-13.72-10.27-18.2-17.92-4.49-7.65-6.73-16.29-6.73-25.92s2.24-18.28,6.73-25.92Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M995.35,1295.2c4.68,2.55,8.36,6.33,11.05,11.33,2.69,5.01,4.04,11.05,4.04,18.13v46.04h-16.01v-43.63c0-6.99-1.75-12.35-5.24-16.08-3.5-3.73-8.27-5.59-14.31-5.59s-10.84,1.86-14.38,5.59c-3.54,3.73-5.31,9.09-5.31,16.08v43.63h-16.15v-104.83h16.15v35.84c2.74-3.31,6.21-5.86,10.41-7.65,4.2-1.79,8.81-2.69,13.81-2.69,5.95,0,11.26,1.27,15.94,3.82Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M1101.95,1337.7h-59.64c.47,6.23,2.78,11.24,6.94,15.02,4.16,3.78,9.26,5.67,15.3,5.67,8.69,0,14.83-3.63,18.42-10.91h17.42c-2.36,7.18-6.64,13.06-12.82,17.64-6.19,4.58-13.86,6.87-23.02,6.87-7.46,0-14.14-1.68-20.04-5.03-5.9-3.35-10.53-8.07-13.89-14.17-3.35-6.09-5.03-13.15-5.03-21.18s1.63-15.09,4.89-21.18c3.26-6.09,7.84-10.79,13.74-14.1,5.9-3.3,12.68-4.96,20.33-4.96s13.93,1.61,19.69,4.82c5.76,3.21,10.25,7.72,13.46,13.53,3.21,5.81,4.82,12.49,4.82,20.05,0,2.93-.19,5.57-.57,7.93ZM1085.65,1324.67c-.1-5.95-2.22-10.72-6.37-14.31-4.16-3.59-9.31-5.38-15.44-5.38-5.57,0-10.34,1.77-14.31,5.31-3.97,3.54-6.33,8.34-7.08,14.38h43.21Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M1120.71,1310.43c3.26-6.09,7.77-10.79,13.53-14.1,5.76-3.3,12.37-4.96,19.83-4.96,9.44,0,17.26,2.24,23.45,6.73,6.19,4.49,10.36,10.89,12.54,19.2h-17.42c-1.42-3.87-3.68-6.89-6.8-9.07-3.12-2.17-7.04-3.26-11.76-3.26-6.61,0-11.88,2.34-15.8,7.01-3.92,4.67-5.88,11.22-5.88,19.62s1.96,14.97,5.88,19.69c3.92,4.72,9.18,7.08,15.8,7.08,9.35,0,15.54-4.11,18.56-12.32h17.42c-2.27,7.93-6.52,14.24-12.75,18.91-6.23,4.67-13.98,7.01-23.23,7.01-7.46,0-14.07-1.68-19.83-5.03-5.76-3.35-10.27-8.07-13.53-14.17-3.26-6.09-4.89-13.15-4.89-21.18s1.63-15.09,4.89-21.18Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M1237.09,1331.75l35.98,38.96h-21.82l-28.9-33.57v33.57h-16.15v-104.83h16.15v60.92l28.33-34.14h22.38l-35.98,39.1Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M1344.61,1312.63v13.6h-58.22v-13.6h58.22Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M1383.71,1272.25v98.46h-16.15v-98.46h16.15Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M1460.84,1295.2c4.86,2.55,8.66,6.33,11.4,11.33,2.74,5.01,4.11,11.05,4.11,18.13v46.04h-16.01v-43.63c0-6.99-1.75-12.35-5.24-16.08-3.5-3.73-8.27-5.59-14.31-5.59s-10.84,1.86-14.38,5.59c-3.54,3.73-5.31,9.09-5.31,16.08v43.63h-16.15v-78.06h16.15v8.92c2.64-3.21,6.02-5.71,10.13-7.51,4.11-1.79,8.48-2.69,13.1-2.69,6.14,0,11.64,1.27,16.5,3.82Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M1599.88,1328.49c3.68,4.63,5.52,9.87,5.52,15.73,0,5.01-1.3,9.52-3.9,13.53-2.6,4.02-6.35,7.18-11.26,9.49-4.91,2.32-10.62,3.47-17.14,3.47h-39.38v-98.46h37.54c6.7,0,12.47,1.13,17.28,3.4,4.82,2.27,8.45,5.31,10.91,9.14,2.45,3.83,3.68,8.1,3.68,12.82,0,5.67-1.51,10.39-4.53,14.17-3.02,3.78-7.08,6.57-12.18,8.36,5.29.94,9.77,3.73,13.46,8.36ZM1549.88,1313.62h19.97c5.29,0,9.42-1.2,12.39-3.61,2.98-2.41,4.46-5.88,4.46-10.41s-1.49-7.91-4.46-10.41c-2.97-2.5-7.11-3.75-12.39-3.75h-19.97v28.19ZM1584.58,1353.57c3.12-2.64,4.67-6.33,4.67-11.05s-1.65-8.64-4.96-11.47c-3.31-2.83-7.7-4.25-13.17-4.25h-21.25v30.74h21.82c5.48,0,9.77-1.32,12.89-3.97Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M1693.66,1292.65v78.06h-16.15v-9.21c-2.55,3.21-5.88,5.74-9.99,7.58-4.11,1.84-8.48,2.76-13.1,2.76-6.14,0-11.64-1.28-16.5-3.83-4.87-2.55-8.69-6.33-11.47-11.33-2.79-5.01-4.18-11.05-4.18-18.13v-45.9h16.01v43.49c0,6.99,1.75,12.35,5.24,16.08,3.49,3.73,8.26,5.6,14.31,5.6s10.84-1.86,14.38-5.6c3.54-3.73,5.31-9.09,5.31-16.08v-43.49h16.15Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M1714.42,1310.5c3.26-6.04,7.7-10.74,13.32-14.1,5.62-3.35,11.88-5.03,18.77-5.03,5.1,0,10.13,1.11,15.09,3.33s8.9,5.17,11.83,8.85v-37.68h16.29v104.83h-16.29v-11.76c-2.65,3.78-6.3,6.89-10.98,9.35-4.68,2.45-10.04,3.68-16.08,3.68-6.8,0-13.01-1.72-18.63-5.17-5.62-3.45-10.06-8.26-13.32-14.45-3.26-6.19-4.89-13.2-4.89-21.04s1.63-14.78,4.89-20.83ZM1770.09,1317.58c-2.22-3.97-5.12-6.99-8.71-9.07-3.59-2.08-7.46-3.12-11.62-3.12s-8.03,1.02-11.62,3.04c-3.59,2.03-6.49,5.01-8.71,8.92-2.22,3.92-3.33,8.57-3.33,13.95s1.11,10.11,3.33,14.17c2.22,4.06,5.15,7.15,8.78,9.28,3.64,2.12,7.48,3.19,11.55,3.19s8.03-1.04,11.62-3.12c3.59-2.08,6.49-5.12,8.71-9.14,2.22-4.01,3.33-8.71,3.33-14.1s-1.11-10.06-3.33-14.02Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M1810.46,1310.5c3.26-6.04,7.7-10.74,13.32-14.1,5.62-3.35,11.88-5.03,18.77-5.03,5.1,0,10.13,1.11,15.09,3.33s8.9,5.17,11.83,8.85v-37.68h16.29v104.83h-16.29v-11.76c-2.65,3.78-6.3,6.89-10.98,9.35-4.68,2.45-10.04,3.68-16.08,3.68-6.8,0-13.01-1.72-18.63-5.17-5.62-3.45-10.06-8.26-13.32-14.45-3.26-6.19-4.89-13.2-4.89-21.04s1.63-14.78,4.89-20.83ZM1866.14,1317.58c-2.22-3.97-5.12-6.99-8.71-9.07-3.59-2.08-7.46-3.12-11.62-3.12s-8.03,1.02-11.62,3.04c-3.59,2.03-6.49,5.01-8.71,8.92-2.22,3.92-3.33,8.57-3.33,13.95s1.11,10.11,3.33,14.17c2.22,4.06,5.15,7.15,8.78,9.28,3.64,2.12,7.48,3.19,11.55,3.19s8.03-1.04,11.62-3.12c3.59-2.08,6.49-5.12,8.71-9.14,2.22-4.01,3.33-8.71,3.33-14.1s-1.11-10.06-3.33-14.02Z', Color(0xFFD1D9E0)),
    _Shape.path(r'M1980.1,1292.65l-47.88,114.75h-16.72l15.87-37.97-30.74-76.78h17.99l21.96,59.5,22.81-59.5h16.72Z', Color(0xFFD1D9E0)),
  ];

  // Eyes
  static const double eyeLoopSec = 13.44;
  static const double blinkX = 615.0;
  static const double blinkW = 329.0;
  static const List<double> blinkTimes = [0.0, 0.2406, 0.25, 0.2594, 0.4906, 0.5, 0.5094, 0.7406, 0.75, 0.7594, 0.9806, 0.99, 0.9994, 1.0];
  static const List<double> blinkY = [722.22, 722.22, 791.95, 722.22, 722.22, 791.95, 722.22, 722.22, 791.95, 722.22, 722.22, 791.95, 722.22, 722.22];
  static const List<double> blinkH = [139.46, 139.46, 0.0, 139.46, 139.46, 0.0, 139.46, 139.46, 0.0, 139.46, 139.46, 0.0, 139.46, 139.46];

  static const List<double> pupilTimes = [0.0, 0.0625, 0.125, 0.1875, 0.25, 0.3125, 0.375, 0.4375, 0.5, 0.5625, 0.625, 0.6875, 0.75, 0.8125, 0.875, 0.9375, 1.0];
  static const List<double> pupilLX = [684.69, 633.69, 684.69, 735.69, 684.69, 684.69, 684.69, 684.69, 684.69, 648.69, 684.69, 720.69, 684.69, 648.69, 684.69, 720.69, 684.69];
  static const List<double> pupilRX = [874.14, 823.14, 874.14, 925.14, 874.14, 874.14, 874.14, 874.14, 874.14, 838.14, 874.14, 910.14, 874.14, 838.14, 874.14, 910.14, 874.14];
  static const List<double> pupilY = [791.95, 791.95, 791.95, 791.95, 791.95, 740.95, 791.95, 842.95, 791.95, 755.95, 791.95, 755.95, 791.95, 827.95, 791.95, 827.95, 791.95];
  static const double pupilR = 46.25;

  static const Color eyeWhite = Color(0xFFF5F5F5);
  static final Path eyeLPath = Path()
    ..addOval(Rect.fromCircle(center: const Offset(684.69, 791.95), radius: 69.73));
  static final Path eyeRPath = Path()
    ..addOval(Rect.fromCircle(center: const Offset(874.14, 791.95), radius: 69.73));

  // Clock
  static const double clockCx = 1743.42;
  static const double clockCy = 931.1;

  static final RRect minuteRRect = RRect.fromRectAndRadius(Rect.fromLTWH(1725.8, 709.02, 29.77, 237.61), Radius.circular(14.89));
  static const double minuteTx = 3502.6451;
  static const double minuteTy = 1609.3671;
  static const double minuteRot = 178.4861;
  static const Color minuteColor = Color(0xFF002C3E);

  static final RRect hourRRect = RRect.fromRectAndRadius(Rect.fromLTWH(1800.81, 878.34, 29.77, 204.29), Radius.circular(14.89));
  static const double hourTx = -12.6152;
  static const double hourTy = 1937.2308;
  static const double hourRot = -55.992;
  static const Color hourColor = Color(0xFF002C3E);

  static const double dotTx = -24.01;
  static const double dotTy = 46.39;
  static const double dotRot = -1.51;
  static const double dotCx = 1743.41;
  static const double dotCy = 931.72;
  static const double dotBigR = 37.83;
  static const double dotSmallR = 15.76;
  static const Color dotBigColor = Color(0xFF002C3E);
  static const Color dotSmallColor = Color(0xFFF5F5F5);
}
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _phase = 0;

  @override
  void initState() {
    super.initState();
    _playAnimation();
  }

  void _playAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _phase = 1);

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _phase = 2);

    await Future.delayed(const Duration(seconds: 2));
    startApp();
  }

  void startApp() async {
    if (!mounted) return;

    try {
      await DeepLinkService.coldStartCheckDone.future
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Timed out waiting — proceed with normal splash flow.
    }
    if (DeepLinkService.isHandlingRedirect) {
      debugPrint(
          "🔗 [Splash] Payment deep link is being handled, SplashScreen skipping default navigation.");
      return;
    }
    final pendingCheckout = await TokenStorage.getPendingCheckout();
    if (pendingCheckout) {
      await TokenStorage.savePendingCheckout(false);
      debugPrint(
          "🔗 [Splash] Pending checkout found with no deep-link confirmation — "
              "showing PaymentResultPage as a fallback.");
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PaymentResultPage(success: true)),
      );
      return;
    }

    /// ================= AUTHENTICATION =================
    String? token;
    try {
      token = await TokenStorage.getToken().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Auth Token Fetch Error: $e");
    }

    if (token == null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 1300),
        ),
      );
      return;
    }

    /// ================= ONBOARDING =================
    final nameCompleted = await TokenStorage.getNameCompleted();
    final emailCompleted = await TokenStorage.getEmailCompleted();

    if (!nameCompleted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          const NameOnboardingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    if (!emailCompleted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          const EmailPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    /// ================= FINAL ENTRY =================
    try {
      await SubscriptionApi.getSubscriptionStatus()
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint("Subscription Status Fetch Error: $e");
    }

    final subscriptionStatus = await TokenStorage.getSubscriptionStatus();

    if (NotificationService.isHandlingAlarm) {
      print(
          "🚀 Alarm is being handled, SplashScreen skipping default navigation.");
      return;
    }

    if (DeepLinkService.isHandlingRedirect) {
      debugPrint(
          "🔗 [Splash] Payment deep link is being handled, SplashScreen skipping default navigation.");
      return;
    }

    if (subscriptionStatus == 0) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionPage()),
      );
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002C3E), // Pure Navy from design
      body: Center(
        child: Hero(
          tag: 'logo_hero',
          child: Material(
            color: Colors.transparent,
            child: _buildLogoPhase(),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPhase() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Solo Logo Widget with Smooth Animation
        _smoothElement(
          visible: _phase >= 1,
          child: const SoloLogoAnimated(width: 260)
        ),

      ],
    );
  }

  Widget _smoothElement({required bool visible, required Widget child}) {
    return AnimatedScale(
      scale: visible ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        child: child,
      ),
    );
  }
}