import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mylife_plan/demo/demo_app.dart';
import 'package:mylife_plan/demo/demo_forms.dart';
import 'package:mylife_plan/demo/demo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<(DemoStore, SharedPreferences)> prepare({bool empty = false}) async {
    SharedPreferences.setMockInitialValues({
      'mlp_user': '{"name":"Old account"}',
      'mylife_plan_app_data_v2_guest': '{"legacy":true}',
    });
    final prefs = await SharedPreferences.getInstance();
    final store = DemoStore(prefs, now: () => DateTime(2026, 10, 19, 12));
    await store.init();
    if (empty) await store.clearAll();
    return (store, prefs);
  }

  void screen(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> navigate(
    WidgetTester tester,
    int index, {
    required bool mobile,
  }) async {
    if (mobile) {
      await tester.tap(
        find
            .descendant(
              of: find.byType(NavigationBar),
              matching: find.byType(NavigationDestination),
            )
            .at(index),
      );
    } else {
      await tester.tap(
        find
            .text(
              const [
                'Bugun',
                'Mening rejam',
                'Fokus xonasi',
                'Natijalar',
                'Markaz',
              ][index],
            )
            .first,
      );
    }
    await tester.pumpAndSettle();
  }

  for (final mobile in [false, true]) {
    testWidgets(
      '${mobile ? '390px mobile' : '1440px desktop'} shell opens every section without overflow',
      (tester) async {
        screen(tester, mobile ? const Size(390, 844) : const Size(1440, 1000));
        final (store, prefs) = await prepare();
        await tester.pumpWidget(
          MplDemoApp(enableOnboarding: false, store: store, prefs: prefs),
        );
        await tester.pumpAndSettle();
        expect(find.text('BUGUNGI ASOSIY QADAM'), findsOneWidget);
        expect(tester.takeException(), isNull);
        for (var index = 1; index <= 4; index++) {
          await navigate(tester, index, mobile: mobile);
          expect(find.byType(Scaffold), findsWidgets);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Section $index at ${mobile ? 390 : 1440}px',
          );
        }
        await navigate(tester, 0, mobile: mobile);
        expect(find.text('BUGUNGI ASOSIY QADAM'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        store.dispose();
      },
    );
  }

  testWidgets(
    'task form validates, persists proof and reveals the next action without repeat XP',
    (tester) async {
      screen(tester, const Size(1440, 1000));
      final (store, prefs) = await prepare(empty: true);
      await store.addTask(title: 'Keyingi kichik qadam', priority: 3);
      await tester.pumpWidget(
        MplDemoApp(enableOnboarding: false, store: store, prefs: prefs),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yangi vazifa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saqlash'));
      await tester.pumpAndSettle();
      expect(find.text('Kamida 2 ta belgi kiriting.'), findsOneWidget);
      expect(store.tasks, hasLength(1));
      await tester.enterText(
        find.byType(TextFormField).first,
        'Demo natijani sinash',
      );
      await tester.tap(find.text('Saqlash'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(store.tasks, hasLength(2));
      expect(
        prefs.getString(DemoStore.storageKey),
        contains('Demo natijani sinash'),
      );
      await tester.tap(find.text('Natijani topshirish'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'qisqa');
      await tester.tap(find.text('Topshirish · +40 XP'));
      await tester.pumpAndSettle();
      expect(find.text('Kamida 10 ta belgi kiriting.'), findsOneWidget);
      expect(store.todayCompleted, 0);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Birinchi haqiqiy natijani yozdim va tekshirdim.',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'noto‘g‘ri-havola',
      );
      await tester.tap(find.text('Topshirish · +40 XP'));
      await tester.pumpAndSettle();
      expect(
        find.text('http yoki https bilan boshlangan havola kiriting.'),
        findsOneWidget,
      );
      expect(store.todayCompleted, 0);
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'https://example.com/result',
      );
      await tester.tap(find.text('Topshirish · +40 XP'));
      await tester.pumpAndSettle();
      expect(store.todayCompleted, 1);
      expect(store.xp, 40);
      expect(find.text('Keyingi kichik qadam'), findsNWidgets(2));
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.byIcon(Icons.check_circle_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Topshirilgan natija'), findsOneWidget);
      expect(find.text('Topshirish · +40 XP'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).readOnly,
        isTrue,
      );
      await tester.tap(find.text('Yopish'));
      await tester.pumpAndSettle();
      expect(store.xp, 40);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );

  testWidgets(
    'habit plus and undo update the displayed progress and persisted value',
    (tester) async {
      screen(tester, const Size(390, 844));
      final (store, prefs) = await prepare(empty: true);
      await store.addHabit(title: 'Bir bet o‘qish', target: 2, unit: 'bet');
      final habit = store.habits.single;
      await tester.pumpWidget(
        MplDemoApp(enableOnboarding: false, store: store, prefs: prefs),
      );
      await tester.pumpAndSettle();
      await navigate(tester, 1, mobile: true);
      await tester.tap(find.text('Odatlar'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Odatga +1'));
      await tester.tap(find.byTooltip('Odatga +1'));
      await tester.pumpAndSettle();
      expect(store.habitValue(habit.id), 1);
      expect(find.textContaining('1 / 2 bet'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Bugungi qiymatni qaytarish'));
      await tester.tap(find.byTooltip('Bugungi qiymatni qaytarish'));
      await tester.pumpAndSettle();
      expect(store.habitValue(habit.id), 0);
      expect(find.textContaining('0 / 2 bet'), findsOneWidget);
      final restored = DemoStore(prefs, now: () => store.today);
      await restored.init();
      expect(restored.habitValue(habit.id), 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      restored.dispose();
    },
  );

  testWidgets(
    'clear settings requires confirmation and keeps legacy accounts intact',
    (tester) async {
      screen(tester, const Size(390, 844));
      final (store, prefs) = await prepare();
      final before = store.exportJson();
      await tester.pumpWidget(
        MplDemoApp(enableOnboarding: false, store: store, prefs: prefs),
      );
      await tester.pumpAndSettle();
      Future<void> requestClear() async {
        await tester.tap(find.byTooltip('Sozlamalar'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Toza sahifadan boshlash'));
        await tester.tap(find.text('Toza sahifadan boshlash'));
        await tester.pumpAndSettle();
      }

      await requestClear();
      await tester.tap(find.text('Bekor qilish'));
      await tester.pumpAndSettle();
      expect(store.exportJson(), before);
      await requestClear();
      await tester.tap(find.text('Tasdiqlash'));
      await tester.pumpAndSettle();
      expect(store.tasks, isEmpty);
      expect(store.habits, isEmpty);
      expect(store.goals, isEmpty);
      expect(store.focusSessions, isEmpty);
      expect(store.checkins, isEmpty);
      expect(prefs.getString('mlp_user'), '{"name":"Old account"}');
      expect(
        prefs.getString('mylife_plan_app_data_v2_guest'),
        '{"legacy":true}',
      );
      expect(find.text('Birinchi aniq qadamingizni tanlang.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );

  testWidgets('task save failure keeps input and shows an actionable error', (
    tester,
  ) async {
    screen(tester, const Size(390, 844));
    final (prepared, prefs) = await prepare(empty: true);
    prepared.dispose();
    final store = _FailingDemoStore(prefs);
    await store.init();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => DemoForms.task(context, store),
                child: const Text('Yangi vazifa'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Yangi vazifa'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Saqlanadigan foydali vazifa',
    );
    await tester.tap(find.text('Saqlash'));
    await tester.pumpAndSettle();
    expect(find.text('Sinov uchun saqlash xatosi'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Saqlanadigan foydali vazifa',
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Bekor qilish'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets(
    'edit forms preload values and update each entity without duplication',
    (tester) async {
      screen(tester, const Size(1440, 1000));
      final (store, _) = await prepare(empty: true);
      await store.addGoal(
        title: 'Eski maqsad',
        metric: 'mashq',
        target: 8,
        deadline: store.today,
        category: 'Sport',
      );
      final goal = store.goals.single;
      await store.addTask(title: 'Eski vazifa', minutes: 50, goalId: goal.id);
      await store.addHabit(
        title: 'Eski odat',
        target: 2,
        unit: 'bet',
        weekdays: [1, 3],
        goalId: goal.id,
      );
      final task = store.tasks.single;
      final habit = store.habits.single;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  FilledButton(
                    onPressed: () =>
                        DemoForms.task(context, store, existing: task),
                    child: const Text('Vazifa edit'),
                  ),
                  FilledButton(
                    onPressed: () =>
                        DemoForms.habit(context, store, existing: habit),
                    child: const Text('Odat edit'),
                  ),
                  FilledButton(
                    onPressed: () =>
                        DemoForms.goal(context, store, existing: goal),
                    child: const Text('Maqsad edit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Vazifa edit'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Eski vazifa',
      );
      expect(find.text('50 daqiqa'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Yangi vazifa nomi',
      );
      await tester.tap(find.text('Saqlash'));
      await tester.pumpAndSettle();
      expect(store.tasks.single.id, task.id);
      expect(store.tasks.single.title, 'Yangi vazifa nomi');
      expect(store.tasks.single.minutes, 50);
      expect(store.tasks.single.goalId, goal.id);
      await tester.tap(find.text('Odat edit'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        '2',
      );
      await tester.enterText(
        find.byType(TextFormField).first,
        'Yangi odat nomi',
      );
      await tester.tap(find.text('Saqlash'));
      await tester.pumpAndSettle();
      expect(store.habits.single.id, habit.id);
      expect(store.habits.single.title, 'Yangi odat nomi');
      expect(store.habits.single.weekdays, [1, 3]);
      expect(store.habits.single.goalId, goal.id);
      await tester.tap(find.text('Maqsad edit'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Eski maqsad',
      );
      expect(find.text('Sport'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Yangi maqsad nomi',
      );
      await tester.tap(find.text('Saqlash'));
      await tester.pumpAndSettle();
      expect(store.goals.single.id, goal.id);
      expect(store.goals.single.title, 'Yangi maqsad nomi');
      expect(store.goals.single.category, 'Sport');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );

  testWidgets('focus saves only active seconds and pauses while hidden', (
    tester,
  ) async {
    screen(tester, const Size(1440, 1100));
    final (prepared, prefs) = await prepare(empty: true);
    prepared.dispose();
    var instant = DateTime(2026, 10, 19, 12);
    final store = DemoStore(prefs, now: () => instant);
    await store.init();
    await tester.pumpWidget(
      MplDemoApp(
        enableOnboarding: false,
        store: store,
        prefs: prefs,
        clock: () => instant,
      ),
    );
    await tester.pumpAndSettle();
    await navigate(tester, 2, mobile: false);
    await tester.tap(find.text('Boshlash'));
    await tester.pump();
    instant = instant.add(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('24:30'), findsOneWidget);
    await tester.tap(find.text('Pauza'));
    await tester.pumpAndSettle();
    instant = instant.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));
    expect(find.text('24:30'), findsOneWidget);
    expect(store.focusSessions, isEmpty);
    await tester.tap(find.text('Davom etish'));
    await tester.pump();
    instant = instant.add(const Duration(seconds: 15));
    await tester.pump(const Duration(milliseconds: 250));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pumpAndSettle();
    expect(find.text('24:15'), findsOneWidget);
    expect(find.text('Davom etish'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.text('Sessiyani saqlash'));
    await tester.pumpAndSettle();
    expect(store.focusSessions, hasLength(1));
    expect(store.focusSessions.single.seconds, 45);
    expect(store.todayFocusMinutes, 0);
    expect(store.todayCompleted, 0);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Sessiyani saqlash'),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}

class _FailingDemoStore extends DemoStore {
  _FailingDemoStore(super.prefs);

  @override
  Future<void> addTask({
    required String title,
    String project = 'Shaxsiy',
    int minutes = 25,
    int priority = 2,
    DateTime? dueDate,
    String? goalId,
  }) async => throw StateError('Sinov uchun saqlash xatosi');
}
