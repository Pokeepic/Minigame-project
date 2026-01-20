/// Game Constants
/// All magic numbers and configuration values centralized here
library;

// Profile Constants (global, not namespaced)
const String kProfilesKey = 'profiles_json';
const String kActiveProfileIdKey = 'active_profile';

// XP and Level Constants
const int kLevelXpBase = 100;
const int kLevelXpStep = 25;

// Mastery Constants
const int kMasteryXpBase = 60;
const int kMasteryXpStep = 35;
const int kMaxMasteryLevel = 10;

// Upgrade Constants
const double kXpBoostPerLevel = 0.05;
const double kCoinBoostPerLevel = 0.05;
const int kXpBoostCostBase = 50;
const int kXpBoostCostMult = 2;
const int kCoinBoostCostBase = 50;
const int kCoinBoostCostMult = 2;

// Daily Quest Constants
const int kDailyQuestCount = 3;
const int kBonusXpBase = 150;
const int kBonusCoinsBase = 100;

// Streak and Milestone Constants
const int kStreakMilestone1 = 7;
const int kStreakMilestone2 = 14;
const int kStreakMilestone3 = 30;

// Log Constants
const int kMaxLogs = 200;

// UI Constants
const double kCardPadding = 16.0;
const double kCardBorderRadius = 12.0;
const double kChipBorderRadius = 20.0;
