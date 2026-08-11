import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:solo_app/core/storage/token_storage.dart';

class LocalStorage {
  static const String _contactsKey = "contacts_full";
  static const String _scheduleKey = "schedule_time";
  static const String _scheduleListKey = "schedule_minutes";
  static const String _alertWindowHoursKey = "alert_window_hours";
  static const String _voiceKey = "alert_voice";

  /// ================= SAVE FULL CONTACT LIST =================
  static Future<void> saveContacts(List<Map<String, String>> contacts) async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> encoded = contacts.map((e) => jsonEncode(e)).toList();

    await prefs.setStringList(_contactsKey, encoded);
  }

  /// ================= GET FULL CONTACT LIST =================
  static Future<List<Map<String, String>>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList(_contactsKey) ?? [];

    return data
        .map((e) => Map<String, String>.from(jsonDecode(e)))
        .toList();
  }

  /// ================= SAVE SCHEDULE =================
  static Future<void> saveSchedule(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scheduleKey, time);
  }

  /// ================= GET SCHEDULE =================
  static Future<String?> getSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_scheduleKey);
  }

  static Future<void> saveScheduleMinutes(List<int> minutesOfDay) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = minutesOfDay.map((e) => e.toString()).toList();
    await prefs.setStringList(_scheduleListKey, encoded);
  }

  static Future<List<int>> getScheduleMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getStringList(_scheduleListKey) ?? const [];
    return encoded.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList();
  }

  static Future<void> saveAlertWindowHours(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_alertWindowHoursKey, hours);
  }

  static Future<int> getAlertWindowHours() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_alertWindowHoursKey) ?? 2;
  }

  /// ================= TEST MODE (dev only) =================
  /// When set, overrides the real hour-based alert window with a short
  /// second-based window so the full missed-checkin flow can be tested in
  /// under a minute instead of waiting hours. Always cleared automatically
  /// whenever a REAL schedule is saved (see scheduleMissedCheckinFlow).
  static const String _testWindowSecondsKey = "test_window_seconds";

  static Future<void> saveTestWindowSeconds(int? seconds) async {
    final prefs = await SharedPreferences.getInstance();
    if (seconds == null) {
      await prefs.remove(_testWindowSecondsKey);
    } else {
      await prefs.setInt(_testWindowSecondsKey, seconds);
    }
  }

  static Future<int?> getTestWindowSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_testWindowSecondsKey);
  }

  static Future<void> saveVoice(String voice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceKey, voice);
  }

  static Future<String> getVoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_voiceKey) ?? "Male";
  }

  static Future<void> saveUserName(String name) async {
    await TokenStorage.saveUserName(name);
  }

  static Future<String> getUserName() async {
    return await TokenStorage.getUserName();
  }

  static Future<void> saveActiveCheckinTime(DateTime? time) async {
    final prefs = await SharedPreferences.getInstance();
    if (time == null) {
      await prefs.remove("active_checkin_time");
    } else {
      await prefs.setString("active_checkin_time", time.toIso8601String());
    }
  }

  static Future<DateTime?> getActiveCheckinTime() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString("active_checkin_time");
    return iso != null ? DateTime.parse(iso) : null;
  }

  static Future<void> savePreviousCheckinTime(DateTime? time) async {
    final prefs = await SharedPreferences.getInstance();
    if (time == null) {
      await prefs.remove("previous_checkin_time");
    } else {
      await prefs.setString("previous_checkin_time", time.toIso8601String());
    }
  }

  static Future<DateTime?> getPreviousCheckinTime() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString("previous_checkin_time");
    return iso != null ? DateTime.parse(iso) : null;
  }

  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<bool> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> saveStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  static Future<List<String>> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }
}