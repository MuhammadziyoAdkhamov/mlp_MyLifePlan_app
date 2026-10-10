class AppStats {
  const AppStats({
    required this.dailyProgress,
    required this.weeklyProgress,
    required this.monthlyProgress,
    required this.completedToday,
    required this.totalHabits,
    required this.missedThisWeek,
    required this.bestStreak,
    required this.currentStreak,
    required this.totalXp,
    required this.level,
  });

  final double dailyProgress;
  final double weeklyProgress;
  final double monthlyProgress;
  final int completedToday;
  final int totalHabits;
  final int missedThisWeek;
  final int bestStreak;
  final int currentStreak;
  final int totalXp;
  final int level;

  AppStats copyWith({
    double? dailyProgress,
    double? weeklyProgress,
    double? monthlyProgress,
    int? completedToday,
    int? totalHabits,
    int? missedThisWeek,
    int? bestStreak,
    int? currentStreak,
    int? totalXp,
    int? level,
  }) {
    return AppStats(
      dailyProgress: dailyProgress ?? this.dailyProgress,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      monthlyProgress: monthlyProgress ?? this.monthlyProgress,
      completedToday: completedToday ?? this.completedToday,
      totalHabits: totalHabits ?? this.totalHabits,
      missedThisWeek: missedThisWeek ?? this.missedThisWeek,
      bestStreak: bestStreak ?? this.bestStreak,
      currentStreak: currentStreak ?? this.currentStreak,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
    );
  }

  factory AppStats.fromJson(Map<String, dynamic> json) {
    return AppStats(
      dailyProgress: (json['dailyProgress'] as num?)?.toDouble() ?? 0,
      weeklyProgress: (json['weeklyProgress'] as num?)?.toDouble() ?? 0,
      monthlyProgress: (json['monthlyProgress'] as num?)?.toDouble() ?? 0,
      completedToday: json['completedToday'] as int? ?? 0,
      totalHabits: json['totalHabits'] as int? ?? 0,
      missedThisWeek: json['missedThisWeek'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      totalXp: json['totalXp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyProgress': dailyProgress,
      'weeklyProgress': weeklyProgress,
      'monthlyProgress': monthlyProgress,
      'completedToday': completedToday,
      'totalHabits': totalHabits,
      'missedThisWeek': missedThisWeek,
      'bestStreak': bestStreak,
      'currentStreak': currentStreak,
      'totalXp': totalXp,
      'level': level,
    };
  }
}
