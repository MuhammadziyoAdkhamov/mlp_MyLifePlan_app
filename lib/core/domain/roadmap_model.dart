import 'package:equatable/equatable.dart';

enum MilestoneStatus { notStarted, inProgress, completed }

class MlpTask extends Equatable {
  const MlpTask({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.completedAt,
    this.xpReward = 10,
  });

  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime? completedAt;
  final int xpReward;

  MlpTask copyWith({String? id, String? title, String? description, bool? isCompleted, DateTime? completedAt, int? xpReward}) {
    return MlpTask(
      id: id ?? this.id, title: title ?? this.title, description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted, completedAt: completedAt ?? this.completedAt,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  @override
  List<Object?> get props => [id, title, description, isCompleted, completedAt, xpReward];

  factory MlpTask.fromJson(Map<String, dynamic> json) => MlpTask(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? false,
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
        xpReward: json['xpReward'] as int? ?? 10,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'description': description,
        'isCompleted': isCompleted, 'completedAt': completedAt?.toIso8601String(),
        'xpReward': xpReward,
      };
}

class MlpMilestone extends Equatable {
  const MlpMilestone({
    required this.id,
    required this.title,
    required this.objective,
    required this.tasks,
    this.status = MilestoneStatus.notStarted,
    this.estimatedDays = 7,
    this.assessmentCriteria = '',
    this.completedAt,
  });

  final String id;
  final String title;
  final String objective;
  final List<MlpTask> tasks;
  final MilestoneStatus status;
  final int estimatedDays;
  final String assessmentCriteria;
  final DateTime? completedAt;

  int get completedTasks => tasks.where((t) => t.isCompleted).length;
  double get progress => tasks.isEmpty ? 0 : completedTasks / tasks.length;
  bool get isCompleted => status == MilestoneStatus.completed;

  MlpMilestone copyWith({
    String? id, String? title, String? objective, List<MlpTask>? tasks,
    MilestoneStatus? status, int? estimatedDays, String? assessmentCriteria, DateTime? completedAt,
  }) {
    return MlpMilestone(
      id: id ?? this.id, title: title ?? this.title, objective: objective ?? this.objective,
      tasks: tasks ?? this.tasks, status: status ?? this.status,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      assessmentCriteria: assessmentCriteria ?? this.assessmentCriteria,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, objective, tasks, status, estimatedDays, assessmentCriteria, completedAt];

  factory MlpMilestone.fromJson(Map<String, dynamic> json) => MlpMilestone(
        id: json['id'] as String,
        title: json['title'] as String,
        objective: json['objective'] as String,
        tasks: (json['tasks'] as List<dynamic>? ?? []).map((e) => MlpTask.fromJson(e as Map<String, dynamic>)).toList(),
        status: MilestoneStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => MilestoneStatus.notStarted),
        estimatedDays: json['estimatedDays'] as int? ?? 7,
        assessmentCriteria: json['assessmentCriteria'] as String? ?? '',
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'objective': objective,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'status': status.name, 'estimatedDays': estimatedDays,
        'assessmentCriteria': assessmentCriteria,
        'completedAt': completedAt?.toIso8601String(),
      };
}

class MlpRoadmap extends Equatable {
  const MlpRoadmap({
    required this.id,
    required this.goalId,
    required this.milestones,
    required this.createdAt,
    this.isApproved = false,
    this.totalEstimatedDays = 30,
  });

  final String id;
  final String goalId;
  final List<MlpMilestone> milestones;
  final DateTime createdAt;
  final bool isApproved;
  final int totalEstimatedDays;

  int get completedMilestones => milestones.where((m) => m.isCompleted).length;
  double get overallProgress => milestones.isEmpty ? 0 : completedMilestones / milestones.length;
  MlpMilestone? get currentMilestone => milestones.where((m) => !m.isCompleted).firstOrNull;

  MlpRoadmap copyWith({String? id, String? goalId, List<MlpMilestone>? milestones, DateTime? createdAt, bool? isApproved, int? totalEstimatedDays}) {
    return MlpRoadmap(
      id: id ?? this.id, goalId: goalId ?? this.goalId, milestones: milestones ?? this.milestones,
      createdAt: createdAt ?? this.createdAt, isApproved: isApproved ?? this.isApproved,
      totalEstimatedDays: totalEstimatedDays ?? this.totalEstimatedDays,
    );
  }

  @override
  List<Object?> get props => [id, goalId, milestones, createdAt, isApproved, totalEstimatedDays];

  factory MlpRoadmap.fromJson(Map<String, dynamic> json) => MlpRoadmap(
        id: json['id'] as String,
        goalId: json['goalId'] as String,
        milestones: (json['milestones'] as List<dynamic>? ?? []).map((e) => MlpMilestone.fromJson(e as Map<String, dynamic>)).toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        isApproved: json['isApproved'] as bool? ?? false,
        totalEstimatedDays: json['totalEstimatedDays'] as int? ?? 30,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'goalId': goalId,
        'milestones': milestones.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'isApproved': isApproved, 'totalEstimatedDays': totalEstimatedDays,
      };
}
