class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.totalXp,
    required this.level,
    required this.createdAt,
    this.avatarUrl,
    this.growthFocus = 'consistency',
  });

  final String id;
  final String name;
  final String email;
  final int totalXp;
  final int level;
  final DateTime createdAt;
  final String? avatarUrl;
  final String growthFocus;

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    int? totalXp,
    int? level,
    DateTime? createdAt,
    String? avatarUrl,
    String? growthFocus,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      growthFocus: growthFocus ?? this.growthFocus,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      totalXp: json['totalXp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      avatarUrl: json['avatarUrl'] as String?,
      growthFocus: json['growthFocus'] as String? ?? 'consistency',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'totalXp': totalXp,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
      'avatarUrl': avatarUrl,
      'growthFocus': growthFocus,
    };
  }

  static UserProfile demo() {
    return UserProfile(
      id: 'user_demo',
      name: 'Azizbek',
      email: 'example@gmail.com',
      totalXp: 1240,
      level: 7,
      createdAt: DateTime.now().subtract(const Duration(days: 68)),
    );
  }
}
