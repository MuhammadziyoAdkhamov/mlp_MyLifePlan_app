import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mylife_plan/app/mlp_environment.dart';
import 'package:mylife_plan/app/mlp_product_shell.dart';
import 'package:mylife_plan/app/router/mlp_routes.dart';
import 'package:mylife_plan/app/theme/mlp_design_system.dart';
import 'package:mylife_plan/core/design_system/mlp_widgets.dart';
import 'package:mylife_plan/data/repositories/mlp_ui_repository.dart';
import 'package:mylife_plan/demo/demo_store.dart';
import 'package:mylife_plan/features/focus/mlp_focus_controller.dart';
import 'package:mylife_plan/features/focus/mlp_focus_pages.dart';
import 'package:mylife_plan/features/ai_companion/mlp_companion_pages.dart';
import 'package:mylife_plan/features/progress/mlp_progress_pages.dart';
import 'package:mylife_plan/features/lifestyle/mlp_lifestyle_pages.dart';
import 'package:mylife_plan/features/workspace/mlp_workspace_pages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late DemoStore store;
  late MLPLocalUiRepository ui;
  late MLPFocusController focus;
  late MLPEnvironment e;
  late DateTime now;
  Future<void> prepare() async {
    SharedPreferences.setMockInitialValues({'legacy': 'preserve'});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 10, 27, 18);
    store = DemoStore(prefs, now: () => now);
    await store.init();
    ui = MLPLocalUiRepository(prefs);
    await ui.init();
    await ui.enterGuest(name: 'Azizbek');
    focus = MLPFocusController(store, ui, clock: () => now);
    e = MLPEnvironment(
      store: store,
      ui: ui,
      prefs: prefs,
      focus: focus,
      clock: () => now,
      go: (_, {args}) async {},
      tab: (_) {},
      legacy: () => const Scaffold(body: Text('Legacy preserved')),
    );
  }

  tearDown(() {
    focus.dispose();
    ui.dispose();
    store.dispose();
  });
  Widget app(Widget child) => MaterialApp(theme: MLPTheme.dark, home: child);

  test(
    'focus records actual seconds once and restores paused without background credit',
    () async {
      await prepare();
      final before = store.focusSessions.length;
      final task = store.todayTasks.first;
      focus.configure(25, 5, task: task.id);
      focus.start();
      now = now.add(const Duration(seconds: 47));
      focus.tick();
      focus.pause();
      await focus.persist();
      now = now.add(const Duration(hours: 4));
      final restoredUi = MLPLocalUiRepository(prefs);
      await restoredUi.init();
      final restored = MLPFocusController(store, restoredUi, clock: () => now);
      expect(restored.elapsed, 47);
      expect(restored.running, false);
      await restored.save('Birinchi widgetni tuzdim.', '');
      expect(store.focusSessions.length, before + 1);
      final saved = store.focusSessions.last;
      expect(saved.seconds, 47);
      expect(saved.taskId, task.id);
      expect(saved.note, 'Birinchi widgetni tuzdim.');
      await store.saveDetailedFocus(
        id: saved.id!,
        seconds: 47,
        note: saved.note,
        evidenceUrl: '',
      );
      expect(store.focusSessions.length, before + 1);
      expect(store.tasks.firstWhere((t) => t.id == task.id).completed, false);
      restored.dispose();
      restoredUi.dispose();
    },
  );
  test(
    'breaks never add work; session ids remain unique with a fixed clock',
    () async {
      await prepare();
      final count = store.focusSessions.length;
      focus.configure(5, 5, rest: true);
      final first = focus.sessionId;
      focus.start();
      now = now.add(const Duration(seconds: 20));
      focus.tick();
      await focus.save('', '');
      expect(store.focusSessions.length, count);
      focus.configure(25, 5);
      final second = focus.sessionId;
      await focus.discard();
      focus.configure(25, 5);
      expect(focus.sessionId, isNot(second));
      expect(second, isNot(first));
    },
  );
  test(
    'supplemental state survives restart and malformed data preserves raw storage',
    () async {
      await prepare();
      await ui.saveConversationTurn('Rejam qanday?', 'Demo javob.', now);
      await ui.saveAssessment(
        quiz: 'Flutter asoslari',
        correct: 2,
        total: 3,
        at: now,
      );
      await ui.toggleFavorite('forest');
      await ui.selectCity('Buxoro');
      await ui.saveSoundIntent('Tabiat', 30);
      await ui.useCosmetic('cyan');
      final fresh = MLPLocalUiRepository(prefs);
      await fresh.init();
      expect(fresh.messages.length, 2);
      expect(fresh.assessments.single['correct'], 2);
      expect(fresh.favorites, ['forest']);
      expect(fresh.city, 'Buxoro');
      expect(fresh.soundIntent['sleep'], 30);
      expect(fresh.cosmetic, 'cyan');
      fresh.dispose();
      final broken = jsonDecode(ui.exportUiState()) as Map<String, dynamic>;
      broken['assessments'] = [
        {'correct': 'fake'},
      ];
      final raw = jsonEncode(broken);
      await prefs.setString(MLPLocalUiRepository.storageKey, raw);
      final recovery = MLPLocalUiRepository(prefs);
      await recovery.init();
      expect(recovery.requiresRecovery, true);
      expect(prefs.getString(MLPLocalUiRepository.storageKey), raw);
      expect(prefs.getString('legacy'), 'preserve');
      recovery.dispose();
    },
  );
  test(
    'predefined assessment scoring is independent of activity and self report',
    () async {
      await prepare();
      final xp = store.xp;
      expect(MLPQuizCatalog.score('Flutter asoslari', [null, null, null]), 0);
      expect(MLPQuizCatalog.score('Flutter asoslari', [0, 1, 2]), 3);
      await ui.saveAssessment(
        quiz: 'Flutter asoslari',
        correct: 0,
        total: 3,
        at: now,
      );
      await ui.saveAssessment(
        quiz: 'Flutter asoslari',
        correct: 3,
        total: 3,
        at: now,
      );
      expect(ui.assessments.length, 1);
      expect(store.xp, xp);
    },
  );
  testWidgets(
    'all production tabs and every secondary route build; missing arguments recover',
    (tester) async {
      await prepare();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          MLPProductShell(
            store: store,
            ui: ui,
            prefs: prefs,
            clock: () => now,
            legacyBuilder: e.legacy,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('BUGUNGI ASOSIY QADAM'), findsOneWidget);
      for (final index in [1, 2, 3, 4, 0]) {
        final bar = tester.widget<MLPFloatingTabBar>(
          find.byType(MLPFloatingTabBar),
        );
        bar.onChanged(index);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'tab $index');
      }
      final nav = tester.state<NavigatorState>(find.byType(Navigator).last);
      for (final screen in MLPScreen.values.where(
        (s) => ![
          MLPScreen.splash,
          MLPScreen.today,
          MLPScreen.focus,
          MLPScreen.chat,
          MLPScreen.profile,
        ].contains(s),
      )) {
        nav.pushNamed<void>(screen.path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: screen.path);
        nav.pop();
        await tester.pumpAndSettle();
      }
      nav.pushNamed<void>('/unknown');
      await tester.pumpAndSettle();
      expect(find.text('Bu manzil mavjud emas'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'chat sends one persisted deterministic turn and has no live AI claim',
    (tester) async {
      await prepare();
      await tester.pumpWidget(app(Scaffold(body: MLPChatPage(e: e))));
      await tester.enterText(find.byType(TextField), 'Flutter nima?');
      await tester.tap(find.byTooltip('Xabarni yuborish'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(ui.messages.length, 2);
      expect(ui.messages.last['text'], contains('jonli model emas'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('focus ring remains a separate semantic node from its controls', (
    tester,
  ) async {
    await prepare();
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(Scaffold(body: MLPFocusHub(e: e))));
    await tester.scrollUntilVisible(
      find.text('Fokusni boshlash'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Fokusni boshlash'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Fokus. Qolgan vaqt')), findsOneWidget);
    handle.dispose();
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'responsive pages support 320, standard, large text and landscape',
    (tester) async {
      await prepare();
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      final pages = <Widget>[
        MLPTodayPage(e: e),
        MLPGoalsPage(e: e),
        MLPFocusHub(e: e),
        MLPActiveFocusPage(e: e),
        MLPFocusSummaryPage(e: e),
        MLPVoicePage(e: e),
        MLPAIPreferencesPage(e: e),
        MLPVerificationPage(e: e),
        MLPPassportPage(e: e),
        MLPGrowthPage(e: e),
        MLPRewardsPage(e: e),
        MLPWeatherPage(e: e),
        MLPSoundspacePage(e: e),
        MLPProfilePage(e: e),
        MLPSettingsPage(e: e),
        MLPNotificationsPage(e: e),
      ];
      for (final config in [
        (const Size(320, 740), 1.0),
        (const Size(390, 844), 1.4),
        (const Size(430, 932), 2.0),
        (const Size(844, 390), 1.0),
      ]) {
        tester.view.physicalSize = config.$1;
        for (final page in pages) {
          await tester.pumpWidget(
            app(
              MediaQuery(
                data: MediaQueryData(
                  size: config.$1,
                  textScaler: TextScaler.linear(config.$2),
                ),
                child: Scaffold(body: page),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${page.runtimeType} ${config.$1} scale ${config.$2}',
          );
          await tester.pumpWidget(const SizedBox());
        }
      }
    },
  );
  testWidgets(
    'production Today to focus to summary saves actual activity and keeps task open',
    (tester) async {
      await prepare();
      final count = store.focusSessions.length;
      await tester.pumpWidget(
        app(
          MLPProductShell(
            store: store,
            ui: ui,
            prefs: prefs,
            clock: () => now,
            legacyBuilder: e.legacy,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Fokusni boshlash'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fokusni boshlash'));
      await tester.pumpAndSettle();
      final active = tester.widget<MLPActiveFocusPage>(
        find.byType(MLPActiveFocusPage),
      );
      final taskId = active.e.focus.taskId;
      now = now.add(const Duration(seconds: 53));
      active.e.focus.tick();
      await tester.ensureVisible(find.text('Yakunlash'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yakunlash'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Maqsadga oid birinchi widgetni yaratdim.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sessiyani saqlash'));
      await tester.pumpAndSettle();
      expect(active.e.focus.elapsed, 53);
      await tester.tap(find.text('Sessiyani saqlash'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(store.focusSessions.length, count + 1);
      expect(store.focusSessions.last.seconds, 53);
      expect(store.tasks.firstWhere((t) => t.id == taskId).completed, false);
      expect(find.byType(MLPFocusHub), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'unknown sample answers persist zero score without XP or mastery claims',
    (tester) async {
      await prepare();
      final xp = store.xp;
      await tester.pumpWidget(app(MLPVerificationPage(e: e)));
      for (var i = 0; i < 3; i++) {
        await tester.scrollUntilVisible(
          find.text('Bilmayman'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Bilmayman'));
        await tester.pumpAndSettle();
        final next = find.text(i == 2 ? 'Natijani ko‘rish' : 'Keyingi savol');
        await tester.ensureVisible(next);
        await tester.pumpAndSettle();
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Natijani saqlash'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Natijani saqlash'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(ui.assessments.single['correct'], 0);
      expect(store.xp, xp);
      expect(find.textContaining('Qayta mashq kerak'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'rewards lock unavailable cosmetics and selecting a virtual reward persists',
    (tester) async {
      await prepare();
      await store.clearAll();
      await tester.pumpWidget(app(MLPRewardsPage(e: e)));
      await tester.tap(find.text('Binafsha intilish'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MLPPrimaryButton>(
              find.widgetWithText(MLPPrimaryButton, 'Hozircha yopiq'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Yopish'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Firuza boshlanish'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Profilga qo‘llash'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profilga qo‘llash'));
      await tester.pumpAndSettle();
      expect(ui.cosmetic, 'cyan');
      expect(ui.claimedRewards, ['cyan']);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'sound catalog favorites persist without pretending audio playback',
    (tester) async {
      await prepare();
      await tester.pumpWidget(app(MLPSoundspacePage(e: e)));
      await tester.tap(
        find.byTooltip('Sevimlilarga qo‘shish yoki olib tashlash').first,
      );
      await tester.pumpAndSettle();
      expect(ui.favorites, ['deep']);
      await tester.tap(find.text('Chuqur diqqat'));
      await tester.pumpAndSettle();
      expect(find.textContaining('audio mavjud emas'), findsOneWidget);
      await tester.ensureVisible(find.text('Nega ovoz yo‘q?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nega ovoz yo‘q?'));
      await tester.pumpAndSettle();
      expect(find.text('Audio hali ulanmagan'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'system back pauses focus, returns from nested pages and launcher can be hidden',
    (tester) async {
      await prepare();
      await tester.pumpWidget(
        app(
          MLPProductShell(
            store: store,
            ui: ui,
            prefs: prefs,
            clock: () => now,
            legacyBuilder: e.legacy,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ustoz tezkor tugmasini yashirish'));
      await tester.pumpAndSettle();
      expect(ui.assistantHidden, true);
      expect(find.byTooltip('Ustozni ochish'), findsNothing);
      await tester.ensureVisible(find.text('Fokusni boshlash'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fokusni boshlash'));
      await tester.pumpAndSettle();
      final controller = tester
          .widget<MLPActiveFocusPage>(find.byType(MLPActiveFocusPage))
          .e
          .focus;
      now = now.add(const Duration(seconds: 10));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MLPActiveFocusPage), findsNothing);
      expect(controller.running, false);
      expect(controller.elapsed, 10);
      final bar = tester.widget<MLPFloatingTabBar>(
        find.byType(MLPFloatingTabBar),
      );
      bar.onChanged(4);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('BUGUNGI ASOSIY QADAM'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
