import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../core/storage/token_storage.dart';

class UserApi {

  static Future<Map<String, dynamic>> saveEmail(String email) async {

    final token = await TokenStorage.getToken();

    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/user/email"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "email": email,
      }),
    );

    return jsonDecode(res.body);
  }
}