class UserProfile {
  final String id; // stable unique id
  final String name;
  final int createdAt; // epoch ms

  const UserProfile({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
      };

  static UserProfile fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: (json['createdAt'] as num).toInt(),
      );
}
