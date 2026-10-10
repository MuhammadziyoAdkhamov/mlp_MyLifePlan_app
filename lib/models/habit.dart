import '../core/date_helper.dart';
import 'habit_completion.dart';
import 'habit_enums.dart';

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.frequency,
    required this.createdAt,
    required this.iconCodePoint,
    required this.xpReward,
    required this.completions,
    this.customWeekdays = const [],
    this.goal,
    this.reminder,
    this.isActive = true,
    this.whyNote,
    this.minimalGoal,
    this.stackAfterHabitId,
    this.accountabilityPartner,
    this.futureLetter,
    this.commitmentContract,
  });

  final String id;
  final String name;
  final HabitCategory category;
  final HabitFrequency frequency;
  final DateTime createdAt;
  final int iconCodePoint;
  final int xpReward;
  final List<HabitCompletion> completions;
  final List<int> customWeekdays;
  final String? goal;
  final String? reminder;
  final bool isActive;

  /// Identity-based habit design fields.
  final String? whyNote;
  final String? minimalGoal;
  final String? stackAfterHabitId;
  final String? accountabilityPartner;
  final String? futureLetter;
  final String? commitmentContract;

  Habit copyWith({
    String? id,
    String? name,
    HabitCategory? category,
    HabitFrequency? frequency,
    DateTime? createdAt,
    int? iconCodePoint,
    int? xpReward,
    List<HabitCompletion>? completions,
    List<int>? customWeekdays,
    String? goal,
    String? reminder,
    bool? isActive,
    String? whyNote,
    String? minimalGoal,
    String? stackAfterHabitId,
    String? accountabilityPartner,
    String? futureLetter,
    String? commitmentContract,
    bool clearGoal = false,
    bool clearReminder = false,
    bool clearWhyNote = false,
    bool clearMinimalGoal = false,
    bool clearStackAfterHabitId = false,
    bool clearAccountabilityPartner = false,
    bool clearFutureLetter = false,
    bool clearCommitmentContract = false,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      xpReward: xpReward ?? this.xpReward,
      completions: completions ?? this.completions,
      customWeekdays: customWeekdays ?? this.customWeekdays,
      goal: clearGoal ? null : goal ?? this.goal,
      reminder: clearReminder ? null : reminder ?? this.reminder,
      isActive: isActive ?? this.isActive,
      whyNote: clearWhyNote ? null : whyNote ?? this.whyNote,
      minimalGoal: clearMinimalGoal ? null : minimalGoal ?? this.minimalGoal,
      stackAfterHabitId: clearStackAfterHabitId
          ? null
          : stackAfterHabitId ?? this.stackAfterHabitId,
      accountabilityPartner: clearAccountabilityPartner
          ? null
          : accountabilityPartner ?? this.accountabilityPartner,
      futureLetter: clearFutureLetter
          ? null
          : futureLetter ?? this.futureLetter,
      commitmentContract: clearCommitmentContract
          ? null
          : commitmentContract ?? this.commitmentContract,
    );
  }

  bool isCompletedOn(DateTime date) {
    return completions.any(
      (completion) =>
          DateHelper.isSameDay(completion.date, date) && !completion.isSkip,
    );
  }

  bool isSkippedOn(DateTime date) {
    return completions.any(
      (completion) =>
          DateHelper.isSameDay(completion.date, date) && completion.isSkip,
    );
  }

  HabitCompletion? entryForDay(DateTime date) {
    for (final completion in completions) {
      if (DateHelper.isSameDay(completion.date, date)) {
        return completion;
      }
    }
    return null;
  }

  List<HabitCompletion> get completedEntries {
    return completions.where((item) => !item.isSkip).toList();
  }

  List<HabitCompletion> get skippedEntries {
    return completions.where((item) => item.isSkip).toList();
  }

  int get totalXp =>
      completedEntries.fold(0, (sum, item) => sum + item.xpEarned);

  int get completionCount => completedEntries.length;

  int get skipCount => skippedEntries.length;

  int get minimalCount =>
      completedEntries.where((item) => item.isMinimal).length;

  int get recoveryCount =>
      completedEntries.where((item) => item.isRecovery).length;

  int get totalDurationMinutes => completedEntries.fold(
    0,
    (sum, item) => sum + (item.durationMinutes ?? _defaultMinutesFromGoal()),
  );

  bool isScheduledOn(DateTime date) {
    switch (frequency) {
      case HabitFrequency.everyday:
        return true;
      case HabitFrequency.weekdays:
        return date.weekday <= DateTime.friday;
      case HabitFrequency.weekends:
        return date.weekday >= DateTime.saturday;
      case HabitFrequency.custom:
        return customWeekdays.isEmpty || customWeekdays.contains(date.weekday);
    }
  }

  bool needsRecoveryOn(DateTime date) {
    final today = DateHelper.dateOnly(date);
    if (!isScheduledOn(today) || isCompletedOn(today)) return false;

    var previousScheduled = today.subtract(const Duration(days: 1));
    while (!isScheduledOn(previousScheduled)) {
      previousScheduled = previousScheduled.subtract(const Duration(days: 1));
    }
    return !isCompletedOn(previousScheduled);
  }

  int _defaultMinutesFromGoal() {
    final text = '${goal ?? ''} $name'.toLowerCase();
    final match = RegExp(r'(\d+)').firstMatch(text);
    final value = match == null ? null : int.tryParse(match.group(1)!);
    if (value == null) return 10;
    if (text.contains('hour') || text.contains('soat')) return value * 60;
    if (text.contains('page') || text.contains('sahifa'))
      return (value / 2).round().clamp(5, 120).toInt();
    if (text.contains('glass') || text.contains('cup')) return 2;
    return value.clamp(2, 180).toInt();
  }

  int get currentStreak {
    return currentStreakAt(DateTime.now());
  }

  int currentStreakAt(DateTime date) {
    if (completedEntries.isEmpty) return 0;
    final keys = completedEntries
        .where((entry) => isScheduledOn(entry.date))
        .map((entry) => DateHelper.key(entry.date))
        .toSet();
    var cursor = DateHelper.dateOnly(date);
    if (!isScheduledOn(cursor) || !keys.contains(DateHelper.key(cursor))) {
      cursor = _previousScheduledDay(cursor);
    }
    var streak = 0;
    while (keys.contains(DateHelper.key(cursor))) {
      streak++;
      cursor = _previousScheduledDay(cursor);
    }
    return streak;
  }

  int get bestStreak {
    final dates =
        completedEntries
            .where((entry) => isScheduledOn(entry.date))
            .map((entry) => DateHelper.dateOnly(entry.date))
            .toSet()
            .toList()
          ..sort();
    if (dates.isEmpty) return 0;

    var best = 1;
    var current = 1;
    for (var i = 1; i < dates.length; i++) {
      if (DateHelper.isSameDay(_nextScheduledDay(dates[i - 1]), dates[i])) {
        current++;
      } else {
        current = 1;
      }
      if (current > best) best = current;
    }
    return best;
  }

  DateTime _previousScheduledDay(DateTime date) {
    var cursor = date.subtract(const Duration(days: 1));
    while (!isScheduledOn(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return cursor;
  }

  DateTime _nextScheduledDay(DateTime date) {
    var cursor = date.add(const Duration(days: 1));
    while (!isScheduledOn(cursor)) {
      cursor = cursor.add(const Duration(days: 1));
    }
    return cursor;
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      category: enumFromString(
        HabitCategory.values,
        json['category'] as String?,
        HabitCategory.other,
      ),
      frequency: enumFromString(
        HabitFrequency.values,
        json['frequency'] as String?,
        HabitFrequency.everyday,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      iconCodePoint: json['iconCodePoint'] as int? ?? 0xe3af,
      xpReward: json['xpReward'] as int? ?? 40,
      completions: (json['completions'] as List<dynamic>? ?? [])
          .map((item) => HabitCompletion.fromJson(item as Map<String, dynamic>))
          .toList(),
      customWeekdays: (json['customWeekdays'] as List<dynamic>? ?? const [])
          .whereType<int>()
          .toList(),
      goal: json['goal'] as String?,
      reminder: json['reminder'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      whyNote: json['whyNote'] as String?,
      minimalGoal: json['minimalGoal'] as String?,
      stackAfterHabitId: json['stackAfterHabitId'] as String?,
      accountabilityPartner: json['accountabilityPartner'] as String?,
      futureLetter: json['futureLetter'] as String?,
      commitmentContract: json['commitmentContract'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'frequency': frequency.name,
      'createdAt': createdAt.toIso8601String(),
      'iconCodePoint': iconCodePoint,
      'xpReward': xpReward,
      'completions': completions.map((item) => item.toJson()).toList(),
      'customWeekdays': customWeekdays,
      'goal': goal,
      'reminder': reminder,
      'isActive': isActive,
      'whyNote': whyNote,
      'minimalGoal': minimalGoal,
      'stackAfterHabitId': stackAfterHabitId,
      'accountabilityPartner': accountabilityPartner,
      'futureLetter': futureLetter,
      'commitmentContract': commitmentContract,
    };
  }
}
