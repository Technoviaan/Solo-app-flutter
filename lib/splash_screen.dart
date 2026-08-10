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

class SoloLogoWidget extends StatelessWidget {
  final double size;

  const SoloLogoWidget({super.key, this.size = 70});

  @override
  Widget build(BuildContext context) {
    final scale = size / 74.0;

    return SizedBox(
      width: 278.w * scale,
      height: 130.h * scale,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SvgPicture.asset(
          'assets/svg/solo.svg',
          width: 281,
          height: 131,
        ),
      ),
    );
  }
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
    setState(() => _phase = 1); // Phase 1: Logo visible

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _phase = 2); // Phase 2: Tagline visible

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
          child: const SoloLogoWidget(size: 80),
        ),
        SizedBox(height: 12.h),
        // Tagline with Smooth Animation
        // _smoothElement(
        //   visible: _phase >= 2,
        //   child: Text(
        //     "Your Daily Check-In Buddy",
        //     textAlign: TextAlign.center,
        //     style: TextStyle(
        //       fontFamily: 'Poppins',
        //       color: Colors.white,
        //       fontSize: 20.6.sp,
        //       fontWeight: FontWeight.w500,
        //       letterSpacing: 0.5.w,
        //     ),
        //   ),
        // ),
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