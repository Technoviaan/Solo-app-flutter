import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:solo_app/core/network/api_config.dart';
import 'package:solo_app/core/network/ban_guard.dart';
import 'package:solo_app/core/storage/token_storage.dart';

class CheckinApi {
  static Future<bool> confirmCheckin() async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/checkin/confirm"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      // [BAN_GUARD] Blocks a banned user from confirming an active
      // check-in cycle, which is the whole point of banning them.
      if (BanGuard.checkAndHandle(response)) return false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print("Error confirming checkin: $e");
      return false;
    }
  }

  static Future<bool> resumeCheckin() async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/checkin/resume"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (BanGuard.checkAndHandle(response)) return false;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print("Error resuming checkin: $e");
      return false;
    }
  }

  static Future<bool> saveCheckinTimes(List<String> times) async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/checkin"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "checkInTimes": times,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print("Error saving checkin times: $e");
      return false;
    }
  }
}
