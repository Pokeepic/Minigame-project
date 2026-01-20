import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_bundle.dart';
import '../models/system_log.dart';
import '../models/mastery.dart';
import '../models/profile.dart';
import '../utils/constants.dart';

/// Centralized storage repository using SharedPreferences
/// All storage access should go through this class
class SystemRepository {
  static const String _keyLevel = 'level';
  static const String _keyXp = 'xp';
  static const String _keyXpToNext = 'xpToNext';
  static const String _keyCoins = 'coins';
  static const String _keyDailyBundleJson = 'dailyBundleJson';
  static const String _keyXpBoostLevel = 'xpBoostLevel';
  static const String _keyCoinBoostLevel = 'coinBoostLevel';
  static const String _keyStreak = 'streak';
  static const String _keyBestStreak = 'bestStreak';
  static const String _keyLastClearedDateKey = 'lastClearedDateKey';
  static const String _keyMilestoneClaimedUpTo = 'milestoneClaimedUpTo';
  static const String _keyLastAlertDateKey = 'lastAlertDateKey';
  static const String _keySystemLogJson = 'systemLogJson';
  static const String _keyEquippedTitleId = 'equippedTitleId';
  static const String _keyUnlockedTitlesJson = 'unlockedTitlesJson';
  static const String _keyTotalClears = 'totalClears';
  static const String _keySpentUpgradeDayKey = 'spentUpgradeDayKey';
  static const String _keyClaimedBonusDayKey = 'claimedBonusDayKey';
  static const String _keyTitleMasteryJson = 'titleMasteryJson';

  final SharedPreferences _prefs;

  SystemRepository(this._prefs);

  /// Create repository instance
  static Future<SystemRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SystemRepository(prefs);
  }

  // ---------------------------
  // Profiles (GLOBAL)
  // ---------------------------
  List<UserProfile> getProfiles() {
    final raw = _prefs.getString(kProfilesKey);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(UserProfile.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setProfiles(List<UserProfile> profiles) async {
    final raw = jsonEncode(profiles.map((p) => p.toJson()).toList());
    await _prefs.setString(kProfilesKey, raw);
  }

  String? getActiveProfileId() => _prefs.getString(kActiveProfileIdKey);
  Future<void> setActiveProfileId(String id) =>
      _prefs.setString(kActiveProfileIdKey, id);

  // ---------------------------
  // Namespacing helper
  // ---------------------------
  String _k(String profileId, String key) => 'p:$profileId:$key';

  // ---------------------------
  // Per-profile key registry
  // ---------------------------
  static const String _keyRegistry = '__keys';

  String _registryKey(String profileId) => _k(profileId, _keyRegistry);

  Set<String> _getRegisteredKeys(String pid) {
    final raw = _prefs.getString(_registryKey(pid));
    if (raw == null) return {};
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _registerKey(String pid, String fullKey) async {
    final keys = _getRegisteredKeys(pid);
    if (keys.add(fullKey)) {
      await _prefs.setString(_registryKey(pid), jsonEncode(keys.toList()));
    }
  }

  Future<void> _unregisterKey(String pid, String fullKey) async {
    final keys = _getRegisteredKeys(pid);
    if (keys.remove(fullKey)) {
      await _prefs.setString(_registryKey(pid), jsonEncode(keys.toList()));
    }
  }

  // ---------------------------
  // Internal wrappers
  // ---------------------------
  Future<void> _setInt(String pid, String key, int value) async {
    final full = _k(pid, key);
    await _prefs.setInt(full, value);
    await _registerKey(pid, full);
  }

  Future<void> _setString(String pid, String key, String value) async {
    final full = _k(pid, key);
    await _prefs.setString(full, value);
    await _registerKey(pid, full);
  }

  Future<void> _remove(String pid, String key) async {
    final full = _k(pid, key);
    await _prefs.remove(full);
    await _unregisterKey(pid, full);
  }

  // Player stats (profile-specific)
  int getLevel(String pid) => _prefs.getInt(_k(pid, _keyLevel)) ?? 1;
  Future<void> setLevel(String pid, int value) =>
      _setInt(pid, _keyLevel, value);

  int getXp(String pid) => _prefs.getInt(_k(pid, _keyXp)) ?? 0;
  Future<void> setXp(String pid, int value) =>
      _setInt(pid, _keyXp, value);

  int getXpToNext(String pid) => _prefs.getInt(_k(pid, _keyXpToNext)) ?? 100;
  Future<void> setXpToNext(String pid, int value) =>
      _setInt(pid, _keyXpToNext, value);

  int getCoins(String pid) => _prefs.getInt(_k(pid, _keyCoins)) ?? 0;
  Future<void> setCoins(String pid, int value) =>
      _setInt(pid, _keyCoins, value);

  // Daily quest bundle (profile-specific)
  DailyQuestBundle? getDailyBundle(String pid) {
    final json = _prefs.getString(_k(pid, _keyDailyBundleJson));
    if (json == null) return null;
    try {
      return DailyQuestBundle.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  Future<void> setDailyBundle(String pid, DailyQuestBundle bundle) {
    return _setString(pid, _keyDailyBundleJson, jsonEncode(bundle.toJson()));
  }

  // Upgrades (profile-specific)
  int getXpBoostLevel(String pid) =>
      _prefs.getInt(_k(pid, _keyXpBoostLevel)) ?? 0;
  Future<void> setXpBoostLevel(String pid, int value) =>
      _setInt(pid, _keyXpBoostLevel, value);

  int getCoinBoostLevel(String pid) =>
      _prefs.getInt(_k(pid, _keyCoinBoostLevel)) ?? 0;
  Future<void> setCoinBoostLevel(String pid, int value) =>
      _setInt(pid, _keyCoinBoostLevel, value);

  // Streak (profile-specific)
  int getStreak(String pid) => _prefs.getInt(_k(pid, _keyStreak)) ?? 0;
  Future<void> setStreak(String pid, int value) =>
      _setInt(pid, _keyStreak, value);

  int getBestStreak(String pid) =>
      _prefs.getInt(_k(pid, _keyBestStreak)) ?? 0;
  Future<void> setBestStreak(String pid, int value) =>
      _setInt(pid, _keyBestStreak, value);

  String? getLastClearedDateKey(String pid) =>
      _prefs.getString(_k(pid, _keyLastClearedDateKey));
  Future<void> setLastClearedDateKey(String pid, String value) =>
      _setString(pid, _keyLastClearedDateKey, value);

  // Milestones (profile-specific)
  int getMilestoneClaimedUpTo(String pid) =>
      _prefs.getInt(_k(pid, _keyMilestoneClaimedUpTo)) ?? 0;
  Future<void> setMilestoneClaimedUpTo(String pid, int value) =>
      _setInt(pid, _keyMilestoneClaimedUpTo, value);

  // Alerts (profile-specific)
  String? getLastAlertDateKey(String pid) =>
      _prefs.getString(_k(pid, _keyLastAlertDateKey));
  Future<void> setLastAlertDateKey(String pid, String value) =>
      _setString(pid, _keyLastAlertDateKey, value);

  // Logs (profile-specific)
  List<SystemLogEntry> getLogs(String pid) {
    final json = _prefs.getString(_k(pid, _keySystemLogJson));
    if (json == null) return [];
    try {
      final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      return list.map((e) => SystemLogEntry.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setLogs(String pid, List<SystemLogEntry> logs) {
    final json = jsonEncode(logs.map((e) => e.toJson()).toList());
    return _setString(pid, _keySystemLogJson, json);
  }

  // Titles (profile-specific)
  String? getEquippedTitleId(String pid) =>
      _prefs.getString(_k(pid, _keyEquippedTitleId));
  Future<void> setEquippedTitleId(String pid, String? value) {
    if (value == null) {
      return _remove(pid, _keyEquippedTitleId);
    }
    return _setString(pid, _keyEquippedTitleId, value);
  }

  Map<String, bool> getUnlockedTitles(String pid) {
    final json = _prefs.getString(_k(pid, _keyUnlockedTitlesJson));
    if (json == null) return {};
    try {
      return (jsonDecode(json) as Map).cast<String, bool>();
    } catch (_) {
      return {};
    }
  }

  Future<void> setUnlockedTitles(String pid, Map<String, bool> titles) {
    return _setString(pid, _keyUnlockedTitlesJson, jsonEncode(titles));
  }

  int getTotalClears(String pid) =>
      _prefs.getInt(_k(pid, _keyTotalClears)) ?? 0;
  Future<void> setTotalClears(String pid, int value) =>
      _setInt(pid, _keyTotalClears, value);

  // Day tracking (profile-specific)
  String? getSpentUpgradeDayKey(String pid) =>
      _prefs.getString(_k(pid, _keySpentUpgradeDayKey));
  Future<void> setSpentUpgradeDayKey(String pid, String value) =>
      _setString(pid, _keySpentUpgradeDayKey, value);

  String? getClaimedBonusDayKey(String pid) =>
      _prefs.getString(_k(pid, _keyClaimedBonusDayKey));
  Future<void> setClaimedBonusDayKey(String pid, String value) =>
      _setString(pid, _keyClaimedBonusDayKey, value);

  // Title mastery (profile-specific)
  Map<String, TitleMasteryState> getTitleMastery(String pid) {
    final json = _prefs.getString(_k(pid, _keyTitleMasteryJson));
    if (json == null) return {};
    try {
      final map = (jsonDecode(json) as Map).cast<String, dynamic>();
      return map.map((k, v) => MapEntry(k, TitleMasteryState.fromJson(v)));
    } catch (_) {
      return {};
    }
  }

  Future<void> setTitleMastery(String pid, Map<String, TitleMasteryState> mastery) {
    final json = jsonEncode(mastery.map((k, v) => MapEntry(k, v.toJson())));
    return _setString(pid, _keyTitleMasteryJson, json);
  }

  /// Delete all data for a specific profile
  Future<void> deleteProfileData(String pid) async {
    final keys = _getRegisteredKeys(pid);

    // Remove every stored key for this profile
    for (final k in keys) {
      await _prefs.remove(k);
    }

    // Remove registry itself
    await _prefs.remove(_registryKey(pid));
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAll() => _prefs.clear();
}
