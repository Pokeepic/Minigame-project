import '../models/title.dart';

/// Title Pool - All available titles
final List<TitleBadge> titlePool = [
  TitleBadge(
    id: 'rookie',
    name: 'Rookie Awakened',
    flavor: 'The system has acknowledged your existence.',
    requirement: 'Start the app',
    rarity: TitleRarity.common,
    buff: const TitleBuff(xpMult: 0.02),
    unlockIf: (s) => true,
  ),

  // Streak
  TitleBadge(
    id: 'streak_3',
    name: 'Consistent Executor',
    flavor: 'You do not rely on motivation.',
    requirement: 'Reach a 3-day streak',
    rarity: TitleRarity.rare,
    buff: const TitleBuff(xpMult: 0.04),
    unlockIf: (s) => s.streak >= 3,
  ),
  TitleBadge(
    id: 'streak_7',
    name: 'Discipline Holder',
    flavor: 'A week of control. Few can maintain it.',
    requirement: 'Reach a 7-day streak',
    rarity: TitleRarity.epic,
    buff: const TitleBuff(xpMult: 0.06, coinMult: 0.03),
    unlockIf: (s) => s.streak >= 7,
  ),
  TitleBadge(
    id: 'streak_14',
    name: 'Iron Routine',
    flavor: 'Your habits are no longer fragile.',
    requirement: 'Reach a 14-day streak',
    rarity: TitleRarity.epic,
    buff: const TitleBuff(xpMult: 0.07, bonusXpFlat: 10),
    unlockIf: (s) => s.streak >= 14,
  ),
  TitleBadge(
    id: 'streak_30',
    name: 'System Veteran',
    flavor: 'The system recognizes a long-term user.',
    requirement: 'Reach a 30-day streak',
    rarity: TitleRarity.legendary,
    buff: const TitleBuff(
      xpMult: 0.10,
      coinMult: 0.06,
      bonusXpFlat: 20,
      bonusCoinsFlat: 10,
    ),
    unlockIf: (s) => s.streak >= 30,
  ),

  // Level
  TitleBadge(
    id: 'level_10',
    name: 'Awakened Specialist',
    flavor: 'You\'ve surpassed the early wall.',
    requirement: 'Reach Level 10',
    rarity: TitleRarity.rare,
    buff: const TitleBuff(coinMult: 0.05),
    unlockIf: (s) => s.level >= 10,
  ),

  // Upgrades
  TitleBadge(
    id: 'upgrader',
    name: 'Optimization Addict',
    flavor: 'You sharpen your tools before battle.',
    requirement: 'Buy any upgrade',
    rarity: TitleRarity.common,
    buff: const TitleBuff(bonusCoinsFlat: 5),
    unlockIf: (s) => (s.totalQuestsCompleted + s.totalBonusesClaimed) >= 1,
  ),

  // Clears
  TitleBadge(
    id: 'clear_10',
    name: 'Quest Cleaner',
    flavor: 'No task survives your routine.',
    requirement: 'Clear Daily Quests 10 times',
    rarity: TitleRarity.rare,
    buff: const TitleBuff(xpMult: 0.03, coinMult: 0.03),
    unlockIf: (s) => s.totalBonusesClaimed >= 10,
  ),

  // Hidden titles
  TitleBadge(
    id: 'midnight',
    name: 'Midnight Operator',
    flavor: 'You move when the world sleeps.',
    requirement: '???',
    hidden: true,
    rarity: TitleRarity.epic,
    buff: const TitleBuff(xpMult: 0.06),
    unlockIf: (s) {
      final now = DateTime.now();
      return now.hour >= 0 && now.hour <= 4; // opened app between 12am-4am
    },
  ),
  TitleBadge(
    id: 'no_spend_day',
    name: 'Minimalist Protocol',
    flavor: 'You resisted unnecessary optimization.',
    requirement: '???',
    hidden: true,
    rarity: TitleRarity.legendary,
    buff: const TitleBuff(bonusXpFlat: 30),
    unlockIf: (s) {
      // unlock if you claimed bonus today AND bought no upgrades today
      return s.coins >
          100; // placeholder - will be properly implemented in controller
    },
  ),
];
