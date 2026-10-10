class JourneyTask {
  const JourneyTask({
    required this.id,
    required this.day,
    required this.title,
    required this.description,
    required this.xpReward,
    this.completedAt,
    this.isLocked = false,
  });

  final String id;
  final int day;
  final String title;
  final String description;
  final int xpReward;
  final DateTime? completedAt;
  final bool isLocked;

  bool get isCompleted => completedAt != null;

  JourneyTask copyWith({
    String? id,
    int? day,
    String? title,
    String? description,
    int? xpReward,
    DateTime? completedAt,
    bool? clearCompletedAt,
    bool? isLocked,
  }) {
    return JourneyTask(
      id: id ?? this.id,
      day: day ?? this.day,
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      completedAt: clearCompletedAt == true ? null : completedAt ?? this.completedAt,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  factory JourneyTask.fromJson(Map<String, dynamic> json) {
    return JourneyTask(
      id: json['id'] as String,
      day: json['day'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      xpReward: json['xpReward'] as int? ?? 20,
      completedAt: json['completedAt'] == null ? null : DateTime.parse(json['completedAt'] as String),
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day': day,
      'title': title,
      'description': description,
      'xpReward': xpReward,
      'completedAt': completedAt?.toIso8601String(),
      'isLocked': isLocked,
    };
  }
}
