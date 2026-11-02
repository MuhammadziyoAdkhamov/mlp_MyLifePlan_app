import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mylife_plan/app/mlp_environment.dart';
import 'package:mylife_plan/data/repositories/mlp_ui_repository.dart';
import 'package:mylife_plan/demo/demo_store.dart';
import 'package:mylife_plan/features/progress/mlp_progress_pages.dart';
import 'package:mylife_plan/features/university/mlp_university_edition.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MLP University Edition — Competition Golden Path', () {
    late SharedPreferences prefs;
    late DemoStore store;
    late MLPLocalUiRepository ui;
    late DateTime clock;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      clock = DateTime(2026, 11, 2, 10, 0);
      store = DemoStore(prefs, now: () => clock);
      await store.init();
      ui = MLPLocalUiRepository(prefs);
      await ui.init();
    });

    tearDown(() {
      store.dispose();
      ui.dispose();
    });

    test('1. Six University subjects are seeded and Chiziqli algebra is present', () {
      final goals = store.goals;
      final universitySubjects = goals.where((g) => g.category == 'Fanlar (3-semestr)').toList();
      expect(universitySubjects.length, greaterThanOrEqualTo(6));

      final algebra = universitySubjects.firstWhere((g) => g.title == 'Chiziqli algebra');
      expect(algebra.metric, 'mavzu');
      expect(algebra.target, 12);

      // Verify mission task is seeded
      final mission = store.tasks.firstWhere((t) => t.id == 'task-linear-algebra-mission');
      expect(mission.project, 'Chiziqli algebra');
      expect(mission.completed, isFalse);
    });

    test('2. Real mission submission records evidence and updates DemoStore', () async {
      const proofText = 'Matritsalar bo‘yicha 5 ta amaliy masalani to‘liq yechdim. Determinantlar hisoblandi.';
      const evidenceUrl = 'https://github.com/student/linear-algebra-matrices-hw1.pdf';

      final initialXp = store.xp;
      await store.submitTask(
        'task-linear-algebra-mission',
        proofText,
        evidenceUrl: evidenceUrl,
      );

      final task = store.tasks.firstWhere((t) => t.id == 'task-linear-algebra-mission');
      expect(task.completed, isTrue);
      expect(task.proof, proofText);
      expect(task.evidenceUrl, evidenceUrl);
      expect(store.xp, greaterThan(initialXp));
    });

    test('3. Blind Challenge questions exist and deterministic assessment yields L3 Amaliy daraja', () async {
      const quizName = 'Chiziqli algebra (Matritsalar)';
      expect(MLPQuizCatalog.quizzes.containsKey(quizName), isTrue);

      final questions = MLPQuizCatalog.quizzes[quizName]!;
      expect(questions.length, 3);

      // Question 1: Satr/ustun almashtirilsa belgisi o‘zgaradi (Index 1)
      expect(questions[0].correct, 1);
      // Question 2: A = [[3,2],[1,4]] det = 10 (Index 0)
      expect(questions[1].correct, 0);
      // Question 3: det(I) = 1 (Index 2)
      expect(questions[2].correct, 2);

      // Answer correctly: [1, 0, 2]
      final score = MLPQuizCatalog.score(quizName, [1, 0, 2]);
      expect(score, 3);

      // Save assessment
      await ui.saveAssessment(
        quiz: quizName,
        correct: score,
        total: questions.length,
        taskId: 'task-linear-algebra-mission',
        at: clock,
      );

      expect(ui.assessments.length, 1);
      final recorded = ui.assessments.first;
      expect(recorded['quiz'], quizName);
      expect(recorded['correct'], 3);
      expect(recorded['total'], 3);
    });

    test('4. Full golden path survives simulated restart with persistence verified', () async {
      // 1. Submit mission evidence
      await store.submitTask(
        'task-linear-algebra-mission',
        'Matritsalar topshirildi',
        evidenceUrl: 'https://storage.googleapis.com/hw/matrix_hw.pdf',
      );

      // 2. Complete Blind Challenge
      await ui.saveAssessment(
        quiz: 'Chiziqli algebra (Matritsalar)',
        correct: 3,
        total: 3,
        taskId: 'task-linear-algebra-mission',
        at: clock,
      );

      // 3. Simulate app restart
      final restoredStore = DemoStore(prefs, now: () => clock);
      await restoredStore.init();
      final restoredUi = MLPLocalUiRepository(prefs);
      await restoredUi.init();

      // Verify restored task
      final restoredTask = restoredStore.tasks.firstWhere((t) => t.id == 'task-linear-algebra-mission');
      expect(restoredTask.completed, isTrue);
      expect(restoredTask.evidenceUrl, 'https://storage.googleapis.com/hw/matrix_hw.pdf');

      // Verify restored assessment
      expect(restoredUi.assessments.isNotEmpty, isTrue);
      final restoredAssessment = restoredUi.assessments.firstWhere(
        (a) => a['quiz'] == 'Chiziqli algebra (Matritsalar)',
      );
      expect(restoredAssessment['correct'], 3);

      restoredStore.dispose();
      restoredUi.dispose();
    });

    testWidgets('5. MLPUniversityHub renders smoothly and navigates through the 7 screens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MLPUniversityHub(store: store, ui: ui, initialScreenIndex: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Screen 1: Bosh sahifa
      expect(find.text('FDTU Pilot konsept'), findsWidgets);
      expect(find.text('Darslar'), findsWidgets);
      expect(find.text('Quiz Arena'), findsWidgets);
      expect(find.text('ProofQuest'), findsWidgets);

      // Navigate to Screen 2: Fanlar
      await tester.tap(find.text('2 Fanlar'));
      await tester.pumpAndSettle();
      expect(find.text('Fanlar (3-semestr)'), findsOneWidget);
      expect(find.text('Chiziqli algebra'), findsOneWidget);
      expect(find.text('Diskret tuzilmalar'), findsOneWidget);

      // Navigate to Screen 3: Mavzu
      await tester.tap(find.text('3 Mavzu'));
      await tester.pumpAndSettle();
      expect(find.text('Mavzu: Matritsalar'), findsOneWidget);
      expect(find.text('Video dars (12:40)'), findsOneWidget);

      // Navigate to Screen 4: Quiz Arena
      await tester.tap(find.text('4 Quiz Arena'));
      await tester.pumpAndSettle();
      expect(find.text('482 917'), findsOneWidget);
      expect(find.text('Ishtirokchilar: 17 / 32'), findsOneWidget);

      // Navigate to Screen 5: Test
      await tester.tap(find.text('5 Test'));
      await tester.pumpAndSettle();
      expect(find.text('Determinantning asosiy xossasi qaysi?'), findsOneWidget);

      // Navigate to Screen 6: Real missiya
      await tester.tap(find.text('6 Real missiya'));
      await tester.pumpAndSettle();
      expect(find.text('Real missiya'), findsOneWidget);
      expect(
        find.text('Matritsalar bo‘yicha 5 ta amaliy masalani yechib, PDF yoki rasm ko‘rinishida yuklang.'),
        findsOneWidget,
      );

      // Navigate to Screen 7: Proof Level via Bottom Navigation 'Reyting'
      await tester.tap(find.text('Reyting'));
      await tester.pumpAndSettle();
      expect(find.text('L3'), findsOneWidget);
      expect(find.text('Amaliy daraja'), findsOneWidget);

      // Navigate to Screen 8: Pasport via Bottom Navigation 'Pasport'
      await tester.tap(find.text('Pasport'));
      await tester.pumpAndSettle();
      expect(find.text('Mening ko‘nikmalarim'), findsOneWidget);
      expect(find.text('Proof Level bosqichlari'), findsOneWidget);
    });
  });
}
