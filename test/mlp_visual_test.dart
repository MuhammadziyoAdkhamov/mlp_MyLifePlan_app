import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mylife_plan/app/theme/mlp_design_system.dart';
import 'package:mylife_plan/data/repositories/mlp_ui_repository.dart';
import 'package:mylife_plan/demo/demo_store.dart';
import 'package:mylife_plan/features/onboarding/mlp_account_flow.dart';
import 'package:mylife_plan/features/goals/mlp_goal_flow.dart';
import 'package:mylife_plan/features/goals/mlp_goal_detail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final configFile = File('.dart_tool/package_config.json');
    final config = jsonDecode(configFile.readAsStringSync()) as Map;
    final package = (config['packages'] as List).cast<Map>().firstWhere(
      (p) => p['name'] == 'flutter',
    );
    final root = Directory.fromUri(
      configFile.absolute.uri.resolve(package['rootUri'] as String),
    ).parent.parent.path;
    final fonts = {
      'Segoe UI': File('C:/Windows/Fonts/segoeui.ttf'),
      'MaterialIcons': File(
        '$root/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/MaterialIcons-Regular.otf',
      ),
    };
    for (final entry in fonts.entries) {
      if (entry.value.existsSync()) {
        final loader = FontLoader(entry.key)
          ..addFont(
            Future.value(ByteData.sublistView(entry.value.readAsBytesSync())),
          );
        await loader.load();
      }
    }
  });

  testWidgets(
    'capture Phase B widget renders with actual text and icon fonts',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = DemoStore(prefs, now: () => DateTime(2026, 10, 26));
      await store.init();
      await store.clearAll();
      final repo = MLPLocalUiRepository(prefs);
      await repo.init();
      final draft = MLPGoalDraft(today: store.today, minutes: 30)
        ..title = 'Uch oyda Flutter ilova yaratish'
        ..category = 'Dasturlash'
        ..outcome = 'Ishlaydigan Android portfolio ilovasi'
        ..reason = 'Junior Flutter mutaxassisi bo‘lish';
      final id = await store.addGoalPlan(
        title: draft.title,
        category: draft.category,
        deadline: draft.deadline,
        steps: [
          (
            title: 'Birinchi ekran va navigatsiya',
            minutes: 25,
            date: store.today,
          ),
          (
            title: 'Forma va ma’lumot saqlash',
            minutes: 30,
            date: store.today.add(const Duration(days: 7)),
          ),
        ],
      );
      await repo.saveGoalPlan(id, {
        'outcome': draft.outcome,
        'reason': draft.reason,
        'startingLevel': draft.level,
        'prototype': true,
      });
      final screens = <({String name, Size size, Widget screen})>[
        (
          name: 'welcome-390',
          size: const Size(390, 844),
          screen: MLPWelcomeScreen(repository: repo),
        ),
        (
          name: 'login-320',
          size: const Size(320, 640),
          screen: MLPLoginScreen(repository: repo),
        ),
        (
          name: 'preferences-390',
          size: const Size(390, 844),
          screen: MLPPreferencesScreen(repository: repo),
        ),
        (
          name: 'clarification-390',
          size: const Size(390, 844),
          screen: MLPGoalClarificationScreen(
            store: store,
            ui: repo,
            draft: draft,
          ),
        ),
        (
          name: 'roadmap-390',
          size: const Size(390, 844),
          screen: MLPRoadmapScreen(store: store, ui: repo, draft: draft),
        ),
        (
          name: 'goal-detail-1440',
          size: const Size(1440, 900),
          screen: MLPGoalDetailScreen(
            store: store,
            ui: repo,
            goalId: id,
            onFocus: (_) {},
          ),
        ),
      ];
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final item in screens) {
        tester.view.physicalSize = item.size;
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: MLPTheme.dark,
              home: item.screen,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: item.name);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final png = await tester.runAsync(() async {
          final img = await boundary.toImage(pixelRatio: 1);
          final data = await img.toByteData(format: ui.ImageByteFormat.png);
          img.dispose();
          return data!.buffer.asUint8List();
        });
        final file = File('build/mlp_ui_phase_b/${item.name}.png');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(png!);
      }
      await tester.pumpWidget(const SizedBox());
      store.dispose();
      repo.dispose();
    },
  );
}
