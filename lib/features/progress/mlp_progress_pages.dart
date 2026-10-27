import 'package:flutter/material.dart';
import '../../app/mlp_environment.dart';
import '../../app/router/mlp_routes.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../demo/demo_forms.dart';
import '../../data/models/mlp_schedule.dart';

class MLPQuizQuestion {
  const MLPQuizQuestion(
    this.text,
    this.options,
    this.correct,
    this.explanation,
  );
  final String text, explanation;
  final List<String> options;
  final int correct;
}

abstract final class MLPQuizCatalog {
  static const quizzes = {
    'Flutter asoslari': [
      MLPQuizQuestion(
        'Flutter interfeysining asosiy birligi nima?',
        ['Widget', 'SQL jadvali', 'Server'],
        0,
        'Flutter interfeysi widgetlardan tuziladi.',
      ),
      MLPQuizQuestion(
        'Formani saqlashdan oldin nima tekshiriladi?',
        ['Faqat rangi', 'Kiritilgan qiymatlar', 'Telefon markasi'],
        1,
        'Validatsiya noto‘g‘ri yoki bo‘sh qiymatlarni aniqlaydi.',
      ),
      MLPQuizQuestion(
        'final qiymat qayta tayinlanadimi?',
        ['Ha', 'Faqat tunda', 'Yo‘q'],
        2,
        'final o‘zgaruvchiga qiymat qayta tayinlanmaydi.',
      ),
    ],
    'Ingliz tili asoslari': [
      MLPQuizQuestion(
        'She ___ a student.',
        ['are', 'is', 'am'],
        1,
        'She bilan is ishlatiladi.',
      ),
      MLPQuizQuestion(
        'Book so‘zining oddiy ma’nosi?',
        ['Kitob', 'Deraza', 'Stol'],
        0,
        'Book — kitob.',
      ),
      MLPQuizQuestion(
        'I ___ English every day.',
        ['studies', 'studying', 'study'],
        2,
        'I bilan Present Simpleda study shakli ishlatiladi.',
      ),
    ],
  };
  static int score(String quiz, List<int?> answers) {
    final q = quizzes[quiz]!;
    return List.generate(
      q.length,
      (i) => answers[i] == q[i].correct ? 1 : 0,
    ).fold(0, (a, b) => a + b);
  }
}

class MLPVerificationPage extends StatefulWidget {
  const MLPVerificationPage({super.key, required this.e, this.initialTaskId});
  final MLPEnvironment e;
  final String? initialTaskId;
  @override
  State<MLPVerificationPage> createState() => _VerificationState();
}

class _VerificationState extends State<MLPVerificationPage> {
  String? taskId, error;
  String quiz = 'Flutter asoslari';
  List<int?> answers = [null, null, null];
  int step = 0;
  bool result = false, busy = false, saved = false;
  @override
  void initState() {
    super.initState();
    taskId = widget.initialTaskId;
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.e,
        task = widget.e.store.tasks.where((t) => t.id == taskId).firstOrNull;
    final questions = MLPQuizCatalog.quizzes[quiz]!;
    final seconds = e.store.focusSessions
        .where((f) => f.taskId == task?.id && task != null)
        .fold<int>(0, (sum, f) => sum + f.seconds);
    return MLPPage(
      title: 'Natijani tekshirish',
      children: [
        const MLPNotice(
          'Uch xil dalil alohida ko‘rsatiladi. Havola yuborish yoki taymerni tugatish mahoratni avtomatik tasdiqlamaydi.',
        ),
        DropdownButtonFormField<String>(
          initialValue: task?.id ?? '',
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Vazifa'),
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text('Umumiy namuna testi'),
            ),
            ...e.store.tasks.map(
              (t) => DropdownMenuItem(
                value: t.id,
                child: Text(t.title, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: busy
              ? null
              : (v) => setState(() {
                  taskId = v == '' ? null : v;
                  saved = false;
                }),
        ),
        const SizedBox(height: 20),
        MLPGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1 · O‘z hisoboti',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                task == null
                    ? 'Vazifa tanlanmagan.'
                    : task.completed
                    ? 'Topshirilgan: ${task.proof}'
                    : 'Hali topshirilmagan.',
              ),
              if (task != null && !task.completed)
                TextButton(
                  onPressed: () async {
                    await DemoForms.submit(context, e.store, task);
                    if (mounted) setState(() {});
                  },
                  child: const Text('Hisobot topshirish'),
                ),
              const Divider(),
              Text(
                '2 · Qayd etilgan faollik',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text('$seconds soniya fokus. Bu test natijasi emas.'),
              const Divider(),
              Text(
                '3 · Belgilangan javobli test',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                'Quyidagi uch savol avtomatik tekshiriladi. Butun loyiha yoki kasbiy mahorat tasdiqlanmaydi.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          key: ValueKey(quiz),
          initialValue: quiz,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Namuna mavzusi'),
          items: MLPQuizCatalog.quizzes.keys
              .map(
                (q) => DropdownMenuItem(
                  value: q,
                  child: Text(q, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: busy
              ? null
              : (v) => setState(() {
                  quiz = v!;
                  answers = [null, null, null];
                  step = 0;
                  result = false;
                  saved = false;
                }),
        ),
        const SizedBox(height: 20),
        if (!result) ...[
          MLPProgressBar(
            value: (step + 1) / questions.length,
            label: 'Savol ${step + 1} / ${questions.length}',
          ),
          const SizedBox(height: 16),
          Text(
            questions[step].text,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...List.generate(
            questions[step].options.length,
            (i) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: answers[step] == i,
              title: Text(questions[step].options[i]),
              onChanged: (_) => setState(() => answers[step] = i),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: answers[step] == -1,
            title: const Text('Bilmayman'),
            onChanged: (_) => setState(() => answers[step] = -1),
          ),
          MLPPrimaryButton(
            label: step == questions.length - 1
                ? 'Natijani ko‘rish'
                : 'Keyingi savol',
            onPressed: answers[step] == null
                ? null
                : () => setState(() {
                    if (step < questions.length - 1) {
                      step++;
                    } else {
                      result = true;
                    }
                  }),
          ),
        ] else ...[
          Text(
            '${MLPQuizCatalog.score(quiz, answers)} / ${questions.length} · ${MLPQuizCatalog.score(quiz, answers) >= 2 ? 'Namuna sinovidan o‘tdi' : 'Qayta mashq kerak'}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...List.generate(
            questions.length,
            (i) => MLPNotice(
              '${answers[i] == questions[i].correct ? 'To‘g‘ri' : 'Xato yoki bilmayman'}. ${questions[i].explanation}',
              warning: answers[i] != questions[i].correct,
            ),
          ),
          if (error != null) MLPNotice(error!, warning: true),
          MLPPrimaryButton(
            label: saved ? 'Pasportda ko‘rish' : 'Natijani saqlash',
            busy: busy,
            onPressed: () async {
              if (saved) {
                e.go(MLPScreen.passport);
                return;
              }
              setState(() {
                busy = true;
                error = null;
              });
              try {
                await e.ui.saveAssessment(
                  quiz: quiz,
                  correct: MLPQuizCatalog.score(quiz, answers),
                  total: questions.length,
                  taskId: task?.id,
                  at: e.clock(),
                );
                if (mounted) setState(() => saved = true);
              } catch (_) {
                if (mounted) {
                  setState(
                    () => error = 'Natija saqlanmadi. Qayta urinib ko‘ring.',
                  );
                }
              } finally {
                if (mounted) setState(() => busy = false);
              }
            },
          ),
          const SizedBox(height: 12),
          MLPSecondaryButton(
            label: 'Qayta yechish',
            onPressed: () => setState(() {
              answers = [null, null, null];
              step = 0;
              result = false;
              saved = false;
            }),
          ),
        ],
      ],
    );
  }
}

class MLPPassportPage extends StatelessWidget {
  const MLPPassportPage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([e.store, e.ui]),
    builder: (context, _) => MLPPage(
      title: 'Ko‘nikmalar pasporti',
      children: [
        const MLPNotice(
          'Prototip portfel. Rasmiy sertifikat emas. Faollik, o‘z hisoboti va namuna sinovlari alohida ko‘rsatiladi.',
        ),
        if (e.store.isSampleData)
          const MLPNotice('Namuna va shu qurilmada kiritilgan ma’lumotlar.'),
        MLPMetrics(
          items: [
            (
              value: '${e.store.tasks.where((t) => t.completed).length}',
              label: 'Topshirilgan vazifalar',
              icon: Icons.task_alt,
            ),
            (
              value: '${e.ui.assessments.length}',
              label: 'Namuna baholashlar',
              icon: Icons.fact_check_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const MLPSectionHeader(title: 'Ko‘nikmalar · namuna baholash'),
        const SizedBox(height: 12),
        if (e.ui.assessments.isEmpty)
          MLPEmptyState(
            title: 'Baholash hali yo‘q',
            message:
                'Topshirilgan ish yoki fokus vaqtini tasdiqlangan ko‘nikma deb hisoblamaymiz.',
            action: 'Namuna testini ochish',
            onAction: () => e.go(MLPScreen.verification),
          ),
        ...e.ui.assessments.reversed.map(
          (a) => MLPMenuTile(
            title: '${a['quiz']} · ${a['correct']}/${a['total']}',
            subtitle:
                '${mlpDayKey(DateTime.parse(a['at'] as String))} · belgilangan javobli namuna\nTo‘liq ko‘nikma tasdiqlanmagan',
            icon: (a['correct'] as int) * 3 >= (a['total'] as int) * 2
                ? Icons.check_circle_outline
                : Icons.school_outlined,
            onTap: () => e.info(
              context,
              'Baholash turi',
              'Mahalliy belgilangan javoblar avtomatik tekshirilgan. Faqat ${a['total']} savol bo‘yicha ${a['correct']} to‘g‘ri javob. Bu mustaqil ekspert sertifikati yoki butun kasbiy mahorat tasdig‘i emas.',
            ),
          ),
        ),
        const SizedBox(height: 20),
        const MLPSectionHeader(title: 'Loyihalardagi topshirilgan ishlar'),
        const SizedBox(height: 12),
        if (!e.store.tasks.any((t) => t.completed))
          const MLPEmptyState(
            title: 'Hali ish topshirilmagan',
            message:
                'Vazifani bajarib, o‘z hisobotingiz yoki dalil havolasini qo‘shing.',
          ),
        ...e.store.tasks
            .where((t) => t.completed)
            .take(30)
            .map(
              (t) => MLPMenuTile(
                title: t.title,
                subtitle:
                    '${t.project} · o‘z hisoboti · ${mlpDayKey(t.completedAt ?? t.dueDate)}',
                icon: Icons.folder_open,
                onTap: () => e.info(
                  context,
                  'Topshirilgan dalil',
                  '${t.proof}\n${t.evidenceUrl}\n\nHavola avtomatik tekshirilmagan.',
                ),
              ),
            ),
      ],
    ),
  );
}

class MLPGrowthPage extends StatelessWidget {
  const MLPGrowthPage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([e.store, e.ui]),
    builder: (context, _) {
      final days = List.generate(
        7,
        (i) => DateTime(
          e.store.today.year,
          e.store.today.month,
          e.store.today.day - 6 + i,
        ),
      );
      final values = days.map(e.store.focusMinutesForDay).toList();
      return MLPPage(
        title: 'Rivojlanish',
        children: [
          MLPNotice(
            e.store.isSampleData
                ? 'Namuna va mahalliy qaydlar. Quyidagi raqamlar joriy saqlovdan hisoblangan.'
                : 'Mahalliy qaydlar. Faollik ko‘nikma darajasi bilan tenglashtirilmaydi.',
          ),
          MLPMetrics(
            items: [
              (
                value: '${values.fold(0, (a, b) => a + b)}',
                label: '7 kunlik fokus · daqiqa',
                icon: Icons.timelapse,
              ),
              (
                value: '${e.store.tasks.where((t) => t.completed).length}',
                label: 'Topshirilgan vazifalar',
                icon: Icons.task_alt,
              ),
              (
                value: '${e.ui.assessments.length}',
                label: 'Namuna test natijalari',
                icon: Icons.fact_check,
              ),
            ],
          ),
          const SizedBox(height: 24),
          MLPGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Haftalik fokus',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                MLPWeeklyBars(
                  values: values,
                  labels: days
                      .map(
                        (d) => [
                          'Du',
                          'Se',
                          'Ch',
                          'Pa',
                          'Ju',
                          'Sh',
                          'Ya',
                        ][d.weekday - 1],
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Faqat saqlangan faol daqiqalar.',
                  style: TextStyle(
                    color: MLPColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const MLPSectionHeader(title: 'Maqsadlar natijasi · o‘z hisoboti'),
          const SizedBox(height: 12),
          if (e.store.goals.isEmpty)
            const MLPEmptyState(
              title: 'Maqsadlar hali yo‘q',
              message: 'Birinchi maqsadni kiriting.',
            ),
          ...e.store.goals
              .take(15)
              .map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MLPGoalCard(
                    title: g.title,
                    subtitle:
                        '${g.current}/${g.target} ${g.metric} · bog‘langan vazifalar ${e.store.goalCompletedTaskCount(g.id)}/${e.store.goalTaskCount(g.id)}',
                    progress: g.progress,
                    onTap: () => e.go(
                      MLPScreen.goalDetail,
                      args: MLPRouteArgs(goalId: g.id),
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 12),
          const MLPSectionHeader(title: 'Haftalik mulohaza'),
          const SizedBox(height: 12),
          ...e.store.weeklyReview.map((t) => MLPNotice(t)),
          MLPMenuTile(
            title: 'Baholangan natijalarni ko‘rish',
            subtitle: 'O‘rganish natijasi faqat tegishli dalil bilan',
            icon: Icons.workspace_premium_outlined,
            onTap: () => e.go(MLPScreen.passport),
          ),
        ],
      );
    },
  );
}

class MLPWeeklyBars extends StatelessWidget {
  const MLPWeeklyBars({super.key, required this.values, required this.labels});
  final List<int> values;
  final List<String> labels;
  @override
  Widget build(BuildContext context) {
    final max = values.fold<int>(1, (a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        return Expanded(
          child: Semantics(
            label: '${labels[i]}: ${values[i]} daqiqa',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  SizedBox(
                    height: 22,
                    child: FittedBox(
                      child: Text(
                        '${values[i]}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: MLPColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 110,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: values[i] == 0 ? 2 : 12 + values[i] / max * 98,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              i.isEven
                                  ? MLPColors.turquoise
                                  : MLPColors.primaryLight,
                              MLPColors.primary.withValues(alpha: .3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    child: Text(
                      labels[i],
                      style: const TextStyle(
                        fontSize: 11,
                        color: MLPColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
