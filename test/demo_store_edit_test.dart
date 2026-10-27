import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mylife_plan/demo/demo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late DemoStore store;
  late DateTime clock;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    clock = DateTime(2026, 10, 19, 12);
    store = DemoStore(prefs, now: () => clock);
    await store.init();
    await store.clearAll();
  });

  tearDown(() => store.dispose());

  Future<String> addGoal([String title = 'Portfolio']) async {
    await store.addGoal(
      title: title,
      metric: 'loyiha',
      target: 5,
      deadline: DateTime(2026, 12, 31),
    );
    return store.goals.last.id;
  }

  Future<DemoStore> restored() async {
    final result = DemoStore(prefs, now: () => clock);
    await result.init();
    addTearDown(result.dispose);
    return result;
  }

  test('editing submitted work preserves its evidence, time and XP', () async {
    final goalId = await addGoal();
    await store.addTask(title: 'Portfolio qoralamasi', goalId: goalId);
    final taskId = store.tasks.single.id;
    await store.submitTask(
      taskId,
      'Birinchi portfolio qoralamasi tayyor.',
      evidenceUrl: 'https://example.com/portfolio',
    );
    await store.addFocusSession(taskId: taskId, seconds: 300);
    final submitted = store.tasks.single;
    final xpBefore = store.xp;
    clock = DateTime(2026, 10, 20, 12);
    await store.editTask(
      taskId,
      title: '  Portfolio yakuniy qoralamasi  ',
      project: '  Karyera  ',
      minutes: 50,
      priority: 1,
      dueDate: DateTime(2026, 10, 21, 18),
    );
    final edited = store.tasks.single;
    expect(edited.title, 'Portfolio yakuniy qoralamasi');
    expect(edited.project, 'Karyera');
    expect(edited.minutes, 50);
    expect(edited.priority, 1);
    expect(edited.dueDate, DateTime(2026, 10, 21));
    expect(edited.completed, isTrue);
    expect(edited.proof, submitted.proof);
    expect(edited.evidenceUrl, submitted.evidenceUrl);
    expect(edited.completedAt, submitted.completedAt);
    expect(edited.goalId, goalId);
    expect(store.focusSessions.single.taskId, taskId);
    expect(store.xp, xpBefore);
    expect(store.goalCompletedTaskCount(goalId), 1);
    expect(store.goals.single.current, 0);
    final loaded = await restored();
    expect(loaded.exportJson(), store.exportJson());
    await loaded.submitTask(taskId, 'Natija yana bir marta saqlandi.');
    expect(loaded.xp, xpBefore);
  });

  test('invalid task edits leave memory and saved data unchanged', () async {
    await store.addTask(title: 'Muhim ish');
    final id = store.tasks.single.id;
    final before = store.exportJson();
    final saved = prefs.getString(DemoStore.storageKey);
    for (final invalidEdit in <void Function()>[
      () => store.editTask(id, title: 'x'),
      () => store.editTask(id, title: 'Yangi nom', minutes: 0),
      () => store.editTask(id, project: '  '),
      () => store.editTask(id, priority: 4),
      () => store.editTask(id, goalId: 'missing-goal'),
    ]) {
      expect(invalidEdit, throwsArgumentError);
      expect(store.exportJson(), before);
      expect(prefs.getString(DemoStore.storageKey), saved);
    }
    expect(() => store.editTask('missing'), throwsStateError);
  });

  test('task links are optional, editable and backwards compatible', () async {
    final firstGoal = await addGoal();
    final secondGoal = await addGoal('Til maqsadi');
    await store.addTask(title: 'Bog‘langan ish', goalId: firstGoal);
    final id = store.tasks.single.id;
    await store.editTask(id, goalId: secondGoal);
    expect(store.goalTaskCount(firstGoal), 0);
    expect(store.goalTaskCount(secondGoal), 1);
    await store.editTask(id, title: 'Bog‘lanish saqlanadi');
    expect(store.tasks.single.goalId, secondGoal);
    await store.editTask(id, clearGoal: true);
    expect(store.tasks.single.goalId, isNull);
    final oldFormat = jsonDecode(store.exportJson()) as Map<String, dynamic>;
    ((oldFormat['tasks'] as List).single as Map).remove('goalId');
    await store.importJson(jsonEncode(oldFormat));
    expect(store.tasks.single.goalId, isNull);
    final before = store.exportJson();
    final bad = jsonDecode(before) as Map<String, dynamic>;
    (bad['tasks'] as List).single['goalId'] = 'missing-goal';
    await expectLater(store.importJson(jsonEncode(bad)), throwsFormatException);
    expect(store.exportJson(), before);
    expect(
      () => store.addTask(title: 'Noto‘g‘ri bog‘lanish', goalId: 'missing'),
      throwsArgumentError,
    );
  });

  test('manual metric and linked action progress remain separate', () async {
    final id = await addGoal();
    await store.progressGoal(id, 3);
    await store.addTask(title: 'Birinchi ish', goalId: id);
    await store.addTask(title: 'Ikkinchi ish', goalId: id);
    await store.submitTask(store.tasks.first.id, 'Birinchi ishning natijasi.');
    expect(store.goalTaskCount(id), 2);
    expect(store.goalCompletedTaskCount(id), 1);
    expect(store.goals.single.current, 3);
    expect(store.goals.single.progress, .6);
    await store.editGoal(
      id,
      title: '  Portfolio loyihalari  ',
      metric: '  tayyor loyiha  ',
      target: 8,
      deadline: DateTime(2027, 1, 15, 16),
      category: '  Karyera  ',
    );
    expect(store.goals.single.title, 'Portfolio loyihalari');
    expect(store.goals.single.metric, 'tayyor loyiha');
    expect(store.goals.single.category, 'Karyera');
    expect(store.goals.single.current, 3);
    expect(store.goals.single.deadline, DateTime(2027, 1, 15));
    await store.reopenTask(store.tasks.first.id);
    expect(store.goalCompletedTaskCount(id), 0);
    expect(store.goals.single.current, 3);
    await store.deleteTask(store.tasks.first.id);
    expect(store.goalTaskCount(id), 1);
    expect(store.goals.single.current, 3);
    final loaded = await restored();
    expect(loaded.goals.single.current, 3);
    expect(loaded.goalTaskCount(id), 1);
  });

  test('invalid goal edits do not erase already reported units', () async {
    final id = await addGoal();
    await store.progressGoal(id, 4);
    final before = store.exportJson();
    final saved = prefs.getString(DemoStore.storageKey);
    for (final invalidEdit in <void Function()>[
      () => store.editGoal(id, title: 'x'),
      () => store.editGoal(id, title: 'Yangi nom', target: 3),
      () => store.editGoal(id, target: 0),
      () => store.editGoal(id, metric: ''),
      () => store.editGoal(id, category: ''),
    ]) {
      expect(invalidEdit, throwsArgumentError);
      expect(store.exportJson(), before);
      expect(prefs.getString(DemoStore.storageKey), saved);
    }
    await store.progressGoal(id, 5);
    expect(store.xp, 100);
    await store.editGoal(id, title: 'Yakunlangan portfolio');
    await store.editGoal(id, title: 'Yakunlangan portfolio');
    expect(store.xp, 100);
  });

  test(
    'deleting goal detaches work and habits without losing history',
    () async {
      final id = await addGoal();
      await store.progressGoal(id, 5);
      await store.addTask(title: 'Tayyor ish', goalId: id);
      final taskId = store.tasks.single.id;
      await store.submitTask(taskId, 'Tayyor ishning saqlangan dalili.');
      await store.addHabit(title: 'Har kuni kod', goalId: id);
      await store.incrementHabit(store.habits.single.id);
      final task = store.tasks.single.toJson()..remove('goalId');
      final habit = store.habits.single.toJson()..remove('goalId');
      await store.addFocusSession(taskId: taskId, seconds: 120);
      await store.deleteGoal(id);
      expect(store.goals, isEmpty);
      expect(store.tasks.single.goalId, isNull);
      expect(store.habits.single.goalId, isNull);
      expect(store.tasks.single.toJson()..remove('goalId'), task);
      expect(store.habits.single.toJson()..remove('goalId'), habit);
      expect(store.xp, 57); // Task + habit + two focus minutes.
      expect(store.focusSessions.single.taskId, taskId);
      final loaded = await restored();
      expect(loaded.storageError, isNull);
      expect(loaded.exportJson(), store.exportJson());
      expect(() => store.deleteGoal(id), throwsStateError);
    },
  );

  test(
    'habit edits preserve daily quantities, units, reasons and XP',
    () async {
      await store.addHabit(title: 'Suv ichish', unit: 'stakan', target: 2);
      final id = store.habits.single.id;
      await store.incrementHabit(id);
      await store.incrementHabit(id);
      clock = DateTime(2026, 10, 20, 12);
      await store.skipHabit(id, 'Safarda edim');
      clock = DateTime(2026, 10, 21, 12);
      final previousLogs = store.habits.single.logs;
      final previousReasons = store.habits.single.reasons;
      await store.editHabit(
        id,
        title: '  Harakat qilish  ',
        unit: 'marta',
        target: 1,
        weekdays: [3, 5],
      );
      final habit = store.habits.single;
      expect(habit.title, 'Harakat qilish');
      expect(habit.logs, previousLogs);
      expect(habit.reasons, previousReasons);
      expect(habit.targetForDate(DateTime(2026, 10, 19)), 2);
      expect(habit.unitForDate(DateTime(2026, 10, 19)), 'stakan');
      expect(habit.scheduledOn(DateTime(2026, 10, 19)), isTrue);
      expect(habit.unitForDate(clock), 'marta');
      expect(habit.targetForDate(clock), 1);
      expect(store.xp, 15);
      await store.incrementHabit(id);
      expect(store.xp, 30);
      await store.editHabit(id, target: 3);
      expect(store.habits.single.target, 3);
      expect(store.habits.single.targetForDate(clock), 1);
      expect(store.habitProgress(store.habits.single), 1);
      expect(store.xp, 30);
      await store.incrementHabit(id);
      expect(store.xp, 30);
      final loaded = await restored();
      expect(loaded.storageError, isNull);
      expect(loaded.exportJson(), store.exportJson());
      clock = DateTime(2026, 10, 23, 12);
      expect(loaded.habits.single.targetForDate(clock), 3);
      await loaded.incrementHabit(id);
      expect(
        loaded.habitProgress(loaded.habits.single),
        closeTo(1 / 3, .00001),
      );
      expect(loaded.xp, 30);
    },
  );

  test(
    'habit edit validation is atomic and supports clearing goal links',
    () async {
      final goalId = await addGoal();
      await store.addHabit(title: 'Kod yozish', goalId: goalId);
      final id = store.habits.single.id;
      await store.incrementHabit(id);
      final before = store.exportJson();
      final saved = prefs.getString(DemoStore.storageKey);
      for (final invalidEdit in <void Function()>[
        () => store.editHabit(id, title: 'x'),
        () => store.editHabit(id, title: 'Yangi nom', target: 0),
        () => store.editHabit(id, unit: ''),
        () => store.editHabit(id, weekdays: []),
        () => store.editHabit(id, weekdays: [1, 1]),
        () => store.editHabit(id, goalId: 'missing'),
      ]) {
        expect(invalidEdit, throwsArgumentError);
        expect(store.exportJson(), before);
        expect(prefs.getString(DemoStore.storageKey), saved);
      }
      await store.editHabit(id, title: 'Yangi nom');
      expect(store.habits.single.goalId, goalId);
      await store.editHabit(id, clearGoal: true);
      expect(store.habits.single.goalId, isNull);
      expect(store.habitValue(id), 1);
      expect(store.xp, 15);
    },
  );

  test(
    'undo prunes empty history snapshots and deleted habit stays deleted',
    () async {
      await store.addHabit(title: 'Kitob o‘qish');
      final id = store.habits.single.id;
      await store.incrementHabit(id);
      await store.editHabit(id, target: 5, unit: 'bet');
      expect(store.habits.single.historyRules, isNotEmpty);
      await store.undoHabit(id);
      expect(store.habits.single.historyRules, isEmpty);
      expect(store.habits.single.targetForDate(clock), 5);
      expect(store.habits.single.logs, isEmpty);
      expect(store.xp, 0);
      await store.deleteHabit(id);
      expect(store.habits, isEmpty);
      final loaded = await restored();
      expect(loaded.habits, isEmpty);
      expect(() => store.deleteHabit(id), throwsStateError);
    },
  );

  test(
    'orphaned or invalid history rules cannot bypass import validation',
    () async {
      await store.addHabit(title: 'Kitob o‘qish');
      final before = store.exportJson();
      final orphan = jsonDecode(before) as Map<String, dynamic>;
      (orphan['habits'] as List).single['historyRules'] = {
        '2026-10-19': {'target': 1, 'unit': 'marta'},
      };
      await expectLater(
        store.importJson(jsonEncode(orphan)),
        throwsFormatException,
      );
      expect(store.exportJson(), before);
      await store.incrementHabit(store.habits.single.id);
      await store.editHabit(store.habits.single.id, target: 5);
      final valid = store.exportJson();
      final invalid = jsonDecode(valid) as Map<String, dynamic>;
      (invalid['habits'] as List)
              .single['historyRules']['2026-10-19']['target'] =
          0;
      await expectLater(
        store.importJson(jsonEncode(invalid)),
        throwsFormatException,
      );
      expect(store.exportJson(), valid);
    },
  );
}
