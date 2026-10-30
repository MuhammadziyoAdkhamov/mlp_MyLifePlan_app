import 'package:equatable/equatable.dart';

class DiagnosticResult extends Equatable {
  const DiagnosticResult({
    required this.goalId,
    required this.currentKnowledge,
    required this.weakAreas,
    required this.recommendedPace,
    required this.completedAt,
  });

  final String goalId;
  final String currentKnowledge;
  final List<String> weakAreas;
  final String recommendedPace;
  final DateTime completedAt;

  @override
  List<Object?> get props =>
      [goalId, currentKnowledge, weakAreas, recommendedPace, completedAt];

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticResult(
      goalId: json['goalId'] as String,
      currentKnowledge: json['currentKnowledge'] as String,
      weakAreas: (json['weakAreas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recommendedPace: json['recommendedPace'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goalId': goalId,
      'currentKnowledge': currentKnowledge,
      'weakAreas': weakAreas,
      'recommendedPace': recommendedPace,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}
