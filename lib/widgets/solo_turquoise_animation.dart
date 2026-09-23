import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Controller that lets external code (a text field's focus/typing
/// listeners, for example) drive the SOLO button's eyes without needing
/// a GlobalKey.
///
/// Usage:
///   final soloController = SoloButtonController();
///   SoloTurquoiseAnimation(controller: soloController, ...)
///   ...
///   soloController.lookDown();  // on field focus / on keystroke
///   soloController.resume();   // on field blur / 1s after last keystroke
class SoloButtonController {
  _SoloTurquoiseAnimationState? _state;

  void _attach(_SoloTurquoiseAnimationState state) => _state = state;

  void _detach(_SoloTurquoiseAnimationState state) {
    if (_state == state) _state = null;
  }

  /// Pupils slide from wherever they currently are straight to the
  /// bottom-left, as if looking down at a field being typed into.
  void lookDown() => _state?._lookDown();

  /// Pupils return to front, then the idle wander resumes — skipping
  /// whichever direction was interrupted so it's never repeated
  /// immediately.
  void resume() => _state?._resume();

  void dispose() {
    _state = null;
  }
}

class SoloTurquoiseAnimation extends StatefulWidget {
  final double? width;
  final double? height;
  final double? size;
  final bool isHappy;
  final bool isRed;
  final bool lookUpRight;
  final VoidCallback? onTap;

  /// Optional controller so a parent (e.g. an onboarding page) can call
  /// [SoloButtonController.lookDown] / [SoloButtonController.resume]
  /// without rebuilding or remounting this widget.
  final SoloButtonController? controller;

  const SoloTurquoiseAnimation({
    super.key,
    this.width,
    this.height,
    this.size,
    this.isHappy = false,
    this.isRed = false,
    this.lookUpRight = false,
    this.onTap,
    this.controller,
  });

  @override
  State<SoloTurquoiseAnimation> createState() => _SoloTurquoiseAnimationState();
}

class _SoloTurquoiseAnimationState extends State<SoloTurquoiseAnimation>
    with TickerProviderStateMixin {
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

  // ---------------------------------------------------------------------
  // 8-direction idle wander (same offsets/order as the original SMIL
  // keyframes: left, right, up, down, up-left, up-right, down-left,
  // down-right). Pupils always return to front between looks; a blink
  // fires on every 4th return.
  // ---------------------------------------------------------------------
  static const List<Offset> _directions = [
    Offset(-139, 0),
    Offset(139, 0),
    Offset(0, -139),
    Offset(0, 139),
    Offset(-98, -98),
    Offset(98, -98),
    Offset(-98, 98),
    Offset(98, 98),
  ];

  // "Look down at the field" = bottom-left, same offset as that direction.
  static const Offset _lookDownOffset = Offset(-98, 98);

  static const Duration _moveDuration = Duration(milliseconds: 500);
  static const Duration _holdAtDirection = Duration(milliseconds: 500);
  static const Duration _holdAtFront = Duration(milliseconds: 700);
  static const Duration _blinkHalf = Duration(milliseconds: 110);

  late final AnimationController _moveCtrl;
  late final AnimationController _blinkCtrl;

  Offset _pupilOffset = Offset.zero;
  double _blinkFactor = 1.0; // 1 = fully open, 0 = fully closed

  int _dirIndex = 0;
  int _returnCount = 0;
  int _gen = 0; // bumped on every external interruption (lookDown/resume)
  bool _lookingDown = false;

  @override
  void initState() {
    super.initState();
    _moveCtrl = AnimationController(vsync: this, duration: _moveDuration);
    _blinkCtrl = AnimationController(vsync: this, duration: _blinkHalf * 2);
    widget.controller?._attach(this);

    if (widget.lookUpRight) {
      _pupilOffset = const Offset(98, -98);
    } else if (!widget.isHappy) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runIdleLoop(_gen));
    }
  }

  @override
  void didUpdateWidget(covariant SoloTurquoiseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _moveCtrl.dispose();
    _blinkCtrl.dispose();
    super.dispose();
  }

  Future<void> _animateTo(Offset target, int myGen) async {
    if (!mounted || myGen != _gen) return;
    final Offset start = _pupilOffset;
    final Animation<Offset> anim = Tween<Offset>(begin: start, end: target).animate(
      CurvedAnimation(parent: _moveCtrl, curve: const Cubic(0.42, 0.0, 0.58, 1.0)),
    );

    void listener() {
      if (!mounted || myGen != _gen) return;
      setState(() => _pupilOffset = anim.value);
    }

    _moveCtrl.addListener(listener);
    _moveCtrl.reset();
    await _moveCtrl.forward();
    _moveCtrl.removeListener(listener);

    if (mounted && myGen == _gen) {
      setState(() => _pupilOffset = target);
    }
  }

  Future<void> _playBlink(int myGen) async {
    if (!mounted || myGen != _gen) return;

    void listener() {
      if (!mounted || myGen != _gen) return;
      final double t = _blinkCtrl.value;
      final double factor = t <= 0.5 ? 1.0 - (t / 0.5) : (t - 0.5) / 0.5;
      setState(() => _blinkFactor = factor);
    }

    _blinkCtrl.addListener(listener);
    _blinkCtrl.reset();
    await _blinkCtrl.forward();
    _blinkCtrl.removeListener(listener);

    if (mounted && myGen == _gen) setState(() => _blinkFactor = 1.0);
  }

  /// Idle (automatic, no external calls needed): wanders through the 8
  /// directions forever, returning to front between looks, blinking on
  /// every 4th return.
  Future<void> _runIdleLoop(int myGen) async {
    while (mounted && myGen == _gen) {
      await _animateTo(_directions[_dirIndex], myGen);
      if (!mounted || myGen != _gen) return;

      await Future.delayed(_holdAtDirection);
      if (!mounted || myGen != _gen) return;

      await _animateTo(Offset.zero, myGen);
      if (!mounted || myGen != _gen) return;

      _returnCount++;
      if (_returnCount % 4 == 0) {
        await _playBlink(myGen);
        if (!mounted || myGen != _gen) return;
      }

      _dirIndex = (_dirIndex + 1) % _directions.length;
      await Future.delayed(_holdAtFront);
    }
  }

  void _lookDown() {
    if (widget.isHappy || widget.lookUpRight) return;
    _gen++;
    final myGen = _gen;
    _lookingDown = true;
    _animateTo(_lookDownOffset, myGen);
  }

  Future<void> _resume() async {
    if (widget.isHappy || widget.lookUpRight || !_lookingDown) return;
    _lookingDown = false;
    _gen++;
    final myGen = _gen;

    // Pupils return to front first.
    await _animateTo(Offset.zero, myGen);
    if (myGen != _gen) return;

    _returnCount++;
    if (_returnCount % 4 == 0) {
      await _playBlink(myGen);
      if (myGen != _gen) return;
    }

    // Skip the interrupted direction so it's never repeated immediately.
    _dirIndex = (_dirIndex + 1) % _directions.length;
    _runIdleLoop(myGen);
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
          SvgPicture.string(
            widget.isRed ? _buttonSvgRed : _buttonSvgBase,
            width: targetWidth,
            height: targetHeight,
            fit: BoxFit.contain,
          ),
          if (!widget.isHappy)
            Positioned.fill(
              child: CustomPaint(
                painter: _SoloEyesPainter(
                  pupilOffset: widget.lookUpRight ? const Offset(98, -98) : _pupilOffset,
                  blinkFactor: widget.lookUpRight ? 1.0 : _blinkFactor,
                ),
              ),
            ),
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
      return GestureDetector(onTap: widget.onTap, child: mascot);
    }
    return mascot;
  }
}

/// Alias for ease of use
typedef SoloTurquoiseMascot = SoloTurquoiseAnimation;
typedef SoloMascotAnimation = SoloTurquoiseAnimation;

class _SoloEyesPainter extends CustomPainter {
  final Offset pupilOffset;
  final double blinkFactor;

  _SoloEyesPainter({required this.pupilOffset, required this.blinkFactor});

  @override
  void paint(Canvas canvas, Size size) {
    // 2048 x 2048 coordinate space from SVG viewBox
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

      canvas.drawCircle(leftEyeCenter, eyeRadius, whitePaint);
      canvas.drawCircle(rightEyeCenter, eyeRadius, whitePaint);

      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: leftEyeCenter, radius: eyeRadius)));
      canvas.drawCircle(leftEyeCenter + pupilOffset, pupilRadius, pupilPaint);
      canvas.restore();

      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: rightEyeCenter, radius: eyeRadius)));
      canvas.drawCircle(rightEyeCenter + pupilOffset, pupilRadius, pupilPaint);
      canvas.restore();

      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SoloEyesPainter oldDelegate) {
    return oldDelegate.pupilOffset != pupilOffset || oldDelegate.blinkFactor != blinkFactor;
  }
}