import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:solo_app/core/storage/token_storage.dart';
import 'package:solo_app/home/checkin/notification_service.dart' show navigatorKey;
import 'package:solo_app/loginWithNumber/login_page.dart';

/// ================= BAN GUARD =================
/// Central place that detects "this account has been banned/blocked by
/// admin" from any API response and force logs the user out of the app.
///
/// WHY THIS EXISTS:
/// The admin panel has PATCH /api/admin/ban/:userId which bans a user on
/// the server. That alone does NOT stop the user's already-installed app
/// from working, because the app only ever checks "do I have a saved
/// token", never "is this account still allowed to use the app". So a
/// banned user could keep doing check-ins / SOS / alerts forever until
/// they happened to log out manually.
///
/// This guard is wired into every authenticated API response in the hot
/// paths (login, splash boot, profile load, check-in, notifications). The
/// moment the backend signals a ban on ANY of those calls, we clear the
/// local session and kick the user back to Login with a clear message —
/// no matter which screen they were on.
///
/// [CVC_DEBUG] NOTE: I don't have the backend source, so I can't see the
/// exact JSON shape it sends for a banned account. `_looksBanned` below
/// covers the common conventions (HTTP 403, or a banned/isBanned/blocked
/// flag, or a status/message string containing "banned"/"blocked"). Every
/// time a call is force-logged-out because of this, the raw response is
/// printed to logcat tagged [BAN_GUARD] — check that against a real ban
/// test and tighten the matching below if the backend uses a different
/// shape.
class BanGuard {
  static bool _isHandling = false;

  /// Call this right after getting an http.Response back from any
  /// authenticated call. Returns true if the account was found to be
  /// banned/blocked and the app has already been force logged out —
  /// callers should stop processing that response (don't parse body etc.)
  /// when this returns true.
  static bool checkAndHandle(http.Response response) {
    if (!_looksBanned(response)) return false;

    debugPrint(
      "[BAN_GUARD] Banned/blocked account detected -> forcing logout. "
          "status=${response.statusCode} body=${response.body}",
    );

    _forceLogout();
    return true;
  }

  static bool _looksBanned(http.Response response) {
    // Most common convention for "you're not allowed to access this
    // anymore even though your token is otherwise valid".
    if (response.statusCode == 403) return true;

    if (response.body.isEmpty) return false;

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return false;

      final user = decoded['user'];
      final userMap = user is Map ? user : null;

      if (decoded['banned'] == true ||
          decoded['isBanned'] == true ||
          decoded['blocked'] == true ||
          decoded['suspended'] == true ||
          userMap?['banned'] == true ||
          userMap?['isBanned'] == true ||
          userMap?['blocked'] == true ||
          userMap?['suspended'] == true) {
        return true;
      }

      final status =
      (decoded['status'] ?? userMap?['status'])?.toString().toLowerCase();
      if (status == 'banned' || status == 'blocked' || status == 'suspended') return true;

      final msg =
      (decoded['message'] ?? decoded['error'] ?? '').toString().toLowerCase();
      if (msg.contains('banned') || msg.contains('blocked') || msg.contains('suspended')) return true;
    } catch (_) {
      // Response wasn't JSON, nothing more we can check here.
    }

    return false;
  }

  static Future<void> _forceLogout() async {
    // If 3-4 API calls fail together (common — home page fires several
    // calls at once) only handle the first one, otherwise the user would
    // see multiple stacked dialogs / multiple navigations.
    if (_isHandling) return;
    _isHandling = true;

    await TokenStorage.clear();

    final ctx = navigatorKey.currentState?.overlay?.context;

    if (ctx == null) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
      _isHandling = false;
      return;
    }

    await showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Account Banned"),
        content: const Text(
          "Your account has been banned by the admin. "
              "Please contact support if you think this is a mistake.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );

    _isHandling = false;
  }
}