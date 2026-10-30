import 'package:equatable/equatable.dart';

class XpEvent extends Equatable {
  const XpEvent({
    required this.id,
    required this.label,
    required this.xp,
    required this.earnedAt,
  });

  final String id;
  final String label;
  final int xp;
  final DateTime earnedAt;

  @override
  List<Object?> get props => [id, label, xp, earnedAt];

  factory XpEvent.fromJson(Map<String, dynamic> json) => XpEvent(
        id: json['id'] as String,
        label: json['label'] as String,
        xp: json['xp'] as int,
        earnedAt: DateTime.parse(json['earnedAt'] as String),
      );

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'xp': xp, 'earnedAt': earnedAt.toIso8601String()};
}

class RewardItem extends Equatable {
  const RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.coinCost,
    required this.emoji,
    this.isDemo = true,
  });

  final String id;
  final String title;
  final String description;
  final int coinCost;
  final String emoji;
  final bool isDemo;

  @override
  List<Object?> get props => [id, title, description, coinCost, emoji, isDemo];
}
