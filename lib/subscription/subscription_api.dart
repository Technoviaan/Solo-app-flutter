import 'dart:convert';
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

      print("SubscriptionApi: Fetching subscription status via $url");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      print("SubscriptionApi: Status response status = ${response.statusCode}");
      print("SubscriptionApi: Status response body = ${response.body}");

      if (BanGuard.checkAndHandle(response)) return null;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _applySubscriptionData(data);
        return data;
      }
    } catch (e) {
      print("SubscriptionApi Error (getSubscriptionStatus): $e");
    }
    return null;
  }

  static Future<bool> _applySubscriptionData(Map<String, dynamic> data) async {
    final Map<String, dynamic> nested =
        (data["subscription"] ?? data["user"]?["subscription"]) as Map<String, dynamic>? ?? const {};

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
      print("SubscriptionApi: ✅ Saved subscription status -> $statusVal");
      savedAnything = true;
    }

    // 2. Credits from Backend
    dynamic credits = nested["credits"]?["remaining"] ??
        nested["remainingCredits"] ??
        nested["credits"] ??
        data["creditsRemaining"] ??
        data["remainingCredits"] ??
        data["credits"]?["remaining"] ??
        data["credits"];

    int incomingCredits = credits is int ? credits : int.tryParse(credits?.toString() ?? '') ?? 0;

    int finalCredits = incomingCredits;

    // 🔥 Base Plan Minimum Threshold Check
    // Agar Yearly plan (status 3) hai aur incoming credits 36 se kam hain (jaise top-up 3 aagaya),
    // to base 36 me top-up add hoga (36 + 3 = 39)
    if (statusVal == 3) {
      if (incomingCredits < 36) {
        finalCredits = 36 + incomingCredits;
        print("SubscriptionApi: 💡 Yearly user base 36 + topup ($incomingCredits) -> $finalCredits");
      }
    } else if (statusVal == 2) {
      if (incomingCredits < 3) {
        finalCredits = 3 + incomingCredits;
        print("SubscriptionApi: 💡 Monthly user base 3 + topup ($incomingCredits) -> $finalCredits");
      }
    } else if (statusVal == 1 && incomingCredits == 0) {
      finalCredits = 1;
    }

    // Local credits check: Agar local me already zyada credits hain to ghatao mat
    int currentLocal = await TokenStorage.getCredits();
    if (currentLocal > finalCredits) {
      finalCredits = currentLocal;
    }

    await TokenStorage.saveCredits(finalCredits);
    print("SubscriptionApi: ✅ Final Saved credits -> $finalCredits");
    savedAnything = true;

    return savedAnything;
  }
  static int _mapSubscriptionStatus(dynamic backendStatus, dynamic planType) {
    if (backendStatus is int) return backendStatus;

    final statusStr = backendStatus.toString().toUpperCase().trim();
    final planStr = planType?.toString().toUpperCase().trim() ?? "";

    // Yearly checks
    if (planStr.contains("YEAR") || statusStr.contains("YEAR")) {
      return 3;
    }

    // Trial checks
    if (statusStr == "TRIAL" || planStr.contains("TRIAL")) {
      return 1;
    }

    // Active / Subscribed checks
    if (statusStr == "ACTIVE" || statusStr == "SUBSCRIBED" || statusStr == "PAID") {
      if (planStr.contains("YEAR")) {
        return 3;
      }
      return 2; // Default Monthly
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

      print("SubscriptionApi: Redeeming promo code: $code via $url");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"code": code}),
      );

      print("SubscriptionApi: Promo response status = ${response.statusCode}");
      print("SubscriptionApi: Promo response body = ${response.body}");

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      data['statusCode'] = response.statusCode;
      return data;
    } catch (e) {
      print("SubscriptionApi Error (redeemPromoCode): $e");
      return null;
    }
  }
}