import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mylife_plan/app/theme/mlp_design_system.dart';
import 'package:mylife_plan/app/router/mlp_routes.dart';
import 'package:mylife_plan/data/models/mlp_schedule.dart';
import 'package:mylife_plan/data/repositories/mlp_ui_repository.dart';
import 'package:mylife_plan/demo/demo_store.dart';
import 'package:mylife_plan/features/planner/mlp_calendar.dart';
import 'package:mylife_plan/features/planner/mlp_schedule_editor.dart';

void main() {
  final monday = DateTime(2026, 10, 26);
  MLPSchedule item({
    String id = 'a',
    DateTime? date,
    int start = 1200,
    int end = 1215,
    MLPRepeat repeat = MLPRepeat.once,
    DateTime? until,
    String? taskId,
  }) => MLPSchedule(
    id: id,
    title: 'Duolingo mashg‘uloti',
    date: date ?? monday,
    startMinute: start,
    endMinute: end,
    repeat: repeat,
    until: until,
    taskId: taskId,
    reminderMinutes: 5,
    appLink: 'https://www.duolingo.com',
  );
  Future<(SharedPreferences, DemoStore, MLPLocalUiRepository)> setup() async {
    SharedPreferences.setMockInitialValues({'legacy': 'keep'});
    final prefs = await SharedPreferences.getInstance();
    final store = DemoStore(prefs, now: () => monday);
    await store.init();
    await store.clearAll();
    final ui = MLPLocalUiRepository(prefs);
    await ui.init();
    await ui.savePreferences(
      const MLPUserPreferences(minutes: 15, startMinute: 1200, endMinute: 1260),
    );
    addTearDown(store.dispose);
    addTearDown(ui.dispose);
    return (prefs, store, ui);
  }

  Future<void> tap(WidgetTester tester, String text) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final candidates = find.text(text);
    if (candidates.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        candidates,
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }
    final target = candidates.last;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  test(
    'once/daily/weekdays/weekly respect start, end, leap day and inclusive boundary',
    () {
      expect(item().occursOn(monday), true);
      expect(item().occursOn(DateTime(2026, 10, 27)), false);
      final daily = item(
        repeat: MLPRepeat.daily,
        until: DateTime(2026, 10, 28),
      );
      expect(daily.occursOn(DateTime(2026, 10, 25)), false);
      expect(daily.occursOn(DateTime(2026, 10, 28)), true);
      expect(daily.occursOn(DateTime(2026, 10, 29)), false);
      expect(
        item(repeat: MLPRepeat.weekdays).occursOn(DateTime(2026, 10, 31)),
        false,
      );
      expect(
        item(repeat: MLPRepeat.weekly).occursOn(DateTime(2026, 11, 2)),
        true,
      );
      expect(
        item(repeat: MLPRepeat.weekly).occursOn(DateTime(2026, 11, 3)),
        false,
      );
      final leap = item(date: DateTime(2028, 2, 28), repeat: MLPRepeat.daily);
      expect(leap.occursOn(DateTime(2028, 2, 29)), true);
      expect(
        () => MLPSchedule.fromJson({...item().toJson(), 'date': '2026-02-31'}),
        throwsFormatException,
      );
      expect(() => item(start: 1215, end: 1200), throwsArgumentError);
      expect(
        () => MLPSchedule(
          id: 'x',
          title: 'Link',
          date: monday,
          startMinute: 0,
          endMinute: 5,
          appLink: 'javascript:alert(1)',
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'conflicts find late-start recurring series, ignore adjacent slots and own ID',
    () {
      final daily = item(repeat: MLPRepeat.daily);
      final late = item(
        id: 'later',
        date: DateTime(2027, 8, 12),
        repeat: MLPRepeat.weekly,
        start: 1205,
        end: 1230,
      );
      expect(
        MLPPlannerMath.conflicts(daily, [late]).single.day,
        DateTime(2027, 8, 12),
      );
      expect(MLPPlannerMath.conflicts(daily, [item()]), isEmpty);
      expect(
        MLPPlannerMath.conflicts(daily, [
          item(id: 'next', start: 1215, end: 1230),
        ]),
        isEmpty,
      );
      expect(
        MLPPlannerMath.conflicts(
          item(repeat: MLPRepeat.daily, until: DateTime(2026, 12, 1)),
          [late],
        ),
        isEmpty,
      );
    },
  );
  test(
    'capacity counts linked work once and does not hide remaining task estimate',
    () {
      expect(
        MLPPlannerMath.loadMinutes(
          [item(taskId: 'task')],
          monday,
          {'task': 60, 'another': 60},
        ),
        120,
      );
      expect(
        MLPPlannerMath.loadMinutes(
          [item(taskId: 'task', end: 1320)],
          monday,
          {'task': 60, 'another': 60},
        ),
        180,
      );
      expect(MLPPlannerMath.loadMinutes([item()], monday, {'task': 60}), 75);
      expect(
        MLPPlannerMath.loadMinutes([item()], DateTime(2026, 10, 27), {}),
        0,
      );
    },
  );
  test(
    'schedule CRUD and per-occurrence reports persist; future result blocked; no task completion',
    () async {
      final (prefs, store, ui) = await setup();
      await store.addTask(title: 'Til mashqi', minutes: 15);
      final task = store.tasks.single;
      final value = item(repeat: MLPRepeat.daily, taskId: task.id);
      await ui.saveSchedule(value);
      await expectLater(
        ui.saveScheduleResult(
          MLPScheduleResult(
            scheduleId: value.id,
            day: monday,
            note: 'Bugun til mashqini bajardim',
            reportedAt: monday.add(const Duration(hours: 19)),
          ),
        ),
        throwsArgumentError,
      );
      await ui.saveScheduleResult(
        MLPScheduleResult(
          scheduleId: value.id,
          day: monday,
          note: 'Bugun til mashqini bajardim',
          reportedAt: monday.add(const Duration(hours: 21)),
        ),
      );
      await ui.saveScheduleResult(
        MLPScheduleResult(
          scheduleId: value.id,
          day: monday,
          note: 'Yangilangan o‘z hisobotim',
          reportedAt: monday.add(const Duration(hours: 22)),
        ),
      );
      expect(ui.scheduleResults, hasLength(1));
      expect(store.tasks.single.completed, false);
      expect(store.xp, 0);
      final fresh = MLPLocalUiRepository(prefs);
      await fresh.init();
      expect(fresh.schedules.single.repeat, MLPRepeat.daily);
      expect(fresh.schedules.single.reminderMinutes, 5);
      expect(fresh.scheduleResults.single.note, 'Yangilangan o‘z hisobotim');
      await fresh.saveSchedule(item(repeat: MLPRepeat.weekly));
      expect(fresh.schedules, hasLength(1));
      await fresh.deleteSchedule(value.id);
      expect(fresh.schedules, isEmpty);
      expect(fresh.scheduleResults, isEmpty);
      expect(prefs.getString('legacy'), 'keep');
      fresh.dispose();
    },
  );
  test(
    'malformed stored schedule is preserved and routes to recovery',
    () async {
      final (prefs, _, ui) = await setup();
      await ui.saveSchedule(item());
      final decoded =
          jsonDecode(prefs.getString(MLPLocalUiRepository.storageKey)!)
              as Map<String, dynamic>;
      (decoded['schedules'] as List).first['end'] = -1;
      final raw = jsonEncode(decoded);
      await prefs.setString(MLPLocalUiRepository.storageKey, raw);
      final fresh = MLPLocalUiRepository(prefs);
      await fresh.init();
      expect(fresh.requiresRecovery, true);
      expect(prefs.getString(MLPLocalUiRepository.storageKey), raw);
      fresh.dispose();
    },
  );

  testWidgets(
    'create daily Duolingo schedule, view it, show unavailable launch and persist report',
    (tester) async {
      final (prefs, store, ui) = await setup();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [MLPRouteFeedbackObserver()],
          theme: MLPTheme.dark,
          home: MLPCalendarScreen(
            store: store,
            ui: ui,
            clock: () => DateTime(2026, 10, 26, 21),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'Yangi mashg‘ulot');
      await tap(tester, 'Jadvalni saqlash');
      expect(find.text('Kamida 2 belgi kiriting.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Duolingo mashg‘uloti',
      );
      await tap(tester, 'Bir marta');
      await tap(tester, 'Har kuni');
      await tap(tester, 'Jadvalni saqlash');
      expect(ui.schedules.single.startMinute, 1200);
      expect(ui.schedules.single.endMinute, 1215);
      expect(ui.schedules.single.repeat, MLPRepeat.daily);
      await tap(tester, 'Ilovani ochish');
      expect(find.textContaining('Telefoningiz boshqarilmadi'), findsOneWidget);
      await tap(tester, 'Yopish');
      await tap(tester, 'Natijani qayd qilish');
      await tester.enterText(
        find.byType(TextFormField).first,
        'Bugun uchta yangi ibora o‘rgandim.',
      );
      await tap(tester, 'Natijani saqlash');
      expect(ui.scheduleResults, hasLength(1));
      final fresh = MLPLocalUiRepository(prefs);
      await fresh.init();
      expect(fresh.scheduleResults.single.note, contains('uchta'));
      fresh.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'overlap and overload require confirmation; cancel keeps form; delete is confirmed',
    (tester) async {
      final (_, store, ui) = await setup();
      await ui.saveSchedule(item(id: 'existing'));
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [MLPRouteFeedbackObserver()],
          theme: MLPTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => openMLPScheduleEditor(
                  context,
                  store,
                  ui,
                  existing: ui.schedules.length > 1 ? ui.schedules.last : null,
                ),
                child: const Text('Reja yaratish'),
              ),
            ),
          ),
        ),
      );
      await tap(tester, 'Reja yaratish');
      await tester.enterText(
        find.byType(TextFormField).first,
        'Ikkinchi mashg‘ulot',
      );
      await tap(tester, 'Jadvalni saqlash');
      expect(find.textContaining('vaqt to‘qnashuvi'), findsOneWidget);
      expect(find.textContaining('Yuk 15 daqiqaga oshgan'), findsOneWidget);
      await tap(tester, 'Bekor qilish');
      expect(ui.schedules, hasLength(1));
      expect(find.text('Ikkinchi mashg‘ulot'), findsOneWidget);
      await tap(tester, 'Jadvalni saqlash');
      await tap(tester, 'Baribir saqlash');
      expect(ui.schedules, hasLength(2));
      await tap(tester, 'Reja yaratish');
      await tap(tester, 'Jadvalni o‘chirish');
      await tap(tester, 'Bekor qilish');
      expect(ui.schedules, hasLength(2));
      await tap(tester, 'Jadvalni o‘chirish');
      await tap(tester, 'Tasdiqlash');
      expect(ui.schedules, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'editing an old daily series checks current workload, not only its first week',
    (tester) async {
      final (_, store, ui) = await setup();
      final old = item(date: DateTime(2026, 8, 1), repeat: MLPRepeat.daily);
      await ui.saveSchedule(old);
      await store.addTask(title: 'Bugungi alohida vazifa', minutes: 30);
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [MLPRouteFeedbackObserver()],
          theme: MLPTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () =>
                    openMLPScheduleEditor(context, store, ui, existing: old),
                child: const Text('Tahrirlash'),
              ),
            ),
          ),
        ),
      );
      await tap(tester, 'Tahrirlash');
      await tap(tester, 'Jadvalni saqlash');
      expect(find.textContaining('Yuk 30 daqiqaga oshgan'), findsOneWidget);
      await tap(tester, 'Bekor qilish');
      expect(ui.schedules.single.date, DateTime(2026, 8, 1));
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(360, 800),
    const Size(393, 852),
    const Size(430, 932),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'calendar modes and editor fit $size, large text and keyboard',
      (tester) async {
        final (_, store, ui) = await setup();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        for (final screen in [
          MLPCalendarScreen(store: store, ui: ui),
          MLPScheduleEditor(store: store, ui: ui),
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              navigatorObservers: [MLPRouteFeedbackObserver()],
              theme: MLPTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.4),
                  viewInsets: const EdgeInsets.only(bottom: 160),
                  padding: const EdgeInsets.only(top: 44, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
                ),
                child: child!,
              ),
              home: screen,
            ),
          );
          await tester.pumpAndSettle();
          if (screen is MLPCalendarScreen) {
            await tap(tester, 'Hafta');
            await tap(tester, 'Oy');
          }
          expect(tester.takeException(), isNull, reason: '$screen at $size');
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
