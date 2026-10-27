import 'package:flutter/material.dart';
import '../../app/mlp_environment.dart';
import '../../app/router/mlp_routes.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../data/models/mlp_schedule.dart';
import '../../demo/demo_store.dart';
import '../../demo/demo_forms.dart';

Future<void> mlpStartTask(
  BuildContext context,
  MLPEnvironment e,
  DemoTask task, {
  int? minutes,
}) => e.act(context, () async {
  if (e.focus.running || e.focus.elapsed > 0) {
    await e.go(MLPScreen.activeFocus);
    return;
  }
  e.focus.configure((minutes ?? task.minutes).clamp(1, 180), 5, task: task.id);
  e.focus.start();
  await e.go(MLPScreen.activeFocus);
});

Future<void> mlpTaskActions(
  BuildContext context,
  MLPEnvironment e,
  DemoTask task,
) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (sheet) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(task.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '${task.project} · ${task.minutes} daqiqa · ${mlpDayKey(task.dueDate)}',
          style: const TextStyle(color: MLPColors.secondaryText),
        ),
        const SizedBox(height: 20),
        if (!task.completed)
          MLPMenuTile(
            title: 'Fokusni boshlash',
            icon: Icons.play_circle_outline,
            onTap: () {
              Navigator.pop(sheet);
              mlpStartTask(context, e, task);
            },
          ),
        MLPMenuTile(
          title: task.completed
              ? 'Hisobotni ko‘rish va baholash'
              : 'Natijani topshirish va baholash',
          icon: Icons.fact_check_outlined,
          onTap: () {
            Navigator.pop(sheet);
            e.go(MLPScreen.verification, args: MLPRouteArgs(taskId: task.id));
          },
        ),
        MLPMenuTile(
          title: 'Vazifani tahrirlash',
          icon: Icons.edit_outlined,
          onTap: () {
            Navigator.pop(sheet);
            DemoForms.task(context, e.store, existing: task);
          },
        ),
        if (!task.completed)
          MLPMenuTile(
            title: 'Ertaga ko‘chirish',
            icon: Icons.event_repeat,
            onTap: () {
              Navigator.pop(sheet);
              e.act(
                context,
                () => e.store.deferTask(task.id),
                success: 'Vazifa ertaga ko‘chirildi.',
              );
            },
          ),
        if (task.completed)
          MLPMenuTile(
            title: 'Qayta ochish',
            icon: Icons.refresh,
            onTap: () {
              Navigator.pop(sheet);
              e.act(context, () => e.store.reopenTask(task.id));
            },
          ),
        MLPMenuTile(
          title: 'Vazifani o‘chirish',
          icon: Icons.delete_outline,
          onTap: () async {
            Navigator.pop(sheet);
            final yes = await MLPConfirmationSheet.show(
              context,
              title: 'Vazifa o‘chirilsinmi?',
              message:
                  'Vazifa va uning o‘z hisoboti o‘chadi. Fokus vaqti tarixda qoladi.',
            );
            if (yes && context.mounted) {
              await e.act(context, () => e.store.deleteTask(task.id));
            }
          },
        ),
      ],
    ),
  ),
);

class MLPTodayPage extends StatefulWidget {
  const MLPTodayPage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  State<MLPTodayPage> createState() => _TodayState();
}

class _TodayState extends State<MLPTodayPage> {
  DateTime? selected;
  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    return ListenableBuilder(
      listenable: Listenable.merge([e.store, e.ui]),
      builder: (context, _) {
        final day = selected ?? e.store.today;
        final isToday = mlpDayKey(day) == e.store.todayKey;
        final tasks = isToday
            ? e.store.todayTasks
            : e.store.tasks
                  .where((t) => mlpDayKey(t.dueDate) == mlpDayKey(day))
                  .toList();
        final pending = tasks.where((t) => !t.completed).toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));
        final next = pending.firstOrNull;
        final schedules = e.ui.schedules.where((s) => s.occursOn(day)).toList()
          ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
        final load = MLPPlannerMath.loadMinutes(schedules, day, {
          for (final t in pending) t.id: t.minutes,
        });
        final budget = e.ui.preferences.minutes;
        final weekStart = e.store.today.subtract(
          Duration(days: e.store.today.weekday - 1),
        );
        final goals = e.store.goals
            .where((g) => e.ui.goalPlan(g.id)?['archived'] != true)
            .take(3);
        return MLPPage(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Salom,',
                        style: TextStyle(color: MLPColors.secondaryText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${e.ui.profile?.name ?? 'Mehmon'}!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bugungi fokus — ertangi natija.',
                        style: TextStyle(
                          color: MLPColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Bildirishnomalar',
                  onPressed: () => e.go(MLPScreen.notifications),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                IconButton(
                  tooltip: 'Sozlamalar',
                  onPressed: () => e.go(MLPScreen.settings),
                  icon: const Icon(Icons.tune_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: List.generate(7, (i) {
                final d = weekStart.add(Duration(days: i));
                final active = mlpDayKey(d) == mlpDayKey(day);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Semantics(
                      selected: active,
                      button: true,
                      label: '${mlpDayKey(d)} kunini tanlash',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => selected = d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: active
                                ? MLPColors.turquoise
                                : MLPColors.secondary,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active
                                  ? MLPColors.turquoise
                                  : MLPColors.border,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'][i],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: active
                                      ? MLPColors.background
                                      : MLPColors.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${d.day}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? MLPColors.background
                                      : MLPColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            MLPGlassCard(
              accent: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.adjust_rounded,
                        color: MLPColors.turquoise,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'BUGUNGI ASOSIY QADAM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    next?.title ??
                        (tasks.isEmpty
                            ? 'Birinchi qadamingizni tanlang'
                            : 'Rejadagi vazifalar topshirildi'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    next == null
                        ? 'Kichik qadamlar katta natijalar yaratadi.'
                        : '${next.project} · ${next.minutes} daqiqa${isToday && next.dueDate.isBefore(e.store.today) ? ' · oldingi kundan qolgan' : ''}',
                    style: const TextStyle(
                      color: MLPColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  MLPPrimaryButton(
                    label: next == null
                        ? 'Maqsad yaratish'
                        : 'Fokusni boshlash',
                    icon: next == null ? Icons.add : Icons.play_arrow_rounded,
                    onPressed: () => next == null
                        ? e.go(MLPScreen.goalDiscovery)
                        : mlpStartTask(context, e, next),
                  ),
                  if (next != null)
                    TextButton(
                      onPressed: () =>
                          mlpStartTask(context, e, next, minutes: 5),
                      child: const Text('Faqat 5 daqiqadan boshlayman'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            MLPMetrics(
              items: [
                (
                  value:
                      '${tasks.where((t) => t.completed).length}/${tasks.length}',
                  label: 'Topshirilgan vazifa',
                  icon: Icons.task_alt,
                ),
                (
                  value: '${e.store.focusMinutesForDay(day)} daq',
                  label: 'Saqlangan fokus',
                  icon: Icons.timelapse,
                ),
                (
                  value: '$load/$budget',
                  label: 'Reja / kunlik daqiqa',
                  icon: Icons.schedule,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (load > budget)
              MLPNotice(
                'Rejangiz kunlik vaqtdan ${load - budget} daqiqa ortiq. Taqvimda vazifani boshqa kunga ko‘chiring.',
                warning: true,
              ),
            MLPSectionHeader(
              title: isToday
                  ? 'Bugungi reja'
                  : '${day.day}.${day.month} · reja',
              action: 'Taqvim',
              onAction: () => e.go(MLPScreen.calendar),
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              MLPEmptyState(
                title: 'Rejangiz ochiq',
                message: 'Bitta aniq natijani qo‘shing.',
                action: 'Vazifa qo‘shish',
                onAction: () => DemoForms.task(context, e.store),
              ),
            ...tasks
                .take(6)
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MLPTaskCard(
                      title: t.title,
                      subtitle: '${t.project} · ${t.minutes} daqiqa',
                      completed: t.completed,
                      onTap: () => mlpTaskActions(context, e, t),
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            MLPGlassCard(
              child: Row(
                children: [
                  const MLPAvatarOrb(size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.ui.preferences.nickname,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Rejani yengillashtirish yoki keyingi qadam haqida so‘rang. Demo yordamchi.',
                          style: TextStyle(
                            color: MLPColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ustoz bilan suhbat',
                    onPressed: () => e.tab(3),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            MLPSectionHeader(
              title: 'Maqsadlarim',
              action: 'Barchasi',
              onAction: () => e.tab(1),
            ),
            const SizedBox(height: 12),
            ...goals.map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MLPGoalCard(
                  title: g.title,
                  subtitle:
                      '${g.current}/${g.target} ${g.metric} · o‘z hisoboti',
                  progress: g.progress,
                  onTap: () => e.go(
                    MLPScreen.goalDetail,
                    args: MLPRouteArgs(goalId: g.id),
                  ),
                ),
              ),
            ),
            if (schedules.isNotEmpty) ...[
              const SizedBox(height: 12),
              const MLPSectionHeader(title: 'Taqvimdagi mashg‘ulotlar'),
              const SizedBox(height: 12),
              ...schedules
                  .take(5)
                  .map(
                    (s) => MLPMenuTile(
                      title: s.title,
                      subtitle:
                          '${mlpTime(s.startMinute)}–${mlpTime(s.endMinute)}',
                      icon: Icons.event_outlined,
                      onTap: () => e.go(
                        MLPScreen.scheduleEditor,
                        args: MLPRouteArgs(scheduleId: s.id),
                      ),
                    ),
                  ),
            ],
            if (e.store.isSampleData)
              const MLPNotice(
                'Namuna rejalar va shu qurilmada kiritilgan qaydlar. Faollik, o‘z hisoboti va namuna test bahosi alohida hisoblanadi.',
              ),
            if (e.store.storageError != null)
              MLPMenuTile(
                title: 'Saqlov xatosi · qayta urinish',
                subtitle: e.store.storageError,
                icon: Icons.sync_problem,
                onTap: () => e.act(context, e.store.retrySave),
              ),
          ],
        );
      },
    );
  }
}

class MLPGoalsPage extends StatefulWidget {
  const MLPGoalsPage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  State<MLPGoalsPage> createState() => _GoalsState();
}

class _GoalsState extends State<MLPGoalsPage> {
  int filter = 0;
  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    return ListenableBuilder(
      listenable: Listenable.merge([e.store, e.ui]),
      builder: (context, _) {
        final goals = e.store.goals.where((g) {
          final archived = e.ui.goalPlan(g.id)?['archived'] == true;
          return filter == 2
              ? archived
              : !archived && (filter == 0 || g.progress >= 1);
        }).toList();
        return MLPPage(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Maqsadlar',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Yangi maqsad',
                  onPressed: () => e.go(MLPScreen.goalDiscovery),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: MLPColors.turquoise,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: List.generate(
                3,
                (i) => ChoiceChip(
                  label: Text(['Faol', 'Natijaga yetgan', 'Arxiv'][i]),
                  selected: filter == i,
                  onSelected: (_) => setState(() => filter = i),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (goals.isEmpty)
              MLPEmptyState(
                title: 'Bu bo‘limda maqsad yo‘q',
                message:
                    'O‘zingiz istagan natijani yozing. Rejani tahrirlashingiz mumkin.',
                action: 'Yangi maqsad',
                onAction: () => e.go(MLPScreen.goalDiscovery),
              ),
            ...goals.map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: MLPGoalCard(
                  title: g.title,
                  subtitle:
                      '${g.category} · ${g.current}/${g.target} ${g.metric}\n${e.store.goalCompletedTaskCount(g.id)}/${e.store.goalTaskCount(g.id)} bog‘langan vazifa topshirilgan',
                  progress: g.progress,
                  onTap: () => e.go(
                    MLPScreen.goalDetail,
                    args: MLPRouteArgs(goalId: g.id),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            MLPSectionHeader(
              title: 'Vazifalar',
              action: 'Qo‘shish',
              onAction: () => DemoForms.task(context, e.store),
            ),
            const SizedBox(height: 12),
            ...e.store.tasks
                .take(20)
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MLPTaskCard(
                      title: t.title,
                      subtitle: '${t.project} · ${mlpDayKey(t.dueDate)}',
                      completed: t.completed,
                      onTap: () => mlpTaskActions(context, e, t),
                    ),
                  ),
                ),
            MLPMenuTile(
              title: 'Odatlar va barcha ma’lumotlar',
              subtitle: 'Mavjud boshqaruv oynasi',
              icon: Icons.checklist_rounded,
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => e.legacy()),
              ),
            ),
          ],
        );
      },
    );
  }
}
