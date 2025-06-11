import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A service that manages cache expiration for the app.
/// It ensures that any cached data is automatically expired after 30 days.
class CacheExpiryManager {
  static const int _cacheExpiryDays = 30;
  static const String _cacheTimestampPrefix = 'cache_timestamp_';

  /// Gets the SharedPreferences instance
  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  /// Stores data in cache with a timestamp
  static Future<bool> setWithExpiry(String key, String value) async {
    final prefs = await _prefs;

    // Save the actual data
    final dataSaved = await prefs.setString(key, value);

    // Save timestamp for this key
    final timestampKey = _getTimestampKey(key);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final timestampSaved = await prefs.setString(
      timestampKey,
      timestamp.toString(),
    );

    return dataSaved && timestampSaved;
  }

  /// Gets data from cache if it's not expired
  static Future<String?> getWithExpiry(String key) async {
    final prefs = await _prefs;

    // Check if the key has a timestamp
    final timestampKey = _getTimestampKey(key);
    final timestampStr = prefs.getString(timestampKey);

    // If there's no timestamp, or the data doesn't exist, return null
    if (timestampStr == null) {
      return prefs.getString(key); // Return data without expiry check
    }

    // Check if the cache is expired
    final timestamp = int.parse(timestampStr);
    final now = DateTime.now().millisecondsSinceEpoch;
    final age = now - timestamp;
    const maxAge = _cacheExpiryDays * 24 * 60 * 60 * 1000;

    if (age > maxAge) {
      // Cache is expired, remove it
      await prefs.remove(key);
      await prefs.remove(timestampKey);
      return null;
    }

    // Cache is still valid
    return prefs.getString(key);
  }

  /// Stores an object in cache with a timestamp (after converting to JSON)
  static Future<bool> setObjectWithExpiry(String key, Object value) async {
    final jsonString = jsonEncode(value);
    return await setWithExpiry(key, jsonString);
  }

  /// Gets an object from cache if it's not expired
  static Future<Map<String, dynamic>?> getMapWithExpiry(String key) async {
    final jsonString = await getWithExpiry(key);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding JSON for key $key: $e');
      return null;
    }
  }

  /// Gets a list from cache if it's not expired
  static Future<List<dynamic>?> getListWithExpiry(String key) async {
    final jsonString = await getWithExpiry(key);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      print('Error decoding JSON list for key $key: $e');
      return null;
    }
  }

  /// Removes a key and its timestamp from cache
  static Future<bool> remove(String key) async {
    final prefs = await _prefs;
    final timestampKey = _getTimestampKey(key);

    final keyRemoved = await prefs.remove(key);
    final timestampRemoved = await prefs.remove(timestampKey);

    return keyRemoved && timestampRemoved;
  }

  /// Cleans up all expired cache entries
  static Future<void> cleanExpiredCache() async {
    print('Cleaning expired cache (older than $_cacheExpiryDays days)');
    final prefs = await _prefs;
    final allKeys = prefs.getKeys();
    final now = DateTime.now().millisecondsSinceEpoch;
    const maxAge = _cacheExpiryDays * 24 * 60 * 60 * 1000; // days to ms

    // Find all timestamp keys
    final timestampKeys = allKeys.where(
      (key) => key.startsWith(_cacheTimestampPrefix),
    );

    int removedCount = 0;

    // Check each timestamp
    for (final timestampKey in timestampKeys) {
      final timestampStr = prefs.getString(timestampKey);
      if (timestampStr == null) continue;

      final timestamp = int.parse(timestampStr);
      final age = now - timestamp;

      if (age > maxAge) {
        // Extract the original key from the timestamp key
        final originalKey = _getOriginalKey(timestampKey);

        // Remove both the data and timestamp
        await prefs.remove(originalKey);
        await prefs.remove(timestampKey);
        removedCount++;

        print('Removed expired cache: $originalKey (${_formatDaysOld(age)})');
      }
    }

    print('Cache cleanup complete. Removed $removedCount expired items.');
  }

  /// Helper method to format age in a readable format
  static String _formatDaysOld(int ageInMs) {
    final days = ageInMs / (24 * 60 * 60 * 1000);
    return '${days.toStringAsFixed(1)} days old';
  }

  /// Creates a timestamp key from the original key
  static String _getTimestampKey(String key) {
    return '$_cacheTimestampPrefix$key';
  }

  /// Extracts the original key from a timestamp key
  static String _getOriginalKey(String timestampKey) {
    return timestampKey.substring(_cacheTimestampPrefix.length);
  }
}
