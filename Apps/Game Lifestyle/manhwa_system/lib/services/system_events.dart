/// System Events and Log Types
/// Enums and event definitions for the system
library;

/// Log type enumeration - replaces string-based types
enum LogType {
  quest,
  bonus,
  upgrade,
  level,
  streak,
  milestone,
  title,
  info;

  /// Convert LogType to string for storage
  String toStorageString() => name;

  /// Parse LogType from stored string
  static LogType fromString(String str) {
    return LogType.values.firstWhere(
      (e) => e.name == str,
      orElse: () => LogType.info,
    );
  }

  /// Get display color for log type
  static int getColorForType(LogType type) {
    switch (type) {
      case LogType.quest:
        return 0xFF3EF2D4; // cyan
      case LogType.bonus:
        return 0xFFF2D43E; // gold
      case LogType.upgrade:
        return 0xFFB794F4; // purple
      case LogType.level:
        return 0xFF10B981; // green
      case LogType.streak:
        return 0xFFF97316; // orange
      case LogType.milestone:
        return 0xFFEC4899; // pink
      case LogType.title:
        return 0xFFF2D43E; // gold
      case LogType.info:
        return 0xFF9CA3AF; // gray
    }
  }
}
