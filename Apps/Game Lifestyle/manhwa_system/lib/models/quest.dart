/// Quest Template - represents a type of quest that can be assigned
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
