import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../core/network/ban_guard.dart';
import '../core/storage/token_storage.dart';

class SubscriptionApi {
  /// ================= GET SUBSCRIPTION STATUS =================
  /// GET /subscription/status
  static Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    try {
      final token = await TokenStorage.getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/subscription/status");

      debugPrint("SubscriptionApi: Fetching subscription status via $url");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("SubscriptionApi: Status response status = ${response.statusCode}");
      debugPrint("SubscriptionApi: Status response body = ${response.body}");

      if (BanGuard.checkAndHandle(response)) return null;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _applySubscriptionData(data);
        return data;
      }
    } catch (e) {
      debugPrint("SubscriptionApi Error (getSubscriptionStatus): $e");
    }
    return null;
  }

  static Future<bool> _applySubscriptionData(Map<String, dynamic> data) async {
    final Map<String, dynamic> nested =
        (data["subscription"] ?? data["user"]?["subscription"] ?? data["data"]) as Map<String, dynamic>? ?? const {};

    bool savedAnything = false;

    // 1. Status & Plan Parsing (Dynamic from backend)
    final dynamic rawStatus = nested["status"] ?? data["status"];
    final dynamic rawPlan = nested["planType"] ??
        nested["plan"] ??
        nested["name"] ??
        data["planType"] ??
        data["plan"];

    if (rawStatus != null) {
      final int statusVal = _mapSubscriptionStatus(rawStatus, rawPlan);
      await TokenStorage.saveSubscriptionStatus(statusVal);
      debugPrint("SubscriptionApi: ✅ Saved subscription status -> $statusVal");
      savedAnything = true;
    }

    dynamic rawCredits = nested["credits"]?["remaining"] ??
        nested["remainingCredits"] ??
        nested["creditBalance"] ??
        nested["totalCredits"] ??
        data["totalCredits"] ??
        data["creditsRemaining"] ??
        data["remainingCredits"] ??
        data["creditBalance"] ??
        data["credits"]?["remaining"] ??
        data["user"]?["credits"] ??
        data["user"]?["totalCredits"] ??
        _primitiveOrNull(nested["credits"]) ??
        _primitiveOrNull(data["credits"]);

    if (rawCredits != null) {
      final int? parsedCredits = _parseToInt(rawCredits);

      if (parsedCredits != null) {
        await TokenStorage.saveCredits(parsedCredits);
        debugPrint("SubscriptionApi: ✅ Saved exact backend credits -> $parsedCredits");
        savedAnything = true;
      } else {
        debugPrint(
          "SubscriptionApi: ⚠️ Could not parse credits from raw value: $rawCredits (type ${rawCredits.runtimeType}) — keeping previously saved value",
        );
      }
    }

    return savedAnything;
  }

  /// Returns [value] only if it is a primitive we can safely stringify
  /// and parse (int, num, or String). Returns null for Maps/Lists/etc.
  /// so they never get passed into int.tryParse(toString()).
  static dynamic _primitiveOrNull(dynamic value) {
    if (value is int || value is num || value is String) {
      return value;
    }
    return null;
  }

  /// Safely converts a raw credits value into an int, or null if it
  /// cannot be reliably parsed (instead of defaulting to 0).
  static int? _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static int _mapSubscriptionStatus(dynamic backendStatus, dynamic planType) {
    if (backendStatus is int) return backendStatus;

    final statusStr = backendStatus.toString().toUpperCase().trim();
    final planStr = planType?.toString().toUpperCase().trim() ?? "";

    if (planStr.contains("YEAR") || statusStr.contains("YEAR")) {
      return 3;
    }
    if (statusStr == "TRIAL" || planStr.contains("TRIAL")) {
      return 1;
    }
    if (statusStr == "ACTIVE" || statusStr == "SUBSCRIBED" || statusStr == "PAID") {
      if (planStr.contains("YEAR")) return 3;
      return 2;
    }
    if (statusStr == "MONTHLY" || planStr.contains("MONTH")) {
      return 2;
    }
    return 0;
  }

  /// ================= REDEEM PROMO CODE =================
  static Future<Map<String, dynamic>?> redeemPromoCode(String code) async {
    try {
      final token = await TokenStorage.getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/promo/redeem");

      debugPrint("SubscriptionApi: Redeeming promo code: $code via $url");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"code": code}),
      );

      debugPrint("SubscriptionApi: Promo response status = ${response.statusCode}");
      debugPrint("SubscriptionApi: Promo response body = ${response.body}");

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      data['statusCode'] = response.statusCode;
      return data;
    } catch (e) {
      debugPrint("SubscriptionApi Error (redeemPromoCode): $e");
      return null;
    }
  }

  /// ================= START TRIAL =================
  static Future<Map<String, dynamic>?> startTrial() async {
    try {
      final token = await TokenStorage.getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/subscription/start-trial");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _applySubscriptionData(data);
        return data;
      }
    } catch (e) {
      debugPrint("SubscriptionApi Error (startTrial): $e");
    }
    return null;
  }
}