import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../core/storage/token_storage.dart';

class StripeApi {
  /// Holds the backend's error message from the most recent failed call
  static String? lastErrorMessage;

  /// ================= CREATE TRIAL SESSION =================
  /// POST /stripe/create-trial
  static Future<String?> createTrialSession(String priceId) async {
    lastErrorMessage = null;
    try {
      final token = await TokenStorage.getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/stripe/create-trial");

      print("\n==================================================");
      print("🚀 [StripeApi] POST Request: $url");
      print("📦 [StripeApi] Payload: ${jsonEncode({"priceId": priceId})}");
      print("==================================================\n");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "priceId": priceId,
        }),
      );

      print("\n==================================================");
      print("📥 [StripeApi] Trial Response Status: ${response.statusCode}");
      print("📥 [StripeApi] Trial Response Body: ${response.body}");
      print("==================================================\n");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["url"] as String?;
      } else {
        try {
          final data = jsonDecode(response.body);
          lastErrorMessage = data["message"] as String?;
        } catch (_) {}
        print("❌ [StripeApi] createTrialSession failed -> $lastErrorMessage");
      }
    } catch (e) {
      print("❌ [StripeApi Error (createTrialSession)]: $e");
    }
    return null;
  }

  /// ================= CREATE SUBSCRIPTION SESSION =================
  /// POST /stripe/create-subscription
  static Future<String?> createSubscriptionSession(String priceId) async {
    lastErrorMessage = null;
    try {
      final token = await TokenStorage.getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/stripe/create-subscription");

      print("\n==================================================");
      print("🚀 [StripeApi] POST Request: $url");
      print("📦 [StripeApi] Payload: ${jsonEncode({"priceId": priceId})}");
      print("==================================================\n");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "priceId": priceId,
        }),
      );

      print("\n==================================================");
      print("📥 [StripeApi] Subscription Response Status: ${response.statusCode}");
      print("📥 [StripeApi] Subscription Response Body: ${response.body}");
      print("==================================================\n");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["url"] as String?;
      } else {
        try {
          final data = jsonDecode(response.body);
          lastErrorMessage = data["message"] as String?;
        } catch (_) {}
        print("❌ [StripeApi] createSubscriptionSession failed -> $lastErrorMessage");
      }
    } catch (e) {
      print("❌ [StripeApi Error (createSubscriptionSession)]: $e");
    }
    return null;
  }

  /// ================= CREATE TOP-UP SESSION =================
  /// POST /stripe/create-topup
  static Future<String?> createTopupSession(String priceId) async {
    lastErrorMessage = null;
    try {
      final token = await TokenStorage.getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/stripe/create-topup");

      print("\n==================================================");
      print("🚀 [StripeApi] POST Request: $url");
      print("📦 [StripeApi] Payload: ${jsonEncode({"priceId": priceId})}");
      print("==================================================\n");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "priceId": priceId,
        }),
      );

      print("\n==================================================");
      print("📥 [StripeApi] Topup Response Status: ${response.statusCode}");
      print("📥 [StripeApi] Topup Response Body: ${response.body}");
      print("==================================================\n");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["url"] as String?;
      } else {
        try {
          final data = jsonDecode(response.body);
          lastErrorMessage = data["message"] as String?;
        } catch (_) {}
        print("❌ [StripeApi] createTopupSession failed -> $lastErrorMessage");
      }
    } catch (e) {
      print("❌ [StripeApi Error (createTopupSession)]: $e");
    }
    return null;
  }

  /// ================= OPEN CUSTOMER PORTAL =================
  /// POST /stripe/open-portal
  static Future<String?> openPortal() async {
    try {
      final token = await TokenStorage.getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/stripe/open-portal");

      print("\n==================================================");
      print("🚀 [StripeApi] POST Request (Open Portal): $url");
      print("==================================================\n");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("\n==================================================");
      print("📥 [StripeApi] Open Portal Response Status: ${response.statusCode}");
      print("📥 [StripeApi] Open Portal Response Body: ${response.body}");
      print("==================================================\n");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["url"] as String?;
      }
    } catch (e) {
      print("❌ [StripeApi Error (openPortal)]: $e");
    }
    return null;
  }
}