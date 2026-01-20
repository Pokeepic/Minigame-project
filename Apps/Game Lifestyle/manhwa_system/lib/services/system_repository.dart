import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_bundle.dart';
import '../models/system_log.dart';
import '../models/mastery.dart';

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

  // Player stats
  int getLevel() => _prefs.getInt(_keyLevel) ?? 1;
  Future<void> setLevel(int value) => _prefs.setInt(_keyLevel, value);

  int getXp() => _prefs.getInt(_keyXp) ?? 0;
  Future<void> setXp(int value) => _prefs.setInt(_keyXp, value);

  int getXpToNext() => _prefs.getInt(_keyXpToNext) ?? 100;
  Future<void> setXpToNext(int value) => _prefs.setInt(_keyXpToNext, value);

  int getCoins() => _prefs.getInt(_keyCoins) ?? 0;
  Future<void> setCoins(int value) => _prefs.setInt(_keyCoins, value);

  // Daily quest bundle
  DailyQuestBundle? getDailyBundle() {
    final json = _prefs.getString(_keyDailyBundleJson);
    if (json == null) return null;
    try {
      return DailyQuestBundle.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  Future<void> setDailyBundle(DailyQuestBundle bundle) {
    return _prefs.setString(_keyDailyBundleJson, jsonEncode(bundle.toJson()));
  }

  // Upgrades
  int getXpBoostLevel() => _prefs.getInt(_keyXpBoostLevel) ?? 0;
  Future<void> setXpBoostLevel(int value) =>
      _prefs.setInt(_keyXpBoostLevel, value);

  int getCoinBoostLevel() => _prefs.getInt(_keyCoinBoostLevel) ?? 0;
  Future<void> setCoinBoostLevel(int value) =>
      _prefs.setInt(_keyCoinBoostLevel, value);

  // Streak
  int getStreak() => _prefs.getInt(_keyStreak) ?? 0;
  Future<void> setStreak(int value) => _prefs.setInt(_keyStreak, value);

  int getBestStreak() => _prefs.getInt(_keyBestStreak) ?? 0;
  Future<void> setBestStreak(int value) => _prefs.setInt(_keyBestStreak, value);

  String? getLastClearedDateKey() => _prefs.getString(_keyLastClearedDateKey);
  Future<void> setLastClearedDateKey(String value) =>
      _prefs.setString(_keyLastClearedDateKey, value);

  // Milestones
  int getMilestoneClaimedUpTo() => _prefs.getInt(_keyMilestoneClaimedUpTo) ?? 0;
  Future<void> setMilestoneClaimedUpTo(int value) =>
      _prefs.setInt(_keyMilestoneClaimedUpTo, value);

  // Alerts
  String? getLastAlertDateKey() => _prefs.getString(_keyLastAlertDateKey);
  Future<void> setLastAlertDateKey(String value) =>
      _prefs.setString(_keyLastAlertDateKey, value);

  // Logs
  List<SystemLogEntry> getLogs() {
    final json = _prefs.getString(_keySystemLogJson);
    if (json == null) return [];
    try {
      final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      return list.map((e) => SystemLogEntry.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setLogs(List<SystemLogEntry> logs) {
    final json = jsonEncode(logs.map((e) => e.toJson()).toList());
    return _prefs.setString(_keySystemLogJson, json);
  }

  // Titles
  String? getEquippedTitleId() => _prefs.getString(_keyEquippedTitleId);
  Future<void> setEquippedTitleId(String? value) {
    if (value == null) {
      return _prefs.remove(_keyEquippedTitleId);
    }
    return _prefs.setString(_keyEquippedTitleId, value);
  }

  Map<String, bool> getUnlockedTitles() {
    final json = _prefs.getString(_keyUnlockedTitlesJson);
    if (json == null) return {};
    try {
      return (jsonDecode(json) as Map).cast<String, bool>();
    } catch (_) {
      return {};
    }
  }

  Future<void> setUnlockedTitles(Map<String, bool> titles) {
    return _prefs.setString(_keyUnlockedTitlesJson, jsonEncode(titles));
  }

  int getTotalClears() => _prefs.getInt(_keyTotalClears) ?? 0;
  Future<void> setTotalClears(int value) =>
      _prefs.setInt(_keyTotalClears, value);

  // Day tracking
  String? getSpentUpgradeDayKey() => _prefs.getString(_keySpentUpgradeDayKey);
  Future<void> setSpentUpgradeDayKey(String value) =>
      _prefs.setString(_keySpentUpgradeDayKey, value);

  String? getClaimedBonusDayKey() => _prefs.getString(_keyClaimedBonusDayKey);
  Future<void> setClaimedBonusDayKey(String value) =>
      _prefs.setString(_keyClaimedBonusDayKey, value);

  // Title mastery
  Map<String, TitleMasteryState> getTitleMastery() {
    final json = _prefs.getString(_keyTitleMasteryJson);
    if (json == null) return {};
    try {
      final map = (jsonDecode(json) as Map).cast<String, dynamic>();
      return map.map((k, v) => MapEntry(k, TitleMasteryState.fromJson(v)));
    } catch (_) {
      return {};
    }
  }

  Future<void> setTitleMastery(Map<String, TitleMasteryState> mastery) {
    final json = jsonEncode(mastery.map((k, v) => MapEntry(k, v.toJson())));
    return _prefs.setString(_keyTitleMasteryJson, json);
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAll() => _prefs.clear();
}
