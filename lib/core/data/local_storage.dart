/*
  Use Shared preferences to store data locally
  in NSUserDefaults (ios) and SharedPreferences (android)
  You can use Hive as lightweight and fast key-value database
  or sqflite with complex queries
  https://pub.dev/packages/hive
  https://pub.dev/packages/sqflite
*/

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());

class LocalStorage {
  LocalStorage._();

  static final LocalStorage _instance = LocalStorage._();

  factory LocalStorage() {
    return _instance;
  }

  // For example
  static const _keyAccessToken = 'access_token';
  static const _keyExpiredAt = 'expired_at';

  Future<int?> getExpiredAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyExpiredAt);
  }

  Future<void> saveExpiredAt(int expiredAt) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_keyExpiredAt, expiredAt);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  Future<String> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken) ?? '';
  }

  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_keyAccessToken, token);
  }
}
