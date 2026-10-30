import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mylife_plan/app/theme/mlp_design_system.dart';
import 'package:mylife_plan/core/design_system/mlp_appearance.dart';
import 'package:mylife_plan/data/repositories/mlp_ui_repository.dart';
import 'package:mylife_plan/features/lifestyle/mlp_background_settings.dart';

class _Picker implements MLPBackgroundPicker {
  _Picker({this.bytes, this.fail = false});
  final Uint8List? bytes;
  final bool fail;
  @override
  Future<Uint8List?> choose() async {
    if (fail) throw StateError('Galereya ochilmadi.');
    return bytes;
  }

  @override
  Future<Uint8List?> recoverLostImage() => choose();
}

class _Storage extends InMemorySharedPreferencesStore {
  _Storage() : super.empty();
  bool reject = false;
  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      reject ? Future.value(false) : super.setValue(valueType, key, value);
  @override
  Future<bool> remove(String key) =>
      reject ? Future.value(false) : super.remove(key);
}

Future<Uint8List> _png({
  int width = 40,
  int height = 60,
  Color color = Colors.blue,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return Uint8List.fromList(
      data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  } finally {
    picture.dispose();
    image.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test(
    'photo survives restart, is bounded, and confirmed reset removes only its own key',
    () async {
      await prefs.setString('existing_business_data', 'keep');
      final controller = MLPAppearanceController();
      await controller.init(prefs);
      final source = await _png(width: 3000, height: 1000);
      expect(await controller.chooseBackground(_Picker(bytes: source)), isTrue);
      final bytes = controller.backgroundBytes!;
      expect(bytes.length, lessThanOrEqualTo(MLPBackgroundImage.maxImageBytes));
      expect(
        prefs.getString(MLPAppearanceController.storageKey)!.length,
        lessThanOrEqualTo(MLPBackgroundImage.maxStoredCharacters),
      );
      final codec = await ui.instantiateImageCodec(bytes);
      final image = (await codec.getNextFrame()).image;
      expect(image.width, 1440);
      expect(image.height, 480);
      image.dispose();
      codec.dispose();
      final restored = MLPAppearanceController();
      await restored.init(prefs);
      expect(restored.backgroundBytes, orderedEquals(bytes));
      expect(restored.exportState()['png'], base64Encode(bytes));
      await restored.setBackground(null);
      expect(restored.backgroundBytes, isNull);
      expect(prefs.containsKey(MLPAppearanceController.storageKey), isFalse);
      expect(prefs.getString('existing_business_data'), 'keep');
      controller.dispose();
      restored.dispose();
    },
  );

  test(
    'picker cancellation and selection errors retain the previous background',
    () async {
      final controller = MLPAppearanceController();
      await controller.init(prefs);
      await controller.setBackground(await _png());
      final old = controller.backgroundBytes;
      final raw = prefs.getString(MLPAppearanceController.storageKey);
      expect(await controller.chooseBackground(_Picker()), isFalse);
      expect(identical(controller.backgroundBytes, old), isTrue);
      await expectLater(
        controller.chooseBackground(_Picker(fail: true)),
        throwsStateError,
      );
      expect(identical(controller.backgroundBytes, old), isTrue);
      expect(prefs.getString(MLPAppearanceController.storageKey), raw);
      controller.dispose();
    },
  );

  test(
    'invalid bytes and oversized input cannot replace an existing photo',
    () async {
      final controller = MLPAppearanceController();
      await controller.init(prefs);
      await controller.setBackground(await _png());
      final old = controller.backgroundBytes;
      await expectLater(
        controller.setBackground(
          Uint8List(MLPBackgroundImage.maxInputBytes + 1),
        ),
        throwsFormatException,
      );
      await expectLater(
        controller.setBackground(Uint8List.fromList([1, 2, 3])),
        throwsA(anything),
      );
      expect(identical(controller.backgroundBytes, old), isTrue);
      controller.dispose();
    },
  );

  test(
    'corrupt saved photo is preserved and cannot corrupt UI business state',
    () async {
      const raw = '{"version":1,"png":"not-a-photo"}';
      await prefs.setString(MLPAppearanceController.storageKey, raw);
      final controller = MLPAppearanceController();
      await controller.init(prefs);
      expect(controller.initialized, isTrue);
      expect(controller.backgroundBytes, isNull);
      expect(controller.error, isNotNull);
      expect(prefs.getString(MLPAppearanceController.storageKey), raw);
      final uiState = MLPLocalUiRepository(prefs);
      await uiState.init();
      await uiState.enterGuest(name: 'Azizbek');
      expect(uiState.requiresRecovery, isFalse);
      expect(uiState.profile?.name, 'Azizbek');
      await controller.setBackground(null);
      expect(uiState.profile?.name, 'Azizbek');
      uiState.dispose();
      controller.dispose();
    },
  );

  test(
    'failed write or reset never publishes a background that did not persist',
    () async {
      final oldPlatform = SharedPreferencesStorePlatform.instance;
      addTearDown(() => SharedPreferencesStorePlatform.instance = oldPlatform);
      final storage = _Storage();
      SharedPreferencesStorePlatform.instance = storage;
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = storage;
      final localPrefs = await SharedPreferences.getInstance();
      final controller = MLPAppearanceController();
      await controller.init(localPrefs);
      await controller.setBackground(await _png());
      final old = controller.backgroundBytes;
      final oldRaw = localPrefs.getString(MLPAppearanceController.storageKey);
      storage.reject = true;
      await expectLater(
        controller.setBackground(await _png(color: Colors.red)),
        throwsStateError,
      );
      expect(identical(controller.backgroundBytes, old), isTrue);
      expect(localPrefs.getString(MLPAppearanceController.storageKey), oldRaw);
      await expectLater(controller.setBackground(null), throwsStateError);
      expect(identical(controller.backgroundBytes, old), isTrue);
      storage.reject = false;
      await controller.setBackground(null);
      expect(controller.backgroundBytes, isNull);
      expect(controller.error, isNull);
      controller.dispose();
    },
  );

  test(
    'Android lost selection can recover through the same bounded persistent path',
    () async {
      final controller = MLPAppearanceController();
      await controller.init(prefs);
      await controller.recoverBackground(_Picker(bytes: await _png()));
      expect(controller.backgroundBytes, isNotNull);
      final saved = controller.backgroundBytes;
      await controller.recoverBackground(_Picker(fail: true));
      expect(identical(controller.backgroundBytes, saved), isTrue);
      expect(controller.error, isNotNull);
      controller.dispose();
    },
  );

  testWidgets(
    'settings chooser cancellation is explicit and layout handles small large-text screens',
    (tester) async {
      final controller = MLPAppearanceController();
      await controller.init(prefs);
      addTearDown(controller.dispose);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MLPAppearanceScope(
          controller: controller,
          child: MaterialApp(
            theme: MLPTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: MLPBackgroundSettingsPage(picker: _Picker()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Galereyadan rasm tanlash'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Galereyadan rasm tanlash'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Tanlash bekor qilindi. Avvalgi fon saqlandi.'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Tanlash bekor qilindi. Avvalgi fon saqlandi.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(controller.backgroundBytes, isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
