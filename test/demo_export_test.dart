import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mylife_plan/demo/demo_review.dart';
import 'package:mylife_plan/demo/demo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DemoStore store;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 10, 19, 12);
    store = DemoStore(prefs, now: () => now);
    await store.init();
    await store.clearAll();
  });
  tearDown(() => store.dispose());

  test(
    'CSV quotes content, keeps UTF-8 text, and neutralizes spreadsheet formulas',
    () async {
      await store.addTask(title: '=1+1, "salom"', project: ' \t@SUM(1,2)');
      await store.submitTask(store.tasks.single.id, '\n+SUM(1,2) dalil matni');
      // Imported text may preserve whitespace that input forms trim away.
      final backup = jsonDecode(store.exportJson()) as Map<String, dynamic>;
      (backup['tasks'] as List).single['project'] = ' \t@SUM(1,2)';
      (backup['tasks'] as List).single['proof'] = '\n+SUM(1,2) dalil matni';
      await store.importJson(jsonEncode(backup));
      final csv = DemoExports.csv(store);
      expect(csv, startsWith('\uFEFF"id","vazifa"'));
      expect(csv, contains('"\'=1+1, ""salom"""'));
      expect(csv, contains('"\' \t@SUM(1,2)"'));
      expect(csv, contains('"\'\n+SUM(1,2) dalil matni"'));
      expect(csv, endsWith('\r\n'));
    },
  );

  test(
    'ICS escapes injection and text, uses exclusive end date, folds UTF-8 octets',
    () async {
      final title = 'Yil yakuni, muhim; ${'O‘qish ' * 14}😀\nBEGIN:VEVENT';
      await store.addTask(
        title: title,
        dueDate: DateTime(2026, 12, 31),
        project: 'Ish; sinov, test',
      );
      final ics = DemoExports.ics(
        store,
        generatedAt: DateTime.utc(2026, 10, 19, 7, 30),
      );
      final unfolded = ics.replaceAll('\r\n ', '');
      expect(unfolded, contains('DTSTAMP:20261019T073000Z'));
      expect(unfolded, contains('DTSTART;VALUE=DATE:20261231'));
      expect(unfolded, contains('DTEND;VALUE=DATE:20270101'));
      expect(unfolded, contains(r'SUMMARY:Yil yakuni\, muhim\;'));
      expect(unfolded, contains(r'😀\nBEGIN:VEVENT'));
      expect(
        RegExp(
          r'^BEGIN:VEVENT$',
          multiLine: true,
        ).allMatches(unfolded.replaceAll('\r\n', '\n')),
        hasLength(1),
      );
      expect(unfolded, contains(r'CATEGORIES:Ish\; sinov\, test'));
      expect(unfolded, contains('UID:${store.tasks.single.id}@mpl.local'));
      expect(unfolded, endsWith('END:VCALENDAR\r\n'));
      for (final line in ics.split('\r\n')) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75), reason: line);
      }
      expect(utf8.decode(utf8.encode(ics)), ics);
    },
  );

  test(
    'mentor report counts only this week, distinguishes sample data, includes proof',
    () async {
      now = DateTime(2026, 10, 10, 12);
      await store.addTask(title: 'Eski bajarilgan vazifa');
      await store.submitTask(
        store.tasks.single.id,
        'Eski ishning yetarli dalili.',
      );
      now = DateTime(2026, 10, 19, 12);
      await store.addTask(title: 'Yangi bajarilgan vazifa');
      await store.submitTask(
        store.tasks.last.id,
        'Portfolio qoralamasini tayyorladim.',
      );
      await store.addFocusSession(seconds: 1500);
      final report = DemoExports.report(store);
      expect(report, contains('Topshirilgan vazifalar: 1'));
      expect(report, contains('Fokus: 25 daqiqa'));
      expect(report, contains('Portfolio qoralamasini tayyorladim.'));
      expect(report, isNot(contains('Eski bajarilgan vazifa')));
      expect(report, isNot(contains('DEMO:')));
      await store.loadSample();
      expect(DemoExports.report(store), contains('DEMO:'));
    },
  );

  testWidgets('review and hub render at a narrow mobile width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() => store.loadSample());
    for (final page in [DemoReview(store: store), DemoHub(store: store)]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(body: page),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('starter requires confirmation and cannot be duplicated', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(body: DemoHub(store: store)),
      ),
    );
    await tester.tap(find.text('7 kunlik rejani ko‘rish'));
    await tester.pumpAndSettle();
    expect(store.tasks, isEmpty);
    await tester.tap(find.text('7 ta vazifani qo‘shish'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(store.tasks, hasLength(7));
    expect(
      store.tasks.map((task) => DemoStore.dayKey(task.dueDate)).toSet(),
      hasLength(7),
    );
    await tester.tap(find.text('Rejaga qo‘shilgan'));
    await tester.pumpAndSettle();
    expect(store.tasks, hasLength(7));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'JSON import validates before replacement and invokes reset only on success',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var replacements = 0;
      await tester.runAsync(
        () => store.addTask(title: 'Saqlanib turadigan vazifa'),
      );
      final original = store.exportJson();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: Scaffold(
            body: DemoHub(store: store, onDataReplaced: () => replacements++),
          ),
        ),
      );
      await tester.ensureVisible(find.text('JSON import'));
      await tester.tap(find.text('JSON import'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '{broken');
      await tester.tap(find.text('Tekshirish va import'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Almashtirish'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(replacements, 0);
      expect(store.exportJson(), original);
      expect(find.text('MPL JSON nusxasini import qilish'), findsOneWidget);
      await tester.enterText(find.byType(TextField), original);
      await tester.tap(find.text('Tekshirish va import'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Almashtirish'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(replacements, 1);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
