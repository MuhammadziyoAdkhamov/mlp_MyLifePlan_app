import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _legacyAppDataKey = 'mylife_plan_app_data_v1';
  static const String _guestAppDataKey = 'mylife_plan_app_data_v2_guest';
  static const String _userAppDataPrefix = 'mylife_plan_app_data_v2_user_';

  String _keyFor(String? userId) =>
      userId == null ? _guestAppDataKey : '$_userAppDataPrefix$userId';

  String _appearanceKeyFor(String? userId) => '${_keyFor(userId)}_appearance';

  Future<Map<String, dynamic>?> loadAppearance({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_appearanceKeyFor(userId));
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveAppearance(
    Map<String, dynamic> appearance, {
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appearanceKeyFor(userId), jsonEncode(appearance));
  }

  Future<Map<String, dynamic>?> loadAppData({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(userId));
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveAppData(Map<String, dynamic> data, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(userId), jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadLegacyAppData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyAppDataKey);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<bool> migrateLegacyAppData({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyAppDataKey);
    if (raw == null || raw.isEmpty) return false;

    final legacyData = jsonDecode(raw) as Map<String, dynamic>;
    final profile = legacyData['profile'];
    final profileId = profile is Map ? profile['id'] as String? : null;
    final profileEmail = profile is Map ? profile['email'] as String? : null;
    final legacyIsGuest =
        profileId == 'user_demo' ||
        profileId == 'guest_local' ||
        profileEmail == 'guest@mylife.local';
    final belongsToScope = userId == null ? legacyIsGuest : profileId == userId;
    if (!belongsToScope) return false;

    final scopedKey = _keyFor(userId);
    if (prefs.containsKey(scopedKey)) return false;

    await prefs.setString(scopedKey, raw);
    await prefs.remove(_legacyAppDataKey);
    return true;
  }

  Future<void> clear({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(userId));
    await prefs.remove(_appearanceKeyFor(userId));
  }
}
