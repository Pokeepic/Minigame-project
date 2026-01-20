import 'package:flutter/material.dart';

/// Title System Models

enum TitleRarity { common, rare, epic, legendary }

class TitleBuff {
  final double xpMult; // e.g. 0.05 = +5%
  final double coinMult; // e.g. 0.05 = +5%
  final int bonusXpFlat; // e.g. +10 bonus XP on claim
  final int bonusCoinsFlat; // e.g. +5 bonus coins on claim

  const TitleBuff({
    this.xpMult = 0,
    this.coinMult = 0,
    this.bonusXpFlat = 0,
    this.bonusCoinsFlat = 0,
  });
}

/// Abstract interface for checking unlock conditions
/// This decouples title logic from widget state
abstract class SystemState {
  int get level;
  int get streak;
  int get coins;
  int get totalQuestsCompleted;
  int get totalBonusesClaimed;
  int get maxStreak;
  Map<String, bool> get unlockedTitles;
}

class TitleBadge {
  final String id;
  final String name;
  final String flavor;
  final String requirement; // shown if not hidden
  final bool hidden; // secret?
  final TitleRarity rarity;
  final TitleBuff buff;
  final bool Function(SystemState s) unlockIf;

  const TitleBadge({
    required this.id,
    required this.name,
    required this.flavor,
    required this.requirement,
    required this.unlockIf,
    this.hidden = false,
    this.rarity = TitleRarity.common,
    this.buff = const TitleBuff(),
  });
}

// Helper functions for title rarity
String rarityLabel(TitleRarity r) {
  switch (r) {
    case TitleRarity.common:
      return 'COMMON';
    case TitleRarity.rare:
      return 'RARE';
    case TitleRarity.epic:
      return 'EPIC';
    case TitleRarity.legendary:
      return 'LEGENDARY';
  }
}

Color rarityColor(TitleRarity r) {
  switch (r) {
    case TitleRarity.common:
      return const Color(0xFF9CA3AF); // gray
    case TitleRarity.rare:
      return const Color(0xFF3EF2D4); // cyan
    case TitleRarity.epic:
      return const Color(0xFFB794F4); // purple
    case TitleRarity.legendary:
      return const Color(0xFFF2D43E); // gold
  }
}

double rarityGlow(TitleRarity r) {
  switch (r) {
    case TitleRarity.common:
      return 6;
    case TitleRarity.rare:
      return 10;
    case TitleRarity.epic:
      return 14;
    case TitleRarity.legendary:
      return 18;
  }
}
