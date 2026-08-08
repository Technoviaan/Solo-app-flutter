import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:solo_app/core/network/api_config.dart';
import 'package:solo_app/core/storage/token_storage.dart';

class ProfileApi {

  static Future<Map<String, dynamic>?> getProfile() async {

    final token = await TokenStorage.getToken();

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/user/profile"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null) {
        final subscription = data["subscription"] ?? data["user"]?["subscription"];
        if (subscription != null) {
          if (subscription["status"] != null) {
            await TokenStorage.saveSubscriptionStatus(subscription["status"]);
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
      }
      return data;
    }

    print(response.body);
    return null;
  }

  static Future<bool> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? gender,
    String? age,
    File? image,
  }) async {

    final token = await TokenStorage.getToken();

    var request = http.MultipartRequest(
      "PUT",
      Uri.parse("${ApiConfig.baseUrl}/user/profile"),
    );

    request.headers["Authorization"] = "Bearer $token";

    request.fields["name"] = name;
    request.fields["email"] = email;
    if (phone != null) {
      request.fields["phone"] = phone;
    }

    if (gender != null) {
      request.fields["gender"] = gender;
    }

    if (age != null) {
      request.fields["age"] = age;
    }

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "image",
          image.path,
        ),
      );
    }

    final response = await request.send();

    final res = await http.Response.fromStream(response);

    print("UPDATE RESPONSE:");
    print(res.body);

    if (res.statusCode == 200) {
      return true;
    }

    return false;
  }

  static Future<bool> updatePreferences({
    String? language,
    String? alertVoice,
  }) async {
    final token = await TokenStorage.getToken();

    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/user/preferences"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        if (language != null) "language": language,
        if (alertVoice != null) "alertVoice": alertVoice,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    return false;
  }
}