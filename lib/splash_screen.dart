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
import 'package:solo_app/subscription/subscription_api.dart';

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
    // Phase 1: Navy Background (already there)
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _phase = 1); // Phase 1: Teal Dot

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _phase = 2); // Phase 2: + Lime Dot

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _phase = 3); // Phase 3: + S and L

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _phase = 4); // Phase 4: + Tagline

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _phase = 5); // Phase 5: + Eyes and Clock Hands

    await Future.delayed(const Duration(seconds: 2)); // Hold at final logo
    startApp();
  }

  void startApp() async {
    if (!mounted) return;

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
    // Fetch fresh subscription status from the backend to ensure we have up-to-date status
    try {
      await SubscriptionApi.getSubscriptionStatus()
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint("Subscription Status Fetch Error: $e");
    }

    final subscriptionStatus = await TokenStorage.getSubscriptionStatus();

    // 🚀 CRITICAL: If an alarm is ringing and we are already navigating to CheckinScreen,
    // don't push HomePage which would overwrite it.
    if (NotificationService.isHandlingAlarm) {
      print(
          "🚀 Alarm is being handled, SplashScreen skipping default navigation.");
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
            // Material is needed for Text styles to transition correctly
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // S (Custom Width/Height)
            _smoothElement(
              visible: _phase >= 3,
              child: SvgPicture.asset(
                'assets/svg/s.svg',
                height: 72.17.h,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
            if (_phase >= 3) SizedBox(width: 8.w),

            // O (TEAL - Layered with two circles and eyes)

            _smoothElement(
              visible: _phase >= 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back Circle (94.36px)
                  Container(
                    width: 94.36.w,
                    height: 94.36.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1CB9B3)
                          .withValues(alpha: 0.8), // Slightly lighter background teal
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Highlighted Front Circle (75.48px)
                  Container(
                    width: 75.48.w,
                    height: 75.49.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1CC4BE),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10.w,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: _smoothElement(
                      visible: _phase >= 5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _eyeDigit(),
                          SizedBox(width: 6.w),
                          _eyeDigit(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),

            // L
            _smoothElement(
              visible: _phase >= 3,
              child: SvgPicture.asset(
                'assets/svg/L.svg',
                height: 72.17.h,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
            if (_phase >= 3) SizedBox(width: 8.w),

            // O (LIME)
            _smoothElement(
              visible: _phase >= 2,
              child: Container(
                width: 72.75.w,
                height: 72.75.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFB7D43A),
                  shape: BoxShape.circle,
                ),
                child: _smoothElement(
                  visible: _phase >= 5,
                  child: CustomPaint(
                    painter: _ClockHandsPainter(),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _smoothElement(
          visible: _phase >= 4,
          child: Text(
            "Your Daily Check-In Buddy",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 20.6.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5.w,
            ),
          ),
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

  Widget _eyeDigit() {
    return Container(
      width: 19.98.w,
      height: 19.98.w,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: const Alignment(1.6, 0.0),
      child: Container(
        width: 13.26.w,
        height: 13.26.w,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ClockHandsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final navyPaint = Paint()
      ..color = const Color(0xFF002C3E)
      ..strokeWidth = 6 // Thicker needles like in the image
      ..strokeCap = StrokeCap.round;

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Minute hand (pointing towards 2 o'clock - roughly)
    canvas.drawLine(center, center + const Offset(18, -6), navyPaint);

    // Hour hand (pointing towards 7 o'clock - roughly)
    canvas.drawLine(center, center + const Offset(-10, 20), navyPaint);

    // Dark outer pivot circle
    canvas.drawCircle(center, 7, navyPaint);

    // White small center circle
    canvas.drawCircle(center, 3, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
