import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mylife_plan/app/theme/mlp_design_system.dart';
import 'package:mylife_plan/data/repositories/mlp_ui_repository.dart';
import 'package:mylife_plan/demo/demo_store.dart';
import 'package:mylife_plan/features/goals/mlp_goal_flow.dart';
import 'package:mylife_plan/features/goals/mlp_goal_detail.dart';
import 'package:mylife_plan/features/onboarding/mlp_account_flow.dart';

void main() {
  Future<(SharedPreferences, DemoStore, MLPLocalUiRepository)> setup() async {
    SharedPreferences.setMockInitialValues({'legacy-account': 'keep'});
    final prefs = await SharedPreferences.getInstance();
    final store = DemoStore(prefs, now: () => DateTime(2026, 10, 26));
    await store.init();
    await store.clearAll();
    final ui = MLPLocalUiRepository(prefs);
    await ui.init();
    addTearDown(store.dispose);
    addTearDown(ui.dispose);
    return (prefs, store, ui);
  }

  test(
    'roadmap creates a single persisted goal with linked tasks and no mastery',
    () async {
      final (prefs, store, _) = await setup();
      final before = store.exportJson();
      await expectLater(
        store.addGoalPlan(
          title: 'Mos kelmaydi',
          category: 'Boshqa',
          deadline: store.today,
          steps: [(title: 'Noto‘g‘ri vazifa', minutes: 0, date: store.today)],
        ),
        throwsArgumentError,
      );
      expect(store.exportJson(), before);
      final id = await store.addGoalPlan(
        title: 'Mening maxsus maqsadim',
        category: 'Boshqa',
        deadline: store.today.add(const Duration(days: 7)),
        steps: [
          (title: 'Birinchi ish', minutes: 15, date: store.today),
          (
            title: 'Natijani tahlil qilish',
            minutes: 25,
            date: store.today.add(const Duration(days: 7)),
          ),
        ],
      );
      expect(store.goals.single.id, id);
      expect(store.tasks.length, 2);
      expect(store.tasks.every((t) => t.goalId == id), true);
      expect(store.goals.single.current, 0);
      expect(store.xp, 0);
      final restored = DemoStore(prefs);
      await restored.init();
      expect(restored.tasks.map((t) => t.title), [
        'Birinchi ish',
        'Natijani tahlil qilish',
      ]);
      expect(prefs.getString('legacy-account'), 'keep');
      restored.dispose();
    },
  );

  testWidgets(
    'custom goal goes through clarification, honest self-assessment and editable roadmap',
    (tester) async {
      final (prefs, store, ui) = await setup();
      await tester.pumpWidget(
        MaterialApp(
          theme: MLPTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => openMLPGoalFlow(context, store, ui),
                child: const Text('Yangi maqsad'),
              ),
            ),
          ),
        ),
      );
      Future<void> tap(String text) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(text));
        await tester.pumpAndSettle();
        await tester.tap(find.text(text));
        await tester.pumpAndSettle();
      }

      await tap('Yangi maqsad');
      await tap('Maqsadni aniqlashtirish');
      expect(
        find.text('Maqsadni kamida 2 belgi bilan yozing.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextFormField).first,
        'O‘zimning bog‘ loyihamni boshlash',
      );
      await tap('Maqsadni aniqlashtirish');
      expect(find.byType(MLPGoalClarificationScreen), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Uchta kichik gul ekish',
      );
      await tester.enterText(find.byType(TextFormField).at(2), '30');
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'Muntazamlikni o‘rganish uchun',
      );
      await tap('Boshlang‘ich baholash');
      expect(find.textContaining('faqat o‘z bahongiz'), findsOneWidget);
      await tap('Yo‘l xaritasini ko‘rish');
      expect(find.byType(MLPRoadmapScreen), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Tuproq va urug‘ tayyorlash',
      );
      await tap('Rejani tasdiqlash');
      expect(find.text('Yangi maqsad'), findsOneWidget);
      expect(store.goals.single.title, 'O‘zimning bog‘ loyihamni boshlash');
      expect(store.tasks.first.title, 'Tuproq va urug‘ tayyorlash');
      expect(store.tasks.every((t) => t.goalId == store.goals.single.id), true);
      final fresh = MLPLocalUiRepository(prefs);
      await fresh.init();
      expect(
        fresh.goalPlan(store.goals.single.id)!['diagnostic']['kind'],
        'self-report',
      );
      expect(fresh.goalPlan(store.goals.single.id)!['prototype'], true);
      expect(tester.takeException(), isNull);
      fresh.dispose();
    },
  );

  testWidgets(
    'sample diagnosis counts wrong and unknown answers as incorrect',
    (tester) async {
      final (_, store, ui) = await setup();
      final draft = MLPGoalDraft(today: store.today, minutes: 25)
        ..category = 'Dasturlash'
        ..title = 'Flutter o‘rganish';
      await tester.pumpWidget(
        MaterialApp(
          theme: MLPTheme.dark,
          home: MLPDiagnosticScreen(store: store, ui: ui, draft: draft),
        ),
      );
      await tester.tap(find.text('Bilmayman'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keyingi savol'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SQL'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Natijani ko‘rish'));
      await tester.pumpAndSettle();
      expect(find.text('Namuna testi: 0 / 2'), findsOneWidget);
      expect(find.textContaining('Umumiy darajangiz'), findsOneWidget);
      expect(store.xp, 0);
    },
  );

  testWidgets(
    'goal detail adds linked tasks and confirms archive, edit and delete',
    (tester) async {
      final (_, store, ui) = await setup();
      await store.addGoal(
        title: 'Mening loyiham',
        metric: 'natija',
        target: 1,
        deadline: store.today,
      );
      final id = store.goals.single.id;
      await tester.pumpWidget(
        MaterialApp(
          theme: MLPTheme.dark,
          home: MLPGoalDetailScreen(
            store: store,
            ui: ui,
            goalId: id,
            onFocus: (_) {},
          ),
        ),
      );
      Future<void> tap(String text) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(text));
        await tester.pumpAndSettle();
        await tester.tap(find.text(text));
        await tester.pumpAndSettle();
      }

      await tap('Bog‘langan vazifa qo‘shish');
      await tester.enterText(
        find.byType(TextFormField).first,
        'Birinchi amaliy topshiriq',
      );
      await tap('Saqlash');
      expect(store.tasks.single.goalId, id);
      await tap('Arxivlash');
      await tap('Bekor qilish');
      expect(ui.goalPlan(id), isNull);
      await tap('Arxivlash');
      await tap('Tasdiqlash');
      expect(ui.goalPlan(id)!['archived'], true);
      await tap('Arxivdan chiqarish');
      await tap('Tasdiqlash');
      expect(ui.goalPlan(id)!['archived'], false);
      await tap('Maqsadni tahrirlash');
      await tester.enterText(
        find.byType(TextFormField).first,
        'Yangilangan loyiha',
      );
      await tap('Saqlash');
      expect(store.goals.single.title, 'Yangilangan loyiha');
      await tap('Maqsadni o‘chirish');
      await tap('Bekor qilish');
      expect(store.goals, hasLength(1));
      await tap('Maqsadni o‘chirish');
      await tap('Tasdiqlash');
      expect(store.goals, isEmpty);
      expect(store.tasks.single.goalId, isNull);
      expect(find.text('Maqsad topilmadi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'onboarding and goal pages render at $size with large text and keyboard',
      (tester) async {
        final (_, store, ui) = await setup();
        await store.addGoal(
          title: 'Ko‘rinish uchun maqsad',
          metric: 'natija',
          target: 1,
          deadline: store.today,
        );
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final draft = MLPGoalDraft(today: store.today, minutes: 25)
          ..title = 'Men tanlagan mustaqil maqsad'
          ..outcome = 'Haqiqiy amaliy natija'
          ..reason = 'Kelajakdagi kasb uchun';
        final screens = <Widget>[
          const MLPSplashScreen(),
          MLPWelcomeScreen(repository: ui),
          MLPRegistrationScreen(repository: ui),
          MLPLoginScreen(repository: ui),
          MLPPreferencesScreen(repository: ui),
          MLPGoalDiscoveryScreen(store: store, ui: ui),
          MLPGoalClarificationScreen(store: store, ui: ui, draft: draft),
          MLPDiagnosticScreen(store: store, ui: ui, draft: draft),
          MLPRoadmapScreen(store: store, ui: ui, draft: draft),
          MLPGoalDetailScreen(
            store: store,
            ui: ui,
            goalId: store.goals.single.id,
            onFocus: (_) {},
          ),
        ];
        for (final screen in screens) {
          await tester.pumpWidget(
            MaterialApp(
              theme: MLPTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.4),
                  disableAnimations: true,
                  viewInsets: const EdgeInsets.only(bottom: 160),
                ),
                child: child!,
              ),
              home: screen,
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} at $size',
          );
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
