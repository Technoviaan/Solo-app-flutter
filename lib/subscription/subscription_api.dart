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

      // [BAN_GUARD] This runs on every app boot (SplashScreen calls it
      // before entering Home), so a banned user gets kicked to Login the
      // very next time they open the app, even if they never touch a
      // check-in/notification screen.
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

    // 1. Status Parsing
    final dynamic status = nested["status"] ?? data["status"];
    int statusVal = 0;
    if (status != null) {
      statusVal = _mapSubscriptionStatus(status, data["planType"]);
      await TokenStorage.saveSubscriptionStatus(statusVal);
      print("SubscriptionApi: ✅ Saved subscription status -> $statusVal");
      savedAnything = true;
    }

    // 2. Credits Parsing (With Fallback if Backend sends 0 for Active Plan)
    dynamic credits = nested["credits"]?["remaining"] ?? data["creditsRemaining"] ?? data["credits"];
    int creditsVal = credits is int ? credits : int.tryParse(credits?.toString() ?? '') ?? 0;

    // Fallback: Agar Active Monthly/Yearly plan hai par backend credits 0 bhej raha hai
    if (creditsVal == 0 && (statusVal == 2 || statusVal == 3)) {
      creditsVal = statusVal == 2 ? 3 : 36;
      print("SubscriptionApi: ⚠️ Applied fallback credits -> $creditsVal");
    }

    await TokenStorage.saveCredits(creditsVal);
    print("SubscriptionApi: ✅ Saved credits -> $creditsVal");
    savedAnything = true;

    return savedAnything;
  }

  static int _mapSubscriptionStatus(dynamic backendStatus, dynamic planType) {
    if (backendStatus is int) return backendStatus;

    final statusStr = backendStatus.toString().toUpperCase();
    final planStr = planType?.toString().toUpperCase() ?? "";

    if (statusStr == "TRIAL") return 1;
    if (statusStr == "ACTIVE" || statusStr == "SUBSCRIBED") {
      if (planStr == "YEARLY") return 3;
      return 2; // Default Monthly
    }
    if (statusStr == "MONTHLY") return 2;
    if (statusStr == "YEARLY") return 3;
    return 0;
  }

  /// ================= REDEEM PROMO CODE =================
  /// POST /promo/redeem
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

      // Status code add kar dete hain response map me easy checking ke liye
      data['statusCode'] = response.statusCode;
      return data;
    } catch (e) {
      print("SubscriptionApi Error (redeemPromoCode): $e");
      return null;
    }
  }

}