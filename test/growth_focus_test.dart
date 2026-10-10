import 'package:flutter_test/flutter_test.dart';
import 'package:mylife_plan/models/growth_focus.dart';

void main() {
  for (final focus in GrowthFocus.values) {
    test('${focus.name} produces three distinct starter habits', () {
      final plan = focus.starterHabits;

      expect(plan, hasLength(3));
      expect(plan.map((habit) => habit.name).toSet(), hasLength(3));
      expect(plan.every((habit) => habit.minimalGoal.isNotEmpty), isTrue);
    });
  }

  test('unknown focus IDs fall back to consistency', () {
    expect(growthFocusFromId('unknown'), GrowthFocus.consistency);
  });
}
