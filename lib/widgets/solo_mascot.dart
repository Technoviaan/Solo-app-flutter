import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/app_size.dart';

class SoloMascot extends StatefulWidget {
  final bool isFormValid;

  const SoloMascot({
    super.key,
    required this.isFormValid,
  });

  @override
  State<SoloMascot> createState() => _SoloMascotState();
}

class _SoloMascotState extends State<SoloMascot> {
  static const String eyeCenter = "assets/images/eye_center.png";
  static const String eyeRight = "assets/images/eye_right.png";
  static const String eyeLeft = "assets/images/eye_left.png";

  bool _initialDelayDone = false;
  Timer? _initialTimer;

  @override
  void initState() {
    super.initState();
    _initialTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _initialDelayDone = true;
        });
      }
    });

  }

  @override
  void dispose() {
    _initialTimer?.cancel();
    super.dispose();
  }

  String get _currentFrame {
    if (!_initialDelayDone) {
      return eyeCenter;
    }
    return widget.isFormValid ? eyeRight : eyeLeft;
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
          _currentFrame,
          key: ValueKey(_currentFrame),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}