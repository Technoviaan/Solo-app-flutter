import 'dart:convert';
import 'package:http/http.dart' as http;
import '../network/api_config.dart';
import '../storage/token_storage.dart';

class DeleteAccountApi {

  static Future<bool> deleteAccount() async {

    final token = await TokenStorage.getToken();

    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/user"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data["message"]);
      return true;
    }

    return false;
  }
}