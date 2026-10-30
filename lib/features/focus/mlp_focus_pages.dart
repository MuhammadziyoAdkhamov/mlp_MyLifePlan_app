import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/design_system/mlp_focus_dial.dart';
import '../../app/mlp_environment.dart';
import '../../app/router/mlp_routes.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../core/design_system/mlp_liquid_glass.dart';
import '../../core/design_system/mlp_haptics.dart';
import '../../data/models/mlp_schedule.dart';

class MLPFocusHub extends StatelessWidget {
  const MLPFocusHub({super.key, required this.e});
  final MLPEnvironment e;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: e.focus,
    builder: (context, _) => MLPPage(
      children: [
        MLPSegmented(
          labels: const ['25/5', '50/10', 'Maxsus'],
          selected: e.focus.duration == 1500
              ? 0
              : e.focus.duration == 3000
              ? 1
              : 2,
          onChanged: (value) {
            if (e.focus.running || e.focus.elapsed > 0) {
              e.info(
                context,
                'Sessiya davom etmoqda',
                'Vaqtni o‘zgartirishdan oldin joriy sessiyani yakunlang.',
              );
            } else if (value == 2) {
              _custom(context);
            } else {
              e.act(
                context,
                () async => e.focus.configure(
                  value == 0 ? 25 : 50,
                  value == 0 ? 5 : 10,
                  task: e.focus.taskId,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 20),
        Center(child: _TimerRing(e: e)),
        const SizedBox(height: 16),
        MLPMenuTile(
          title: e.focus.task?.title ?? 'Erkin fokus',
          subtitle: e.focus.task?.project ?? 'O‘zingiz uchun vaqt',
          icon: CupertinoIcons.folder,
          onTap: () => _settings(context),
        ),
        const SizedBox(height: 24),
        MLPPrimaryButton(
          label: e.focus.elapsed > 0 || e.focus.running
              ? 'Sessiyaga qaytish'
              : 'Boshlash',
          icon: CupertinoIcons.play_fill,
          onPressed: () {
            if (e.focus.remaining > 0) e.focus.start();
            e.go(MLPScreen.activeFocus);
          },
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 12,
          runSpacing: 12,
          children: [
            _FocusTool(
              label: 'Musiqa',
              icon: CupertinoIcons.music_note_2,
              onPressed: () => e.go(MLPScreen.soundspace),
            ),
            _FocusTool(
              label: 'Tanaffus',
              icon: Icons.local_cafe_outlined,
              onPressed: () {
                if (e.focus.elapsed > 0 || e.focus.running) {
                  e.info(
                    context,
                    'Avval sessiyani yakunlang',
                    'Faol vaqt saqlangach, tanlangan tanaffusni boshlashingiz mumkin.',
                  );
                } else {
                  final minutes = e.focus.breakSeconds ~/ 60;
                  e.focus.configure(minutes, minutes, rest: true);
                  e.focus.start();
                  e.go(MLPScreen.activeFocus);
                }
              },
            ),
            _FocusTool(
              label: 'Sozlash',
              icon: CupertinoIcons.slider_horizontal_3,
              onPressed: () => _settings(context),
            ),
            _FocusTool(
              label: 'Tarix',
              icon: CupertinoIcons.clock,
              onPressed: () => _settings(context),
            ),
          ],
        ),
        if (e.focus.error != null)
          MLPErrorState(message: e.focus.error!, onRetry: e.focus.persist),
      ],
    ),
  );

  void _settings(BuildContext context) => mlpShowSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => SizedBox(
      height: MediaQuery.sizeOf(context).height * .8,
      child: details(context),
    ),
  );

  Widget details(BuildContext context) => ListenableBuilder(
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
                  for (final pair in [
                    (15, 3),
                    (25, 5),
                    (39, 5),
                    (50, 10),
                    (60, 10),
                    (90, 15),
                  ])
                    ChoiceChip(
                      label: Text(
                        pair.$1 == 39
                            ? '39 daq 🎯'
                            : (pair.$1 == 25 || pair.$1 == 50
                                  ? '${pair.$1}/${pair.$2}'
                                  : '${pair.$1} daq'),
                      ),
                      selected: e.focus.duration == pair.$1 * 60,
                      onSelected: e.focus.elapsed > 0 || e.focus.running
                          ? null
                          : (_) {
                              MLPHaptics.selection();
                              e.act(
                                context,
                                () async => e.focus.configure(
                                  pair.$1,
                                  pair.$2,
                                  task: e.focus.taskId,
                                ),
                              );
                            },
                    ),
                  ActionChip(
                    label: const Text('O‘z vaqtim ✏️'),
                    onPressed: e.focus.elapsed > 0 || e.focus.running
                        ? null
                        : () => _custom(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '5 daqiqa kamaytirish',
                            icon: const Icon(
                              Icons.replay_5_rounded,
                              size: 20,
                              color: MLPColors.turquoise,
                            ),
                            onPressed:
                                (e.focus.elapsed > 0 ||
                                    e.focus.running ||
                                    e.focus.duration <= 300)
                                ? null
                                : () {
                                    MLPHaptics.selection();
                                    final m = ((e.focus.duration ~/ 60) - 5)
                                        .clamp(1, 180);
                                    e.act(
                                      context,
                                      () async => e.focus.configure(
                                        m,
                                        e.focus.breakSeconds ~/ 60,
                                        task: e.focus.taskId,
                                      ),
                                    );
                                  },
                          ),
                          IconButton(
                            tooltip: '1 daqiqa kamaytirish',
                            icon: const Icon(
                              Icons.remove_circle_outline_rounded,
                              size: 20,
                              color: MLPColors.text,
                            ),
                            onPressed:
                                (e.focus.elapsed > 0 ||
                                    e.focus.running ||
                                    e.focus.duration <= 60)
                                ? null
                                : () {
                                    MLPHaptics.selection();
                                    final m = ((e.focus.duration ~/ 60) - 1)
                                        .clamp(1, 180);
                                    e.act(
                                      context,
                                      () async => e.focus.configure(
                                        m,
                                        e.focus.breakSeconds ~/ 60,
                                        task: e.focus.taskId,
                                      ),
                                    );
                                  },
                          ),
                        ],
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: (e.focus.elapsed > 0 || e.focus.running)
                            ? null
                            : () => _custom(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${e.focus.duration ~/ 60} daqiqa',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: MLPColors.turquoise,
                                ),
                              ),
                              const Text(
                                'Bemalol sozlang (1–180)',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: MLPColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '1 daqiqa qo‘shish',
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 20,
                              color: MLPColors.text,
                            ),
                            onPressed:
                                (e.focus.elapsed > 0 ||
                                    e.focus.running ||
                                    e.focus.duration >= 180 * 60)
                                ? null
                                : () {
                                    MLPHaptics.selection();
                                    final m = ((e.focus.duration ~/ 60) + 1)
                                        .clamp(1, 180);
                                    e.act(
                                      context,
                                      () async => e.focus.configure(
                                        m,
                                        e.focus.breakSeconds ~/ 60,
                                        task: e.focus.taskId,
                                      ),
                                    );
                                  },
                          ),
                          IconButton(
                            tooltip: '5 daqiqa qo‘shish',
                            icon: const Icon(
                              Icons.forward_5_rounded,
                              size: 20,
                              color: MLPColors.turquoise,
                            ),
                            onPressed:
                                (e.focus.elapsed > 0 ||
                                    e.focus.running ||
                                    e.focus.duration >= 175 * 60)
                                ? null
                                : () {
                                    MLPHaptics.selection();
                                    final m = ((e.focus.duration ~/ 60) + 5)
                                        .clamp(1, 180);
                                    e.act(
                                      context,
                                      () async => e.focus.configure(
                                        m,
                                        e.focus.breakSeconds ~/ 60,
                                        task: e.focus.taskId,
                                      ),
                                    );
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
    final value = await mlpShowDialog<int>(
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
        background: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: Image.asset(
                    'assets/images/mlp_moon_mountain_v1.png',
                    fit: BoxFit.cover,
                    color: const Color(0x9909182C),
                    colorBlendMode: BlendMode.multiply,
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xCC030B1D),
                        Color(0x22030B1D),
                        Color(0xEE030B1D),
                      ],
                      stops: [0, .4, 1],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        title: e.focus.isBreak ? 'Tanaffus' : 'Fokus',
        children: [
          const Text(
            'Kichik qadamlar katta natijalarga olib keladi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: MLPColors.secondaryText),
          ),
          const SizedBox(height: 16),
          Text(
            e.focus.task?.title ?? 'O‘zingiz uchun vaqt',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 28),
          const SizedBox(height: 100),
          Center(
            child: MLPTimerDisplay(
              seconds: e.focus.remaining,
              label: 'Qolgan vaqt',
            ),
          ),
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
              MLPCircleAction(
                size: 60,
                label: e.focus.running ? 'Pauza' : 'Davom etish',
                icon: e.focus.running ? Icons.pause : Icons.play_arrow,
                onPressed: e.focus.remaining == 0
                    ? null
                    : () => e.focus.running ? e.focus.pause() : e.focus.start(),
              ),
              MLPCircleAction(
                size: 60,
                color: const Color(0xFFFF526D),
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
        title: 'Sessiya yakunlandi!',
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x66FFD700),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Icon(
                CupertinoIcons.star_fill,
                color: Color(0xFFFFD700),
                size: 76,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    '+ 50 XP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: MLPTimerDisplay(
              seconds: e.focus.elapsed,
              label: 'Fokus vaqti',
            ),
          ),
          const SizedBox(height: 14),
          if (e.focus.task != null) ...[
            MLPGlassCard(
              padding: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loyiha: ${e.focus.task!.project}',
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vazifa: ${e.focus.task!.title}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
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
            label: 'Saqlash',
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
        width: 320,
        child: AspectRatio(
          aspectRatio: 1,
          child: TweenAnimationBuilder<double>(
            tween: Tween(
              end: e.focus.duration == 0
                  ? 0
                  : e.focus.remaining / e.focus.duration,
            ),
            duration: MLPDimensions.motion(context),
            builder: (context, value, child) =>
                CustomPaint(painter: MLPFocusDialPainter(value), child: child),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.focus.isBreak ? 'Tanaffus' : 'Fokus vaqti',
                      style: const TextStyle(color: MLPColors.secondaryText),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${(e.focus.remaining ~/ 60).toString().padLeft(2, '0')}:${(e.focus.remaining % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 58,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _FocusTool extends StatelessWidget {
  const _FocusTool({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 68,
    child: Column(
      children: [
        MLPCircleAction(
          label: label,
          icon: icon,
          onPressed: onPressed,
          filled: false,
          size: 52,
        ),
        const SizedBox(height: 7),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}
