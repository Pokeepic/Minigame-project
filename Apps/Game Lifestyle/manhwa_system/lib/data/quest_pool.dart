import '../models/quest.dart';

/// Quest Pool - All available quest templates
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

/// Get quest template by ID
QuestTemplate templateById(String id) =>
    questPool.firstWhere((q) => q.id == id, orElse: () => questPool.first);

/// Get rank label for difficulty
String rankLabel(int difficulty) {
  switch (difficulty) {
    case 1:
      return 'D';
    case 2:
      return 'C';
    case 3:
      return 'B';
    case 4:
      return 'A';
    default:
      return 'S';
  }
}
