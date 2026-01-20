import 'dart:math';
import '../models/title.dart';
import '../models/daily_bundle.dart';
import '../models/system_log.dart';
import '../models/mastery.dart';
import '../data/quest_pool.dart';
import '../data/title_pool.dart';
import '../services/system_repository.dart';
import '../services/system_events.dart';
import '../utils/constants.dart';
import '../utils/date_keys.dart';

/// System Controller - Handles all game logic
/// Decoupled from UI, can be tested independently
class SystemController implements SystemState {
  final SystemRepository _repo;

  // Callbacks for UI updates
  Function()? onStateChanged;
  Function(String message)? onSystemMessage;

  // Player State
  @override
  int level = 1;
  int xp = 0;
  int xpToNext = kLevelXpBase;
  @override
  int coins = 0;

  int xpBoostLevel = 0;
  int coinBoostLevel = 0;

  @override
  int streak = 0;
  int bestStreak = 0;
  String? lastClearedDateKey;

  int milestoneClaimedUpTo = 0;
  String? lastAlertDateKey;

  // Daily Quest State
  DailyQuestBundle? dailyBundle;

  List<SystemLogEntry> systemLog = [];

  // Title System
  String equippedTitleId = 'rookie';
  @override
  Set<String> unlockedTitleIds = {'rookie'};
  @override
  Map<String, bool> get unlockedTitles => {
    for (var id in unlockedTitleIds) id: true,
  };
  Map<String, TitleMasteryState> titleMastery = {};

  @override
  int totalClears = 0;

  // Hidden title flags
  String? spentUpgradeDayKey;
  String? claimedBonusDayKey;

  SystemController(this._repo);

  /// Initialize the system - load or create state
  Future<void> initialize() async {
    await _loadSystemLog();
    final tKey = todayKey;

    // Load player state
    level = _repo.getLevel();
    xp = _repo.getXp();
    xpToNext = _repo.getXpToNext();
    coins = _repo.getCoins();

    xpBoostLevel = _repo.getXpBoostLevel();
    coinBoostLevel = _repo.getCoinBoostLevel();

    streak = _repo.getStreak();
    bestStreak = _repo.getBestStreak();
    lastClearedDateKey = _repo.getLastClearedDateKey();

    milestoneClaimedUpTo = _repo.getMilestoneClaimedUpTo();
    lastAlertDateKey = _repo.getLastAlertDateKey();

    // Load title system
    equippedTitleId = _repo.getEquippedTitleId() ?? 'rookie';
    totalClears = _repo.getTotalClears();

    final unlockedMap = _repo.getUnlockedTitles();
    unlockedTitleIds = unlockedMap.keys.toSet();
    unlockedTitleIds.add('rookie'); // Ensure rookie always unlocked

    // Load hidden title flags
    spentUpgradeDayKey = _repo.getSpentUpgradeDayKey();
    claimedBonusDayKey = _repo.getClaimedBonusDayKey();

    // Load mastery
    titleMastery = _repo.getTitleMastery();

    // Ensure every title has a mastery state
    for (final t in titlePool) {
      titleMastery.putIfAbsent(t.id, () => TitleMasteryState.fresh());
    }

    // Evaluate unlocks on load
    await _evaluateTitleUnlocks();

    // Load daily bundle
    dailyBundle = _repo.getDailyBundle();

    // Ensure today's bundle exists
    if (dailyBundle == null || dailyBundle!.dateKey != tKey) {
      dailyBundle = _generateDailyBundleFor(tKey);
      await _repo.setDailyBundle(dailyBundle!);
    }

    _notifyStateChanged();
  }

  Future<void> _loadSystemLog() async {
    systemLog = _repo.getLogs();
  }

  Future<void> _saveSystemLog() async {
    // Keep only max logs
    final logsToSave = systemLog.take(kMaxLogs).toList();
    await _repo.setLogs(logsToSave);
  }

  Future<void> _addLog(
    LogType type,
    String message, {
    Map<String, dynamic>? data,
  }) async {
    final entry = SystemLogEntry(
      ts: DateTime.now().millisecondsSinceEpoch,
      type: type,
      message: message,
      data: data,
    );

    systemLog.insert(0, entry);
    if (systemLog.length > kMaxLogs) {
      systemLog = systemLog.take(kMaxLogs).toList();
    }

    await _saveSystemLog();
    _notifyStateChanged();
  }

  DailyQuestBundle _generateDailyBundleFor(String dateKey) {
    // Deterministic daily set
    final rng = Random(dateKey.hashCode);

    // Pick 3 UNIQUE quests
    final ids = <String>{};
    while (ids.length < kDailyQuestCount) {
      ids.add(questPool[rng.nextInt(questPool.length)].id);
    }

    return DailyQuestBundle(
      dateKey: dateKey,
      templateIds: ids.toList(),
      completed: [false, false, false],
      bonusClaimed: false,
    );
  }

  Future<void> _saveAll() async {
    await _repo.setLevel(level);
    await _repo.setXp(xp);
    await _repo.setXpToNext(xpToNext);
    await _repo.setCoins(coins);
    await _repo.setXpBoostLevel(xpBoostLevel);
    await _repo.setCoinBoostLevel(coinBoostLevel);
    await _repo.setStreak(streak);
    await _repo.setBestStreak(bestStreak);
    if (lastClearedDateKey != null) {
      await _repo.setLastClearedDateKey(lastClearedDateKey!);
    }
    await _repo.setMilestoneClaimedUpTo(milestoneClaimedUpTo);
    if (lastAlertDateKey != null) {
      await _repo.setLastAlertDateKey(lastAlertDateKey!);
    }

    // Save title system
    await _repo.setEquippedTitleId(equippedTitleId);
    await _repo.setUnlockedTitles(unlockedTitles);
    await _repo.setTotalClears(totalClears);
    await _repo.setTitleMastery(titleMastery);

    if (dailyBundle != null) {
      await _repo.setDailyBundle(dailyBundle!);
    }
  }

  // Computed properties
  TitleBadge get equippedTitle => titlePool.firstWhere(
    (t) => t.id == equippedTitleId,
    orElse: () => titlePool.first,
  );

  TitleMasteryState get equippedMastery =>
      titleMastery[equippedTitleId] ?? TitleMasteryState.fresh();

  double _scale(double base, int masteryLevel) {
    // Each mastery level adds +6% of the base buff
    final factor = 1.0 + ((masteryLevel - 1) * 0.06);
    return base * factor;
  }

  int _scaleInt(int base, int masteryLevel) =>
      (_scale(base.toDouble(), masteryLevel)).round();

  // Multipliers - centralized calculation
  double get xpMult => 1.0 + (xpBoostLevel * kXpBoostPerLevel) + titleXpMult;
  double get coinMult =>
      1.0 + (coinBoostLevel * kCoinBoostPerLevel) + titleCoinMult;

  double get titleXpMult =>
      _scale(equippedTitle.buff.xpMult, equippedMastery.level);
  double get titleCoinMult =>
      _scale(equippedTitle.buff.coinMult, equippedMastery.level);
  int get titleBonusXpFlat =>
      _scaleInt(equippedTitle.buff.bonusXpFlat, equippedMastery.level);
  int get titleBonusCoinsFlat =>
      _scaleInt(equippedTitle.buff.bonusCoinsFlat, equippedMastery.level);

  /// Apply level ups - centralized logic
  Future<void> _applyLevelUps({bool log = false}) async {
    final levelsGained = <int>[];

    while (xp >= xpToNext && level < 999) {
      xp -= xpToNext;
      level += 1;
      xpToNext = kLevelXpBase + (level - 1) * kLevelXpStep;
      levelsGained.add(level);
    }

    if (log && levelsGained.isNotEmpty) {
      for (final lvl in levelsGained) {
        await _addLog(
          LogType.level,
          'Level Up — Reached Level $lvl',
          data: {'level': lvl},
        );
      }
    }
  }

  // SystemState interface implementation
  @override
  int get maxStreak => bestStreak;

  @override
  int get totalQuestsCompleted => totalClears * 3; // Approximate

  @override
  int get totalBonusesClaimed => totalClears;

  void _notifyStateChanged() {
    onStateChanged?.call();
  }

  void _showSystemMessage(String message) {
    onSystemMessage?.call(message);
  }

  /// Evaluate title unlocks
  Future<void> _evaluateTitleUnlocks() async {
    final newlyUnlocked = <TitleBadge>[];

    for (final t in titlePool) {
      if (!unlockedTitleIds.contains(t.id) && t.unlockIf(this)) {
        unlockedTitleIds.add(t.id);
        newlyUnlocked.add(t);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      // Auto-equip first new title if currently rookie
      if (equippedTitleId == 'rookie') {
        equippedTitleId = newlyUnlocked.first.id;
      }

      // Show + log each unlock
      for (final t in newlyUnlocked) {
        _showSystemMessage(
          'TITLE UNLOCKED — ${t.name} (${rarityLabel(t.rarity)})',
        );
        await _addLog(
          LogType.title,
          'Title Unlocked — ${t.name} (${rarityLabel(t.rarity)})',
          data: {
            'titleId': t.id,
            'title': t.name,
            'rarity': rarityLabel(t.rarity),
          },
        );

        if (t.rarity == TitleRarity.legendary) {
          _showSystemMessage('LEGENDARY TITLE — ${t.name} ⚡');
        }
      }

      await _saveAll();
    }
  }

  /// Gain title mastery XP
  Future<void> _gainTitleMasteryXp(
    int amount, {
    String reason = 'Action',
  }) async {
    final id = equippedTitleId;
    var ms = titleMastery[id] ?? TitleMasteryState.fresh();

    if (ms.level >= kMaxMasteryLevel) return;

    int xpAdd = amount;
    int newLevel = ms.level;
    int newXp = ms.xp;

    while (xpAdd > 0 && newLevel < kMaxMasteryLevel) {
      final need = ms.xpToNext - newXp;
      if (xpAdd >= need) {
        xpAdd -= need;
        newLevel += 1;
        newXp = 0;
        ms = ms.copyWith(
          level: newLevel,
          xp: newXp,
          xpToNext: masteryXpToNext(newLevel),
        );

        // Level up event
        _showSystemMessage(
          'TITLE MASTERY UP — ${equippedTitle.name} Lv $newLevel',
        );
        await _addLog(
          LogType.title,
          'Title Mastery Up — ${equippedTitle.name} Lv $newLevel',
          data: {
            'titleId': id,
            'title': equippedTitle.name,
            'masteryLevel': newLevel,
            'reason': reason,
          },
        );
      } else {
        newXp += xpAdd;
        xpAdd = 0;
        ms = ms.copyWith(xp: newXp);
      }
    }

    titleMastery[id] = ms;
    await _saveAll();
    _notifyStateChanged();
  }

  /// Equip a title
  Future<void> equipTitle(String id) async {
    if (!unlockedTitleIds.contains(id)) return;

    equippedTitleId = id;
    _notifyStateChanged();

    final title = titlePool.firstWhere((t) => t.id == id);
    _showSystemMessage('TITLE EQUIPPED — ${title.name}');
    await _addLog(
      LogType.title,
      'Title Equipped — ${title.name}',
      data: {'titleId': id},
    );
    await _saveAll();
  }

  /// Complete a quest at index
  Future<void> completeQuest(int index) async {
    final b = dailyBundle;
    if (b == null) return;
    if (index < 0 || index >= b.templateIds.length) return;
    if (b.completed[index]) return;

    final t = templateById(b.templateIds[index]);

    final gainedXp = (t.baseXp * xpMult).round();
    final gainedCoins = (t.baseCoins * coinMult).round();

    // Update state
    final newCompleted = [...b.completed];
    newCompleted[index] = true;
    dailyBundle = b.copyWith(completed: newCompleted);

    xp += gainedXp;
    coins += gainedCoins;

    // Apply level ups with logging
    await _applyLevelUps(log: true);

    _showSystemMessage('Quest Completed • +$gainedXp XP • +$gainedCoins Coins');
    await _addLog(
      LogType.quest,
      'Quest Completed — ${t.title} (+$gainedXp XP, +$gainedCoins Coins)',
      data: {
        'xp': gainedXp,
        'coins': gainedCoins,
        'questId': t.id,
        'title': t.title,
      },
    );

    await _saveAll();
    _notifyStateChanged();

    await _gainTitleMasteryXp(12, reason: 'Quest Completed');
    await _evaluateTitleUnlocks();
  }

  /// Check if all quests are done
  bool get allQuestsDone {
    final b = dailyBundle;
    if (b == null) return false;
    return b.completed.every((x) => x);
  }

  /// Update streak on clear today
  void _updateStreakOnClearToday() {
    final tKey = todayKey;

    if (lastClearedDateKey == yesterdayKey) {
      // Continue streak
      streak += 1;
    } else if (lastClearedDateKey == tKey) {
      // Already cleared today (shouldn't happen)
      return;
    } else {
      // Broke streak or first day
      streak = 1;
    }

    lastClearedDateKey = tKey;

    if (streak > bestStreak) {
      bestStreak = streak;
    }
  }

  /// Apply streak milestone rewards if any
  String? _applyStreakMilestoneRewardsIfAny() {
    // Define milestones
    final milestones = [
      kStreakMilestone1,
      kStreakMilestone2,
      kStreakMilestone3,
    ];

    for (final m in milestones) {
      if (streak == m && milestoneClaimedUpTo < m) {
        milestoneClaimedUpTo = m;
        final rewardXp = m * 10;
        final rewardCoins = m * 5;
        xp += rewardXp;
        coins += rewardCoins;
        return 'MILESTONE REWARD ($m-Day Streak) — +$rewardXp XP, +$rewardCoins Coins';
      }
    }

    return null;
  }

  /// Claim all bonus
  Future<void> claimAllBonus() async {
    final b = dailyBundle;
    if (b == null) return;
    if (!allQuestsDone) return;
    if (b.bonusClaimed) return;

    // Bonus scales with difficulty sum
    final templates = b.templateIds.map(templateById).toList();
    final totalDifficulty = templates.fold<int>(
      0,
      (sum, t) => sum + t.difficulty,
    );

    // Base bonus
    final baseBonusXp = kBonusXpBase + totalDifficulty * 10;
    final baseBonusCoins = kBonusCoinsBase + totalDifficulty * 8;

    final bonusXp =
        (baseBonusXp * (1.0 + xpBoostLevel * kXpBoostPerLevel)).round() +
        titleBonusXpFlat;
    final bonusCoins =
        (baseBonusCoins * (1.0 + coinBoostLevel * kCoinBoostPerLevel)).round() +
        titleBonusCoinsFlat;

    // Update state
    dailyBundle = b.copyWith(bonusClaimed: true);
    xp += bonusXp;
    coins += bonusCoins;

    await _applyLevelUps(log: true);

    _updateStreakOnClearToday();
    totalClears += 1;

    // Streak logging
    if (streak == 1) {
      await _addLog(
        LogType.streak,
        'Streak Started — Day 1 🔥',
        data: {'streak': streak},
      );
    } else if (streak == 3 || streak == 7 || streak == 14 || streak == 30) {
      await _addLog(
        LogType.streak,
        'SYSTEM NOTICE — $streak-Day Streak Achieved 🔥',
        data: {'streak': streak},
      );
      _showSystemMessage('SYSTEM NOTICE — $streak-Day Streak Achieved 🔥');
    } else {
      await _addLog(
        LogType.streak,
        'Streak Maintained — Day $streak',
        data: {'streak': streak},
      );
    }

    final milestoneMsg = _applyStreakMilestoneRewardsIfAny();
    final fullMsg = milestoneMsg != null
        ? 'All Quests Cleared • BONUS +$bonusXp XP • +$bonusCoins Coins • STREAK $streak🔥 • $milestoneMsg'
        : 'All Quests Cleared • BONUS +$bonusXp XP • +$bonusCoins Coins • STREAK $streak🔥';

    _showSystemMessage(fullMsg);
    await _addLog(
      LogType.bonus,
      'All Quests Cleared — Bonus Claimed (+$bonusXp XP, +$bonusCoins Coins) • Streak $streak',
      data: {'xp': bonusXp, 'coins': bonusCoins, 'streak': streak},
    );

    if (milestoneMsg != null) {
      await _addLog(LogType.milestone, milestoneMsg, data: {'streak': streak});
      await _gainTitleMasteryXp(40, reason: 'Milestone Reward');
    }

    // Title bonus log
    if (titleBonusXpFlat > 0 || titleBonusCoinsFlat > 0) {
      await _addLog(
        LogType.title,
        'Title Bonus Applied — +$titleBonusXpFlat XP, +$titleBonusCoinsFlat Coins (${equippedTitle.name})',
        data: {
          'titleId': equippedTitle.id,
          'xp': titleBonusXpFlat,
          'coins': titleBonusCoinsFlat,
        },
      );
    }

    // Update tracking
    claimedBonusDayKey = todayKey;
    await _repo.setClaimedBonusDayKey(todayKey);

    await _saveAll();
    await _gainTitleMasteryXp(25, reason: 'Daily Clear');
    await _evaluateTitleUnlocks();
    _notifyStateChanged();
  }

  /// Buy XP boost upgrade
  Future<bool> buyXpBoost() async {
    final cost = kXpBoostCostBase * pow(kXpBoostCostMult, xpBoostLevel).toInt();
    if (coins < cost) return false;

    coins -= cost;
    xpBoostLevel += 1;

    spentUpgradeDayKey = todayKey;
    await _repo.setSpentUpgradeDayKey(todayKey);

    _showSystemMessage('XP Boost Upgraded to Level $xpBoostLevel');
    await _addLog(
      LogType.upgrade,
      'XP Boost Upgraded to Level $xpBoostLevel (-$cost Coins)',
      data: {'cost': cost, 'level': xpBoostLevel},
    );

    await _saveAll();
    await _evaluateTitleUnlocks();
    _notifyStateChanged();
    return true;
  }

  /// Buy Coin boost upgrade
  Future<bool> buyCoinBoost() async {
    final cost =
        kCoinBoostCostBase * pow(kCoinBoostCostMult, coinBoostLevel).toInt();
    if (coins < cost) return false;

    coins -= cost;
    coinBoostLevel += 1;

    spentUpgradeDayKey = todayKey;
    await _repo.setSpentUpgradeDayKey(todayKey);

    _showSystemMessage('Coin Boost Upgraded to Level $coinBoostLevel');
    await _addLog(
      LogType.upgrade,
      'Coin Boost Upgraded to Level $coinBoostLevel (-$cost Coins)',
      data: {'cost': cost, 'level': coinBoostLevel},
    );

    await _saveAll();
    await _evaluateTitleUnlocks();
    _notifyStateChanged();
    return true;
  }

  /// Calculate upgrade cost
  int xpBoostCost() =>
      kXpBoostCostBase * pow(kXpBoostCostMult, xpBoostLevel).toInt();
  int coinBoostCost() =>
      kCoinBoostCostBase * pow(kCoinBoostCostMult, coinBoostLevel).toInt();
}
