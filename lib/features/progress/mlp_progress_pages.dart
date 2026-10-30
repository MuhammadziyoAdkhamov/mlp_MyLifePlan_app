import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/mlp_environment.dart';
import '../../app/router/mlp_routes.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../core/design_system/mlp_liquid_glass.dart';
import '../../core/design_system/mlp_confetti.dart';
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
                if (mounted && context.mounted) {
                  MLPConfetti.show(
                    context,
                    title: 'Sinov natijasi saqlandi! 🏆',
                    subtitle: 'Skill Passport yangilandi',
                  );
                  setState(() => saved = true);
                }
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
      title: 'Passport: Mening ko‘nikmalarim',
      children: [
        MLPGlassCard(
          accent: true,
          padding: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final skill in [
                ('Flutter', 'Asosiy daraja', 0.65, const Color(0xFF00E5FF)),
                ('Dart', 'Asosiy daraja', 0.70, const Color(0xFF2979FF)),
                ('UI/UX', 'Boshlang‘ich', 0.40, const Color(0xFFBA6AFF)),
              ]) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 16, color: skill.$4),
                        const SizedBox(width: 8),
                        Text(skill.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        Text('· ${skill.$2}', style: const TextStyle(color: MLPColors.secondaryText, fontSize: 12)),
                      ],
                    ),
                    Text('${(skill.$3 * 100).toInt()}%', style: TextStyle(color: skill.$4, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: skill.$3,
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(skill.$4),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Center(
                child: TextButton.icon(
                  onPressed: () => e.go(MLPScreen.verification),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('+ Yangi ko‘nikma qo‘shish'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
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

class MLPGrowthPage extends StatefulWidget {
  const MLPGrowthPage({super.key, required this.e, this.embedded = false});
  final MLPEnvironment e;
  final bool embedded;
  @override
  State<MLPGrowthPage> createState() => _GrowthState();
}

class _GrowthState extends State<MLPGrowthPage> {
  int period = 0, offset = 0;
  static const periods = ['Hafta', '8 hafta', 'Oy', 'Yil'];
  static const weekdays = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
  static const months = [
    'Yan',
    'Fev',
    'Mar',
    'Apr',
    'May',
    'Iyn',
    'Iyl',
    'Avg',
    'Sen',
    'Okt',
    'Noy',
    'Dek',
  ];

  ({DateTime start, DateTime end, List<DateTime> bins, List<String> labels})
  range() {
    final now = widget.e.store.today;
    final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
    if (period < 2) {
      final count = period == 0 ? 7 : 8;
      final size = period == 0 ? 1 : 7;
      final start = DateTime(
        monday.year,
        monday.month,
        monday.day - (period == 1 ? 49 : 0) + offset * count * size,
      );
      final bins = List.generate(
        count + 1,
        (i) => DateTime(start.year, start.month, start.day + i * size),
      );
      return (
        start: start,
        end: bins.last,
        bins: bins,
        labels: List.generate(
          count,
          (i) => period == 0 ? weekdays[i] : '${bins[i].day}/${bins[i].month}',
        ),
      );
    }
    if (period == 2) {
      final start = DateTime(now.year, now.month + offset);
      final end = DateTime(start.year, start.month + 1);
      final bins = <DateTime>[start];
      for (
        var day = 8;
        day <= end.subtract(const Duration(days: 1)).day;
        day += 7
      ) {
        bins.add(DateTime(start.year, start.month, day));
      }
      bins.add(end);
      return (
        start: start,
        end: end,
        bins: bins,
        labels: List.generate(
          bins.length - 1,
          (i) =>
              '${bins[i].day}–${bins[i + 1].subtract(const Duration(days: 1)).day}',
        ),
      );
    }
    final start = DateTime(now.year + offset);
    final bins = List.generate(13, (i) => DateTime(start.year, i + 1));
    return (start: start, end: bins.last, bins: bins, labels: months);
  }

  String duration(int seconds) {
    if (seconds < 60) return '$seconds s';
    final minutes = seconds ~/ 60;
    return minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';
  }

  Future<void> share(BuildContext context, String report) =>
      mlpShowDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Statistika nusxasi'),
          content: SingleChildScrollView(child: SelectableText(report)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Yopish'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: report));
                if (dialog.mounted) {
                  MLPToast.show(dialog, 'Statistika nusxalandi.');
                }
              },
              child: const Text('Nusxalash'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.e.store, widget.e.ui]),
    builder: (context, _) {
      final e = widget.e, r = range();
      final sessions = e.store.focusSessions
          .where((s) => !s.date.isBefore(r.start) && s.date.isBefore(r.end))
          .toList();
      final seconds = sessions.fold<int>(0, (a, b) => a + b.seconds);
      final values = List.generate(
        r.bins.length - 1,
        (i) =>
            sessions
                .where(
                  (s) =>
                      !s.date.isBefore(r.bins[i]) &&
                      s.date.isBefore(r.bins[i + 1]),
                )
                .fold<int>(0, (a, b) => a + b.seconds) ~/
            60,
      );
      final completed = e.store.tasks
          .where(
            (t) =>
                t.completed &&
                t.completedAt != null &&
                !t.completedAt!.isBefore(r.start) &&
                t.completedAt!.isBefore(r.end),
          )
          .length;
      final assessments = e.ui.assessments.where((a) {
        final at = DateTime.parse(a['at'] as String);
        return !at.isBefore(r.start) && at.isBefore(r.end);
      }).length;
      final projects = <String, int>{};
      for (final session in sessions) {
        final task = e.store.tasks
            .where((t) => t.id == session.taskId)
            .firstOrNull;
        final project = task?.project.trim();
        final name = project == null || project.isEmpty
            ? 'Bog‘lanmagan fokus'
            : project;
        projects.update(
          name,
          (value) => value + session.seconds,
          ifAbsent: () => session.seconds,
        );
      }
      final shares = projects.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final last = r.end.subtract(const Duration(days: 1));
      final dates =
          '${r.start.day} ${months[r.start.month - 1]} – ${last.day} ${months[last.month - 1]} ${last.year}';
      final report =
          'MLP · ${periods[period]}\n$dates\nFokus: ${duration(seconds)}\nTopshirilgan vazifalar: $completed\nNamuna baholashlar: $assessments\nMahalliy faollik ma’lumoti. Ko‘nikma tasdig‘i emas.';
      return MLPPage(
        title: widget.embedded ? null : 'Statistika',
        actions: widget.embedded
            ? null
            : [
                IconButton(
                  tooltip: 'Ulashish',
                  onPressed: () => share(context, report),
                  icon: const Icon(Icons.ios_share),
                ),
              ],
        children: [
          if (widget.embedded) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Statistika',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Ulashish',
                  icon: const Icon(Icons.ios_share, size: 20),
                  onPressed: () => share(
                    context,
                    'MLP · ${periods[period]}\n$dates\nFokus: ${duration(seconds)}\nTopshirilgan vazifalar: $completed\nNamuna baholashlar: $assessments\nMahalliy faollik ma’lumoti. Ko‘nikma tasdig‘i emas.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          MLPSegmented(
            labels: periods,
            selected: period,
            onChanged: (i) => setState(() {
              period = i;
              offset = 0;
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                tooltip: 'Oldingi davr',
                onPressed: () => setState(() => offset--),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  dates,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: MLPColors.secondaryText,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Keyingi davr',
                onPressed: offset < 0 ? () => setState(() => offset++) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          MLPGlassCard(
            padding: 18,
            child: Column(
              children: [
                Text(
                  duration(seconds),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Jami fokus vaqti',
                  style: TextStyle(
                    color: MLPColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                MLPWeeklyBars(values: values, labels: r.labels),
                const SizedBox(height: 12),
                const Text(
                  'Saqlangan sessiyalar · ustunlar daqiqada',
                  style: TextStyle(color: MLPColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MLPGlassCard(
            padding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Loyihalar bo‘yicha',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                if (shares.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Bu davrda saqlangan fokus yo‘q.',
                      style: TextStyle(color: MLPColors.secondaryText),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, box) {
                      final ring = Semantics(
                        label: 'Loyihalar bo‘yicha jami ${duration(seconds)}',
                        child: SizedBox(
                          width: 118,
                          height: 118,
                          child: CustomPaint(
                            painter: _ProjectDonut(
                              shares.map((s) => s.value).toList(),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    duration(seconds),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Text(
                                    'Jami',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: MLPColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                      final legend = Column(
                        children: List.generate(
                          shares.length,
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color:
                                        _ProjectDonut.colors[i %
                                            _ProjectDonut.colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    shares[i].key,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(shares[i].value / seconds * 100).round()}%',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      return box.maxWidth < 300 ||
                              MediaQuery.textScalerOf(context).scale(1) > 1.3
                          ? Column(
                              children: [
                                ring,
                                const SizedBox(height: 16),
                                legend,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: legend),
                                const SizedBox(width: 16),
                                ring,
                              ],
                            );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MLPMetrics(
            items: [
              (
                value: '$completed',
                label: 'Davrda topshirilgan',
                icon: Icons.task_alt,
              ),
              (
                value: '$assessments',
                label: 'Namuna baholashlar',
                icon: Icons.fact_check_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          MLPNotice(
            e.store.isSampleData
                ? 'Namuna va mahalliy qaydlar. Barcha raqamlar saqlangan ma’lumotlardan hisoblandi.'
                : 'Mahalliy qaydlar. Faollik ko‘nikma darajasi bilan tenglashtirilmaydi.',
          ),
          TextButton.icon(
            onPressed: () => mlpShowSheet<void>(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              builder: (sheet) => SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistika manbasi',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$dates\n${sessions.length} ta saqlangan fokus sessiyasi · $seconds soniya.\n$completed ta topshirilgan vazifa · $assessments ta namuna baholash.',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Fokus davri sessiyaning saqlangan sanasi bilan aniqlanadi. Loyiha ulushi bog‘langan vazifadan olinadi; bog‘lanmagan yoki o‘chirilgan vazifa vaqti alohida qoladi. Ustunlar to‘liq daqiqalarni ko‘rsatadi. O‘sish foizi yoki mahorat darajasi taxmin qilinmaydi.',
                      style: TextStyle(
                        color: MLPColors.secondaryText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(sheet),
                      child: const Text('Tushunarli'),
                    ),
                  ],
                ),
              ),
            ),
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Ma’lumotlar manbasi'),
          ),
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

class _ProjectDonut extends CustomPainter {
  _ProjectDonut(this.values);
  final List<int> values;
  static const colors = [
    MLPColors.turquoise,
    MLPColors.primary,
    MLPColors.success,
    MLPColors.warning,
    MLPColors.primaryLight,
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = MLPColors.border
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke,
    );
    final total = values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final angle = values[i] / total * math.pi * 2;
      canvas.drawArc(
        rect,
        start,
        angle,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke,
      );
      start += angle;
    }
  }

  @override
  bool shouldRepaint(covariant _ProjectDonut oldDelegate) =>
      values.toString() != oldDelegate.values.toString();
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
