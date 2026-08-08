import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../core/storage/token_storage.dart';

class SubscriptionApi {
  
  /// ================= START FREE TRIAL =================
  /// POST /subscription/start-trial
  static Future<Map<String, dynamic>?> startTrial() async {
    try {
      final token = await TokenStorage.getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/subscription/start-trial");
      
      print("SubscriptionApi: Starting free trial via $url");
      
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("SubscriptionApi: Start trial response status = ${response.statusCode}");
      print("SubscriptionApi: Start trial response body = ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Parse and save the subscription data returned from the backend
        final subscription = data["subscription"] ?? data["user"]?["subscription"];
        if (subscription != null) {
          if (subscription["status"] != null) {
            final int statusVal = _mapSubscriptionStatus(subscription["status"]);
            await TokenStorage.saveSubscriptionStatus(statusVal);
          }
          if (subscription["credits"] != null && subscription["credits"]["remaining"] != null) {
            await TokenStorage.saveCredits(subscription["credits"]["remaining"]);
          }
          if (subscription["limits"] != null) {
            if (subscription["limits"]["maxContacts"] != null) {
              await TokenStorage.saveMaxContacts(subscription["limits"]["maxContacts"]);
            }
            if (subscription["limits"]["maxCheckins"] != null) {
              await TokenStorage.saveMaxCheckins(subscription["limits"]["maxCheckins"]);
            }
          }
        } else {
          // If no nested subscription field but the backend returned status 1, update local storage
          await TokenStorage.saveSubscriptionStatus(1);
          await TokenStorage.saveCredits(1);
          await TokenStorage.saveMaxContacts(1);
          await TokenStorage.saveMaxCheckins(2);
        }
        return data;
      }
    } catch (e) {
      print("SubscriptionApi Error (startTrial): $e");
    }
    return null;
  }

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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Parse and save the subscription data returned from the backend
        final subscription = data["subscription"] ?? data["user"]?["subscription"];
        if (subscription != null) {
          if (subscription["status"] != null) {
            final int statusVal = _mapSubscriptionStatus(subscription["status"]);
            await TokenStorage.saveSubscriptionStatus(statusVal);
          }
          if (subscription["credits"] != null && subscription["credits"]["remaining"] != null) {
            await TokenStorage.saveCredits(subscription["credits"]["remaining"]);
          }
          if (subscription["limits"] != null) {
            if (subscription["limits"]["maxContacts"] != null) {
              await TokenStorage.saveMaxContacts(subscription["limits"]["maxContacts"]);
            }
            if (subscription["limits"]["maxCheckins"] != null) {
              await TokenStorage.saveMaxCheckins(subscription["limits"]["maxCheckins"]);
            }
          }
        }
        return data;
      }
    } catch (e) {
      print("SubscriptionApi Error (getSubscriptionStatus): $e");
    }
    return null;
  }

  /// Helper to convert backend string status (e.g. "NONE", "TRIAL", "ACTIVE", "EXPIRED") to app integer status:
  /// NONE: 0, TRIAL: 1, ACTIVE (MONTHLY): 2, YEARLY: 3
  static int _mapSubscriptionStatus(dynamic backendStatus) {
    if (backendStatus is int) return backendStatus;
    
    final statusStr = backendStatus.toString().toUpperCase();
    if (statusStr == "TRIAL") return 1;
    if (statusStr == "MONTHLY" || statusStr == "ACTIVE" || statusStr == "SUBSCRIBED") return 2;
    if (statusStr == "YEARLY") return 3;
    return 0; // "NONE", "EXPIRED", etc.
  }
}
