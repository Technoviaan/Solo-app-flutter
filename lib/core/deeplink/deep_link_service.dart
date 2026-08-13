import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../../home/checkin/notification_service.dart' show navigatorKey;
import '../../subscription/payment_result_page.dart';

class DeepLinkService {
  DeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _linkSubscription;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Cold start: app launched directly from the solo://... link.
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint("🔗 [DeepLink] Cold-start link received: $initialUri");
        _handleUri(initialUri);
      } else {
        debugPrint("🔗 [DeepLink] No cold-start link (normal app launch).");
      }
    } catch (e) {
      debugPrint("🔗 [DeepLink] Error reading initial link: $e");
    }

    // App already running (foreground or background) and the link fires.
    _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen(
          (uri) {
        debugPrint("🔗 [DeepLink] Incoming link while app running: $uri");
        _handleUri(uri);
      },
      onError: (err) {
        debugPrint("🔗 [DeepLink] uriLinkStream error: $err");
      },
    );

    debugPrint("🔗 [DeepLink] DeepLinkService initialized, listening for solo:// links.");
  }

  static void _handleUri(Uri uri) {
    if (uri.scheme != "solo") {
      debugPrint("🔗 [DeepLink] Ignoring non-solo scheme: $uri");
      return;
    }

    // solo://payment-success -> uri.host == "payment-success"
    // solo://payment-cancel  -> uri.host == "payment-cancel"
    String target = uri.host;
    if (target.isEmpty && uri.pathSegments.isNotEmpty) {
      target = uri.pathSegments.first;
    }

    debugPrint("🔗 [DeepLink] Parsed target = '$target' from $uri");

    switch (target) {
      case "payment-success":
        _navigateToResult(success: true);
        break;
      case "payment-cancel":
        _navigateToResult(success: false);
        break;
      default:
        debugPrint("🔗 [DeepLink] Unknown deep link target, ignoring: $uri");
    }
  }

  static Future<void> _navigateToResult({required bool success}) async {
    // Same wait-for-navigator pattern used by NotificationService for the
    // missed check-in flow: on a cold start the deep link can arrive before
    // MaterialApp/navigatorKey has attached a navigator.
    int retryCount = 0;
    while (navigatorKey.currentState == null && retryCount < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      retryCount++;
    }

    if (navigatorKey.currentState == null) {
      debugPrint("🔗 [DeepLink] Navigator never became ready after 10s, "
          "dropping payment-${success ? 'success' : 'cancel'} deep link.");
      return;
    }

    debugPrint("🔗 [DeepLink] Navigating to PaymentResultPage(success: $success)");

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PaymentResultPage(success: success),
      ),
          (route) => false,
    );
  }

  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _initialized = false;
  }
}