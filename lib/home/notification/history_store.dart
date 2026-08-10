import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HistoryStore {
  static const String _checkinKey = "history_checkins_local";
  static const String _alertsKey = "history_alerts_local";

  static Future<void> logCheckin({
    required String status,
    required DateTime scheduledTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_checkinKey) ?? <String>[];
    final record = {
      "createdAt": DateTime.now().toIso8601String(),
      "scheduledTime": scheduledTime.toIso8601String(),
      "status": status,
    };
    items.insert(0, jsonEncode(record));
    await prefs.setStringList(_checkinKey, items);
  }

  static Future<List<Map<String, dynamic>>> getLocalCheckins() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_checkinKey) ?? <String>[];
    return items.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> logAlert({
    required String type,
    required List<String> contacts,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_alertsKey) ?? <String>[];
    final at = DateTime.now().toIso8601String();

    if (contacts.isEmpty) {
      items.insert(0, jsonEncode({"createdAt": at, "type": type, "contact": "—"}));
    } else {
      for (final contact in contacts) {
        items.insert(
          0,
          jsonEncode({
            "createdAt": at,
            "type": type,
            "contact": contact,
          }),
        );
      }
    }
    await prefs.setStringList(_alertsKey, items);
  }

  static Future<List<Map<String, dynamic>>> getLocalAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_alertsKey) ?? <String>[];
    return items.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_checkinKey);
    await prefs.remove(_alertsKey);
  }
}
