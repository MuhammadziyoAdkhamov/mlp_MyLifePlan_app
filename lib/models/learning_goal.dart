import 'package:equatable/equatable.dart';

class LearningGoal extends Equatable {
  const LearningGoal({
    required this.id,
    required this.title,
    this.category,
    required this.outcome,
    required this.currentLevel,
    this.targetDate,
    required this.availableMinutesPerDay,
    required this.createdAt,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String? category;
  final String outcome;
  final String currentLevel;
  final DateTime? targetDate;
  final int availableMinutesPerDay;
  final DateTime createdAt;
  final bool isActive;

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        outcome,
        currentLevel,
        targetDate,
        availableMinutesPerDay,
        createdAt,
        isActive,
      ];

  LearningGoal copyWith({
    String? id,
    String? title,
    String? category,
    String? outcome,
    String? currentLevel,
    DateTime? targetDate,
    int? availableMinutesPerDay,
    DateTime? createdAt,
    bool? isActive,
    bool clearCategory = false,
    bool clearTargetDate = false,
  }) {
    return LearningGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      category: clearCategory ? null : category ?? this.category,
      outcome: outcome ?? this.outcome,
      currentLevel: currentLevel ?? this.currentLevel,
      targetDate: clearTargetDate ? null : targetDate ?? this.targetDate,
      availableMinutesPerDay:
          availableMinutesPerDay ?? this.availableMinutesPerDay,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory LearningGoal.fromJson(Map<String, dynamic> json) {
    return LearningGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String?,
      outcome: json['outcome'] as String,
      currentLevel: json['currentLevel'] as String,
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      availableMinutesPerDay: json['availableMinutesPerDay'] as int? ?? 30,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'outcome': outcome,
      'currentLevel': currentLevel,
      'targetDate': targetDate?.toIso8601String(),
      'availableMinutesPerDay': availableMinutesPerDay,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
