import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:solo_app/home/checkin/notification_service.dart' show navigatorKey;
import 'package:solo_app/subscription/payment_result_page.dart';
import 'package:solo_app/core/storage/token_storage.dart';

class DeepLinkService {
  DeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _linkSubscription;
  static bool _initialized = false;

  static bool isHandlingRedirect = false;
  static final Completer<void> coldStartCheckDone = Completer<void>();

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Cold start check
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
    } finally {
      if (!coldStartCheckDone.isCompleted) {
        coldStartCheckDone.complete();
      }
    }

    // App running in foreground / background
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

    String target = uri.host;
    if (target.isEmpty && uri.pathSegments.isNotEmpty) {
      target = uri.pathSegments.first;
    }

    debugPrint("🔗 [DeepLink] Parsed target = '$target' from $uri");

    switch (target) {
      case "payment-success":
        isHandlingRedirect = true;
        _navigateToResult(success: true);
        break;
      case "payment-cancel":
        isHandlingRedirect = true;
        _navigateToResult(success: false);
        break;
      default:
        debugPrint("🔗 [DeepLink] Unknown deep link target, ignoring: $uri");
    }
  }

  static Future<void> _navigateToResult({required bool success}) async {
    int retryCount = 0;
    while (navigatorKey.currentState == null && retryCount < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      retryCount++;
    }

    if (navigatorKey.currentState == null) {
      debugPrint("🔗 [DeepLink] Navigator never became ready, dropping deep link.");
      isHandlingRedirect = false;
      return;
    }

    debugPrint("🔗 [DeepLink] Navigating to PaymentResultPage(success: $success)");

    await TokenStorage.savePendingCheckout(false);

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PaymentResultPage(success: success),
      ),
          (route) => false,
    );

    isHandlingRedirect = false;
  }

  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _initialized = false;
  }
}