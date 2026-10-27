import 'package:flutter/material.dart';
import '../../app/mlp_environment.dart';
import '../../app/router/mlp_routes.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../data/models/mlp_schedule.dart';

class MLPFocusHub extends StatelessWidget {
  const MLPFocusHub({super.key, required this.e});
  final MLPEnvironment e;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([e.focus, e.store]),
    builder: (context, _) => MLPPage(
      children: [
        Text(
          'Bir vaqt. Bitta vazifa.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Diqqat uchun joy oching.',
          style: TextStyle(color: MLPColors.secondaryText),
        ),
        const SizedBox(height: 20),
        MLPGlassCard(
          accent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _TimerRing(e: e)),
              const SizedBox(height: 24),
              Text(
                e.focus.task?.title ?? 'Erkin fokus',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final pair in [(25, 5), (50, 10)])
                    ChoiceChip(
                      label: Text('${pair.$1}/${pair.$2}'),
                      selected: e.focus.duration == pair.$1 * 60,
                      onSelected: e.focus.elapsed > 0 || e.focus.running
                          ? null
                          : (_) => e.act(
                              context,
                              () async => e.focus.configure(
                                pair.$1,
                                pair.$2,
                                task: e.focus.taskId,
                              ),
                            ),
                    ),
                  ActionChip(
                    label: const Text('O‘z vaqtim'),
                    onPressed: () => _custom(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                key: ValueKey('focus-task-${e.focus.taskId}'),
                initialValue: e.focus.task?.id ?? '',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Bog‘langan vazifa',
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Erkin fokus')),
                  ...e.store.tasks
                      .where((t) => !t.completed || t.id == e.focus.taskId)
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(
                            '${t.project} · ${t.title}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                ],
                onChanged: e.focus.running || e.focus.elapsed > 0
                    ? null
                    : (v) => e.act(
                        context,
                        () async => e.focus.configure(
                          e.focus.duration ~/ 60,
                          e.focus.breakSeconds ~/ 60,
                          task: v == '' ? null : v,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              MLPPrimaryButton(
                label: e.focus.elapsed > 0
                    ? 'Sessiyaga qaytish'
                    : 'Fokusni boshlash',
                icon: Icons.play_arrow_rounded,
                onPressed: () {
                  e.focus.start();
                  e.go(MLPScreen.activeFocus);
                },
              ),
              if (e.focus.elapsed == 0 && !e.focus.running)
                TextButton(
                  onPressed: () {
                    e.focus.configure(
                      e.focus.breakSeconds ~/ 60,
                      e.focus.breakSeconds ~/ 60,
                      rest: true,
                    );
                    e.focus.start();
                    e.go(MLPScreen.activeFocus);
                  },
                  child: Text('${e.focus.breakSeconds ~/ 60} daqiqa tanaffus'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (e.focus.error != null) MLPNotice(e.focus.error!, warning: true),
        const MLPNotice(
          'Ilova fonga o‘tganda pauza qilinadi. Qayta ochilganda oxirgi saqlangan vaqt pauzada tiklanadi. Fokus — faollik, o‘rganilgan ko‘nikma tasdig‘i emas.',
        ),
        MLPMetrics(
          items: [
            (
              value: '${e.store.todayFocusMinutes}',
              label: 'Bugungi fokus · daqiqa',
              icon: Icons.timelapse,
            ),
            (
              value: '${e.store.focusSessions.length}',
              label: 'Saqlangan sessiyalar',
              icon: Icons.check_circle_outline,
            ),
            (
              value: '${e.ui.preferences.minutes}',
              label: 'Kunlik vaqt niyati',
              icon: Icons.schedule,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const MLPSectionHeader(title: 'Fokus tarixi'),
        const SizedBox(height: 12),
        if (e.store.focusSessions.isEmpty)
          const MLPEmptyState(
            title: 'Birinchi sessiyangiz oldinda',
            message: 'Saqlangan haqiqiy faol vaqt shu yerda ko‘rinadi.',
          ),
        ...e.store.focusSessions.reversed
            .take(15)
            .map(
              (f) => MLPMenuTile(
                title: '${f.seconds ~/ 60} daqiqa ${f.seconds % 60} soniya',
                subtitle:
                    '${mlpDayKey(f.date)} · ${f.note.isEmpty ? 'Faollik qaydi' : f.note}',
                icon: Icons.timelapse,
                onTap: () => e.info(
                  context,
                  'Sessiya qaydi',
                  '${f.note}\n${f.evidenceUrl}\n\nBu faollik dalili. Mustaqil baholash emas.',
                ),
              ),
            ),
      ],
    ),
  );
  Future<void> _custom(BuildContext context) async {
    final input = TextEditingController(text: '${e.focus.duration ~/ 60}');
    final key = GlobalKey<FormState>();
    final value = await showDialog<int>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Fokus davomiyligi'),
        content: Form(
          key: key,
          child: MLPTextField(
            controller: input,
            label: 'Daqiqa · 1–180',
            keyboardType: TextInputType.number,
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return n == null || n < 1 || n > 180
                  ? '1–180 daqiqa kiriting.'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(dialog, int.parse(input.text));
              }
            },
            child: const Text('Tanlash'),
          ),
        ],
      ),
    );
    if (value != null && context.mounted) {
      await e.act(
        context,
        () async => e.focus.configure(value, 5, task: e.focus.taskId),
      );
    }
    // Dialog text fields are gone after the reverse transition.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
  }
}

class MLPActiveFocusPage extends StatelessWidget {
  const MLPActiveFocusPage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (popped, _) {
      if (popped && e.focus.running) e.focus.pause();
    },
    child: ListenableBuilder(
      listenable: e.focus,
      builder: (context, _) => MLPPage(
        title: e.focus.isBreak ? 'Tanaffus' : 'Fokusda',
        children: [
          const SizedBox(height: 16),
          Text(
            e.focus.task?.title ?? 'O‘zingiz uchun vaqt',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 28),
          Center(child: _TimerRing(e: e)),
          const SizedBox(height: 24),
          Text(
            e.focus.running
                ? 'DIQQAT VAQTI'
                : e.focus.remaining == 0
                ? 'VAQT TUGADI'
                : 'PAUZA',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MLPColors.turquoise,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              MLPPrimaryButton(
                label: e.focus.running ? 'Pauza' : 'Davom etish',
                icon: e.focus.running ? Icons.pause : Icons.play_arrow,
                onPressed: e.focus.remaining == 0
                    ? null
                    : () => e.focus.running ? e.focus.pause() : e.focus.start(),
              ),
              MLPSecondaryButton(
                label: 'Yakunlash',
                icon: Icons.stop_rounded,
                onPressed: () {
                  e.focus.pause();
                  e.go(MLPScreen.focusSummary);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          MLPMenuTile(
            title: 'Fon ovozi',
            subtitle: 'MLP Soundspace · audio holati alohida ko‘rsatiladi',
            icon: Icons.forest_outlined,
            onTap: () => e.go(MLPScreen.soundspace),
          ),
          if (e.focus.error != null)
            MLPErrorState(
              message: e.focus.error!,
              onRetry: () => e.focus.persist(),
            ),
          const MLPNotice(
            'Har bir haqiqiy soniya muhim. Saqlash vazifani avtomatik bajarmaydi.',
          ),
        ],
      ),
    ),
  );
}

class MLPFocusSummaryPage extends StatefulWidget {
  const MLPFocusSummaryPage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  State<MLPFocusSummaryPage> createState() => _SummaryState();
}

class _SummaryState extends State<MLPFocusSummaryPage> {
  final keyForm = GlobalKey<FormState>();
  final note = TextEditingController(), url = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    note.dispose();
    url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    return PopScope(
      canPop: !busy,
      child: MLPPage(
        title: 'Sessiya yakuni',
        children: [
          Center(
            child: MLPTimerDisplay(
              seconds: e.focus.elapsed,
              label: 'Haqiqiy faol vaqt',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            e.focus.task?.title ??
                (e.focus.isBreak ? 'Tanaffus' : 'Erkin fokus'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          MLPNotice(
            e.focus.isBreak
                ? 'Tanaffus fokus soatlariga yoki XPga qo‘shilmaydi.'
                : 'Bu vaqt faollik dalili. Ko‘nikma o‘sishi alohida baholanadi.',
          ),
          Form(
            key: keyForm,
            child: Column(
              children: [
                MLPTextField(
                  controller: note,
                  label: 'Nima bajardingiz?',
                  maxLines: 3,
                  maxLength: 2000,
                  validator: (v) =>
                      e.focus.isBreak || (v ?? '').trim().length >= 10
                      ? null
                      : 'Kamida 10 belgi bilan yozing.',
                ),
                const SizedBox(height: 16),
                MLPTextField(
                  controller: url,
                  label: 'Dalil havolasi (ixtiyoriy)',
                  maxLength: 1000,
                  keyboardType: TextInputType.url,
                  validator: (v) => mlpWebLink((v ?? '').trim())
                      ? null
                      : 'To‘g‘ri http yoki https havola kiriting.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (error != null) MLPNotice(error!, warning: true),
          MLPPrimaryButton(
            label: 'Sessiyani saqlash',
            busy: busy,
            onPressed: e.focus.elapsed < 1
                ? null
                : () async {
                    if (!keyForm.currentState!.validate() || busy) return;
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      await e.focus.save(note.text.trim(), url.text.trim());
                      if (context.mounted) {
                        e.tab(2);
                        MLPToast.show(context, 'Sessiya saqlandi.');
                      }
                    } catch (_) {
                      if (mounted) {
                        setState(() {
                          busy = false;
                          error =
                              'Saqlanmadi. Qayta urinib ko‘ring; takroriy sessiya yaratilmaydi.';
                        });
                      }
                    }
                  },
          ),
          const SizedBox(height: 12),
          MLPSecondaryButton(
            label: 'Saqlamasdan tozalash',
            onPressed: busy
                ? null
                : () async {
                    final yes = await MLPConfirmationSheet.show(
                      context,
                      title: 'Sessiya tozalansinmi?',
                      message: 'Saqlanmagan faol vaqt va qaydlar o‘chadi.',
                    );
                    if (yes && context.mounted) {
                      await e.act(context, () async {
                        await e.focus.discard();
                        e.tab(2);
                      });
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  const _TimerRing({required this.e});
  final MLPEnvironment e;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        '${e.focus.isBreak ? 'Tanaffus' : 'Fokus'}. Qolgan vaqt ${e.focus.remaining ~/ 60} daqiqa ${e.focus.remaining % 60} soniya',
    child: ExcludeSemantics(
      child: SizedBox(
        width: 252,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: e.focus.duration == 0
                      ? 0
                      : e.focus.remaining / e.focus.duration,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: MLPColors.border,
                  color: MLPColors.turquoise,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.focus.isBreak ? 'Tanaffus' : 'Pomodoro',
                      style: const TextStyle(color: MLPColors.secondaryText),
                    ),
                    const SizedBox(height: 12),
                    MLPTimerDisplay(
                      seconds: e.focus.remaining,
                      label: 'Qolgan vaqt',
                    ),
                    const SizedBox(height: 12),
                    Icon(
                      e.focus.running ? Icons.graphic_eq : Icons.timelapse,
                      color: MLPColors.turquoise,
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
}
