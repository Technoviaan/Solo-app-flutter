import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:solo_app/home/notification/model/alert_history_model.dart';
import 'package:solo_app/home/notification/model/checkin_history_model.dart';
import '../../core/network/api_config.dart';
import '../../core/network/ban_guard.dart';
import '../../core/storage/token_storage.dart';


class NotificationApi {

  static Future<List<CheckinHistoryModel>> getCheckinHistory() async {

    final token = await TokenStorage.getToken();

    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/checkin/history"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    if (BanGuard.checkAndHandle(res)) return [];

    if (res.statusCode == 200) {

      final List data = jsonDecode(res.body);

      return data
          .map((e) => CheckinHistoryModel.fromJson(e))
          .toList();
    }

    return [];
  }

  static Future<List<AlertHistoryModel>> getAlertHistory() async {

    final token = await TokenStorage.getToken();

    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/alerts/history"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    if (BanGuard.checkAndHandle(res)) return [];

    if (res.statusCode == 200) {

      final List data = jsonDecode(res.body);

      return data
          .map((e) => AlertHistoryModel.fromJson(e))
          .toList();
    }

    return [];
  }

  static Future<bool> clearCheckinHistory() async {

    final token = await TokenStorage.getToken();

    final res = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/checkin/history/clear"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    return res.statusCode == 200;
  }

  static Future<bool> triggerSos() async {

    final token = await TokenStorage.getToken();

    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/alerts/sos"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    if (BanGuard.checkAndHandle(res)) return false;

    return res.statusCode == 200 || res.statusCode == 201;
  }
}