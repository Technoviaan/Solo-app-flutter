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

    // 1. Status & Plan Parsing
    final dynamic rawStatus = nested["status"] ?? data["status"];
    final dynamic rawPlan = nested["planType"] ??
        nested["plan"] ??
        nested["name"] ??
        data["planType"] ??
        data["plan"];

    int statusVal = 0;
    if (rawStatus != null) {
      statusVal = _mapSubscriptionStatus(rawStatus, rawPlan);
      await TokenStorage.saveSubscriptionStatus(statusVal);
      debugPrint("SubscriptionApi: ✅ Saved subscription status -> $statusVal");
      savedAnything = true;
    }

    // 2. Credits Extraction
    dynamic rawCredits = nested["credits"]?["remaining"] ??
        nested["remainingCredits"] ??
        nested["creditBalance"] ??
        nested["credits"] ??
        data["creditsRemaining"] ??
        data["remainingCredits"] ??
        data["creditBalance"] ??
        data["credits"]?["remaining"] ??
        data["credits"] ??
        data["user"]?["credits"];

    int parsedCredits = 0;
    if (rawCredits != null) {
      parsedCredits = rawCredits is int
          ? rawCredits
          : (int.tryParse(rawCredits.toString()) ?? 0);
    }

    // 🔥 FLUTTER FALLBACK: Agar backend 0 bhej raha hai jabki user active plan pe hai
    if (parsedCredits == 0) {
      if (statusVal == 3) {
        // Yearly Plan Active -> 36 Credits
        parsedCredits = 36;
        debugPrint("SubscriptionApi: ⚡ Fallback applied for YEARLY -> 36 credits");
      } else if (statusVal == 2) {
        // Monthly Plan Active -> 3 Credits
        parsedCredits = 3;
        debugPrint("SubscriptionApi: ⚡ Fallback applied for MONTHLY -> 3 credits");
      } else if (statusVal == 1) {
        // Trial Active -> 1 Credit
        parsedCredits = 1;
        debugPrint("SubscriptionApi: ⚡ Fallback applied for TRIAL -> 1 credit");
      }
    }

    await TokenStorage.saveCredits(parsedCredits);
    debugPrint("SubscriptionApi: ✅ Final Saved credits -> $parsedCredits");
    savedAnything = true;

    return savedAnything;
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