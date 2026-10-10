class HabitCompletion {
  const HabitCompletion({
    required this.date,
    required this.xpEarned,
    this.type = 'full',
    this.skipReason,
    this.mood,
    this.energy,
    this.durationMinutes,
    this.note,
  });

  final DateTime date;
  final int xpEarned;

  /// full, minimal, recovery, skip
  final String type;
  final String? skipReason;
  final int? mood;
  final int? energy;
  final int? durationMinutes;
  final String? note;

  bool get isSkip => type == 'skip' || skipReason != null;
  bool get isMinimal => type == 'minimal';
  bool get isRecovery => type == 'recovery';

  HabitCompletion copyWith({
    DateTime? date,
    int? xpEarned,
    String? type,
    String? skipReason,
    int? mood,
    int? energy,
    int? durationMinutes,
    String? note,
    bool clearSkipReason = false,
    bool clearMood = false,
    bool clearEnergy = false,
    bool clearDuration = false,
    bool clearNote = false,
  }) {
    return HabitCompletion(
      date: date ?? this.date,
      xpEarned: xpEarned ?? this.xpEarned,
      type: type ?? this.type,
      skipReason: clearSkipReason ? null : skipReason ?? this.skipReason,
      mood: clearMood ? null : mood ?? this.mood,
      energy: clearEnergy ? null : energy ?? this.energy,
      durationMinutes:
          clearDuration ? null : durationMinutes ?? this.durationMinutes,
      note: clearNote ? null : note ?? this.note,
    );
  }

  factory HabitCompletion.fromJson(Map<String, dynamic> json) {
    return HabitCompletion(
      date: DateTime.parse(json['date'] as String),
      xpEarned: json['xpEarned'] as int? ?? 0,
      type: json['type'] as String? ??
          ((json['skipReason'] as String?) == null ? 'full' : 'skip'),
      skipReason: json['skipReason'] as String?,
      mood: json['mood'] as int?,
      energy: json['energy'] as int?,
      durationMinutes: json['durationMinutes'] as int?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'xpEarned': xpEarned,
      'type': type,
      'skipReason': skipReason,
      'mood': mood,
      'energy': energy,
      'durationMinutes': durationMinutes,
      'note': note,
    };
  }
}
