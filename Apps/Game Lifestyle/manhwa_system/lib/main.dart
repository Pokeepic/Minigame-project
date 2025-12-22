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

class DailyQuest {
  final String dateKey; // yyyy-mm-dd
  final String templateId;
  final bool completed;

  const DailyQuest({
    required this.dateKey,
    required this.templateId,
    required this.completed,
  });

  DailyQuest copyWith({bool? completed}) => DailyQuest(
        dateKey: dateKey,
        templateId: templateId,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'templateId': templateId,
        'completed': completed,
      };

  static DailyQuest fromJson(Map<String, dynamic> json) => DailyQuest(
        dateKey: json['dateKey'] as String,
        templateId: json['templateId'] as String,
        completed: json['completed'] as bool,
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

QuestTemplate templateById(String id) =>
    questPool.firstWhere((q) => q.id == id, orElse: () => questPool.first);

String todayKey() {
  final now = DateTime.now();
  // local date, stable key
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

/// ---------- Storage ----------
class StorageKeys {
  static const level = 'level';
  static const xp = 'xp';
  static const xpToNext = 'xpToNext';
  static const coins = 'coins';

  static const dailyQuestJson = 'dailyQuestJson';
}

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

  // Daily Quest State
  DailyQuest? dailyQuest;

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

    // Load daily quest
    final jsonStr = prefs.getString(StorageKeys.dailyQuestJson);
    if (jsonStr != null) {
      try {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        dailyQuest = DailyQuest.fromJson(map);
      } catch (_) {
        dailyQuest = null;
      }
    }

    // Ensure today's quest exists
    final tKey = todayKey();
    if (dailyQuest == null || dailyQuest!.dateKey != tKey) {
      dailyQuest = _generateDailyQuestFor(tKey);
      await _saveDailyQuest(prefs);
    }

    setState(() => loading = false);
  }

  DailyQuest _generateDailyQuestFor(String dateKey) {
    // Deterministic-ish daily randomness (so it won't keep changing)
    // We seed with dateKey hash so today's quest stays same all day.
    final seed = dateKey.hashCode;
    final rng = Random(seed);

    // Weighted pick: prefer mixed difficulties, but keep it simple for V1
    final picked = questPool[rng.nextInt(questPool.length)];

    return DailyQuest(dateKey: dateKey, templateId: picked.id, completed: false);
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.level, level);
    await prefs.setInt(StorageKeys.xp, xp);
    await prefs.setInt(StorageKeys.xpToNext, xpToNext);
    await prefs.setInt(StorageKeys.coins, coins);
    await _saveDailyQuest(prefs);
  }

  Future<void> _saveDailyQuest(SharedPreferences prefs) async {
    if (dailyQuest == null) return;
    await prefs.setString(StorageKeys.dailyQuestJson, json.encode(dailyQuest!.toJson()));
  }

  void _completeQuest() async {
    final q = dailyQuest;
    if (q == null || q.completed) return;

    final t = templateById(q.templateId);

    setState(() {
      dailyQuest = q.copyWith(completed: true);

      // Rewards (upgrades multipliers later)
      xp += t.baseXp;
      coins += t.baseCoins;

      // Level up loop (handles big XP)
      while (xp >= xpToNext) {
        xp -= xpToNext;
        level += 1;
        xpToNext = 100 + (level - 1) * 25;
      }
    });

    await _saveAll();
  }

  // Developer tool button for testing daily reset
  void _forceNewDailyQuest() async {
    final prefs = await SharedPreferences.getInstance();
    final fakeDate = DateTime.now().subtract(const Duration(days: 1));
    final key =
        '${fakeDate.year.toString().padLeft(4, '0')}-${fakeDate.month.toString().padLeft(2, '0')}-${fakeDate.day.toString().padLeft(2, '0')}';
    dailyQuest = _generateDailyQuestFor(key);
    await _saveDailyQuest(prefs);
    await _loadOrCreate();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final q = dailyQuest!;
    final t = templateById(q.templateId);

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                      _Chip(label: 'Coins', value: coins.toString()),
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
                  const Text('DAILY QUEST', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(t.description, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _Chip(label: 'Title', value: t.title),
                      const SizedBox(width: 10),
                      _Chip(label: 'Rank', value: 'D${t.difficulty}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Chip(label: 'Reward', value: '+${t.baseXp} XP'),
                      const SizedBox(width: 10),
                      _Chip(label: 'Reward', value: '+${t.baseCoins} Coins'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: q.completed ? null : _completeQuest,
                      child: Text(q.completed ? 'COMPLETED' : 'COMPLETE'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Today: ${q.dateKey}', style: TextStyle(color: Colors.white.withOpacity(0.45))),
                ],
              ),
            ),
          ],
        ),
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
