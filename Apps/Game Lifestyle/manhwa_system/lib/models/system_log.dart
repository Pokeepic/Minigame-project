import '../services/system_events.dart';

/// System Log Entry - represents an activity log entry
class SystemLogEntry {
  final int ts; // epoch ms
  final LogType type;
  final String message;
  final Map<String, dynamic>? data; // optional extra data

  const SystemLogEntry({
    required this.ts,
    required this.type,
    required this.message,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'ts': ts,
    'type': type.toStorageString(),
    'message': message,
    if (data != null) 'data': data,
  };

  static SystemLogEntry fromJson(Map<String, dynamic> json) => SystemLogEntry(
    ts: json['ts'] as int,
    type: LogType.fromString(json['type'] as String),
    message: json['message'] as String,
    data: (json['data'] as Map?)?.cast<String, dynamic>(),
  );
}
