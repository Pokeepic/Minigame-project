import '../utils/constants.dart';

/// Daily Quest Bundle - represents the 3 daily quests for a specific day
class DailyQuestBundle {
  final String dateKey; // yyyy-MM-dd
  final List<String> templateIds; // length 3
  final List<bool> completed; // length 3
  final bool bonusClaimed;

  const DailyQuestBundle({
    required this.dateKey,
    required this.templateIds,
    required this.completed,
    required this.bonusClaimed,
  }) : assert(
         templateIds.length == kDailyQuestCount,
         'Must have exactly 3 template IDs',
       ),
       assert(
         completed.length == kDailyQuestCount,
         'Must have exactly 3 completion flags',
       );

  DailyQuestBundle copyWith({List<bool>? completed, bool? bonusClaimed}) =>
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

  static DailyQuestBundle fromJson(Map<String, dynamic> json) =>
      DailyQuestBundle(
        dateKey: json['dateKey'] as String,
        templateIds: (json['templateIds'] as List).cast<String>(),
        completed: (json['completed'] as List).cast<bool>(),
        bonusClaimed: (json['bonusClaimed'] as bool?) ?? false,
      );
}
