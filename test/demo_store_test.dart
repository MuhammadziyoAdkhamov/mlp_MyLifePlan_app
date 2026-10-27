import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mylife_plan/demo/demo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late DemoStore store;
  late DateTime clock;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'legacy_mpl_data': 'keep-me'});
    prefs = await SharedPreferences.getInstance();
    clock = DateTime(2026, 10, 19, 12); // Monday.
    store = DemoStore(prefs, now: () => clock);
    await store.init();
  });

  tearDown(() => store.dispose());

  test(
    'first launch seeds labelled data in its own key; clear stays empty',
    () async {
      expect(store.isSampleData, isTrue);
      expect(store.tasks, isNotEmpty);
      expect(store.habits, isNotEmpty);
      expect(prefs.getString('legacy_mpl_data'), 'keep-me');
      await store.clearAll();
      expect(store.tasks, isEmpty);
      expect(store.habits, isEmpty);
      expect(store.goals, isEmpty);
      expect(store.focusSessions, isEmpty);
      expect(store.checkins, isEmpty);
      expect(store.xp, 0);
      final restored = DemoStore(prefs, now: () => clock);
      await restored.init();
      expect(restored.tasks, isEmpty);
      expect(restored.isSampleData, isFalse);
      expect(prefs.getString('legacy_mpl_data'), 'keep-me');
      await restored.loadSample();
      expect(restored.tasks, isNotEmpty);
      expect(restored.isSampleData, isTrue);
      restored.dispose();
    },
  );

  test(
    'task needs proof; submissions are idempotent and reopen reverses XP',
    () async {
      await store.clearAll();
      await store.addTask(title: 'Portfolio case study', priority: 1);
      final id = store.tasks.single.id;
      expect(() => store.submitTask(id, 'done'), throwsArgumentError);
      expect(() => store.submitTask(id, '          '), throwsArgumentError);
      expect(
        () => store.submitTask(
          id,
          'Case study yozildi.',
          evidenceUrl: 'javascript:alert(1)',
        ),
        throwsArgumentError,
      );
      expect(store.xp, 0);
      expect(store.tasks.single.completed, isFalse);
      await store.submitTask(
        id,
        'Case study qoralamasini yozdim.',
        evidenceUrl: 'https://example.com/portfolio',
      );
      final submittedAt = store.tasks.single.completedAt;
      expect(store.xp, 40);
      expect(store.todayCompleted, 1);
      clock = clock.add(const Duration(hours: 1));
      await store.submitTask(id, 'Case study yakuniy nusxasini yukladim.');
      expect(store.xp, 40);
      expect(store.tasks.single.completedAt, submittedAt);
      await store.reopenTask(id);
      expect(store.xp, 0);
      expect(store.tasks.single.proof, isEmpty);
      expect(store.tasks.single.completedAt, isNull);
    },
  );

  test('overdue work stays visible and deferral moves to tomorrow', () async {
    await store.clearAll();
    await store.addTask(
      title: 'Kechikkan vazifa',
      dueDate: DateTime(2026, 10, 17),
    );
    final id = store.tasks.single.id;
    expect(store.todayTasks.single.id, id);
    await store.deferTask(id);
    expect(store.todayTasks, isEmpty);
    expect(DemoStore.dayKey(store.tasks.single.dueDate), '2026-10-20');
    await store.deleteTask(id);
    expect(store.tasks, isEmpty);
    expect(() => store.reopenTask(id), throwsStateError);
  });

  test(
    'habit streak skips rest days but breaks at missed scheduled days',
    () async {
      await store.clearAll();
      await store.addHabit(title: 'Mashq qilish', weekdays: [1, 3, 5]);
      final id = store.habits.single.id;
      await store.incrementHabit(id);
      await store.incrementHabit(id); // Cannot farm target XP.
      expect(store.habitValue(id), 1);
      expect(store.xp, 15);
      expect(store.habitStreak(id), 1);
      clock = DateTime(2026, 10, 20, 12); // Tuesday is a rest day.
      expect(store.scheduledHabits(), isEmpty);
      expect(store.habitStreak(id), 1);
      expect(() => store.incrementHabit(id), throwsStateError);
      clock = DateTime(2026, 10, 21, 12);
      expect(store.habitStreak(id), 1); // Today is still available.
      await store.incrementHabit(id);
      expect(store.habitStreak(id), 2);
      clock = DateTime(2026, 10, 26, 12); // Friday was missed.
      expect(store.habitStreak(id), 0);
      await store.incrementHabit(id);
      expect(store.habitStreak(id), 1);
      await store.undoHabit(id);
      expect(store.habitValue(id), 0);
      await store.skipHabit(id, 'Safarda edim');
      expect(store.habits.single.reasons[store.todayKey], 'Safarda edim');
      await store.incrementHabit(id);
      expect(store.habits.single.reasons.containsKey(store.todayKey), isFalse);
    },
  );

  test(
    'target habit awards only at target and undo reverses that award',
    () async {
      await store.clearAll();
      await store.addHabit(title: 'Suv ichish', target: 2, unit: 'stakan');
      final id = store.habits.single.id;
      await store.incrementHabit(id);
      expect(store.habitProgress(store.habits.single), .5);
      expect(store.xp, 0);
      await store.incrementHabit(id);
      expect(store.xp, 15);
      expect(store.completionForDay(clock), 1);
      await store.undoHabit(id);
      expect(store.xp, 0);
      expect(store.completionForDay(clock), 0);
    },
  );

  test(
    'goal progress is absolute, clamped, persisted and cannot farm XP',
    () async {
      await store.clearAll();
      await store.addGoal(
        title: 'Kitoblar',
        metric: 'kitob',
        target: 12,
        deadline: DateTime(2026, 12, 31),
        category: 'Ta’lim',
      );
      final id = store.goals.single.id;
      await store.progressGoal(id, 5);
      expect(store.goals.single.current, 5);
      await store.progressGoal(id, 99);
      expect(store.goals.single.current, 12);
      expect(store.xp, 100);
      await store.progressGoal(id, 12);
      expect(store.xp, 100);
      await store.progressGoal(id, -2);
      expect(store.goals.single.current, 0);
      expect(store.xp, 0);
      final restored = DemoStore(prefs, now: () => clock);
      await restored.init();
      expect(restored.goals.single.current, 0);
      restored.dispose();
    },
  );

  test('focus and one check-in per day survive restart', () async {
    await store.clearAll();
    await store.addTask(title: 'Fokus vazifasi');
    final id = store.tasks.single.id;
    expect(() => store.addFocusSession(seconds: 0), throwsArgumentError);
    await store.addFocusSession(taskId: id, seconds: 1500);
    await store.saveCheckin(mood: 4, energy: 3, note: 'Yaxshi kun');
    await store.saveCheckin(mood: 5, energy: 4, note: 'Yangilangan izoh');
    expect(store.xp, 35);
    expect(store.todayFocusMinutes, 25);
    expect(store.checkins, hasLength(1));
    final restored = DemoStore(prefs, now: () => clock);
    await restored.init();
    expect(restored.todayFocusMinutes, 25);
    expect(restored.todayCheckin!.note, 'Yangilangan izoh');
    expect(restored.xp, store.xp);
    expect(restored.exportJson(), store.exportJson());
    restored.dispose();
  });

  test(
    'JSON round-trip works and invalid imports do not mutate live or saved data',
    () async {
      final before = store.exportJson();
      final savedBefore = prefs.getString(DemoStore.storageKey);
      final malformed = <String, dynamic>{
        ...jsonDecode(before) as Map<String, dynamic>,
      };
      (malformed['tasks'] as List).first['dueDate'] = '2026-02-30';
      await expectLater(
        store.importJson(jsonEncode(malformed)),
        throwsFormatException,
      );
      expect(store.exportJson(), before);
      expect(prefs.getString(DemoStore.storageKey), savedBefore);
      await expectLater(store.importJson('{broken'), throwsFormatException);
      await expectLater(
        store.importJson(jsonEncode({'version': 1})),
        throwsFormatException,
      );
      await store.clearAll();
      await store.importJson(before);
      expect(store.exportJson(), before);
      expect(store.isSampleData, isTrue);
    },
  );

  test(
    'invalid import rejects duplicated IDs, unscheduled logs and oversized input',
    () async {
      final before = store.exportJson();
      final duplicate = jsonDecode(before) as Map<String, dynamic>;
      (duplicate['tasks'] as List).add((duplicate['tasks'] as List).first);
      await expectLater(
        store.importJson(jsonEncode(duplicate)),
        throwsFormatException,
      );
      final scheduled = jsonDecode(before) as Map<String, dynamic>;
      final habit = (scheduled['habits'] as List).first;
      habit['weekdays'] = [2]; // Saved Monday log becomes invalid.
      await expectLater(
        store.importJson(jsonEncode(scheduled)),
        throwsFormatException,
      );
      await expectLater(
        store.importJson(' ' * (2 * 1024 * 1024 + 1)),
        throwsFormatException,
      );
      expect(store.exportJson(), before);
    },
  );

  test(
    'corrupt saved data is preserved and requires an explicit reset',
    () async {
      await prefs.setString(DemoStore.storageKey, '{broken');
      final damaged = DemoStore(prefs, now: () => clock);
      await damaged.init();
      expect(damaged.storageError, isNotNull);
      expect(damaged.tasks, isEmpty);
      expect(prefs.getString(DemoStore.storageKey), '{broken');
      expect(() => damaged.addTask(title: 'Saqlov testi'), throwsStateError);
      await damaged.clearAll();
      await damaged.addTask(title: 'Qayta boshlash');
      expect(damaged.tasks.single.title, 'Qayta boshlash');
      expect(damaged.storageError, isNull);
      damaged.dispose();
    },
  );
}
