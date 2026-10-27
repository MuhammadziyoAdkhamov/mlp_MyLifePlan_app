import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline demo data lives in one separate key. Legacy MPL data is never read
/// or changed by this store.
class DemoTask {
  const DemoTask({
    required this.id,
    required this.title,
    required this.project,
    required this.minutes,
    required this.dueDate,
    this.priority = 2,
    this.completed = false,
    this.proof = '',
    this.evidenceUrl = '',
    this.completedAt,
    this.goalId,
  });

  final String id, title, project, proof, evidenceUrl;
  final int minutes, priority;
  final DateTime dueDate;
  final bool completed;
  final DateTime? completedAt;
  final String? goalId;

  DemoTask copyWith({
    String? title,
    String? project,
    int? minutes,
    int? priority,
    DateTime? dueDate,
    bool? completed,
    String? proof,
    String? evidenceUrl,
    DateTime? completedAt,
    String? goalId,
    bool clearGoal = false,
  }) => DemoTask(
    id: id,
    title: title ?? this.title,
    project: project ?? this.project,
    minutes: minutes ?? this.minutes,
    priority: priority ?? this.priority,
    dueDate: dueDate ?? this.dueDate,
    completed: completed ?? this.completed,
    proof: proof ?? this.proof,
    evidenceUrl: evidenceUrl ?? this.evidenceUrl,
    completedAt: completed == false ? null : completedAt ?? this.completedAt,
    goalId: clearGoal ? null : goalId ?? this.goalId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'project': project,
    'minutes': minutes,
    'dueDate': DemoStore.dayKey(dueDate),
    'priority': priority,
    'completed': completed,
    'proof': proof,
    'evidenceUrl': evidenceUrl,
    'completedAt': completedAt?.toIso8601String(),
    'goalId': goalId,
  };
}

/// A saved day's definition survives later changes to an existing habit.
class DemoHabitDayRule {
  const DemoHabitDayRule({required this.target, required this.unit});

  final int target;
  final String unit;

  Map<String, dynamic> toJson() => {'target': target, 'unit': unit};
}

class DemoHabit {
  DemoHabit({
    required this.id,
    required this.title,
    this.unit = 'marta',
    this.target = 1,
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
    Map<String, int> logs = const {},
    Map<String, String> reasons = const {},
    Map<String, DemoHabitDayRule> historyRules = const {},
    this.goalId,
  }) : weekdays = List.unmodifiable(weekdays),
       logs = Map.unmodifiable(logs),
       reasons = Map.unmodifiable(reasons),
       historyRules = Map.unmodifiable(historyRules);

  final String id, title, unit;
  final int target;
  final List<int> weekdays;
  final Map<String, int> logs;
  final Map<String, String> reasons;
  final Map<String, DemoHabitDayRule> historyRules;
  final String? goalId;

  int targetForDate(DateTime date) =>
      historyRules[DemoStore.dayKey(date)]?.target ?? target;

  String unitForDate(DateTime date) =>
      historyRules[DemoStore.dayKey(date)]?.unit ?? unit;

  bool scheduledOn(DateTime date) =>
      historyRules.containsKey(DemoStore.dayKey(date)) ||
      weekdays.contains(date.weekday);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'unit': unit,
    'target': target,
    'weekdays': weekdays,
    'logs': logs,
    'reasons': reasons,
    'goalId': goalId,
    'historyRules': historyRules.map(
      (date, rule) => MapEntry(date, rule.toJson()),
    ),
  };

  DemoHabit _withLogs(Map<String, int> values, Map<String, String> notes) =>
      DemoHabit(
        id: id,
        title: title,
        unit: unit,
        target: target,
        weekdays: weekdays,
        logs: values,
        reasons: notes,
        historyRules: {
          for (final entry in historyRules.entries)
            if (values.containsKey(entry.key) || notes.containsKey(entry.key))
              entry.key: entry.value,
        },
        goalId: goalId,
      );
}

class DemoGoal {
  const DemoGoal({
    required this.id,
    required this.title,
    required this.metric,
    required this.target,
    required this.current,
    required this.deadline,
    required this.category,
  });

  final String id, title, metric, category;
  final int target, current;
  final DateTime deadline;

  double get progress => target == 0 ? 0 : current / target;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'metric': metric,
    'target': target,
    'current': current,
    'deadline': DemoStore.dayKey(deadline),
    'category': category,
  };
}

class FocusRecord {
  const FocusRecord({
    required this.taskId,
    required this.seconds,
    required this.date,
  });
  final String? taskId;
  final int seconds;
  final DateTime date;
  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'seconds': seconds,
    'date': date.toIso8601String(),
  };
}

class DailyCheckin {
  const DailyCheckin({
    required this.date,
    required this.mood,
    required this.energy,
    required this.note,
  });
  final DateTime date;
  final int mood, energy;
  final String note;
  Map<String, dynamic> toJson() => {
    'date': DemoStore.dayKey(date),
    'mood': mood,
    'energy': energy,
    'note': note,
  };
}

class DemoStore extends ChangeNotifier {
  DemoStore(this._prefs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const storageKey = 'mpl_lifeos_demo_v1';
  static const _schema = 'mpl.lifeos.demo';
  static const _maxImportBytes = 2 * 1024 * 1024;
  final SharedPreferences _prefs;
  final DateTime Function() _now;
  List<DemoTask> _tasks = [];
  List<DemoHabit> _habits = [];
  List<DemoGoal> _goals = [];
  List<FocusRecord> _focus = [];
  List<DailyCheckin> _checkins = [];
  bool _isSampleData = false;
  bool _initialized = false;
  bool _corrupt = false;
  int _serial = 0;
  bool _planWriting = false;
  Future<void> _writeQueue = Future.value();
  String? storageError;

  bool get initialized => _initialized;
  bool get isSampleData => _isSampleData;
  DateTime get today => _date(_now());
  String get todayKey => dayKey(today);
  List<DemoTask> get tasks => List.unmodifiable(_tasks);
  List<DemoHabit> get habits => List.unmodifiable(_habits);
  List<DemoGoal> get goals => List.unmodifiable(_goals);
  List<FocusRecord> get focusSessions => List.unmodifiable(_focus);
  List<DailyCheckin> get checkins => List.unmodifiable(_checkins);
  DailyCheckin? get latestCheckin {
    if (_checkins.isEmpty) return null;
    return _checkins.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }

  DailyCheckin? get todayCheckin {
    for (final item in _checkins) {
      if (dayKey(item.date) == todayKey) return item;
    }
    return null;
  }

  /// Includes overdue work so unfinished tasks cannot disappear from Today.
  List<DemoTask> get todayTasks {
    final result = _tasks
        .where(
          (task) =>
              !task.dueDate.isAfter(today) &&
              (!task.completed ||
                  dayKey(task.completedAt ?? task.dueDate) == todayKey),
        )
        .toList();
    result.sort((a, b) {
      if (a.completed != b.completed) return a.completed ? 1 : -1;
      final priority = a.priority.compareTo(b.priority);
      return priority != 0 ? priority : a.dueDate.compareTo(b.dueDate);
    });
    return List.unmodifiable(result);
  }

  int get todayCompleted => _tasks
      .where(
        (t) => t.completed && dayKey(t.completedAt ?? t.dueDate) == todayKey,
      )
      .length;
  int get todayFocusMinutes => focusMinutesForDay(today);
  int get level => 1 + xp ~/ 250;
  int get xp {
    final habitAwards = _habits.fold<int>(
      0,
      (sum, habit) =>
          sum +
          habit.logs.entries
                  .where(
                    (e) =>
                        e.value >= habit.targetForDate(DateTime.parse(e.key)) &&
                        habit.scheduledOn(DateTime.parse(e.key)),
                  )
                  .length *
              15,
    );
    return _tasks.where((t) => t.completed).length * 40 +
        habitAwards +
        _goals.where((g) => g.current >= g.target).length * 100 +
        _focus.fold<int>(0, (sum, f) => sum + f.seconds ~/ 60) +
        _checkins.length * 10;
  }

  int get streak {
    final active = <String>{
      for (final task in _tasks)
        if (task.completed) dayKey(task.completedAt ?? task.dueDate),
      for (final habit in _habits)
        for (final entry in habit.logs.entries)
          if (entry.value > 0) entry.key,
      for (final focus in _focus)
        if (focus.seconds >= 60) dayKey(focus.date),
      for (final checkin in _checkins) dayKey(checkin.date),
    };
    var cursor = today;
    if (!active.contains(dayKey(cursor))) cursor = _shift(cursor, -1);
    var count = 0;
    while (active.contains(dayKey(cursor))) {
      count++;
      cursor = _shift(cursor, -1);
    }
    return count;
  }

  /// A transparent daily score: 70% planned actions, 20% focus, 10% check-in.
  int get score =>
      (completionForDay(today) * 70 +
              (todayFocusMinutes / 25).clamp(0, 1) * 20 +
              (todayCheckin == null ? 0 : 10))
          .round();

  static String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  static DateTime _date(DateTime value) =>
      DateTime(value.year, value.month, value.day);
  static DateTime _shift(DateTime value, int days) =>
      DateTime(value.year, value.month, value.day + days);

  Future<void> init() async {
    if (_initialized) return;
    final raw = _prefs.get(storageKey);
    if (raw == null) {
      _seed();
      await _persist();
    } else {
      try {
        if (raw is! String) {
          throw const FormatException('Saqlov turi noto‘g‘ri.');
        }
        _apply(_decode(raw));
      } on FormatException catch (error) {
        // Preserve the raw saved value until an explicit clear or import.
        _corrupt = true;
        storageError = 'Saqlangan ma’lumotni o‘qib bo‘lmadi: ${error.message}';
      }
    }
    _initialized = true;
    notifyListeners();
  }

  String _id(String prefix) {
    String id;
    do {
      id = '$prefix-${_now().microsecondsSinceEpoch}-${_serial++}';
    } while (_tasks.any((t) => t.id == id) ||
        _habits.any((h) => h.id == id) ||
        _goals.any((g) => g.id == id));
    return id;
  }

  void _ensureWritable() {
    if (_planWriting) {
      throw StateError(
        'Reja saqlanmoqda. Bir ozdan keyin qayta urinib ko‘ring.',
      );
    }
    if (_corrupt) {
      throw StateError(
        'Saqlov buzilgan. JSON import qiling yoki ma’lumotlarni tozalang.',
      );
    }
  }

  Future<void> _changed() {
    notifyListeners();
    return _persist();
  }

  Future<void> _persist() {
    final snapshot = exportJson();
    final write = _writeQueue.then((_) async {
      try {
        if (!await _prefs.setString(storageKey, snapshot)) {
          throw StateError('Mahalliy saqlov yozuvni qabul qilmadi.');
        }
      } catch (_) {
        storageError = 'Ma’lumotni qurilmaga saqlab bo‘lmadi.';
        try {
          await _prefs.reload();
        } catch (_) {
          storageError =
              'Saqlov keshini ham tiklab bo‘lmadi. Ilovani qayta oching.';
        }
        notifyListeners();
        rethrow;
      }
      final hadError = storageError != null;
      storageError = null;
      if (hadError) notifyListeners();
    });
    // A failed platform write must not poison all subsequent writes.
    _writeQueue = write.catchError((Object _) {});
    return write;
  }

  /// Retry saving the visible in-memory state after a platform write failure.
  Future<void> retrySave() {
    _ensureWritable();
    return _persist();
  }

  Future<void> addTask({
    required String title,
    String project = 'Shaxsiy',
    int minutes = 25,
    int priority = 2,
    DateTime? dueDate,
    String? goalId,
  }) {
    _ensureWritable();
    _text(title.trim(), 'Vazifa', min: 2, max: 160);
    _text(project.trim(), 'Loyiha', min: 1, max: 80);
    _range(minutes, 'Daqiqa', 1, 1440);
    _range(priority, 'Ustuvorlik', 1, 3);
    final day = _day(dayKey(dueDate ?? today));
    _validGoalReference(goalId);
    _tasks.add(
      DemoTask(
        id: _id('task'),
        title: title.trim(),
        project: project.trim(),
        minutes: minutes,
        priority: priority,
        dueDate: day,
        goalId: goalId,
      ),
    );
    return _changed();
  }

  Future<void> editTask(
    String id, {
    String? title,
    String? project,
    int? minutes,
    int? priority,
    DateTime? dueDate,
    String? goalId,
    bool clearGoal = false,
  }) {
    _ensureWritable();
    final i = _taskIndex(id);
    final previous = _tasks[i];
    final next = previous.copyWith(
      title: title?.trim(),
      project: project?.trim(),
      minutes: minutes,
      priority: priority,
      dueDate: dueDate == null ? null : _day(dayKey(dueDate)),
      goalId: goalId,
      clearGoal: clearGoal,
    );
    _text(next.title, 'Vazifa', min: 2, max: 160);
    _text(next.project, 'Loyiha', min: 1, max: 80);
    _range(next.minutes, 'Daqiqa', 1, 1440);
    _range(next.priority, 'Ustuvorlik', 1, 3);
    _validGoalReference(next.goalId);
    _tasks[i] = next;
    return _changed();
  }

  void _validGoalReference(String? goalId) {
    if (goalId != null && !_goals.any((g) => g.id == goalId)) {
      throw ArgumentError('Bog‘langan maqsad topilmadi.');
    }
  }

  Future<void> submitTask(String id, String proof, {String evidenceUrl = ''}) {
    _ensureWritable();
    _text(proof.trim(), 'Natija dalili', min: 10, max: 4000);
    _validUrl(evidenceUrl.trim());
    final i = _taskIndex(id);
    _tasks[i] = _tasks[i].copyWith(
      completed: true,
      proof: proof.trim(),
      evidenceUrl: evidenceUrl.trim(),
      completedAt: _tasks[i].completedAt ?? _now(),
    );
    return _changed();
  }

  Future<void> reopenTask(String id) {
    _ensureWritable();
    final i = _taskIndex(id);
    _tasks[i] = _tasks[i].copyWith(
      completed: false,
      proof: '',
      evidenceUrl: '',
    );
    return _changed();
  }

  Future<void> deferTask(String id) {
    _ensureWritable();
    final i = _taskIndex(id);
    if (_tasks[i].completed) {
      throw StateError('Bajarilgan vazifani ko‘chirib bo‘lmaydi.');
    }
    _tasks[i] = _tasks[i].copyWith(
      dueDate: _shift(
        _tasks[i].dueDate.isAfter(today) ? _tasks[i].dueDate : today,
        1,
      ),
    );
    return _changed();
  }

  Future<void> deleteTask(String id) {
    _ensureWritable();
    _tasks.removeAt(_taskIndex(id));
    return _changed();
  }

  int _taskIndex(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index < 0) throw StateError('Vazifa topilmadi.');
    return index;
  }

  Future<void> addHabit({
    required String title,
    String unit = 'marta',
    int target = 1,
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
    String? goalId,
  }) {
    _ensureWritable();
    _text(title.trim(), 'Odat', min: 2, max: 160);
    _text(unit.trim(), 'Birlik', min: 1, max: 30);
    _range(target, 'Kunlik maqsad', 1, 1000000);
    _weekdays(weekdays);
    if (goalId != null && !_goals.any((g) => g.id == goalId)) {
      throw ArgumentError('Bog‘langan maqsad topilmadi.');
    }
    _habits.add(
      DemoHabit(
        id: _id('habit'),
        title: title.trim(),
        unit: unit.trim(),
        target: target,
        weekdays: weekdays,
        goalId: goalId,
      ),
    );
    return _changed();
  }

  List<DemoHabit> scheduledHabits([DateTime? date]) =>
      List.unmodifiable(_habits.where((h) => h.scheduledOn(date ?? today)));

  int habitValue(String id, [DateTime? date]) =>
      _habits[_habitIndex(id)].logs[dayKey(date ?? today)] ?? 0;

  double habitProgress(DemoHabit habit, [DateTime? date]) =>
      ((habit.logs[dayKey(date ?? today)] ?? 0) /
              habit.targetForDate(date ?? today))
          .clamp(0, 1);

  Future<void> editHabit(
    String id, {
    String? title,
    String? unit,
    int? target,
    List<int>? weekdays,
    String? goalId,
    bool clearGoal = false,
  }) {
    _ensureWritable();
    final i = _habitIndex(id);
    final previous = _habits[i];
    final nextTitle = title?.trim() ?? previous.title;
    final nextUnit = unit?.trim() ?? previous.unit;
    final nextTarget = target ?? previous.target;
    final nextDays = weekdays ?? previous.weekdays;
    _text(nextTitle, 'Odat', min: 2, max: 160);
    _text(nextUnit, 'Birlik', min: 1, max: 30);
    _range(nextTarget, 'Kunlik maqsad', 1, 1000000);
    _weekdays(nextDays);
    final nextGoalId = clearGoal ? null : goalId ?? previous.goalId;
    _validGoalReference(nextGoalId);
    final history = {...previous.historyRules};
    if (nextUnit != previous.unit ||
        nextTarget != previous.target ||
        !setEquals(nextDays.toSet(), previous.weekdays.toSet())) {
      for (final date in {...previous.logs.keys, ...previous.reasons.keys}) {
        history.putIfAbsent(
          date,
          () => DemoHabitDayRule(target: previous.target, unit: previous.unit),
        );
      }
    }
    _habits[i] = DemoHabit(
      id: previous.id,
      title: nextTitle,
      unit: nextUnit,
      target: nextTarget,
      weekdays: nextDays,
      logs: previous.logs,
      reasons: previous.reasons,
      historyRules: history,
      goalId: nextGoalId,
    );
    return _changed();
  }

  Future<void> deleteHabit(String id) {
    _ensureWritable();
    _habits.removeAt(_habitIndex(id));
    return _changed();
  }

  Future<void> incrementHabit(String id) {
    _ensureWritable();
    final i = _habitIndex(id);
    final habit = _habits[i];
    if (!habit.scheduledOn(today)) {
      throw StateError('Bu odat bugungi jadvalga kiritilmagan.');
    }
    final value = habit.logs[todayKey] ?? 0;
    if (value >= habit.targetForDate(today)) return Future.value();
    _habits[i] = habit._withLogs({
      ...habit.logs,
      todayKey: value + 1,
    }, {...habit.reasons}..remove(todayKey));
    return _changed();
  }

  Future<void> undoHabit(String id) {
    _ensureWritable();
    final i = _habitIndex(id);
    final habit = _habits[i];
    final value = habit.logs[todayKey] ?? 0;
    if (value == 0) return Future.value();
    final logs = {...habit.logs};
    if (value == 1) {
      logs.remove(todayKey);
    } else {
      logs[todayKey] = value - 1;
    }
    _habits[i] = habit._withLogs(logs, {...habit.reasons});
    return _changed();
  }

  Future<void> skipHabit(String id, String reason) {
    _ensureWritable();
    _text(reason.trim(), 'Sabab', min: 3, max: 500);
    final i = _habitIndex(id);
    final habit = _habits[i];
    if (!habit.scheduledOn(today)) {
      throw StateError('Bu odat bugungi jadvalga kiritilmagan.');
    }
    _habits[i] = habit._withLogs({...habit.logs}..remove(todayKey), {
      ...habit.reasons,
      todayKey: reason.trim(),
    });
    return _changed();
  }

  int _habitIndex(String id) {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index < 0) throw StateError('Odat topilmadi.');
    return index;
  }

  /// Unscheduled days do not break a streak. An unfinished scheduled today is
  /// allowed until the day ends; a missed previous scheduled day breaks it.
  int habitStreak(String id) {
    final habit = _habits[_habitIndex(id)];
    var cursor = today;
    var count = 0;
    final completedKeys = habit.logs.entries
        .where((e) => e.value >= habit.targetForDate(DateTime.parse(e.key)))
        .map((e) => e.key)
        .toSet();
    if (completedKeys.isEmpty) return 0;
    final earliest = completedKeys.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
    while (dayKey(cursor).compareTo(earliest) >= 0) {
      if (habit.scheduledOn(cursor)) {
        if (completedKeys.contains(dayKey(cursor))) {
          count++;
        } else if (cursor != today) {
          break;
        }
      }
      cursor = _shift(cursor, -1);
    }
    return count;
  }

  Future<void> addGoal({
    required String title,
    required String metric,
    required int target,
    required DateTime deadline,
    String category = 'Shaxsiy',
  }) {
    _ensureWritable();
    _text(title.trim(), 'Maqsad', min: 2, max: 160);
    _text(metric.trim(), 'O‘lchov', min: 1, max: 40);
    _text(category.trim(), 'Yo‘nalish', min: 1, max: 60);
    _range(target, 'Maqsad natijasi', 1, 1000000000);
    final day = _day(dayKey(deadline));
    _goals.add(
      DemoGoal(
        id: _id('goal'),
        title: title.trim(),
        metric: metric.trim(),
        target: target,
        current: 0,
        deadline: day,
        category: category.trim(),
      ),
    );
    return _changed();
  }

  /// A roadmap goal and its initial tasks are one local write, never a series
  /// of partially created goals. Existing standalone CRUD remains compatible.
  Future<String> addGoalPlan({
    required String title,
    required String category,
    required DateTime deadline,
    required List<({String title, int minutes, DateTime date})> steps,
  }) async {
    _ensureWritable();
    _text(title.trim(), 'Maqsad', min: 2, max: 160);
    _text(category.trim(), 'Yo‘nalish', min: 1, max: 60);
    _range(steps.length, 'Bosqichlar', 1, 30);
    final lastDay = _day(dayKey(deadline));
    for (final step in steps) {
      _text(step.title.trim(), 'Vazifa', min: 2, max: 160);
      _range(step.minutes, 'Daqiqa', 1, 1440);
      if (_day(dayKey(step.date)).isAfter(lastDay)) {
        throw ArgumentError('Vazifa maqsad muddatidan keyin bo‘lmasin.');
      }
    }
    _planWriting = true;
    try {
      await _writeQueue;
      final id = _id('goal');
      final added = <String>{};
      _goals.add(
        DemoGoal(
          id: id,
          title: title.trim(),
          metric: 'bosqich (o‘z hisoboti)',
          target: steps.length,
          current: 0,
          deadline: lastDay,
          category: category,
        ),
      );
      for (final step in steps) {
        final taskId = _id('task');
        added.add(taskId);
        _tasks.add(
          DemoTask(
            id: taskId,
            title: step.title.trim(),
            project: category,
            minutes: step.minutes,
            dueDate: _day(dayKey(step.date)),
            goalId: id,
          ),
        );
      }
      try {
        await _persist();
        notifyListeners();
        return id;
      } catch (_) {
        _goals.removeWhere((goal) => goal.id == id);
        _tasks.removeWhere((task) => added.contains(task.id));
        notifyListeners();
        rethrow;
      }
    } finally {
      _planWriting = false;
    }
  }

  Future<void> editGoal(
    String id, {
    String? title,
    String? metric,
    int? target,
    DateTime? deadline,
    String? category,
  }) {
    _ensureWritable();
    final i = _goalIndex(id);
    final previous = _goals[i];
    final next = DemoGoal(
      id: previous.id,
      title: title?.trim() ?? previous.title,
      metric: metric?.trim() ?? previous.metric,
      target: target ?? previous.target,
      current: previous.current,
      deadline: deadline == null ? previous.deadline : _day(dayKey(deadline)),
      category: category?.trim() ?? previous.category,
    );
    _text(next.title, 'Maqsad', min: 2, max: 160);
    _text(next.metric, 'O‘lchov', min: 1, max: 40);
    _text(next.category, 'Yo‘nalish', min: 1, max: 60);
    _range(next.target, 'Maqsad natijasi', 1, 1000000000);
    if (next.target < next.current) {
      throw ArgumentError(
        'Maqsad natijasi saqlangan joriy qiymatdan kichik bo‘lmasin.',
      );
    }
    _goals[i] = next;
    return _changed();
  }

  Future<void> deleteGoal(String id) {
    _ensureWritable();
    final i = _goalIndex(id);
    _goals.removeAt(i);
    _tasks = [
      for (final task in _tasks)
        task.goalId == id ? task.copyWith(clearGoal: true) : task,
    ];
    _habits = [
      for (final habit in _habits)
        if (habit.goalId == id)
          DemoHabit(
            id: habit.id,
            title: habit.title,
            unit: habit.unit,
            target: habit.target,
            weekdays: habit.weekdays,
            logs: habit.logs,
            reasons: habit.reasons,
            historyRules: habit.historyRules,
          )
        else
          habit,
    ];
    return _changed();
  }

  int _goalIndex(String id) {
    final index = _goals.indexWhere((goal) => goal.id == id);
    if (index < 0) throw StateError('Maqsad topilmadi.');
    return index;
  }

  /// Linked actions describe work; numeric goal units remain manually reported.
  int goalTaskCount(String goalId) =>
      _tasks.where((task) => task.goalId == goalId).length;

  int goalCompletedTaskCount(String goalId) =>
      _tasks.where((task) => task.goalId == goalId && task.completed).length;

  Future<void> progressGoal(String id, int value) {
    _ensureWritable();
    final i = _goalIndex(id);
    final goal = _goals[i];
    _goals[i] = DemoGoal(
      id: goal.id,
      title: goal.title,
      metric: goal.metric,
      target: goal.target,
      current: value.clamp(0, goal.target),
      deadline: goal.deadline,
      category: goal.category,
    );
    return _changed();
  }

  Future<void> addFocusSession({String? taskId, required int seconds}) {
    _ensureWritable();
    _range(seconds, 'Fokus davomiyligi', 1, 86400);
    if (taskId != null) _taskIndex(taskId);
    _focus.add(FocusRecord(taskId: taskId, seconds: seconds, date: _now()));
    return _changed();
  }

  int focusMinutesForDay(DateTime date) =>
      _focus
          .where((f) => dayKey(f.date) == dayKey(date))
          .fold<int>(0, (sum, f) => sum + f.seconds) ~/
      60;

  Future<void> saveCheckin({
    required int mood,
    required int energy,
    String note = '',
  }) {
    _ensureWritable();
    _range(mood, 'Kayfiyat', 1, 5);
    _range(energy, 'Energiya', 1, 5);
    _text(note.trim(), 'Izoh', max: 2000);
    _checkins.removeWhere((c) => dayKey(c.date) == todayKey);
    _checkins.add(
      DailyCheckin(date: today, mood: mood, energy: energy, note: note.trim()),
    );
    return _changed();
  }

  /// A ratio in [0, 1] over scheduled tasks and habits on a calendar date.
  double completionForDay(DateTime date) {
    final key = dayKey(date);
    final dayTasks = _tasks.where((t) => dayKey(t.dueDate) == key).toList();
    final dayHabits = scheduledHabits(date);
    final total = dayTasks.length + dayHabits.length;
    if (total == 0) return 0;
    final done =
        dayTasks
            .where(
              (t) =>
                  t.completed &&
                  !(_date(t.completedAt ?? t.dueDate).isAfter(_date(date))),
            )
            .length +
        dayHabits
            .where((h) => (h.logs[key] ?? 0) >= h.targetForDate(date))
            .length;
    return done / total;
  }

  List<String> get weeklyReview {
    final start = _shift(today, -6);
    final completed = _tasks
        .where(
          (t) =>
              t.completed &&
              !(t.completedAt ?? t.dueDate).isBefore(start) &&
              !(t.completedAt ?? t.dueDate).isAfter(_now()),
        )
        .length;
    final focusMinutes =
        _focus
            .where((f) => !f.date.isBefore(start) && !f.date.isAfter(_now()))
            .fold<int>(0, (sum, f) => sum + f.seconds) ~/
        60;
    var scheduled = 0;
    var done = 0;
    for (var offset = 0; offset < 7; offset++) {
      final date = _shift(start, offset);
      for (final habit in scheduledHabits(date)) {
        scheduled++;
        if ((habit.logs[dayKey(date)] ?? 0) >= habit.targetForDate(date)) {
          done++;
        }
      }
    }
    final overdue = _tasks
        .where((t) => !t.completed && t.dueDate.isBefore(today))
        .length;
    return List.unmodifiable([
      'Oxirgi 7 kunda $completed ta vazifa topshirildi, $focusMinutes daqiqa fokus qilindi.',
      scheduled == 0
          ? 'Hali odat jadvali yo‘q. Bitta kichik odatdan boshlang.'
          : 'Odatlar: $done / $scheduled bajarildi (${(done / scheduled * 100).round()}%).',
      overdue > 0
          ? '$overdue ta vazifa kechikkan. Bugun eng muhim bittasini tanlang.'
          : 'Kechikkan vazifa yo‘q. Ertangi birinchi natijani oldindan belgilang.',
      if (_checkins.isNotEmpty && (todayCheckin?.energy ?? 5) <= 2)
        'Bugun energiya past: vazifani 5 daqiqalik eng kichik qadamga bo‘ling.',
    ]);
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
    'schema': _schema,
    'version': 1,
    'isSampleData': _isSampleData,
    'tasks': _tasks.map((t) => t.toJson()).toList(),
    'habits': _habits.map((h) => h.toJson()).toList(),
    'goals': _goals.map((g) => g.toJson()).toList(),
    'focusSessions': _focus.map((f) => f.toJson()).toList(),
    'checkins': _checkins.map((c) => c.toJson()).toList(),
  });

  Future<void> importJson(String source) async {
    if (_planWriting) throw StateError('Avval reja saqlanishini kuting.');
    // Decode and validate the entire document before touching live state.
    final data = _decode(source);
    final previous = exportJson();
    final previouslyCorrupt = _corrupt;
    _apply(data);
    _corrupt = false;
    try {
      await _persist();
    } catch (_) {
      _apply(_decode(previous));
      _corrupt = previouslyCorrupt;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> clearAll() {
    if (_planWriting) throw StateError('Avval reja saqlanishini kuting.');
    _tasks = [];
    _habits = [];
    _goals = [];
    _focus = [];
    _checkins = [];
    _isSampleData = false;
    _corrupt = false;
    return _changed();
  }

  Future<void> loadSample() {
    if (_planWriting) throw StateError('Avval reja saqlanishini kuting.');
    _seed();
    _corrupt = false;
    return _changed();
  }

  void _seed() {
    final day = today;
    _isSampleData = true;
    _tasks = [
      DemoTask(
        id: 'sample-task-1',
        title: 'Portfolio uchun case study qoralamasi',
        project: 'Karyera',
        minutes: 50,
        priority: 1,
        dueDate: day,
        goalId: 'sample-goal-2',
      ),
      DemoTask(
        id: 'sample-task-2',
        title: '20 ta inglizcha so‘zni misol bilan yozish',
        project: 'Ingliz tili',
        minutes: 25,
        priority: 2,
        dueDate: day,
        goalId: 'sample-goal-3',
      ),
      DemoTask(
        id: 'sample-task-3',
        title: '30 daqiqa kuch mashqi',
        project: 'Sog‘liq',
        minutes: 30,
        priority: 2,
        dueDate: day,
      ),
      DemoTask(
        id: 'sample-task-4',
        title: 'Bugungi eng muhim natijani belgilash',
        project: 'Shaxsiy',
        minutes: 5,
        priority: 1,
        dueDate: day,
        completed: true,
        proof: 'Portfolio case study qoralamasini tugatishni tanladim.',
        completedAt: DateTime(day.year, day.month, day.day, 8),
      ),
      DemoTask(
        id: 'sample-task-5',
        title: 'Mentor uchun loyiha savollarini tayyorlash',
        project: 'Karyera',
        minutes: 20,
        priority: 2,
        dueDate: _shift(day, 1),
        goalId: 'sample-goal-2',
      ),
    ];
    final readingLogs = <String, int>{};
    final waterLogs = <String, int>{};
    for (var i = 1; i <= 6; i++) {
      readingLogs[dayKey(_shift(day, -i))] = i == 3 ? 5 : 10;
      waterLogs[dayKey(_shift(day, -i))] = i == 4 ? 4 : 8;
    }
    readingLogs[todayKey] = 3;
    waterLogs[todayKey] = 2;
    _habits = [
      DemoHabit(
        id: 'sample-habit-1',
        title: 'Kitob o‘qish',
        unit: 'bet',
        target: 10,
        logs: readingLogs,
        goalId: 'sample-goal-1',
      ),
      DemoHabit(
        id: 'sample-habit-2',
        title: 'Suv ichish',
        unit: 'stakan',
        target: 8,
        logs: waterLogs,
      ),
      DemoHabit(
        id: 'sample-habit-3',
        title: 'Ertalabki harakat',
        unit: 'marta',
        target: 1,
        weekdays: const [1, 2, 3, 4, 5],
        logs: {
          for (var i = 1; i <= 6; i++)
            if (_shift(day, -i).weekday <= 5) dayKey(_shift(day, -i)): 1,
        },
      ),
    ];
    _goals = [
      DemoGoal(
        id: 'sample-goal-1',
        title: '12 ta kitob o‘qish',
        metric: 'kitob',
        target: 12,
        current: 4,
        deadline: DateTime(day.year + 1, 1, 1),
        category: 'Rivojlanish',
      ),
      DemoGoal(
        id: 'sample-goal-2',
        title: 'Portfolio va ilk mijozlar',
        metric: 'case study',
        target: 5,
        current: 2,
        deadline: _shift(day, 60),
        category: 'Karyera',
      ),
      DemoGoal(
        id: 'sample-goal-3',
        title: 'Ingliz tilida ishonchli gapirish',
        metric: 'dars',
        target: 40,
        current: 14,
        deadline: _shift(day, 90),
        category: 'Ta’lim',
      ),
    ];
    _focus = [
      FocusRecord(
        taskId: 'sample-task-1',
        seconds: 1500,
        date: DateTime(day.year, day.month, day.day, 9),
      ),
      for (var i = 1; i <= 6; i++)
        FocusRecord(
          taskId: null,
          seconds: i.isEven ? 3000 : 1500,
          date: _shift(day, -i),
        ),
    ];
    _checkins = [
      DailyCheckin(
        date: _shift(day, -1),
        mood: 4,
        energy: 3,
        note: 'Kichik qadamlar bilan oldinga yurdim.',
      ),
    ];
  }

  static void _text(String value, String label, {int min = 0, int max = 4000}) {
    if (value.trim().length < min || value.length > max) {
      throw ArgumentError('$label $min–$max belgi bo‘lishi kerak.');
    }
  }

  static void _range(int value, String label, int min, int max) {
    if (value < min || value > max) {
      throw ArgumentError('$label $min–$max oralig‘ida bo‘lsin.');
    }
  }

  static void _weekdays(List<int> values) {
    if (values.isEmpty ||
        values.length > 7 ||
        values.toSet().length != values.length ||
        values.any((v) => v < 1 || v > 7)) {
      throw ArgumentError(
        'Hafta kunlari 1–7 oralig‘ida va takrorlanmas bo‘lsin.',
      );
    }
  }

  static void _validUrl(String value) {
    if (value.isEmpty) return;
    final uri = Uri.tryParse(value);
    if (value.length > 2048 ||
        uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw ArgumentError('Dalil havolasi http yoki https manzil bo‘lsin.');
    }
  }

  static Map<String, dynamic> _decode(String source) {
    try {
      if (utf8.encode(source).length > _maxImportBytes) {
        throw const FormatException('Fayl 2 MB dan katta.');
      }
      final json = jsonDecode(source);
      final root = _object(json);
      if (root['schema'] != _schema ||
          root['version'] != 1 ||
          root['version'] is! int) {
        throw const FormatException('MPL demo v1 formati kerak.');
      }
      if (root['isSampleData'] is! bool) {
        throw const FormatException('Demo belgisi noto‘g‘ri.');
      }
      final taskIds = <String>{};
      for (final row in _list(root, 'tasks')) {
        final t = _object(row);
        _unique(_string(t, 'id', 1, 120), taskIds);
        _string(t, 'title', 2, 160);
        _string(t, 'project', 1, 80);
        _integer(t, 'minutes', 1, 1440);
        _integer(t, 'priority', 1, 3);
        _day(t['dueDate']);
        if (t['completed'] is! bool) {
          throw const FormatException('Vazifa holati noto‘g‘ri.');
        }
        final proof = _string(t, 'proof', 0, 4000);
        _validUrl(_string(t, 'evidenceUrl', 0, 2048));
        if (t['completed'] == true) {
          if (proof.trim().length < 10) {
            throw const FormatException('Bajarilgan vazifada dalil yo‘q.');
          }
          _timestamp(t['completedAt']);
        } else if (t['completedAt'] != null) {
          throw const FormatException(
            'Bajarilmagan vazifada topshirilgan vaqt bor.',
          );
        }
      }
      final goalIds = <String>{};
      for (final row in _list(root, 'goals')) {
        final g = _object(row);
        _unique(_string(g, 'id', 1, 120), goalIds);
        _string(g, 'title', 2, 160);
        _string(g, 'metric', 1, 40);
        _string(g, 'category', 1, 60);
        final target = _integer(g, 'target', 1, 1000000000);
        _integer(g, 'current', 0, target);
        _day(g['deadline']);
      }
      for (final row in _list(root, 'tasks')) {
        final task = _object(row);
        if (task['goalId'] != null &&
            (task['goalId'] is! String || !goalIds.contains(task['goalId']))) {
          throw const FormatException('Bog‘langan maqsad topilmadi.');
        }
      }
      final habitIds = <String>{};
      for (final row in _list(root, 'habits')) {
        final h = _object(row);
        _unique(_string(h, 'id', 1, 120), habitIds);
        _string(h, 'title', 2, 160);
        _string(h, 'unit', 1, 30);
        final target = _integer(h, 'target', 1, 1000000);
        final days = h['weekdays'];
        if (days is! List || days.any((d) => d is! int)) {
          throw const FormatException('Hafta kunlari noto‘g‘ri.');
        }
        _weekdays(days.cast<int>());
        final logs = _object(h['logs']);
        final reasons = _object(h['reasons']);
        final history = h['historyRules'] == null
            ? <String, dynamic>{}
            : _object(h['historyRules']);
        if (logs.length > 20000 || reasons.length > 20000) {
          throw const FormatException('Odat tarixi juda katta.');
        }
        if (history.length > 20000) {
          throw const FormatException('Odat qoidalari tarixi juda katta.');
        }
        for (final entry in history.entries) {
          _day(entry.key);
          if (!logs.containsKey(entry.key) && !reasons.containsKey(entry.key)) {
            throw const FormatException('Tarixiy qoidada kun qaydi yo‘q.');
          }
          final rule = _object(entry.value);
          _integer(rule, 'target', 1, 1000000);
          _string(rule, 'unit', 1, 30);
        }
        for (final entry in logs.entries) {
          final date = _day(entry.key);
          final savedRule = history[entry.key];
          final dayTarget = savedRule == null
              ? target
              : _integer(_object(savedRule), 'target', 1, 1000000);
          if (entry.value is! int ||
              (entry.value as int) < 0 ||
              (entry.value as int) > dayTarget ||
              (savedRule == null && !days.contains(date.weekday))) {
            throw const FormatException('Odat qaydi noto‘g‘ri.');
          }
        }
        for (final entry in reasons.entries) {
          final date = _day(entry.key);
          if (entry.value is! String ||
              (!history.containsKey(entry.key) &&
                  !days.contains(date.weekday)) ||
              logs.containsKey(entry.key)) {
            throw const FormatException('Odat sababi noto‘g‘ri.');
          }
          _text(entry.value as String, 'Sabab', min: 3, max: 500);
        }
        if (h['goalId'] != null &&
            (h['goalId'] is! String || !goalIds.contains(h['goalId']))) {
          throw const FormatException('Bog‘langan maqsad topilmadi.');
        }
      }
      for (final row in _list(root, 'focusSessions')) {
        final f = _object(row);
        if (f['taskId'] != null && f['taskId'] is! String) {
          throw const FormatException('Fokus vazifasi noto‘g‘ri.');
        }
        _integer(f, 'seconds', 1, 86400);
        _timestamp(f['date']);
      }
      final checkinDates = <String>{};
      for (final row in _list(root, 'checkins')) {
        final c = _object(row);
        final date = dayKey(_day(c['date']));
        _unique(date, checkinDates);
        _integer(c, 'mood', 1, 5);
        _integer(c, 'energy', 1, 5);
        _string(c, 'note', 0, 2000);
      }
      return root;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException(
        'JSON ma’lumotlari noto‘g‘ri yoki to‘liq emas.',
      );
    }
  }

  static Map<String, dynamic> _object(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Obyekt kutilgan.');
    }
    return value;
  }

  static List<dynamic> _list(Map<String, dynamic> root, String key) {
    final value = root[key];
    if (value is! List || value.length > 5000) {
      throw FormatException('$key ro‘yxati noto‘g‘ri yoki juda katta.');
    }
    return value;
  }

  static String _string(
    Map<String, dynamic> row,
    String key,
    int min,
    int max,
  ) {
    final value = row[key];
    if (value is! String) throw FormatException('$key matn bo‘lishi kerak.');
    _text(value, key, min: min, max: max);
    return value;
  }

  static int _integer(Map<String, dynamic> row, String key, int min, int max) {
    final value = row[key];
    if (value is! int) throw FormatException('$key butun son bo‘lishi kerak.');
    _range(value, key, min, max);
    return value;
  }

  static DateTime _day(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Sana YYYY-MM-DD ko‘rinishida bo‘lsin.');
    }
    final date = DateTime.tryParse(value);
    if (date == null || dayKey(date) != value) {
      throw const FormatException('Sana noto‘g‘ri.');
    }
    return date;
  }

  static DateTime _timestamp(dynamic value) {
    if (value is! String || value.length > 40 || !value.contains('T')) {
      throw const FormatException('Vaqt noto‘g‘ri.');
    }
    final date = DateTime.tryParse(value);
    if (date == null) throw const FormatException('Vaqt noto‘g‘ri.');
    return date;
  }

  static void _unique(String value, Set<String> ids) {
    if (!ids.add(value)) {
      throw const FormatException('Takrorlangan identifikator.');
    }
  }

  void _apply(Map<String, dynamic> root) {
    _isSampleData = root['isSampleData'] as bool;
    _tasks = (root['tasks'] as List).map((row) {
      final t = row as Map<String, dynamic>;
      return DemoTask(
        id: t['id'],
        title: t['title'],
        project: t['project'],
        minutes: t['minutes'],
        priority: t['priority'],
        dueDate: _day(t['dueDate']),
        completed: t['completed'],
        proof: t['proof'],
        evidenceUrl: t['evidenceUrl'],
        completedAt: t['completedAt'] == null
            ? null
            : _timestamp(t['completedAt']),
        goalId: t['goalId'],
      );
    }).toList();
    _habits = (root['habits'] as List).map((row) {
      final h = row as Map<String, dynamic>;
      return DemoHabit(
        id: h['id'],
        title: h['title'],
        unit: h['unit'],
        target: h['target'],
        weekdays: (h['weekdays'] as List).cast<int>(),
        logs: (h['logs'] as Map<String, dynamic>).cast<String, int>(),
        reasons: (h['reasons'] as Map<String, dynamic>).cast<String, String>(),
        goalId: h['goalId'],
        historyRules: {
          for (final entry
              in ((h['historyRules'] as Map<String, dynamic>?) ?? {}).entries)
            entry.key: DemoHabitDayRule(
              target: (entry.value as Map<String, dynamic>)['target'] as int,
              unit: (entry.value as Map<String, dynamic>)['unit'] as String,
            ),
        },
      );
    }).toList();
    _goals = (root['goals'] as List).map((row) {
      final g = row as Map<String, dynamic>;
      return DemoGoal(
        id: g['id'],
        title: g['title'],
        metric: g['metric'],
        target: g['target'],
        current: g['current'],
        deadline: _day(g['deadline']),
        category: g['category'],
      );
    }).toList();
    _focus = (root['focusSessions'] as List).map((row) {
      final f = row as Map<String, dynamic>;
      return FocusRecord(
        taskId: f['taskId'],
        seconds: f['seconds'],
        date: _timestamp(f['date']),
      );
    }).toList();
    _checkins = (root['checkins'] as List).map((row) {
      final c = row as Map<String, dynamic>;
      return DailyCheckin(
        date: _day(c['date']),
        mood: c['mood'],
        energy: c['energy'],
        note: c['note'],
      );
    }).toList();
  }
}
