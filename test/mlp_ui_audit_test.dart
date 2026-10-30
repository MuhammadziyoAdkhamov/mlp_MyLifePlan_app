import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mylife_plan/app/mlp_environment.dart';
import 'package:mylife_plan/app/router/mlp_routes.dart';
import 'package:mylife_plan/app/theme/mlp_design_system.dart';
import 'package:mylife_plan/core/design_system/mlp_liquid_glass.dart';
import 'package:mylife_plan/core/design_system/mlp_confetti.dart';
import 'package:mylife_plan/core/design_system/mlp_device_frame.dart';
import 'package:mylife_plan/core/design_system/mlp_widgets.dart';
import 'package:mylife_plan/data/repositories/mlp_ui_repository.dart';
import 'package:mylife_plan/demo/demo_store.dart';
import 'package:mylife_plan/features/focus/mlp_focus_controller.dart';
import 'package:mylife_plan/features/ai_companion/mlp_companion_pages.dart';
import 'package:mylife_plan/features/workspace/mlp_workspace_pages.dart';

class _RejectableStorage extends InMemorySharedPreferencesStore {
  _RejectableStorage() : super.empty();
  bool reject = false;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      reject ? false : super.setValue(valueType, key, value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DemoStore store;
  late MLPLocalUiRepository repo;
  late MLPFocusController focus;
  late MLPEnvironment e;
  late _RejectableStorage storage;
  final navigator = GlobalKey<NavigatorState>();
  final now = DateTime(2026, 10, 28, 18);

  Future<void> prepare() async {
    SharedPreferences.setMockInitialValues({});
    final previous = SharedPreferencesStorePlatform.instance;
    addTearDown(() => SharedPreferencesStorePlatform.instance = previous);
    storage = _RejectableStorage();
    SharedPreferencesStorePlatform.instance = storage;
    final prefs = await SharedPreferences.getInstance();
    store = DemoStore(prefs, now: () => now);
    await store.init();
    repo = MLPLocalUiRepository(prefs);
    await repo.init();
    await repo.enterGuest();
    focus = MLPFocusController(store, repo, clock: () => now);
    e = MLPEnvironment(
      store: store,
      ui: repo,
      prefs: prefs,
      focus: focus,
      clock: () => now,
      go: (screen, {args}) async {
        await navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => screen == MLPScreen.voice
                ? MLPVoicePage(e: e)
                : MLPChatPage(e: e),
          ),
        );
      },
      tab: (_) {},
      legacy: () => const SizedBox(),
    );
  }

  tearDown(() {
    focus.dispose();
    repo.dispose();
    store.dispose();
  });

  Widget app(Widget child, {bool reduce = true, double scale = 1}) =>
      MaterialApp(
        navigatorKey: navigator,
        theme: MLPTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduce,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: Scaffold(body: child),
      );

  testWidgets('reduced-motion chat scrolls and persists a new turn', (
    tester,
  ) async {
    await prepare();
    for (var i = 0; i < 12; i++) {
      await repo.saveConversationTurn(
        'Oldingi savol $i',
        'Oldingi javob $i',
        now,
      );
    }
    await tester.pumpWidget(app(MLPChatPage(e: e)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Flutter nima?');
    await tester.tap(find.byTooltip('Xabarni yuborish'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(repo.messages.length, 26);
    expect(repo.messages.last['text'], contains('jonli model emas'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'ending voice returns to the original chat without duplicate routes',
    (tester) async {
      await prepare();
      await tester.pumpWidget(app(MLPChatPage(e: e)));
      await tester.pumpAndSettle();
      final before = tester.state(find.byType(MLPChatPage));
      await tester.tap(find.byTooltip('Ovozli suhbat ko‘rinishi'));
      await tester.pumpAndSettle();
      final end = find.byTooltip('Suhbatni tugatish va chatga qaytish');
      await tester.scrollUntilVisible(
        end,
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(end);
      await tester.pumpAndSettle();
      expect(find.byType(MLPVoicePage), findsNothing);
      expect(tester.state(find.byType(MLPChatPage)), same(before));
      expect(navigator.currentState!.canPop(), false);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('dialog and secondary page respect reduced motion', (
    tester,
  ) async {
    await prepare();
    late BuildContext origin;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            origin = context;
            return const Text('Origin');
          },
        ),
      ),
    );
    mlpShowDialog<void>(
      context: origin,
      builder: (_) => const AlertDialog(title: Text('Dialog')),
    );
    await tester.pump();
    final dialogContext = tester.element(find.byType(AlertDialog));
    expect(ModalRoute.of(dialogContext)!.transitionDuration, Duration.zero);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    const child = Text('Secondary');
    final result = const MLPPageTransitionsBuilder().buildTransitions<void>(
      MaterialPageRoute<void>(builder: (_) => child),
      origin,
      const AlwaysStoppedAnimation(.2),
      const AlwaysStoppedAnimation(0),
      child,
    );
    expect(result, same(child));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('floating tabs stay at the bottom without covering the body', (
    tester,
  ) async {
    await prepare();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: MLPTheme.dark,
        home: MLPScaffold(
          body: const Center(child: Text('Body content')),
          bottomNavigationBar: MLPFloatingTabBar(index: 0, onChanged: (_) {}),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(MLPFloatingTabBar));
    expect(rect.height, lessThan(150));
    expect(rect.bottom, 852);
    expect(rect.top, greaterThan(700));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final reduce in [true, false]) {
    testWidgets(
      'celebration fits 320px at large text, reduced motion $reduce',
      (tester) async {
        await prepare();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        late BuildContext origin;
        await tester.pumpWidget(
          app(
            Builder(
              builder: (context) {
                origin = context;
                return const SizedBox();
              },
            ),
            reduce: reduce,
            scale: 2,
          ),
        );
        MLPConfetti.show(
          origin,
          title: 'Uzoq nomli kundalik dasturlash odati bajarildi',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('Natijangiz saqlandi'), findsOneWidget);
        if (reduce) expect(tester.binding.hasScheduledFrame, false);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(find.text('Natijangiz saqlandi'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'habit controls have a 48px target and rejected write reports failure',
    (tester) async {
      await prepare();
      await store.clearAll();
      await store.addHabit(title: 'Sinov odati');
      await tester.pumpWidget(app(MLPDetailedTodayPage(e: e)));
      await tester.pumpAndSettle();
      expect(find.text('⚡ Jami ${store.xp} XP'), findsOneWidget);
      final control = find.byTooltip('Sinov odati: +1 qo‘shish');
      await tester.scrollUntilVisible(
        control,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.getSize(control).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
      storage.reject = true;
      await tester.tap(control);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(store.storageError, isNotNull);
      expect(find.textContaining('+15 XP hisobingizda'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'web frame supplies local dimensions, safe insets and reversible toggle',
    (tester) async {
      await prepare();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      late MediaQueryData viewport;
      final content = Builder(
        builder: (context) {
          viewport = MediaQuery.of(context);
          return const Scaffold(body: SafeArea(child: Text('Frame content')));
        },
      );
      final frame = MaterialApp(
        theme: MLPTheme.dark,
        home: MLPIPhoneFrame(enabled: true, child: content),
      );
      await tester.pumpWidget(frame);
      expect(viewport.size.width, lessThan(430));
      expect(viewport.padding.top, 44);
      await tester.tap(find.text('Keng ekranga o‘tish'));
      await tester.pumpAndSettle();
      expect(find.text('Mobil ko‘rinish'), findsOneWidget);
      await tester.tap(find.text('Mobil ko‘rinish'));
      await tester.pumpAndSettle();
      expect(viewport.padding.top, 44);
      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpAndSettle();
      expect(find.text('MLP · Mobil ko‘rinish namunasi'), findsNothing);
      expect(find.text('Frame content'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
