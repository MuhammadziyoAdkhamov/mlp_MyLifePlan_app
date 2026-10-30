import 'package:flutter/material.dart';
import '../../app/router/mlp_routes.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../core/design_system/mlp_liquid_glass.dart';
import '../../data/repositories/mlp_ui_repository.dart';
import '../../demo/demo_store.dart';

Future<void> openMLPGoalFlow(
  BuildContext context,
  DemoStore store,
  MLPLocalUiRepository ui,
) => _next(
  context,
  MLPScreen.goalDiscovery,
  MLPGoalDiscoveryScreen(store: store, ui: ui),
);
Future<void> _next(BuildContext context, MLPScreen route, Widget child) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: route.path),
        builder: (_) => child,
      ),
    );

class MLPGoalDraft {
  MLPGoalDraft({required DateTime today, required this.minutes})
    : deadline = DateTime(today.year, today.month + 1, today.day);
  String title = '',
      category = 'Boshqa',
      outcome = '',
      reason = '',
      level = 'Boshlang‘ich';
  DateTime deadline;
  int minutes;
  Map<String, dynamic> diagnostic = {
    'kind': 'self-report',
    'level': 'Bilmayman',
  };
  List<({String title, int minutes, DateTime date})>? steps;
}

class MLPGoalDiscoveryScreen extends StatefulWidget {
  const MLPGoalDiscoveryScreen({
    super.key,
    required this.store,
    required this.ui,
  });
  final DemoStore store;
  final MLPLocalUiRepository ui;
  @override
  State<MLPGoalDiscoveryScreen> createState() => _DiscoveryState();
}

class _DiscoveryState extends State<MLPGoalDiscoveryScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  late final MLPGoalDraft draft;
  @override
  void initState() {
    super.initState();
    draft = MLPGoalDraft(
      today: widget.store.today,
      minutes: widget.ui.preferences.minutes,
    );
  }

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Page(
    title: 'Maqsadni tanlang',
    children: [
      Text(
        'Nimaga erishmoqchisiz?',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      const Text(
        'Yo‘nalish yordam beradi. Maqsadingiz esa butunlay o‘zingizniki bo‘lishi mumkin.',
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            [
                  'Ta’lim',
                  'Ingliz tili',
                  'Dasturlash',
                  'Sog‘lom turmush',
                  'Kasb',
                  'Moliya',
                  'Shaxsiy rivojlanish',
                  'Boshqa',
                ]
                .map(
                  (c) => ChoiceChip(
                    avatar: Icon(
                      c == 'Dasturlash'
                          ? Icons.code_rounded
                          : c == 'Ta’lim'
                          ? Icons.school_outlined
                          : c == 'Sog‘lom turmush'
                          ? Icons.favorite_outline
                          : Icons.category_outlined,
                      size: 18,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    label: Text(c),
                    selected: draft.category == c,
                    onSelected: (_) => setState(() => draft.category = c),
                  ),
                )
                .toList(),
      ),
      const SizedBox(height: 24),
      Form(
        key: form,
        child: MLPTextField(
          controller: title,
          label: 'O‘z maqsadim',
          hint: 'Uch oyda Flutter ilova yaratmoqchiman.',
          maxLength: 160,
          maxLines: 3,
          validator: (v) => (v ?? '').trim().length < 2
              ? 'Maqsadni kamida 2 belgi bilan yozing.'
              : null,
        ),
      ),
      const SizedBox(height: 24),
      MLPPrimaryButton(
        label: 'Maqsadni aniqlashtirish',
        icon: Icons.arrow_forward_rounded,
        onPressed: () {
          if (!form.currentState!.validate()) return;
          draft.title = title.text.trim();
          _next(
            context,
            MLPScreen.goalClarification,
            MLPGoalClarificationScreen(
              store: widget.store,
              ui: widget.ui,
              draft: draft,
            ),
          );
        },
      ),
    ],
  );
}

class MLPGoalClarificationScreen extends StatefulWidget {
  const MLPGoalClarificationScreen({
    super.key,
    required this.store,
    required this.ui,
    required this.draft,
  });
  final DemoStore store;
  final MLPLocalUiRepository ui;
  final MLPGoalDraft draft;
  @override
  State<MLPGoalClarificationScreen> createState() => _ClarificationState();
}

class _ClarificationState extends State<MLPGoalClarificationScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, outcome, reason, minutes;
  MLPGoalDraft get d => widget.draft;
  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: d.title);
    outcome = TextEditingController(text: d.outcome);
    reason = TextEditingController(text: d.reason);
    minutes = TextEditingController(text: '${d.minutes}');
  }

  @override
  void dispose() {
    title.dispose();
    outcome.dispose();
    reason.dispose();
    minutes.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v ?? '').trim().length < 2 ? 'Kamida 2 belgi kiriting.' : null;
  @override
  Widget build(BuildContext context) => _Page(
    title: 'Maqsadni aniqlashtirish',
    children: [
      const _Note(
        'Aniq natija va o‘zingizga mos sur’atni tanlang. Bu ma’lumotlar sizning hisobotingiz bo‘ladi.',
      ),
      const SizedBox(height: 20),
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MLPTextField(
              controller: title,
              label: 'Maqsad nomi',
              maxLength: 160,
              validator: _required,
            ),
            const SizedBox(height: 16),
            MLPTextField(
              controller: outcome,
              label: 'Qanday natijaga erishmoqchisiz?',
              maxLines: 2,
              maxLength: 500,
              validator: _required,
            ),
            const SizedBox(height: 16),
            MLPSecondaryButton(
              label: 'Maqsad sanasi · ${DemoStore.dayKey(d.deadline)}',
              icon: Icons.calendar_today_rounded,
              onPressed: () async {
                final day = await showDatePicker(
                  context: context,
                  initialDate: d.deadline,
                  firstDate: widget.store.today,
                  lastDate: DateTime(widget.store.today.year + 5, 12, 31),
                  cancelText: 'Bekor qilish',
                  confirmText: 'Tanlash',
                  helpText: 'Maqsad sanasi',
                );
                if (day != null) setState(() => d.deadline = day);
              },
            ),
            const SizedBox(height: 16),
            MLPTextField(
              controller: minutes,
              label: 'Har kuni necha daqiqa?',
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 5 || n > 720
                    ? '5–720 daqiqa kiriting.'
                    : null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Boshlang‘ich daraja · o‘z bahosi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  ['Boshlang‘ich', 'O‘rta', 'Amaliy tajriba bor', 'Bilmayman']
                      .map(
                        (l) => ChoiceChip(
                          label: Text(l),
                          selected: d.level == l,
                          onSelected: (_) => setState(() => d.level = l),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 20),
            MLPTextField(
              controller: reason,
              label: 'Nega bu siz uchun muhim?',
              maxLength: 500,
              maxLines: 2,
              validator: _required,
            ),
            const SizedBox(height: 20),
            const _Note(
              'Yuqoridagi maydonlar — tahrirlanadigan xulosa. Keyingi bosqichdan orqaga qaytib tuzata olasiz.',
            ),
            const SizedBox(height: 24),
            MLPPrimaryButton(
              label: 'Boshlang‘ich baholash',
              onPressed: () {
                if (!form.currentState!.validate()) return;
                d.title = title.text.trim();
                d.outcome = outcome.text.trim();
                d.reason = reason.text.trim();
                d.minutes = int.parse(minutes.text);
                _next(
                  context,
                  MLPScreen.diagnosis,
                  MLPDiagnosticScreen(
                    store: widget.store,
                    ui: widget.ui,
                    draft: d,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ],
  );
}

class MLPDiagnosticScreen extends StatefulWidget {
  const MLPDiagnosticScreen({
    super.key,
    required this.store,
    required this.ui,
    required this.draft,
  });
  final DemoStore store;
  final MLPLocalUiRepository ui;
  final MLPGoalDraft draft;
  @override
  State<MLPDiagnosticScreen> createState() => _DiagnosticState();
}

class _DiagnosticState extends State<MLPDiagnosticScreen> {
  final List<int?> answers = [null, null];
  int step = 0;
  String level = 'Bilmayman';
  bool result = false;
  List<({String question, List<String> answers, int correct, String why})>
  get questions => widget.draft.category == 'Dasturlash'
      ? [
          (
            question: "Flutter'da qaysi vidjet list ko‘rinishlarini yaratadi?",
            answers: ['ListView', 'Column', 'Row'],
            correct: 0,
            why: 'ListView ro‘yxat ko‘rinishlarini yaratadi.',
          ),
          (
            question: 'Flutterda ekrandagi elementning asosiy birligi nima?',
            answers: ['SQL', 'Widget', 'HTTP'],
            correct: 1,
            why: 'Flutter interfeysi widgetlardan tuziladi.',
          ),
        ]
      : [
          (
            question: 'To‘g‘ri shaklni tanlang: She ___ a student.',
            answers: ['are', 'is', 'am'],
            correct: 1,
            why: 'She olmoshi bilan is ishlatiladi.',
          ),
          (
            question: 'Book so‘zining oddiy ma’nosi qaysi?',
            answers: ['Kitob', 'Stol', 'Deraza'],
            correct: 0,
            why: 'Book — kitob. Bu savol CEFR darajasini aniqlamaydi.',
          ),
        ];
  bool get objective =>
      ['Dasturlash', 'Ingliz tili'].contains(widget.draft.category);
  int get correct => List.generate(
    2,
    (i) => answers[i] == questions[i].correct ? 1 : 0,
  ).reduce((a, b) => a + b);
  void _roadmap() {
    widget.draft.diagnostic = objective
        ? {
            'kind': 'sample-test',
            'correct': correct,
            'total': 2,
            'answers': answers,
          }
        : {'kind': 'self-report', 'level': level};
    _next(
      context,
      MLPScreen.roadmap,
      MLPRoadmapScreen(store: widget.store, ui: widget.ui, draft: widget.draft),
    );
  }

  @override
  Widget build(BuildContext context) => _Page(
    title: 'Boshlang‘ich baholash',
    children: [
      _Note(
        objective
            ? 'Qisqa namuna testi: faqat ikki savol avtomatik tekshiriladi. Natija mustaqil ko‘nikma sertifikati emas.'
            : 'Bu yo‘nalishda obyektiv test ulanmagan. Quyidagi tanlov faqat o‘z bahongiz sifatida saqlanadi.',
      ),
      const SizedBox(height: 24),
      if (!objective) ...[
        Text(
          'Hozir qayerdasiz?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ...['Boshlang‘ich', 'O‘rta', 'Amaliy tajriba bor', 'Bilmayman'].map(
          (l) => MLPSelectionTile(
            selected: level == l,
            label: l,
            onSelected: () => setState(() => level = l),
          ),
        ),
        const SizedBox(height: 20),
        MLPPrimaryButton(label: 'Yo‘l xaritasini ko‘rish', onPressed: _roadmap),
      ] else if (!result) ...[
        MLPProgressBar(value: (step + 1) / 2, label: '${step + 1}/10 · Boshlang‘ich test'),
        const SizedBox(height: 20),
        Text(
          questions[step].question,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        ...List.generate(
          questions[step].answers.length,
          (i) => MLPSelectionTile(
            selected: answers[step] == i,
            label: questions[step].answers[i],
            onSelected: () => setState(() => answers[step] = i),
          ),
        ),
        MLPSelectionTile(
          selected: answers[step] == -1,
          label: 'Bilmayman',
          onSelected: () => setState(() => answers[step] = -1),
        ),
        const SizedBox(height: 20),
        MLPPrimaryButton(
          label: step == 0 ? 'Keyingi savol' : 'Natijani ko‘rish',
          onPressed: answers[step] == null
              ? null
              : () => setState(() {
                  if (step == 0) {
                    step = 1;
                  } else {
                    result = true;
                  }
                }),
        ),
      ] else ...[
        Text(
          'Namuna testi: $correct / 2',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          'Faqat shu savollar tekshirildi. Umumiy darajangiz yoki maqsadga erishganingiz tasdiqlanmadi.',
        ),
        const SizedBox(height: 16),
        ...List.generate(
          2,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MLPGlassCard(
              child: Text(
                '${answers[i] == questions[i].correct
                    ? 'To‘g‘ri'
                    : answers[i] == -1
                    ? 'Bilmayman'
                    : 'Xato'}. ${questions[i].why}',
              ),
            ),
          ),
        ),
        MLPPrimaryButton(label: 'Yo‘l xaritasini ko‘rish', onPressed: _roadmap),
        const SizedBox(height: 12),
        MLPSecondaryButton(
          label: 'Qayta yechish',
          onPressed: () => setState(() {
            answers.fillRange(0, 2, null);
            step = 0;
            result = false;
          }),
        ),
      ],
    ],
  );
}

class MLPRoadmapScreen extends StatefulWidget {
  const MLPRoadmapScreen({
    super.key,
    required this.store,
    required this.ui,
    required this.draft,
  });
  final DemoStore store;
  final MLPLocalUiRepository ui;
  final MLPGoalDraft draft;
  @override
  State<MLPRoadmapScreen> createState() => _RoadmapState();
}

class _RoadmapState extends State<MLPRoadmapScreen> {
  final form = GlobalKey<FormState>();
  final List<TextEditingController> titles = [], times = [];
  final List<DateTime> dates = [];
  bool busy = false;
  String? error, savedGoal;
  MLPGoalDraft get d => widget.draft;
  @override
  void initState() {
    super.initState();
    final prefix = d.title.length > 100 ? d.title.substring(0, 100) : d.title;
    final isFlutter = d.category == 'Dasturlash' || d.title.toLowerCase().contains('flutter');
    final stepNames = isFlutter
        ? ['Dart asoslari (1-2 hafta)', 'Flutter UI (3-5 hafta)', 'State Management (6-8 hafta)']
        : ['Reja va manba', 'Birinchi amaliy qadam', 'Natijani tahlil qilish'];
    final generated =
        d.steps ??
        List.generate(
          stepNames.length,
          (i) => (
            title: '${stepNames[i]} · $prefix',
            minutes: d.minutes.clamp(5, 60),
            date: widget.store.today.add(
              Duration(
                days: (d.deadline.difference(widget.store.today).inDays * i / (stepNames.length - 1))
                    .round(),
              ),
            ),
          ),
        );
    for (final step in generated) {
      titles.add(TextEditingController(text: step.title));
      times.add(TextEditingController(text: '${step.minutes}'));
      dates.add(step.date);
    }
  }

  @override
  void dispose() {
    for (final c in [...titles, ...times]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snapshot() => d.steps = List.generate(
    titles.length,
    (i) => (
      title: titles[i].text.trim(),
      minutes: int.parse(times[i].text),
      date: dates[i],
    ),
  );
  Future<void> _save() async {
    if (busy || !form.currentState!.validate()) return;
    _snapshot();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      savedGoal ??= await widget.store.addGoalPlan(
        title: d.title,
        category: d.category,
        deadline: d.deadline,
        steps: d.steps!,
      );
      await widget.ui.saveGoalPlan(savedGoal!, {
        'outcome': d.outcome,
        'reason': d.reason,
        'startingLevel': d.level,
        'diagnostic': d.diagnostic,
        'dailyMinutes': d.minutes,
        'prototype': true,
        'archived': false,
      });
      if (mounted) {
        MLPToast.show(context, 'Maqsad va vazifalar saqlandi.');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = savedGoal == null
              ? 'Maqsad saqlanmadi. Kiritganlaringiz saqlandi, qayta urinib ko‘ring.'
              : 'Maqsad va vazifalar saqlandi, lekin izohlar yozilmadi. Qayta saqlash faqat izohlarni yozadi.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _Page(
    title: 'Sizning rejangiz',
    children: [
      const _Note(
        'Prototip reja: belgilangan uch bosqichli namuna, haqiqiy AI yaratmagan. Har bir vazifa va sanani tahrirlang.',
      ),
      const SizedBox(height: 20),
      Text(d.title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      Text(
        'Boshlanish: ${d.level} · o‘z bahosi\nNatija: ${d.outcome}\nMuddat: ${DemoStore.dayKey(d.deadline)}\nKunlik imkoniyat: ${d.minutes} daqiqa',
      ),
      const SizedBox(height: 12),
      Text(
        'Rejadagi taxminiy ish: ${times.fold<int>(0, (sum, c) => sum + (int.tryParse(c.text) ?? 0))} daqiqa · ${titles.length} vazifa',
      ),
      const SizedBox(height: 24),
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...List.generate(
              titles.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: MLPGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${i + 1}-bosqich',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      MLPTextField(
                        controller: titles[i],
                        label: 'Vazifa',
                        maxLines: 2,
                        maxLength: 160,
                        enabled: savedGoal == null && !busy,
                        validator: (v) => (v ?? '').trim().length < 2
                            ? 'Vazifa nomini yozing.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      MLPTextField(
                        controller: times[i],
                        label: 'Daqiqa',
                        onChanged: (_) => setState(() {}),
                        enabled: savedGoal == null && !busy,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return n == null || n < 1 || n > 1440
                              ? '1–1440 daqiqa kiriting.'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      MLPSecondaryButton(
                        label: DemoStore.dayKey(dates[i]),
                        icon: Icons.calendar_today_outlined,
                        onPressed: savedGoal != null || busy
                            ? null
                            : () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: dates[i],
                                  firstDate: widget.store.today,
                                  lastDate: d.deadline,
                                  cancelText: 'Bekor qilish',
                                  confirmText: 'Tanlash',
                                );
                                if (date != null) {
                                  setState(() => dates[i] = date);
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Text(
              'Haftalik jadval: yuqoridagi sanalar bo‘yicha. Har bosqich alohida kundalik vazifa bo‘ladi. Fokus yoki vazifa bajarilishi mustaqil ko‘nikma tasdig‘i emas.',
            ),
            const SizedBox(height: 20),
            if (error != null) ...[_Note(error!), const SizedBox(height: 12)],
            MLPPrimaryButton(
              label: savedGoal == null
                  ? 'Rejani tasdiqlash'
                  : 'Izohlarni qayta saqlash',
              busy: busy,
              onPressed: _save,
            ),
          ],
        ),
      ),
    ],
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => MLPGlassCard(
    child: Text(
      text,
      style: const TextStyle(color: MLPColors.secondaryText, height: 1.6),
    ),
  );
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => MLPScaffold(
    title: title,
    body: SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );
}
