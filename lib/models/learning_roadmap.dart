import 'package:equatable/equatable.dart';

class LearningStage extends Equatable {
  const LearningStage({
    required this.id,
    required this.title,
    required this.objective,
    required this.assessmentCriteria,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String objective;
  final String assessmentCriteria;
  final bool isCompleted;

  @override
  List<Object?> get props => [id, title, objective, assessmentCriteria, isCompleted];

  LearningStage copyWith({
    String? id,
    String? title,
    String? objective,
    String? assessmentCriteria,
    bool? isCompleted,
  }) {
    return LearningStage(
      id: id ?? this.id,
      title: title ?? this.title,
      objective: objective ?? this.objective,
      assessmentCriteria: assessmentCriteria ?? this.assessmentCriteria,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory LearningStage.fromJson(Map<String, dynamic> json) {
    return LearningStage(
      id: json['id'] as String,
      title: json['title'] as String,
      objective: json['objective'] as String,
      assessmentCriteria: json['assessmentCriteria'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'objective': objective,
      'assessmentCriteria': assessmentCriteria,
      'isCompleted': isCompleted,
    };
  }
}

class LearningRoadmap extends Equatable {
  const LearningRoadmap({
    required this.id,
    required this.goalId,
    required this.stages,
    this.isApproved = false,
    required this.createdAt,
  });

  final String id;
  final String goalId;
  final List<LearningStage> stages;
  final bool isApproved;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, goalId, stages, isApproved, createdAt];

  LearningRoadmap copyWith({
    String? id,
    String? goalId,
    List<LearningStage>? stages,
    bool? isApproved,
    DateTime? createdAt,
  }) {
    return LearningRoadmap(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      stages: stages ?? this.stages,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory LearningRoadmap.fromJson(Map<String, dynamic> json) {
    return LearningRoadmap(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      stages: (json['stages'] as List<dynamic>? ?? [])
          .map((item) => LearningStage.fromJson(item as Map<String, dynamic>))
          .toList(),
      isApproved: json['isApproved'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'stages': stages.map((s) => s.toJson()).toList(),
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
