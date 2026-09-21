import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:solo_app/core/deeplink/deep_link_service.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.retryPendingNavigationIfAny();
    });
    DeepLinkService.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DeepLinkService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.retryPendingNavigationIfAny();
      NotificationService.ensureSosScreenIfOverdue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOLO',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,


      localizationsDelegates: const [
        CountryLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),

      ],

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