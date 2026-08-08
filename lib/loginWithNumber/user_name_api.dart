import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../core/storage/token_storage.dart';

class NameApi {

  static Future<Map<String, dynamic>> saveName(String name) async {

    final token = await TokenStorage.getToken();

    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/user/save-name"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "name": name,
      }),
    );

    return jsonDecode(res.body);
  }
}