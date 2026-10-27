enum MLPRepeat { once, daily, weekdays, weekly }

extension MLPRepeatLabel on MLPRepeat {
  String get label => switch (this) {
    MLPRepeat.once => 'Bir marta',
    MLPRepeat.daily => 'Har kuni',
    MLPRepeat.weekdays => 'Dushanba–juma',
    MLPRepeat.weekly => 'Har hafta',
  };
}

DateTime mlpDay(DateTime value) => DateTime(value.year, value.month, value.day);
String mlpDayKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String mlpTime(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
DateTime _readDay(Object? raw) {
  if (raw is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
    throw const FormatException('Sana formati noto‘g‘ri.');
  }
  final value = DateTime.parse(raw);
  if (mlpDayKey(value) != raw) throw const FormatException('Sana mavjud emas.');
  return value;
}

bool mlpWebLink(String value) {
  if (value.isEmpty) return true;
  final uri = Uri.tryParse(value);
  return value.length <= 1000 &&
      uri != null &&
      ['http', 'https'].contains(uri.scheme) &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty;
}

class MLPSchedule {
  MLPSchedule({
    required this.id,
    required this.title,
    required DateTime date,
    required this.startMinute,
    required this.endMinute,
    this.repeat = MLPRepeat.once,
    DateTime? until,
    this.goalId,
    this.taskId,
    this.reminderMinutes,
    this.appLink = '',
  }) : date = mlpDay(date),
       until = until == null ? null : mlpDay(until) {
    if (id.isEmpty ||
        id.length > 100 ||
        title.trim().length < 2 ||
        title.length > 160) {
      throw ArgumentError('Mashg‘ulot nomi 2–160 belgi bo‘lsin.');
    }
    if (startMinute < 0 || endMinute > 1440 || startMinute >= endMinute) {
      throw ArgumentError(
        'Tugash soati boshlanishdan keyin bo‘lsin. Tun oralig‘ini ikki mashg‘ulotga ajrating.',
      );
    }
    if (this.until != null && this.until!.isBefore(this.date)) {
      throw ArgumentError('Takrorlash tugashi boshlanishdan oldin bo‘lmasin.');
    }
    if (reminderMinutes != null &&
        ![0, 5, 10, 15, 30, 60].contains(reminderMinutes)) {
      throw ArgumentError('Eslatma vaqtini ro‘yxatdan tanlang.');
    }
    if (!mlpWebLink(appLink)) {
      throw ArgumentError('Faqat to‘g‘ri http yoki https havola kiriting.');
    }
  }
  final String id, title, appLink;
  final DateTime date;
  final DateTime? until;
  final int startMinute, endMinute;
  final int? reminderMinutes;
  final String? goalId, taskId;
  final MLPRepeat repeat;
  int get minutes => endMinute - startMinute;
  bool occursOn(DateTime value) {
    final day = mlpDay(value);
    if (day.isBefore(date) || (until != null && day.isAfter(until!))) {
      return false;
    }
    return switch (repeat) {
      MLPRepeat.once => day == date,
      MLPRepeat.daily => true,
      MLPRepeat.weekdays => day.weekday <= 5,
      MLPRepeat.weekly => day.weekday == date.weekday,
    };
  }

  DateTime startOn(DateTime day) => DateTime(
    day.year,
    day.month,
    day.day,
    startMinute ~/ 60,
    startMinute % 60,
  );
  DateTime endOn(DateTime day) =>
      DateTime(day.year, day.month, day.day, endMinute ~/ 60, endMinute % 60);
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': mlpDayKey(date),
    'start': startMinute,
    'end': endMinute,
    'repeat': repeat.name,
    'until': until == null ? null : mlpDayKey(until!),
    'goalId': goalId,
    'taskId': taskId,
    'reminder': reminderMinutes,
    'appLink': appLink,
  };
  factory MLPSchedule.fromJson(Map<String, dynamic> json) => MLPSchedule(
    id: json['id'] as String,
    title: json['title'] as String,
    date: _readDay(json['date']),
    startMinute: json['start'] as int,
    endMinute: json['end'] as int,
    repeat: MLPRepeat.values.byName(json['repeat'] as String),
    until: json['until'] == null ? null : _readDay(json['until']),
    goalId: json['goalId'] as String?,
    taskId: json['taskId'] as String?,
    reminderMinutes: json['reminder'] as int?,
    appLink: json['appLink'] as String? ?? '',
  );
}

class MLPScheduleResult {
  MLPScheduleResult({
    required this.scheduleId,
    required DateTime day,
    required this.note,
    required this.reportedAt,
    this.evidenceUrl = '',
  }) : day = mlpDay(day) {
    if (note.trim().length < 10 || note.length > 2000 || scheduleId.isEmpty) {
      throw ArgumentError('Natijani 10–2000 belgi bilan yozing.');
    }
    if (!mlpWebLink(evidenceUrl)) {
      throw ArgumentError('Dalil uchun http yoki https havola kiriting.');
    }
  }
  final String scheduleId, note, evidenceUrl;
  final DateTime day, reportedAt;
  Map<String, dynamic> toJson() => {
    'scheduleId': scheduleId,
    'day': mlpDayKey(day),
    'note': note,
    'evidenceUrl': evidenceUrl,
    'reportedAt': reportedAt.toIso8601String(),
    'kind': 'self-report',
  };
  factory MLPScheduleResult.fromJson(Map<String, dynamic> json) {
    if (json['kind'] != 'self-report') {
      throw const FormatException('Hisobot turi mos emas.');
    }
    return MLPScheduleResult(
      scheduleId: json['scheduleId'] as String,
      day: _readDay(json['day']),
      note: json['note'] as String,
      evidenceUrl: json['evidenceUrl'] as String? ?? '',
      reportedAt: DateTime.parse(json['reportedAt'] as String),
    );
  }
}

abstract interface class MLPScheduleRepository {
  List<MLPSchedule> get schedules;
  List<MLPScheduleResult> get scheduleResults;
  Future<void> saveSchedule(MLPSchedule value);
  Future<void> deleteSchedule(String id);
  Future<void> saveScheduleResult(MLPScheduleResult result);
}

abstract final class MLPPlannerMath {
  /// Repeat rules have a seven-day period. Check each pair at their common
  /// start (even when a different series starts years later), bounded by until.
  static List<({MLPSchedule schedule, DateTime day})> conflicts(
    MLPSchedule candidate,
    Iterable<MLPSchedule> schedules,
  ) {
    final found = <({MLPSchedule schedule, DateTime day})>[];
    for (final other in schedules) {
      if (candidate.id == other.id ||
          candidate.startMinute >= other.endMinute ||
          candidate.endMinute <= other.startMinute) {
        continue;
      }
      final start = candidate.date.isAfter(other.date)
          ? candidate.date
          : other.date;
      final days = candidate.repeat == MLPRepeat.once
          ? [candidate.date]
          : other.repeat == MLPRepeat.once
          ? [other.date]
          : List.generate(
              7,
              (i) => DateTime(start.year, start.month, start.day + i),
            );
      for (final day in days) {
        if (candidate.occursOn(day) && other.occursOn(day)) {
          found.add((schedule: other, day: day));
          break;
        }
      }
    }
    return found;
  }

  /// A task's estimate is counted once; short calendar blocks do not hide its
  /// remaining workload, while longer/multiple blocks still count in full.
  static int loadMinutes(
    Iterable<MLPSchedule> schedules,
    DateTime day,
    Map<String, int> taskMinutes,
  ) {
    final linked = <String, int>{};
    var total = 0;
    for (final item in schedules.where((s) => s.occursOn(day))) {
      total += item.minutes;
      if (item.taskId != null) {
        linked.update(
          item.taskId!,
          (n) => n + item.minutes,
          ifAbsent: () => item.minutes,
        );
      }
    }
    for (final task in taskMinutes.entries) {
      final rest = task.value - (linked[task.key] ?? 0);
      if (rest > 0) total += rest;
    }
    return total;
  }
}
