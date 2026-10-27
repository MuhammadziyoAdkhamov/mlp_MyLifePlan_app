import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mylife_plan/demo/demo_store.dart';
import 'package:mylife_plan/data/repositories/mlp_ui_repository.dart';

class _Storage extends InMemorySharedPreferencesStore {
  _Storage() : super.empty();
  bool fail = false;
  Completer<void>? hold;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (hold != null) await hold!.future;
    if (fail) return false;
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Storage platform;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final original = SharedPreferencesStorePlatform.instance;
    addTearDown(() => SharedPreferencesStorePlatform.instance = original);
    platform = _Storage();
    SharedPreferencesStorePlatform.instance = platform;
    prefs = await SharedPreferences.getInstance();
  });

  test(
    'UI write failure does not publish a guest; retry survives rejected platform write',
    () async {
      final ui = MLPLocalUiRepository(prefs);
      await ui.init();
      platform.fail = true;
      await expectLater(ui.enterGuest(), throwsStateError);
      expect(ui.profile, isNull);
      expect(ui.onboarded, false);
      expect(ui.error, isNotNull);
      final restored = MLPLocalUiRepository(prefs);
      await restored.init();
      expect(restored.profile, isNull);
      restored.dispose();
      platform.fail = false;
      await ui.enterGuest();
      expect(ui.onboarded, true);
      expect(ui.error, isNull);
      ui.dispose();
    },
  );

  test(
    'failed roadmap write rolls back only new goal/tasks; retry creates one plan',
    () async {
      final store = DemoStore(prefs);
      await store.init();
      final initial = store.exportJson();
      platform.fail = true;
      await expectLater(
        store.addGoalPlan(
          title: 'Yangi loyiha',
          category: 'Kasb',
          deadline: store.today,
          steps: [(title: 'Birinchi ish', minutes: 25, date: store.today)],
        ),
        throwsStateError,
      );
      expect(store.exportJson(), initial);
      expect(prefs.getString(DemoStore.storageKey), initial);
      expect(store.storageError, isNotNull);
      platform.fail = false;
      final id = await store.addGoalPlan(
        title: 'Yangi loyiha',
        category: 'Kasb',
        deadline: store.today,
        steps: [(title: 'Birinchi ish', minutes: 25, date: store.today)],
      );
      expect(store.goals.where((g) => g.id == id).length, 1);
      expect(store.tasks.where((t) => t.goalId == id).length, 1);
      expect(store.storageError, isNull);
      store.dispose();
    },
  );

  test(
    'pending roadmap blocks competing writes and reset until atomic save finishes',
    () async {
      final store = DemoStore(prefs);
      await store.init();
      platform.hold = Completer<void>();
      final save = store.addGoalPlan(
        title: 'Yangi loyiha',
        category: 'Kasb',
        deadline: store.today,
        steps: [(title: 'Birinchi ish', minutes: 25, date: store.today)],
      );
      expect(() => store.addTask(title: 'Parallel ish'), throwsStateError);
      expect(() => store.clearAll(), throwsStateError);
      await expectLater(store.importJson(store.exportJson()), throwsStateError);
      platform.hold!.complete();
      await save;
      platform.hold = null;
      await store.addTask(title: 'Keyingi ish');
      expect(store.tasks.where((t) => t.title == 'Keyingi ish').length, 1);
      store.dispose();
    },
  );
}
