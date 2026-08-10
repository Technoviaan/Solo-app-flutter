import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../core/storage/token_storage.dart';

class AuthApi {

  /// ================= SEND OTP =================
  static Future<Map<String, dynamic>> sendOtp(
      String countryCode,
      String phone,
      ) async {

    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/send-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "countryCode": countryCode,
        "phone": phone,
      }),
    );

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

    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "countryCode": countryCode,
        "phone": phone,
        "otp": otp,
        "language": lang,
      }),
    );

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

    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/send-email-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
      }),
    );

    return jsonDecode(res.body);
  }

  /// ================= VERIFY EMAIL OTP =================
  static Future<Map<String, dynamic>> verifyEmailOtp(
      String email,
      String otp,
      ) async {

    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/auth/verify-email-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "otp": otp,
      }),
    );

    return jsonDecode(res.body);
  }
}