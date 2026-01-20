import '../utils/constants.dart';

/// Title Mastery State - represents progression within a title
class TitleMasteryState {
  final int level; // 1..10
  final int xp; // progress within this level
  final int xpToNext;

  const TitleMasteryState({
    required this.level,
    required this.xp,
    required this.xpToNext,
  });

  TitleMasteryState copyWith({int? level, int? xp, int? xpToNext}) =>
      TitleMasteryState(
        level: level ?? this.level,
        xp: xp ?? this.xp,
        xpToNext: xpToNext ?? this.xpToNext,
      );

  Map<String, dynamic> toJson() => {
    'level': level,
    'xp': xp,
    'xpToNext': xpToNext,
  };

  static TitleMasteryState fromJson(Map<String, dynamic> json) =>
      TitleMasteryState(
        level: (json['level'] as num).toInt(),
        xp: (json['xp'] as num).toInt(),
        xpToNext: (json['xpToNext'] as num).toInt(),
      );

  static TitleMasteryState fresh() =>
      const TitleMasteryState(level: 1, xp: 0, xpToNext: kMasteryXpBase);
}

/// Calculate XP required for next mastery level
int masteryXpToNext(int masteryLevel) =>
    kMasteryXpBase + (masteryLevel - 1) * kMasteryXpStep;
