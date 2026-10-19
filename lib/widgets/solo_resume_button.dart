import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum _ResumeMode { wander, catchup, hold, done }

/// Controller to trigger resume animation externally (e.g. from label tap)
class SoloResumeButtonController {
  _SoloResumeButtonState? _state;

  void _attach(_SoloResumeButtonState state) => _state = state;
  void _detach(_SoloResumeButtonState state) {
    if (_state == state) _state = null;
  }

  void triggerResume() => _state?.triggerResume();
  bool get isResumed => _state?._isResumed ?? false;

  void dispose() {
    _state = null;
  }
}

class SoloResumeButton extends StatefulWidget {
  final double size;
  final VoidCallback? onResumed;
  final SoloResumeButtonController? controller;

  const SoloResumeButton({
    super.key,
    required this.size,
    this.onResumed,
    this.controller,
  });

  @override
  State<SoloResumeButton> createState() => _SoloResumeButtonState();
}

class _SoloResumeButtonState extends State<SoloResumeButton>
    with TickerProviderStateMixin {
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

  static const String _buttonSvgTurquoise = '''
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

  static const String _happyLidsSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2048 2048" width="100%" height="100%">
  <g id="Lids-happy">
    <path d="M923.44,931.64c-18.04,0-32.67-14.63-32.67-32.67v-46.39c0-67.95-55.28-123.23-123.23-123.23s-123.23,55.28-123.23,123.23v46.39c0,18.04-14.63,32.67-32.67,32.67s-32.67-14.63-32.67-32.67v-46.39c0-103.98,84.59-188.57,188.57-188.57s188.57,84.59,188.57,188.57v46.39c0,18.04-14.63,32.67-32.67,32.67Z" fill="#024c48"/>
    <path d="M1436,931.64c-18.04,0-32.67-14.63-32.67-32.67v-46.39c0-67.95-55.28-123.23-123.23-123.23s-123.23,55.28-123.23,123.23v46.39c0,18.04-14.63,32.67-32.67,32.67s-32.67-14.63-32.67-32.67v-46.39c0-103.98,84.59-188.57,188.57-188.57s188.57,84.59,188.57,188.57v46.39c0,18.04-14.63,32.67-32.67,32.67Z" fill="#024c48"/>
  </g>
</svg>
''';

  static const int _moveMs = 875;
  static const int _frontHoldMs = 500;

  static const List<Offset> _seq = [
    Offset(0, 0), Offset(-98, -98), Offset(0, 0), Offset(-80, 114), Offset(0, 0),
    Offset(0, 0), Offset(-139, 0), Offset(0, 0), Offset(139, 0), Offset(0, 0),
    Offset(0, 0), Offset(0, 139), Offset(0, 0), Offset(139, 0), Offset(0, 0),
    Offset(0, 0), Offset(-139, 0), Offset(0, 0), Offset(-80, 114), Offset(0, 0),
    Offset(0, 0), Offset(0, -139), Offset(0, 0), Offset(-80, 114), Offset(0, 0),
    Offset(0, 0), Offset(-139, 0), Offset(0, 0), Offset(139, 0), Offset(0, 0),
    Offset(0, 0), Offset(0, 139), Offset(0, 0), Offset(139, 0), Offset(0, 0),
    Offset(0, 0), Offset(-139, 0), Offset(0, 0), Offset(-80, 114), Offset(0, 0),
    Offset(0, 0),
  ];

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final Ticker _ticker;

  _ResumeMode _mode = _ResumeMode.wander;
  bool _isResumed = false;
  bool _isHappy = false;

  double _wanderT = 0;
  double _catchupT = 0;
  Offset _catchupFrom = Offset.zero;
  double _holdT = 0;
  double _lastMs = 0;

  Offset _pupilOffset = Offset.zero;
  double _blinkFactor = 1.0;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.018).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void didUpdateWidget(covariant SoloResumeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _ticker.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  double _ease(double t) {
    return t < 0.5 ? 2.0 * t * t : 1.0 - math.pow(-2.0 * t + 2.0, 2) / 2.0;
  }

  void _onTick(Duration elapsed) {
    final nowMs = elapsed.inMicroseconds / 1000.0;
    if (_lastMs == 0) _lastMs = nowMs;
    double dt = nowMs - _lastMs;
    _lastMs = nowMs;
    if (dt > 200) dt = 200;

    if (_mode == _ResumeMode.wander) {
      _wanderT += dt;
      _updateWander();
    } else if (_mode == _ResumeMode.catchup) {
      _catchupT += dt;
      _updateCatchup();
    } else if (_mode == _ResumeMode.hold) {
      _holdT += dt;
      _updateHold();
    }
  }

  void _updateWander() {
    final idx = (_wanderT ~/ _moveMs) % (_seq.length - 1);
    final lt = (_wanderT % _moveMs) / _moveMs;
    final e = _ease(lt);
    final from = _seq[idx];
    final to = _seq[(idx + 1) % _seq.length];

    final newOffset = Offset(
      from.dx + (to.dx - from.dx) * e,
      from.dy + (to.dy - from.dy) * e,
    );

    double newBlink = 1.0;
    if (from == Offset.zero && to == Offset.zero) {
      if (lt > 0.35 && lt < 0.65) {
        final bt = (lt - 0.35) / 0.3;
        newBlink = bt < 0.5 ? 1.0 - bt * 2.0 : (bt - 0.5) * 2.0;
      }
    }

    if (mounted) {
      setState(() {
        _pupilOffset = newOffset;
        _blinkFactor = newBlink.clamp(0.0, 1.0);
      });
    }
  }

  void _updateCatchup() {
    final t = (_catchupT / _moveMs).clamp(0.0, 1.0);
    final e = _ease(t);
    final newOffset = Offset(
      _catchupFrom.dx + (0.0 - _catchupFrom.dx) * e,
      _catchupFrom.dy + (0.0 - _catchupFrom.dy) * e,
    );

    if (mounted) {
      setState(() {
        _pupilOffset = newOffset;
        _blinkFactor = 1.0;
      });
    }

    if (t >= 1.0) {
      _holdT = 0;
      _mode = _ResumeMode.hold;
    }
  }

  void _updateHold() {
    if (mounted) {
      setState(() {
        _pupilOffset = Offset.zero;
        _blinkFactor = 1.0;
      });
    }

    if (_holdT >= _frontHoldMs) {
      if (mounted) {
        setState(() {
          _isHappy = true;
          _mode = _ResumeMode.done;
        });
      }
    }
  }

  void triggerResume() {
    if (_mode != _ResumeMode.wander) return;

    if (mounted) {
      setState(() {
        _isResumed = true;
        _catchupFrom = _pupilOffset;
        _catchupT = 0;
        _mode = _ResumeMode.catchup;
      });
    }

    widget.onResumed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnim,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: triggerResume,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // SVG Base Button: cuts instantly from Red to Turquoise
              SvgPicture.string(
                _isResumed ? _buttonSvgTurquoise : _buttonSvgRed,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
              ),

              // Eyes / Happy Lids
              if (!_isHappy)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SoloResumeEyesPainter(
                      pupilOffset: _pupilOffset,
                      blinkFactor: _blinkFactor,
                    ),
                  ),
                ),

              if (_isHappy)
                SvgPicture.string(
                  _happyLidsSvg,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.contain,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoloResumeEyesPainter extends CustomPainter {
  final Offset pupilOffset;
  final double blinkFactor;

  _SoloResumeEyesPainter({
    required this.pupilOffset,
    required this.blinkFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 2048.0;
    canvas.save();
    canvas.scale(scale, scale);

    if (blinkFactor > 0.01) {
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

      // Draw Left Pupil (clipped to eye circle)
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: leftEyeCenter, radius: eyeRadius)),
      );
      canvas.drawCircle(leftEyeCenter + pupilOffset, pupilRadius, pupilPaint);
      canvas.restore();

      // Draw Right Pupil (clipped to eye circle)
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: rightEyeCenter, radius: eyeRadius)),
      );
      canvas.drawCircle(rightEyeCenter + pupilOffset, pupilRadius, pupilPaint);
      canvas.restore();

      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SoloResumeEyesPainter oldDelegate) {
    return oldDelegate.pupilOffset != pupilOffset ||
        oldDelegate.blinkFactor != blinkFactor;
  }
}
