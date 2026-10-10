enum HabitCategory { health, study, mind, faith, money, other }

enum HabitFrequency { everyday, weekdays, weekends, custom }

extension HabitCategoryX on HabitCategory {
  String get label {
    switch (this) {
      case HabitCategory.health:
        return 'Health';
      case HabitCategory.study:
        return 'Study';
      case HabitCategory.mind:
        return 'Mind';
      case HabitCategory.faith:
        return 'Faith';
      case HabitCategory.money:
        return 'Money';
      case HabitCategory.other:
        return 'Other';
    }
  }
}

extension HabitFrequencyX on HabitFrequency {
  String get label {
    switch (this) {
      case HabitFrequency.everyday:
        return 'Everyday';
      case HabitFrequency.weekdays:
        return 'Weekdays';
      case HabitFrequency.weekends:
        return 'Weekends';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }
}

T enumFromString<T>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  return values.firstWhere(
    (value) => value.toString().split('.').last == name,
    orElse: () => fallback,
  );
}
