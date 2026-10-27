import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mylife_plan/app/router/mlp_routes.dart';
import 'package:mylife_plan/app/theme/mlp_design_system.dart';
import 'package:mylife_plan/core/design_system/mlp_widgets.dart';
import 'package:mylife_plan/data/repositories/mlp_ui_repository.dart';
import 'package:mylife_plan/demo/demo_app.dart';
import 'package:mylife_plan/demo/demo_store.dart';
import 'package:mylife_plan/features/onboarding/mlp_account_flow.dart';

void main() {
  Future<(SharedPreferences, MLPLocalUiRepository)> setup() async {
    SharedPreferences.setMockInitialValues({'legacy': 'preserve'});
    final prefs = await SharedPreferences.getInstance();
    final repo = MLPLocalUiRepository(prefs);
    await repo.init();
    return (prefs, repo);
  }

  test('all 28 routes are unique and unknown routes parse safely', () {
    expect(MLPScreen.values.length, 28);
    expect(MLPScreen.values.map((s) => s.path).toSet().length, 28);
    expect(MLPScreen.parse('/missing'), isNull);
    expect(MLPScreen.parse('/goals/detail?id=abc'), MLPScreen.goalDetail);
  });

  test(
    'local registration never verifies identity and preserves legacy data',
    () async {
      final (prefs, repo) = await setup();
      expect(
        () =>
            repo.registerDemo(name: 'A', phone: '+998900000000', gender: 'Qiz'),
        throwsArgumentError,
      );
      expect(
        () => repo.registerDemo(name: 'Aziza', phone: '+100', gender: 'Qiz'),
        throwsArgumentError,
      );
      expect(prefs.getString(MLPLocalUiRepository.storageKey), isNull);
      await repo.registerDemo(
        name: 'Aziza',
        phone: '+998 90 000 00 00',
        gender: 'Qiz',
      );
      expect(repo.profile!.verified, false);
      expect(repo.onboarded, false);
      await repo.savePreferences(
        const MLPUserPreferences(minutes: 45, nickname: 'Hamroh'),
      );
      await repo.finishOnboarding();
      final restored = MLPLocalUiRepository(prefs);
      await restored.init();
      expect(restored.profile!.name, 'Aziza');
      expect(restored.preferences.minutes, 45);
      expect(restored.preferences.nickname, 'Hamroh');
      expect(restored.onboarded, true);
      await restored.exitSession();
      expect(restored.profile!.name, 'Aziza');
      expect(prefs.getString('legacy'), 'preserve');
    },
  );

  test('corrupt UI data is preserved until explicit reset', () async {
    final (prefs, _) = await setup();
    await prefs.setString(MLPLocalUiRepository.storageKey, '{broken');
    final repo = MLPLocalUiRepository(prefs);
    await repo.init();
    expect(repo.error, isNotNull);
    await expectLater(repo.enterGuest(), throwsStateError);
    expect(prefs.getString(MLPLocalUiRepository.storageKey), '{broken');
    await repo.resetUiData();
    await repo.enterGuest();
    expect(repo.profile!.guest, true);
    expect(repo.profile!.verified, false);
    expect(
      jsonDecode(prefs.getString(MLPLocalUiRepository.storageKey)!)['version'],
      1,
    );
  });

  testWidgets(
    'reduced motion and floating tab semantics work at 320px and large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      int selected = 0;
      late Duration duration;
      await tester.pumpWidget(
        MaterialApp(
          theme: MLPTheme.dark,
          home: MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(1.5),
            ),
            child: Builder(
              builder: (context) {
                duration = MLPDimensions.motion(context);
                return MLPScaffold(
                  body: const SizedBox(),
                  bottomNavigationBar: MLPFloatingTabBar(
                    index: selected,
                    onChanged: (i) => selected = i,
                  ),
                );
              },
            ),
          ),
        ),
      );
      expect(duration, Duration.zero);
      await tester.tap(find.text('Profil'));
      expect(selected, 4);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'production entry supports guest and leaves existing goals intact',
    (tester) async {
      final (prefs, _) = await setup();
      final store = DemoStore(prefs);
      await store.init();
      final count = store.goals.length;
      await tester.pumpWidget(MplDemoApp(store: store, prefs: prefs));
      await tester.pumpAndSettle();
      expect(find.byType(MLPWelcomeScreen), findsOneWidget);
      await tester.ensureVisible(find.text('Mehmon sifatida kirish'));
      await tester.tap(find.text('Mehmon sifatida kirish'));
      await tester.pumpAndSettle();
      expect(find.text('BUGUNGI ASOSIY QADAM'), findsOneWidget);
      expect(store.goals.length, count);
      expect(prefs.getString('legacy'), 'preserve');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MplDemoApp(store: store, prefs: prefs));
      await tester.pumpAndSettle();
      expect(find.byType(MLPWelcomeScreen), findsNothing);
      expect(find.text('BUGUNGI ASOSIY QADAM'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );

  testWidgets(
    'registration validates and proceeds to preferences without OTP',
    (tester) async {
      final (_, repo) = await setup();
      await tester.pumpWidget(
        MaterialApp(
          theme: MLPTheme.dark,
          home: MLPRegistrationScreen(repository: repo),
        ),
      );
      await tester.ensureVisible(find.text('Davom etish'));
      await tester.tap(find.text('Davom etish'));
      await tester.pumpAndSettle();
      expect(find.text('Kamida 2 belgilik ism kiriting.'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Aziz');
      await tester.enterText(fields.at(1), '+998900000000');
      await tester.ensureVisible(find.text('Davom etish'));
      await tester.tap(find.text('Davom etish'));
      await tester.pumpAndSettle();
      expect(find.byType(MLPPreferencesScreen), findsOneWidget);
      expect(repo.profile!.verified, false);
      expect(find.textContaining('SMS yuborildi'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'production registration saves preferences and allows editing them later',
    (tester) async {
      final (prefs, _) = await setup();
      final store = DemoStore(prefs);
      await store.init();
      await tester.pumpWidget(MplDemoApp(store: store, prefs: prefs));
      await tester.pumpAndSettle();
      Future<void> tap(String text) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(text));
        await tester.pumpAndSettle();
        await tester.tap(find.text(text));
        await tester.pumpAndSettle();
      }

      await tap('Boshlash');
      await tester.enterText(find.byType(TextFormField).at(0), 'Aziza');
      await tester.enterText(find.byType(TextFormField).at(1), '+998900000000');
      await tap('Davom etish');
      await tester.enterText(find.byType(TextFormField).at(0), '45');
      await tester.enterText(find.byType(TextFormField).at(1), 'Hamroh');
      await tap('MLPni boshlash');
      expect(find.text('BUGUNGI ASOSIY QADAM'), findsOneWidget);
      var fresh = MLPLocalUiRepository(prefs);
      await fresh.init();
      expect(fresh.profile!.name, 'Aziza');
      expect(fresh.profile!.verified, false);
      expect(fresh.preferences.minutes, 45);
      expect(fresh.preferences.nickname, 'Hamroh');
      fresh.dispose();
      await tester.tap(find.byTooltip('Sozlamalar'));
      await tester.pumpAndSettle();
      await tap('Shaxsiy tanlovlar');
      expect(find.byType(MLPPreferencesScreen), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '60');
      await tap('Saqlash');
      fresh = MLPLocalUiRepository(prefs);
      await fresh.init();
      expect(fresh.preferences.minutes, 60);
      expect(fresh.preferences.nickname, 'Hamroh');
      fresh.dispose();
      expect(find.text('BUGUNGI ASOSIY QADAM'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
