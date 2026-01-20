/// Date Key Utilities
/// Centralized date formatting and key generation

/// Generates a date key in yyyy-MM-dd format from a DateTime
String dateKeyFrom(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Gets today's date key
String get todayKey => dateKeyFrom(DateTime.now());

/// Gets yesterday's date key
String get yesterdayKey {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return dateKeyFrom(yesterday);
}

/// Checks if a date key is today
bool isToday(String dateKey) => dateKey == todayKey;

/// Checks if a date key is from yesterday
bool isYesterday(String dateKey) => dateKey == yesterdayKey;
