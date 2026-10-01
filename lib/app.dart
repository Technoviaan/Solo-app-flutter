import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:solo_app/core/deeplink/deep_link_service.dart';
import 'package:solo_app/core/utils/app_size.dart';
import 'package:solo_app/home/checkin/notification_service.dart';
import 'package:solo_app/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import 'loginWithNumber/login_page.dart';

class SoloApp extends StatefulWidget {
  final String? initialToken;
  final bool pendingCheckout;

  const SoloApp({
    super.key,
    this.initialToken,
    this.pendingCheckout = false,
  });

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
        scaffoldBackgroundColor: const Color(0xFFF8F9F5),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: SleekSlidePageTransitionsBuilder(),
            TargetPlatform.iOS: SleekSlidePageTransitionsBuilder(),
            TargetPlatform.windows: SleekSlidePageTransitionsBuilder(),
            TargetPlatform.macOS: SleekSlidePageTransitionsBuilder(),
            TargetPlatform.linux: SleekSlidePageTransitionsBuilder(),
          },
        ),
      ),
      builder: (context, child) {
        AppSize.init(context);
        return child!;
      },
      home: (widget.initialToken == null && !widget.pendingCheckout)
          ? const LoginPage(animateEntrance: true)
          : SplashScreen(
              initialToken: widget.initialToken,
              pendingCheckout: widget.pendingCheckout,
            ),
    );
  }
}

/// A sleek, ultra-smooth page transitions builder designed for SOLO's minimalist aesthetic.
/// Provides buttery slide navigation with cubic curves and subtle parallax on pop/push.
class SleekSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const SleekSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Forward curve: smooth easeOutCubic (snappy and luxurious, no stutter)
    // Reverse curve (Back arrow tap): smooth easeInOutCubic (buttery smooth slide back)
    final primaryAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    final secondaryCurvedAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    // Primary page slides in from right to center, slides out to right on pop
    final primaryOffset = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(primaryAnimation);

    // Previous page slightly shifts left for parallax depth
    final secondaryOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.25, 0.0),
    ).animate(secondaryCurvedAnimation);

    return SlideTransition(
      position: secondaryOffset,
      child: SlideTransition(
        position: primaryOffset,
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(-4, 0),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}