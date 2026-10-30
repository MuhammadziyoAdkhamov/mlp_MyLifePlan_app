import 'package:equatable/equatable.dart';

enum GoalPriority { high, medium, low }
enum GoalCategory {
  til, dasturlash, biznes, sogliq, moliya, din, sport, ijodiyot, custom;

  String get uzLabel {
    switch (this) {
      case GoalCategory.til: return 'Til O\'rganish';
      case GoalCategory.dasturlash: return 'Dasturlash';
      case GoalCategory.biznes: return 'Biznes';
      case GoalCategory.sogliq: return 'Sog\'liq';
      case GoalCategory.moliya: return 'Moliya';
      case GoalCategory.din: return 'Din';
      case GoalCategory.sport: return 'Sport';
      case GoalCategory.ijodiyot: return 'Ijodiyot';
      case GoalCategory.custom: return 'Boshqa';
    }
  }

  String get icon {
    switch (this) {
      case GoalCategory.til: return '🗣️';
      case GoalCategory.dasturlash: return '💻';
      case GoalCategory.biznes: return '📊';
      case GoalCategory.sogliq: return '❤️';
      case GoalCategory.moliya: return '💰';
      case GoalCategory.din: return '🕌';
      case GoalCategory.sport: return '⚽';
      case GoalCategory.ijodiyot: return '🎨';
      case GoalCategory.custom: return '✨';
    }
  }
}

class MlpGoal extends Equatable {
  const MlpGoal({
    required this.id,
    required this.title,
    required this.outcome,
    required this.category,
    required this.priority,
    required this.minutesPerDay,
    required this.createdAt,
    this.deadline,
    this.currentLevel = 'Boshlang\'ich',
    this.isActive = true,
    this.roadmapId,
  });

  final String id;
  final String title;
  final String outcome;
  final GoalCategory category;
  final GoalPriority priority;
  final int minutesPerDay;
  final DateTime createdAt;
  final DateTime? deadline;
  final String currentLevel;
  final bool isActive;
  final String? roadmapId;

  MlpGoal copyWith({
    String? id, String? title, String? outcome,
    GoalCategory? category, GoalPriority? priority,
    int? minutesPerDay, DateTime? createdAt, DateTime? deadline,
    String? currentLevel, bool? isActive, String? roadmapId,
  }) {
    return MlpGoal(
      id: id ?? this.id, title: title ?? this.title, outcome: outcome ?? this.outcome,
      category: category ?? this.category, priority: priority ?? this.priority,
      minutesPerDay: minutesPerDay ?? this.minutesPerDay, createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline, currentLevel: currentLevel ?? this.currentLevel,
      isActive: isActive ?? this.isActive, roadmapId: roadmapId ?? this.roadmapId,
    );
  }

  @override
  List<Object?> get props => [id, title, outcome, category, priority, minutesPerDay, createdAt, deadline, currentLevel, isActive, roadmapId];

  factory MlpGoal.fromJson(Map<String, dynamic> json) => MlpGoal(
        id: json['id'] as String,
        title: json['title'] as String,
        outcome: json['outcome'] as String,
        category: GoalCategory.values.firstWhere((e) => e.name == json['category'], orElse: () => GoalCategory.custom),
        priority: GoalPriority.values.firstWhere((e) => e.name == json['priority'], orElse: () => GoalPriority.medium),
        minutesPerDay: json['minutesPerDay'] as int? ?? 30,
        createdAt: DateTime.parse(json['createdAt'] as String),
        deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
        currentLevel: json['currentLevel'] as String? ?? 'Boshlang\'ich',
        isActive: json['isActive'] as bool? ?? true,
        roadmapId: json['roadmapId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'outcome': outcome, 'category': category.name,
        'priority': priority.name, 'minutesPerDay': minutesPerDay,
        'createdAt': createdAt.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
        'currentLevel': currentLevel, 'isActive': isActive, 'roadmapId': roadmapId,
      };
}
