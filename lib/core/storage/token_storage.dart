import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Cache for SharedPreferences instance to avoid repeated getInstance() calls
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _getPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// AUTH KEYS (Secure)
  static const String _tokenKey = "auth_token";
  
  /// ONBOARDING KEYS (Public)
  static const String _nameKey = "name_completed";
  static const String _emailKey = "email_completed";

  /// SUBSCRIPTION KEYS (Public)
  static const String _subscriptionStatusKey = "subscription_status";
  static const String _creditsKey = "credits_remaining";
  static const String _maxContactsKey = "max_contacts";
  static const String _maxCheckinsKey = "max_checkins";

  /// LANGUAGE KEY (Public)
  static const String _languageKey = "language";

  // ================= TOKEN (Secure Storage) =================

  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // ================= NAME (SharedPreferences) =================

  static Future<void> saveNameCompleted(bool value) async {
    final prefs = await _getPrefs;
    await prefs.setBool(_nameKey, value);
  }

  static Future<bool> getNameCompleted() async {
    final prefs = await _getPrefs;
    return prefs.getBool(_nameKey) ?? false;
  }

  // ================= EMAIL (SharedPreferences) =================

  static Future<void> saveEmailCompleted(bool value) async {
    final prefs = await _getPrefs;
    await prefs.setBool(_emailKey, value);
  }

  static Future<bool> getEmailCompleted() async {
    final prefs = await _getPrefs;
    return prefs.getBool(_emailKey) ?? false;
  }

  // ================= SUBSCRIPTION (SharedPreferences) =================

  static Future<void> saveSubscriptionStatus(int status) async {
    final prefs = await _getPrefs;
    await prefs.setInt(_subscriptionStatusKey, status);
  }

  static Future<int> getSubscriptionStatus() async {
    final prefs = await _getPrefs;
    return prefs.getInt(_subscriptionStatusKey) ?? 0;
  }

  static Future<void> saveCredits(int credits) async {
    final prefs = await _getPrefs;
    await prefs.setInt(_creditsKey, credits);
  }

  static Future<int> getCredits() async {
    final prefs = await _getPrefs;
    return prefs.getInt(_creditsKey) ?? 0;
  }

  static Future<void> saveMaxContacts(int value) async {
    final prefs = await _getPrefs;
    await prefs.setInt(_maxContactsKey, value);
  }

  static Future<int> getMaxContacts() async {
    final prefs = await _getPrefs;
    return prefs.getInt(_maxContactsKey) ?? 0;
  }

  static Future<void> saveMaxCheckins(int value) async {
    final prefs = await _getPrefs;
    await prefs.setInt(_maxCheckinsKey, value);
  }

  static Future<int> getMaxCheckins() async {
    final prefs = await _getPrefs;
    return prefs.getInt(_maxCheckinsKey) ?? 0;
  }

  // ================= LANGUAGE (SharedPreferences) =================

  static Future<void> saveLanguage(String lang) async {
    final prefs = await _getPrefs;
    await prefs.setString(_languageKey, lang);
  }

  static Future<String?> getLanguage() async {
    final prefs = await _getPrefs;
    return prefs.getString(_languageKey);
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await _getPrefs;
    await prefs.setString("user_name", name);
  }

  static Future<String> getUserName() async {
    final prefs = await _getPrefs;
    return prefs.getString("user_name") ?? "User";
  }

  // ================= CLEAR =================

  static Future<void> clear() async {
    await _secureStorage.deleteAll();
    final prefs = await _getPrefs;
    await prefs.clear();
  }
}