import 'package:flutter/material.dart';
import 'dart:math' as math;

class AppSize {
  static late double screenWidth;
  static late double screenHeight;
  static late double pixelRatio;
  static late double textScaleFactor;
  static late double safeAreaTop;
  static late double safeAreaBottom;
  static bool _initialized = false;

  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
    pixelRatio = mediaQuery.devicePixelRatio;
    textScaleFactor = mediaQuery.textScaler.scale(1.0);
    safeAreaTop = mediaQuery.padding.top;
    safeAreaBottom = mediaQuery.padding.bottom;
    _initialized = true;
  }

  // Design dimensions (based on iPhone 13/14)
  static const double designWidth = 375;
  static const double designHeight = 812;

  static double get _scaleW => _initialized ? screenWidth / designWidth : 1.0;
  static double get _scaleH => _initialized ? screenHeight / designHeight : 1.0;

  static double w(double width) => width * _scaleW;
  static double h(double height) => height * _scaleH;
  static double sp(double size) => size * _scaleW;

  static double bottom(double original) {
    if (!_initialized) return original;
    return math.max(original, safeAreaBottom > 0 ? safeAreaBottom + 10 : original);
  }
}

extension ResponsiveNum on num {
  double get w => AppSize.w(this.toDouble());
  double get h => AppSize.h(this.toDouble());
  double get sp => AppSize.sp(this.toDouble());
}