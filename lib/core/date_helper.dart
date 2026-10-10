class DateHelper {
  const DateHelper._();

  static DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  static String key(DateTime date) {
    final d = dateOnly(date);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static List<DateTime> lastDays(int count, {DateTime? from}) {
    final start = dateOnly(from ?? DateTime.now());
    return List.generate(count, (index) => start.subtract(Duration(days: count - 1 - index)));
  }

  static DateTime parseDateOnly(String value) {
    final parts = value.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }
}
