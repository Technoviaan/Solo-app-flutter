import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../core/storage/token_storage.dart';

class StripeApi {
  /// ================= CREATE SUBSCRIPTION SESSION =================
  /// POST /stripe/create-subscription
  /// Returns the Stripe checkout URL.
  static Future<String?> createSubscriptionSession(String priceId) async {
    try {
      final token = await TokenStorage.getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/stripe/create-subscription");
      
      print("StripeApi: Creating subscription checkout session for Price ID: $priceId");
      
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

      print("StripeApi: Create subscription response status = ${response.statusCode}");
      print("StripeApi: Create subscription response body = ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["url"] as String?;
      }
    } catch (e) {
      print("StripeApi Error (createSubscriptionSession): $e");
    }
    return null;
  }

  /// ================= CREATE TOP-UP SESSION =================
  /// POST /stripe/create-topup
  /// Returns the Stripe checkout URL.
  static Future<String?> createTopupSession(String priceId) async {
    try {
      final token = await TokenStorage.getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/stripe/create-topup");
      
      print("StripeApi: Creating topup checkout session for Price ID: $priceId");
      
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

      print("StripeApi: Create topup response status = ${response.statusCode}");
      print("StripeApi: Create topup response body = ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["url"] as String?;
      }
    } catch (e) {
      print("StripeApi Error (createTopupSession): $e");
    }
    return null;
  }

  /// ================= OPEN CUSTOMER PORTAL =================
  /// POST /stripe/open-portal
  /// Returns the Customer Portal URL.
  static Future<String?> openPortal() async {
    try {
      final token = await TokenStorage.getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/stripe/open-portal");
      
      print("StripeApi: Opening customer portal");
      
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("StripeApi: Open portal response status = ${response.statusCode}");
      print("StripeApi: Open portal response body = ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data["url"] as String?;
      }
    } catch (e) {
      print("StripeApi Error (openPortal): $e");
    }
    return null;
  }
}
