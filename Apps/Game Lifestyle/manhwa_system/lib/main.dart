import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SystemApp());
}

class SystemApp extends StatelessWidget {
  const SystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manhwa System',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3EF2D4),
        ),
      ),
      home: const SystemHomePage(),
    );
  }
}

/// ---------- Data Models ----------
class QuestTemplate {
  final String id;
  final String title;
  final String description;
  final int baseXp;
  final int baseCoins;
  final int difficulty; // 1..5

  const QuestTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.baseXp,
    required this.baseCoins,
    required this.difficulty,
  });
}

class DailyQuestBundle {
  final String dateKey; // yyyy-mm-dd
  final List<String> templateIds; // length 3
  final List<bool> completed; // length 3
  final bool bonusClaimed;

  const DailyQuestBundle({
    required this.dateKey,
    required this.templateIds,
    required this.completed,
    required this.bonusClaimed,
  });

  DailyQuestBundle copyWith({
    List<bool>? completed,
    bool? bonusClaimed,
  }) =>
      DailyQuestBundle(
        dateKey: dateKey,
        templateIds: templateIds,
        completed: completed ?? this.completed,
        bonusClaimed: bonusClaimed ?? this.bonusClaimed,
      );

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'templateIds': templateIds,
        'completed': completed,
        'bonusClaimed': bonusClaimed,
      };

  static DailyQuestBundle fromJson(Map<String, dynamic> json) => DailyQuestBundle(
        dateKey: json['dateKey'] as String,
        templateIds: (json['templateIds'] as List).cast<String>(),
        completed: (json['completed'] as List).cast<bool>(),
        bonusClaimed: (json['bonusClaimed'] as bool?) ?? false,
      );
}

/// ---------- Quest Pool (edit these anytime) ----------
const List<QuestTemplate> questPool = [
  QuestTemplate(
    id: 'study_10',
    title: 'Focus Mode',
    description: 'Do 10 minutes of focused study.',
    baseXp: 30,
    baseCoins: 20,
    difficulty: 1,
  ),
  QuestTemplate(
    id: 'walk_15',
    title: 'Body Maintenance',
    description: 'Walk for 15 minutes.',
    baseXp: 35,
    baseCoins: 22,
    difficulty: 2,
  ),
  QuestTemplate(
    id: 'pushups_20',
    title: 'Strength Trial',
    description: 'Do 20 push-ups (any form).',
    baseXp: 45,
    baseCoins: 28,
    difficulty: 3,
  ),
  QuestTemplate(
    id: 'read_15',
    title: 'Knowledge Absorption',
    description: 'Read 15 minutes of a book/article.',
    baseXp: 35,
    baseCoins: 22,
    difficulty: 2,
  ),
  QuestTemplate(
    id: 'clean_10',
    title: 'Domain Control',
    description: 'Clean your desk/room for 10 minutes.',
    baseXp: 40,
    baseCoins: 25,
    difficulty: 2,
  ),
  QuestTemplate(
    id: 'deepwork_25',
    title: 'Deep Work Trial',
    description: 'Do 25 minutes of deep work (no distractions).',
    baseXp: 60,
    baseCoins: 35,
    difficulty: 4,
  ),
];

String rankLabel(int difficulty) {
  switch (difficulty) {
    case 1: return 'D';
    case 2: return 'C';
    case 3: return 'B';
    case 4: return 'A';
    default: return 'S';
  }
}

QuestTemplate templateById(String id) =>
    questPool.firstWhere((q) => q.id == id, orElse: () => questPool.first);

String todayKey() {
  final now = DateTime.now();
  // local date, stable key
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

String dateKeyFrom(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

String yesterdayKey() => dateKeyFrom(DateTime.now().subtract(const Duration(days: 1)));

/// ---------- Storage ----------
class StorageKeys {
  static const level = 'level';
  static const xp = 'xp';
  static const xpToNext = 'xpToNext';
  static const coins = 'coins';

  static const dailyBundleJson = 'dailyBundleJson';

  static const xpBoostLevel = 'xpBoostLevel';
  static const coinBoostLevel = 'coinBoostLevel';

  static const streak = 'streak';
  static const bestStreak = 'bestStreak';
  static const lastClearedDateKey = 'lastClearedDateKey';

  static const milestoneClaimedUpTo = 'milestoneClaimedUpTo';

class SystemHomePage extends StatefulWidget {
  const SystemHomePage({super.key});

  @override
  State<SystemHomePage> createState() => _SystemHomePageState();
}

class _SystemHomePageState extends State<SystemHomePage> {
  // Player State
  int level = 1;
  int xp = 0;
  int xpToNext = 100;
  int coins = 0;

  int xpBoostLevel = 0;   // each level = +5% XP
  int coinBoostLevel = 0; // each level = +5% coins

  int streak = 0;
  int bestStreak = 0;
  String? lastClearedDateKey;

  int milestoneClaimedUpTo = 0;

  String? systemMsg;
  bool systemMsgVisible = false;

  // Daily Quest State
  DailyQuestBundle? dailyBundle;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrCreate();
  }

  Future<void> _loadOrCreate() async {
    final prefs = await SharedPreferences.getInstance();

    // Load player state
    level = prefs.getInt(StorageKeys.level) ?? 1;
    xp = prefs.getInt(StorageKeys.xp) ?? 25;
    xpToNext = prefs.getInt(StorageKeys.xpToNext) ?? (100 + (level - 1) * 25);
    coins = prefs.getInt(StorageKeys.coins) ?? 120;

    xpBoostLevel = prefs.getInt(StorageKeys.xpBoostLevel) ?? 0;
    coinBoostLevel = prefs.getInt(StorageKeys.coinBoostLevel) ?? 0;

    streak = prefs.getInt(StorageKeys.streak) ?? 0;
    bestStreak = prefs.getInt(StorageKeys.bestStreak) ?? 0;
    lastClearedDateKey = prefs.getString(StorageKeys.lastClearedDateKey);

    milestoneClaimedUpTo = prefs.getInt(StorageKeys.milestoneClaimedUpTo) ?? 0;

    // Load daily bundle
    final jsonStr = prefs.getString(StorageKeys.dailyBundleJson);
    if (jsonStr != null) {
      try {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        dailyBundle = DailyQuestBundle.fromJson(map);
      } catch (_) {
        dailyBundle = null;
      }
    }

    // Ensure today's bundle exists
    final tKey = todayKey();
    if (dailyBundle == null || dailyBundle!.dateKey != tKey) {
      dailyBundle = _generateDailyBundleFor(tKey);
      await _saveDailyBundle(prefs);
    }

    setState(() => loading = false);
  }

  DailyQuestBundle _generateDailyBundleFor(String dateKey) {
    // deterministic daily set
    final rng = Random(dateKey.hashCode);

    // We pick 3 UNIQUE quests
    final ids = <String>{};
    while (ids.length < 3) {
      ids.add(questPool[rng.nextInt(questPool.length)].id);
    }

    return DailyQuestBundle(
      dateKey: dateKey,
      templateIds: ids.toList(),
      completed: [false, false, false],
      bonusClaimed: false,
    );
  }

  Future<void> _saveDailyBundle(SharedPreferences prefs) async {
    if (dailyBundle == null) return;
    await prefs.setString(
      StorageKeys.dailyBundleJson,
      json.encode(dailyBundle!.toJson()),
    );
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.level, level);
    await prefs.setInt(StorageKeys.xp, xp);
    await prefs.setInt(StorageKeys.xpToNext, xpToNext);
    await prefs.setInt(StorageKeys.coins, coins);
    await prefs.setInt(StorageKeys.xpBoostLevel, xpBoostLevel);
    await prefs.setInt(StorageKeys.coinBoostLevel, coinBoostLevel);
    await prefs.setInt(StorageKeys.streak, streak);
    await prefs.setInt(StorageKeys.bestStreak, bestStreak);
    if (lastClearedDateKey != null) {
      await prefs.setString(StorageKeys.lastClearedDateKey, lastClearedDateKey!);
    }
    await prefs.setInt(StorageKeys.milestoneClaimedUpTo, milestoneClaimedUpTo);
    await _saveDailyBundle(prefs);
  }

  void _completeQuestAt(int index) async {
    final b = dailyBundle;
    if (b == null) return;
    if (index < 0 || index >= b.templateIds.length) return;
    if (b.completed[index]) return;

    final t = templateById(b.templateIds[index]);

    final xpMultiplier = 1.0 + (xpBoostLevel * 0.05);
    final coinMultiplier = 1.0 + (coinBoostLevel * 0.05);

    final gainedXp = (t.baseXp * xpMultiplier).round();
    final gainedCoins = (t.baseCoins * coinMultiplier).round();

    setState(() {
      final newCompleted = [...b.completed];
      newCompleted[index] = true;
      dailyBundle = b.copyWith(completed: newCompleted);

      xp += gainedXp;
      coins += gainedCoins;

      // Level up loop (handles big XP)
      while (xp >= xpToNext) {
        xp -= xpToNext;
        level += 1;
        xpToNext = 100 + (level - 1) * 25;
      }
    });

    showSystemMessage('Quest Completed • +$gainedXp XP • +$gainedCoins Coins');
    await _saveAll();
  }

  bool get _allDone {
    final b = dailyBundle;
    if (b == null) return false;
    return b.completed.every((x) => x);
  }

  void _claimAllBonus() async {
    final b = dailyBundle;
    if (b == null) return;
    if (!_allDone) return;
    if (b.bonusClaimed) return;

    // Bonus scales with difficulty sum (feels like a system)
    final templates = b.templateIds.map(templateById).toList();
    final totalDifficulty = templates.fold<int>(0, (sum, t) => sum + t.difficulty);

    // Base bonus
    final baseBonusXp = 20 + totalDifficulty * 10;     // example: 50..?
    final baseBonusCoins = 15 + totalDifficulty * 8;

    final xpMultiplier = 1.0 + (xpBoostLevel * 0.05);
    final coinMultiplier = 1.0 + (coinBoostLevel * 0.05);

    final bonusXp = (baseBonusXp * xpMultiplier).round();
    final bonusCoins = (baseBonusCoins * coinMultiplier).round();

    setState(() {
      dailyBundle = b.copyWith(bonusClaimed: true);

      xp += bonusXp;
      coins += bonusCoins;

      while (xp >= xpToNext) {
        xp -= xpToNext;
        level += 1;
        xpToNext = 100 + (level - 1) * 25;
      }
    });

    _updateStreakOnClearToday();

    final milestoneMsg = _applyStreakMilestoneRewardsIfAny();
    final fullMsg = milestoneMsg != null
        ? 'All Quests Cleared • BONUS +$bonusXp XP • +$bonusCoins Coins • STREAK $streak🔥 • $milestoneMsg'
        : 'All Quests Cleared • BONUS +$bonusXp XP • +$bonusCoins Coins • STREAK $streak🔥';

    showSystemMessage(fullMsg);
    await _saveAll();
  }

  void _updateStreakOnClearToday() {
    final today = todayKey();
    final yKey = yesterdayKey();

    // If already counted today, do nothing
    if (lastClearedDateKey == today) return;

    if (lastClearedDateKey == yKey) {
      streak += 1;
    } else {
      streak = 1;
    }

    lastClearedDateKey = today;
    if (streak > bestStreak) bestStreak = streak;
  }

  String? _applyStreakMilestoneRewardsIfAny() {
    const milestones = [7, 14, 30, 50, 100];
    if (!milestones.contains(streak)) return null;
    if (streak <= milestoneClaimedUpTo) return null;

    // Rewards scale with milestone
    final index = milestones.indexOf(streak);
    final baseXp = 50 + index * 50; // 50, 100, 150, 200, 250
    final baseCoins = 25 + index * 25; // 25, 50, 75, 100, 125

    final xpMultiplier = 1.0 + (xpBoostLevel * 0.05);
    final coinMultiplier = 1.0 + (coinBoostLevel * 0.05);

    final rewardXp = (baseXp * xpMultiplier).round();
    final rewardCoins = (baseCoins * coinMultiplier).round();

    setState(() {
      xp += rewardXp;
      coins += rewardCoins;

      while (xp >= xpToNext) {
        xp -= xpToNext;
        level += 1;
        xpToNext = 100 + (level - 1) * 25;
      }

      milestoneClaimedUpTo = streak;
    });

    return 'MILESTONE REACHED! +$rewardXp XP +$rewardCoins Coins';
  }

  // Developer tool button for testing daily reset
  void _forceNewDailyQuest() async {
    final prefs = await SharedPreferences.getInstance();
    final fakeDate = DateTime.now().subtract(const Duration(days: 1));
    final key =
        '${fakeDate.year.toString().padLeft(4, '0')}-${fakeDate.month.toString().padLeft(2, '0')}-${fakeDate.day.toString().padLeft(2, '0')}';
    dailyBundle = _generateDailyBundleFor(key);
    await _saveDailyBundle(prefs);
    await _loadOrCreate();
  }

  int get xpBoostCost => 50 + (xpBoostLevel * 40);
  int get coinBoostCost => 50 + (coinBoostLevel * 40);

  Future<void> buyXpBoost() async {
    final cost = xpBoostCost;
    if (coins < cost) return;

    setState(() {
      coins -= cost;
      xpBoostLevel += 1;
    });

    showSystemMessage('Upgrade Purchased — System Efficiency Lv $xpBoostLevel');

    await _saveAll();
  }

  Future<void> buyCoinBoost() async {
    final cost = coinBoostCost;
    if (coins < cost) return;

    setState(() {
      coins -= cost;
      coinBoostLevel += 1;
    });

    showSystemMessage('Upgrade Purchased — Coin Magnet Lv $coinBoostLevel');

    await _saveAll();
  }

  Future<void> showSystemMessage(String message) async {
    setState(() {
      systemMsg = message;
      systemMsgVisible = true;
    });

    // stay visible
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;
    setState(() => systemMsgVisible = false);

    // give time to animate out
    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;
    setState(() => systemMsg = null);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final b = dailyBundle!;
    final templates = b.templateIds.map(templateById).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SYSTEM'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B0F17),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Dev: force reset',
            onPressed: _forceNewDailyQuest,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Your normal content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SystemCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PLAYER STATUS', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Level $level',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  _XPBar(value: (xpToNext == 0) ? 0 : xp / xpToNext),
                                  const SizedBox(height: 6),
                                  Text('$xp / $xpToNext XP', style: TextStyle(color: Colors.white.withOpacity(0.75))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              children: [
                                _Chip(label: 'Coins', value: coins.toString()),
                                const SizedBox(height: 10),
                                _Chip(label: 'Streak', value: streak == 0 ? '-' : '$streak'),
                                const SizedBox(height: 10),
                                _Chip(label: 'Best', value: bestStreak == 0 ? '-' : '$bestStreak'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SystemCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DAILY QUESTS', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),

                        for (int i = 0; i < templates.length; i++) ...[
                          _DailyQuestRow(
                            title: templates[i].title,
                            description: templates[i].description,
                            rank: rankLabel(templates[i].difficulty),
                            rewardXp: (templates[i].baseXp * (1.0 + xpBoostLevel * 0.05)).round(),
                            rewardCoins: (templates[i].baseCoins * (1.0 + coinBoostLevel * 0.05)).round(),
                            completed: b.completed[i],
                            onComplete: () => _completeQuestAt(i),
                          ),
                          if (i != templates.length - 1) const SizedBox(height: 12),
                        ],

                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_allDone && !b.bonusClaimed) ? _claimAllBonus : null,
                            child: Text(b.bonusClaimed ? 'BONUS CLAIMED' : 'CLAIM ALL BONUS'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Today: ${b.dateKey}', style: TextStyle(color: Colors.white.withOpacity(0.45))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SystemCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UPGRADES (FAKE)',
                          style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),

                        _UpgradeRow(
                          title: 'System Efficiency',
                          subtitle: 'XP gain +${(xpBoostLevel * 5)}% (Next: +${((xpBoostLevel + 1) * 5)}%)',
                          cost: xpBoostCost.toString(),
                          enabled: coins >= xpBoostCost,
                          onBuy: buyXpBoost,
                          levelText: 'Lv $xpBoostLevel',
                        ),

                        const SizedBox(height: 12),

                        _UpgradeRow(
                          title: 'Coin Magnet',
                          subtitle: 'Coins +${(coinBoostLevel * 5)}% (Next: +${((coinBoostLevel + 1) * 5)}%)',
                          cost: coinBoostCost.toString(),
                          enabled: coins >= coinBoostCost,
                          onBuy: buyCoinBoost,
                          levelText: 'Lv $coinBoostLevel',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // SYSTEM MESSAGE overlay (bottom)
          if (systemMsg != null) _SystemOverlayMessage(
            message: systemMsg!,
            visible: systemMsgVisible,
          ),
        ],
      ),
    );
  }
}

/// ---------- UI Components ----------
class _SystemCard extends StatelessWidget {
  final Widget child;
  const _SystemCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3EF2D4).withOpacity(0.22)),
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  const _Chip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 11, letterSpacing: 1.1, color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _XPBar extends StatelessWidget {
  final double value; // 0..1
  const _XPBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 10,
        backgroundColor: Colors.white.withOpacity(0.10),
      ),
    );
  }
}

class _DailyQuestRow extends StatelessWidget {
  final String title;
  final String description;
  final String rank; // D/C/B/A/S
  final int rewardXp;
  final int rewardCoins;
  final bool completed;
  final VoidCallback onComplete;

  const _DailyQuestRow({
    required this.title,
    required this.description,
    required this.rank,
    required this.rewardXp,
    required this.rewardCoins,
    required this.completed,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              _Chip(label: 'Rank', value: rank),
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: TextStyle(color: Colors.white.withOpacity(0.85))),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(label: 'XP', value: '+$rewardXp'),
              const SizedBox(width: 10),
              _Chip(label: 'Coins', value: '+$rewardCoins'),
              const Spacer(),
              ElevatedButton(
                onPressed: completed ? null : onComplete,
                child: Text(completed ? 'DONE' : 'COMPLETE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpgradeRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cost;
  final bool enabled;
  final VoidCallback onBuy;
  final String levelText;

  const _UpgradeRow({
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.enabled,
    required this.onBuy,
    required this.levelText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.75))),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _Chip(label: 'Level', value: levelText),
        const SizedBox(width: 10),
        _Chip(label: 'Cost', value: cost),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: enabled ? onBuy : null,
          child: const Text('BUY'),
        ),
      ],
    );
  }
}

class _SystemOverlayMessage extends StatelessWidget {
  final String message;
  final bool visible;

  const _SystemOverlayMessage({
    required this.message,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        offset: visible ? Offset.zero : const Offset(0, 0.15),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: visible ? 1 : 0,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3EF2D4).withOpacity(0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3EF2D4).withOpacity(0.10),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Color(0xFF3EF2D4), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SYSTEM',
                        style: TextStyle(
                          color: Color(0xFF3EF2D4),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
