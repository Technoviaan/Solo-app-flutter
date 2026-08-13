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

    // 🛠️ FIX: On a cold start the app is already "resumed" the instant this
    // observer registers, so didChangeAppLifecycleState's `resumed` branch
    // below never fires for it — there's no transition to catch. Any
    // missed-check-in navigation queued by NotificationService.init()
    // (which runs before runApp(), see notification_service.dart) would
    // otherwise sit stuck in `_pendingCheckinTime` forever, and the user
    // would land on Home/Splash instead of the SOS screen. Firing this once
    // right after the first frame — the earliest point navigatorKey has a
    // navigator attached — guarantees that queued navigation always runs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.retryPendingNavigationIfAny();
    });
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
      // 🛠️ FIX: Whenever the user brings the app back to the foreground
      // (unminimizes it), independently double-check whether an active
      // check-in's due time has already passed. This is what forces the
      // SOS screen even when Alarm.ringing itself never fired while the
      // app sat minimized — see ensureSosScreenIfOverdue in
      // notification_service.dart.
      NotificationService.ensureSosScreenIfOverdue();
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