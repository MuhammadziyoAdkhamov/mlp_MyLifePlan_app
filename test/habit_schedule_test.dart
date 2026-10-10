import 'package:flutter_test/flutter_test.dart';
import 'package:mylife_plan/models/habit.dart';
import 'package:mylife_plan/models/habit_completion.dart';
import 'package:mylife_plan/models/habit_enums.dart';

void main() {
  test('weekday schedule only expects Monday through Friday', () {
    final habit = _habit(HabitFrequency.weekdays);

    expect(habit.isScheduledOn(DateTime(2026, 1, 5)), isTrue);
    expect(habit.isScheduledOn(DateTime(2026, 1, 10)), isFalse);
  });

  test('custom schedule preserves and applies selected weekdays', () {
    final habit = _habit(HabitFrequency.custom, customWeekdays: [1, 3]);

    expect(habit.isScheduledOn(DateTime(2026, 1, 5)), isTrue);
    expect(habit.isScheduledOn(DateTime(2026, 1, 6)), isFalse);
    expect(Habit.fromJson(habit.toJson()).customWeekdays, [1, 3]);
  });

  test('weekday streak skips unscheduled weekend days', () {
    final habit = _habit(
      HabitFrequency.weekdays,
      completions: [
        _completion(DateTime(2026, 1, 8)),
        _completion(DateTime(2026, 1, 9)),
      ],
    );

    expect(habit.currentStreakAt(DateTime(2026, 1, 10)), 2);
    expect(habit.bestStreak, 2);
  });

  test('recovery is offered after a missed scheduled day', () {
    final habit = _habit(
      HabitFrequency.weekdays,
      completions: [_completion(DateTime(2026, 1, 7))],
    );

    expect(habit.needsRecoveryOn(DateTime(2026, 1, 9)), isTrue);
  });

  test('recovery is not offered after completing the previous due day', () {
    final habit = _habit(
      HabitFrequency.weekdays,
      completions: [_completion(DateTime(2026, 1, 8))],
    );

    expect(habit.needsRecoveryOn(DateTime(2026, 1, 9)), isFalse);
  });

  test(
    'recovery is not offered when today is already complete or unscheduled',
    () {
      final completedToday = _habit(
        HabitFrequency.weekdays,
        completions: [_completion(DateTime(2026, 1, 9))],
      );
      final afterMiss = _habit(
        HabitFrequency.weekdays,
        completions: [_completion(DateTime(2026, 1, 7))],
      );

      expect(completedToday.needsRecoveryOn(DateTime(2026, 1, 9)), isFalse);
      expect(afterMiss.needsRecoveryOn(DateTime(2026, 1, 10)), isFalse);
    },
  );
}

Habit _habit(
  HabitFrequency frequency, {
  List<int> customWeekdays = const [],
  List<HabitCompletion> completions = const [],
}) {
  return Habit(
    id: 'habit-test',
    name: 'Test habit',
    category: HabitCategory.other,
    frequency: frequency,
    createdAt: DateTime(2026),
    iconCodePoint: 0xe3af,
    xpReward: 10,
    completions: completions,
    customWeekdays: customWeekdays,
  );
}

HabitCompletion _completion(DateTime date) =>
    HabitCompletion(date: date, xpEarned: 10);
