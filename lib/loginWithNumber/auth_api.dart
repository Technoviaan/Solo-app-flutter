import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../core/storage/token_storage.dart';

class AuthApi {

  /// ================= SEND OTP =================
  static Future<Map<String, dynamic>> sendOtp(
      String countryCode,
      String phone,
      ) async {

    final url = "${ApiConfig.baseUrl}/auth/send-otp";
    final requestBody = {
      "countryCode": countryCode,
      "phone": phone,
    };

    // 🐛 DEBUG: confirm exactly what is being sent to the backend
    debugPrint("📤 [AuthApi.sendOtp] POST $url");
    debugPrint("📤 [AuthApi.sendOtp] body: ${jsonEncode(requestBody)}");

    final res = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    debugPrint("📥 [AuthApi.sendOtp] status: ${res.statusCode}");
    debugPrint("📥 [AuthApi.sendOtp] response: ${res.body}");

    final data = jsonDecode(res.body);

    return data;
  }

  /// ================= VERIFY OTP =================
  static Future<Map<String, dynamic>> verifyOtp(
      String countryCode,
      String phone,
      String otp,
      ) async {

    final lang = await TokenStorage.getLanguage() ?? "en";

    final url = "${ApiConfig.baseUrl}/auth/verify-otp";
    final requestBody = {
      "countryCode": countryCode,
      "phone": phone,
      "otp": otp,
      "language": lang,
    };

    // 🐛 DEBUG: confirm exactly what is being sent to the backend
    debugPrint("📤 [AuthApi.verifyOtp] POST $url");
    debugPrint("📤 [AuthApi.verifyOtp] body: ${jsonEncode(requestBody)}");

    final res = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    debugPrint("📥 [AuthApi.verifyOtp] status: ${res.statusCode}");
    debugPrint("📥 [AuthApi.verifyOtp] response: ${res.body}");

    final data = jsonDecode(res.body);

    if (data != null && (data["status"] == 1 || data["status"] == 2)) {
      return data;
    }

    throw Exception(data?["message"] ?? "OTP verification failed");
  }

  /// ================= SEND EMAIL OTP =================
  static Future<Map<String, dynamic>> sendEmailOtp(
      String email,
      ) async {

    final url = "${ApiConfig.baseUrl}/auth/send-email-otp";
    debugPrint("📤 [AuthApi.sendEmailOtp] POST $url");
    debugPrint("📤 [AuthApi.sendEmailOtp] body: ${jsonEncode({"email": email})}");

    final res = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
      }),
    );

    debugPrint("📥 [AuthApi.sendEmailOtp] status: ${res.statusCode}");
    debugPrint("📥 [AuthApi.sendEmailOtp] response: ${res.body}");

    return jsonDecode(res.body);
  }

  /// ================= VERIFY EMAIL OTP =================
  static Future<Map<String, dynamic>> verifyEmailOtp(
      String email,
      String otp,
      ) async {

    final url = "${ApiConfig.baseUrl}/auth/verify-email-otp";
    final requestBody = {"email": email, "otp": otp};
    debugPrint("📤 [AuthApi.verifyEmailOtp] POST $url");
    debugPrint("📤 [AuthApi.verifyEmailOtp] body: ${jsonEncode(requestBody)}");

    final res = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    debugPrint("📥 [AuthApi.verifyEmailOtp] status: ${res.statusCode}");
    debugPrint("📥 [AuthApi.verifyEmailOtp] response: ${res.body}");

    return jsonDecode(res.body);
  }
}