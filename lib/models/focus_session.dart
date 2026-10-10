class FocusSession {
  const FocusSession({
    required this.id,
    required this.habitId,
    required this.startedAt,
    required this.completedAt,
    required this.durationSeconds,
  });

  final String id;
  final String habitId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationSeconds;

  int get completedMinutes => durationSeconds ~/ 60;

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      durationSeconds: json['durationSeconds'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'habitId': habitId,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
  };
}
