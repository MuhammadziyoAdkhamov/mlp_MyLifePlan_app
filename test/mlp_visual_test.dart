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
import 'package:mylife_plan/features/planner/mlp_calendar.dart';
import 'package:mylife_plan/features/planner/mlp_schedule_editor.dart';
import 'package:mylife_plan/data/models/mlp_schedule.dart';
import 'package:mylife_plan/app/mlp_environment.dart';
import 'package:mylife_plan/app/mlp_product_shell.dart';
import 'package:mylife_plan/core/design_system/mlp_widgets.dart';
import 'package:mylife_plan/core/design_system/mlp_appearance.dart';
import 'package:mylife_plan/features/focus/mlp_focus_controller.dart';
import 'package:mylife_plan/features/focus/mlp_focus_pages.dart';
import 'package:mylife_plan/features/ai_companion/mlp_companion_pages.dart';
import 'package:mylife_plan/features/progress/mlp_progress_pages.dart';
import 'package:mylife_plan/features/lifestyle/mlp_lifestyle_pages.dart';
import 'package:mylife_plan/features/lifestyle/mlp_background_settings.dart';
import 'package:mylife_plan/features/workspace/mlp_workspace_pages.dart';

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
    final cupertinoPackage = (config['packages'] as List)
        .cast<Map>()
        .firstWhere((p) => p['name'] == 'cupertino_icons');
    final cupertinoRoot = Directory.fromUri(
      configFile.absolute.uri.resolve(cupertinoPackage['rootUri'] as String),
    ).path;
    final fonts = {
      'Segoe UI': File('C:/Windows/Fonts/segoeui.ttf'),
      'Segoe UI Emoji': File('C:/Windows/Fonts/seguiemj.ttf'),
      'MaterialIcons': File(
        '$root/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/MaterialIcons-Regular.otf',
      ),
      'packages/cupertino_icons/CupertinoIcons': File(
        '$cupertinoRoot/assets/CupertinoIcons.ttf',
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

  testWidgets('capture Liquid Glass screens with real fonts and decoded scene assets', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = MLPAppearanceController();
    addTearDown(appearance.dispose);
    await appearance.init(prefs);
    // This is an isolated, deterministic visual fixture. Public APIs create
    // every visible count and history item; no production preferences change.
    final day = DateTime(2026, 10, 25);
    var fixtureNow = DateTime(2026, 10, 25, 18);
    final store = DemoStore(prefs, now: () => fixtureNow);
    addTearDown(store.dispose);
    await store.init();
    await store.clearAll();
    final repo = MLPLocalUiRepository(prefs);
    addTearDown(repo.dispose);
    await repo.init();
    await repo.enterGuest(name: 'Azizbek');
    final focus = MLPFocusController(store, repo, clock: () => fixtureNow);
    addTearDown(focus.dispose);
    final env = MLPEnvironment(
      store: store,
      ui: repo,
      prefs: prefs,
      focus: focus,
      clock: () => fixtureNow,
      go: (_, {args}) async {},
      tab: (_) {},
      legacy: () => const SizedBox(),
    );
    final draft = MLPGoalDraft(today: store.today, minutes: 30)
      ..title = 'MLP ustida ishlash'
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
    await store.addGoalPlan(
      title: 'Klaviatura va qaramay yozish',
      category: 'Shaxsiy rivojlanish',
      deadline: day.add(const Duration(days: 30)),
      steps: [(title: 'Asosiy tugmalar bilan mashq', minutes: 25, date: day)],
    );
    await store.addGoalPlan(
      title: 'Ingliz tili o‘qish',
      category: 'Ta’lim',
      deadline: day.add(const Duration(days: 60)),
      steps: [
        (title: 'Ingliz tilida 10 ta yangi so‘z', minutes: 25, date: day),
      ],
    );
    await store.addTask(
      title: 'Sport bilan shug‘ullanish',
      project: 'Sog‘liq',
      minutes: 25,
      priority: 3,
      dueDate: day,
    );
    final firstTask = store.tasks.first;
    final writingTask = store.tasks[2];
    final englishTask = store.tasks[3];
    const dailyMinutes = [35, 42, 90, 40, 25, 55, 40];
    for (var i = 0; i < dailyMinutes.length; i++) {
      fixtureNow = day
          .subtract(Duration(days: 6 - i))
          .add(const Duration(hours: 16));
      await store.saveDetailedFocus(
        id: 'visual-session-$i',
        taskId: i.isEven ? englishTask.id : writingTask.id,
        seconds: dailyMinutes[i] * 60,
        note: 'Vizual sinov uchun saqlangan mashg‘ulot qaydi.',
      );
    }
    fixtureNow = day.add(const Duration(hours: 18));
    await store.submitTask(
      englishTask.id,
      'O‘nta yangi so‘zni o‘qidim va misol gaplarni yozib chiqdim.',
    );
    await store.saveDetailedFocus(
      id: 'visual-current-task',
      taskId: firstTask.id,
      seconds: 300,
      note: 'Birinchi ekran tuzilmasi va widgetlarni rejaladim.',
    );
    expect(
      store.focusSessions.fold<int>(0, (sum, item) => sum + item.seconds),
      332 * 60,
    );
    focus.configure(25, 5, task: firstTask.id);
    final schedule = MLPSchedule(
      id: 'preview-schedule',
      title: 'Duolingo mashg‘uloti',
      date: store.today,
      startMinute: 1200,
      endMinute: 1215,
      repeat: MLPRepeat.daily,
      reminderMinutes: 5,
      appLink: 'https://www.duolingo.com',
    );
    await repo.saveSchedule(schedule);
    final screens = <({String name, Size size, Widget screen})>[
      (
        name: 'today-390',
        size: const Size(390, 844),
        screen: MLPProductShell(
          store: store,
          ui: repo,
          prefs: prefs,
          clock: env.clock,
          legacyBuilder: env.legacy,
        ),
      ),
      (
        name: 'projects-390',
        size: const Size(390, 844),
        screen: MLPScaffold(
          body: MLPIosPlanPage(e: env, initialGoals: true),
          bottomNavigationBar: MLPFloatingTabBar(index: 1, onChanged: (_) {}),
        ),
      ),
      (
        name: 'tasks-390',
        size: const Size(390, 844),
        screen: MLPScaffold(
          body: MLPIosPlanPage(e: env),
          bottomNavigationBar: MLPFloatingTabBar(index: 3, onChanged: (_) {}),
        ),
      ),
      (
        name: 'focus-390',
        size: const Size(390, 844),
        screen: MLPScaffold(
          title: 'Fokus',
          body: MLPFocusHub(e: env),
          bottomNavigationBar: MLPFloatingTabBar(index: 2, onChanged: (_) {}),
        ),
      ),
      (
        name: 'active-focus-390',
        size: const Size(390, 844),
        screen: MLPActiveFocusPage(e: env),
      ),
      (
        name: 'focus-summary-390',
        size: const Size(390, 844),
        screen: MLPFocusSummaryPage(e: env),
      ),
      (
        name: 'chat-390',
        size: const Size(390, 844),
        screen: MLPScaffold(body: MLPChatPage(e: env, showBack: true)),
      ),
      (
        name: 'profile-390',
        size: const Size(390, 844),
        screen: MLPScaffold(body: MLPProfilePage(e: env, showBack: true)),
      ),
      (
        name: 'ai-preferences-390',
        size: const Size(390, 844),
        screen: MLPAIPreferencesPage(e: env),
      ),
      (
        name: 'voice-390',
        size: const Size(390, 844),
        screen: MLPVoicePage(e: env),
      ),
      (
        name: 'growth-390',
        size: const Size(390, 844),
        screen: MLPScaffold(
          body: MLPGrowthPage(e: env, embedded: true),
          bottomNavigationBar: MLPFloatingTabBar(index: 4, onChanged: (_) {}),
        ),
      ),
      (
        name: 'rewards-390',
        size: const Size(390, 844),
        screen: MLPRewardsPage(e: env),
      ),
      (
        name: 'weather-390',
        size: const Size(390, 844),
        screen: MLPWeatherPage(e: env),
      ),
      (
        name: 'soundspace-390',
        size: const Size(390, 844),
        screen: MLPSoundspacePage(e: env),
      ),
      (
        name: 'calendar-390',
        size: const Size(390, 844),
        screen: MLPCalendarScreen(
          store: store,
          ui: repo,
          clock: () => fixtureNow,
        ),
      ),
      (
        name: 'registration-390',
        size: const Size(390, 844),
        screen: MLPRegistrationScreen(repository: repo),
      ),
      (
        name: 'schedule-editor-390',
        size: const Size(390, 844),
        screen: MLPScheduleEditor(store: store, ui: repo, existing: schedule),
      ),
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
      (
        name: 'splash-390',
        size: const Size(390, 844),
        screen: const TickerMode(enabled: false, child: MLPSplashScreen()),
      ),
      (
        name: 'discovery-390',
        size: const Size(390, 844),
        screen: MLPGoalDiscoveryScreen(store: store, ui: repo),
      ),
      (
        name: 'diagnostic-390',
        size: const Size(390, 844),
        screen: MLPDiagnosticScreen(store: store, ui: repo, draft: draft),
      ),
      (
        name: 'verification-390',
        size: const Size(390, 844),
        screen: MLPVerificationPage(e: env, initialTaskId: firstTask.id),
      ),
      (
        name: 'passport-390',
        size: const Size(390, 844),
        screen: MLPPassportPage(e: env),
      ),
      (
        name: 'settings-390',
        size: const Size(390, 844),
        screen: MLPSettingsPage(e: env),
      ),
      (
        name: 'notifications-390',
        size: const Size(390, 844),
        screen: MLPNotificationsPage(e: env),
      ),
      (
        name: 'background-settings-390',
        size: const Size(390, 844),
        screen: const MLPBackgroundSettingsPage(),
      ),
    ];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final baseTheme = MLPTheme.dark;
    final screenshotTheme = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        fontFamilyFallback: ['Segoe UI Emoji'],
      ),
      primaryTextTheme: baseTheme.primaryTextTheme.apply(
        fontFamilyFallback: ['Segoe UI Emoji'],
      ),
    );
    late BuildContext imageContext;
    for (final item in screens) {
      if (item.name == 'active-focus-390') {
        focus.start();
        fixtureNow = fixtureNow.add(const Duration(minutes: 6, seconds: 36));
        focus.tick();
      }
      tester.view.physicalSize = item.size;
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MLPAppearanceScope(
            controller: appearance,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: screenshotTheme,
              home: Builder(
                builder: (context) {
                  imageContext = context;
                  return item.screen;
                },
              ),
            ),
          ),
        ),
      );
      // Real decoding runs outside the fake test clock. Matching the orb's
      // ResizeImage key also avoids capturing its transient loading state.
      await tester.runAsync(() async {
        for (final provider in <ImageProvider>[
          const AssetImage('assets/images/mlp_moon_mountain_v1.png'),
          const ResizeImage(
            AssetImage('assets/images/mlp_ai_nebula_v1.png'),
            width: 720,
          ),
        ]) {
          Object? decodeError;
          await precacheImage(
            provider,
            imageContext,
            onError: (error, _) {
              decodeError = error;
            },
          ).timeout(const Duration(seconds: 20));
          expect(decodeError, isNull, reason: 'Scene asset for ${item.name}');
        }
      });
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
      final file = File('docs/evidence/sprint01/liquid-glass/${item.name}.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(png!);
      if (item.name == 'active-focus-390') focus.pause();
    }
    final overview = [
      (name: 'welcome-390', label: '01 · Boshlash'),
      (name: 'today-390', label: '02 · Bugun'),
      (name: 'projects-390', label: '03 · Loyihalar'),
      (name: 'focus-390', label: '04 · Fokus sessiyasi'),
      (name: 'active-focus-390', label: '05 · Fokusda'),
      (name: 'tasks-390', label: '06 · Vazifalar'),
      (name: 'growth-390', label: '07 · Statistika'),
      (name: 'chat-390', label: '08 · Ustoz AI'),
      (name: 'profile-390', label: '09 · Profil'),
    ];
    final thumbnails = {
      for (final item in overview)
        item.name: MemoryImage(
          File(
            'docs/evidence/sprint01/liquid-glass/${item.name}.png',
          ).readAsBytesSync(),
        ),
    };
    await tester.runAsync(() async {
      for (final image in thumbnails.values) {
        await precacheImage(
          image,
          imageContext,
        ).timeout(const Duration(seconds: 20));
      }
    });
    tester.view.physicalSize = const Size(1200, 2800);
    final sheetKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: sheetKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: screenshotTheme,
          home: Scaffold(
            body: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Text(
                    'MLP · Liquid Glass — UI sinov ko‘rinishlari\nNamuna ma’lumotlari · qurilma tezligi sinovi emas',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 880,
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final item in overview)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: MLPColors.secondary,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Text(
                                  item.label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: MLPColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Image(
                                    image: thumbnails[item.name]!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Nine-screen contact sheet');
    final sheetBoundary =
        sheetKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final sheetPng = await tester.runAsync(() async {
      final image = await sheetBoundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return bytes!.buffer.asUint8List();
    });
    File(
      'docs/evidence/sprint01/liquid-glass/contact-sheet.png',
    ).writeAsBytesSync(sheetPng!);
    File('docs/evidence/sprint01/liquid-glass/README.md').writeAsStringSync(
      '# Liquid Glass UI sinov ko‘rinishlari\n\n'
      'Bu PNGlar haqiqiy foydalanuvchi ma’lumotlari emas. '
      '`test/mlp_visual_test.dart` ularni vaqtinchalik, mock mahalliy saqlovda yaratadi.\n\n'
      '- Namuna sanasi: 2026-10-25; ism: Azizbek.\n'
      '- 3 ta maqsad, bog‘langan vazifalar va bitta mustaqil vazifa public API orqali yaratilgan.\n'
      '- 5h 32m — aynan shu sinov uchun yozilgan sessiyalar yig‘indisi; haqiqiy foydalanuvchining natijasi emas.\n'
      '- 18:24 ko‘rinishi boshqariladigan test soatini 6 daqiqa 36 soniya oldinga surish bilan olingan.\n'
      '- Tog‘ va AI rasmlari dekodlangan; Segoe UI, Segoe UI Emoji, Material va Cupertino ikon shriftlari yuklangan.\n'
      '- `contact-sheet.png` 9 asosiy ekran ko‘rinishini bir joyda jamlaydi.\n\n'
      'Bu Flutter widget renderlari. Android/iOS qurilmasida ishga tushish, '
      '60 FPS, galereya ruxsatlari yoki haqiqiy backend xizmatlarini isbotlamaydi.\n',
    );
    await tester.pumpWidget(const SizedBox());
  });
}
