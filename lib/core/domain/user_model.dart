import 'package:equatable/equatable.dart';

class MlpUser extends Equatable {
  const MlpUser({
    required this.id,
    required this.name,
    this.phone = '',
    this.gender,
    this.xp = 0,
    this.level = 1,
    this.coins = 0,
    this.streak = 0,
  });

  final String id;
  final String name;
  final String phone;
  final String? gender; // 'O\'G\'IL' or 'QIZ'
  final int xp;
  final int level;
  final int coins;
  final int streak;

  int get xpToNextLevel => level * 500;
  double get xpProgress => xp / (xpToNextLevel == 0 ? 1 : xpToNextLevel);

  MlpUser copyWith({
    String? id, String? name, String? phone, String? gender,
    int? xp, int? level, int? coins, int? streak,
  }) {
    return MlpUser(
      id: id ?? this.id, name: name ?? this.name, phone: phone ?? this.phone,
      gender: gender ?? this.gender, xp: xp ?? this.xp, level: level ?? this.level,
      coins: coins ?? this.coins, streak: streak ?? this.streak,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, gender, xp, level, coins, streak];

  factory MlpUser.fromJson(Map<String, dynamic> json) => MlpUser(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String? ?? '',
        gender: json['gender'] as String?,
        xp: json['xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        coins: json['coins'] as int? ?? 0,
        streak: json['streak'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'phone': phone, 'gender': gender,
        'xp': xp, 'level': level, 'coins': coins, 'streak': streak,
      };
}
