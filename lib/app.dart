import 'package:flutter/material.dart';
import 'package:solo_app/core/utils/app_size.dart';
import 'package:solo_app/home/checkin/notification_service.dart';
import 'package:solo_app/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SoloApp extends StatefulWidget {
  const SoloApp({super.key});

  @override
  State<SoloApp> createState() => _SoloAppState();
}

class _SoloAppState extends State<SoloApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.retryPendingNavigationIfAny();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOLO',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        fontFamily: GoogleFonts.inter().fontFamily,
        scaffoldBackgroundColor: const Color(0xFF002C3E),
      ),
      builder: (context, child) {
        AppSize.init(context);
        return child!;
      },
      home: const SplashScreen(),
    );
  }
}