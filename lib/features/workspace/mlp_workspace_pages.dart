import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../app/mlp_environment.dart';
import '../../app/router/mlp_routes.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../core/design_system/mlp_liquid_glass.dart';
import '../../core/design_system/mlp_reference_components.dart';
import '../../data/models/mlp_schedule.dart';
import '../../demo/demo_store.dart';
import '../../demo/demo_forms.dart';
import '../../core/design_system/mlp_haptics.dart';
import '../../core/design_system/mlp_confetti.dart';

part 'mlp_ios_workspace.dart';

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
) => mlpShowSheet<void>(
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

class MLPDetailedTodayPage extends StatefulWidget {
  const MLPDetailedTodayPage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  State<MLPDetailedTodayPage> createState() => _TodayState();
}

class _TodayState extends State<MLPDetailedTodayPage> {
  DateTime? selected;
  bool showWeek = false;
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
          ..sort(_priorityOrder);
        final next = pending.firstOrNull;
        final schedules = e.ui.schedules.where((s) => s.occursOn(day)).toList()
          ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
        final load = MLPPlannerMath.loadMinutes(schedules, day, {
          for (final t in pending) t.id: t.minutes,
        });
        final goals = e.store.goals
            .where((g) => e.ui.goalPlan(g.id)?['archived'] != true)
            .toList();
        final focusSeconds = e.store.focusSessions
            .where((f) => mlpDayKey(f.date) == mlpDayKey(day))
            .fold<int>(0, (sum, f) => sum + f.seconds);
        final represented = schedules
            .take(5)
            .map((s) => s.taskId)
            .whereType<String>()
            .toSet();
        final habits = e.store.scheduledHabits(day);
        final completedHabits = habits
            .where((h) => e.store.habitValue(h.id, day) >= h.targetForDate(day))
            .length;
        final completedTasks = tasks.where((t) => t.completed).length;
        final totalItems = tasks.length + habits.length;
        final momentum = totalItems == 0
            ? 0.0
            : ((completedTasks + completedHabits) / totalItems).clamp(0.0, 1.0);
        final maxStreak = e.store.habits.isEmpty
            ? 0
            : e.store.habits
                  .map((h) => e.store.habitStreak(h.id))
                  .fold<int>(0, (a, b) => math.max(a, b));
        return MLPPage(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MLPPressResponse(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => e.go(MLPScreen.profile),
                      child: Semantics(
                        button: true,
                        label: 'Mening profilim',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Salom,',
                                style: TextStyle(
                                  color: MLPColors.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${e.ui.profile?.name ?? 'Mehmon'}! 👋',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '“Bugungi fokus — ertangi natija.”',
                                style: TextStyle(
                                  color: MLPColors.secondaryText,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Bildirishnomalar',
                  onPressed: () => e.go(MLPScreen.notifications),
                  icon: const Icon(Icons.notifications_none_rounded, size: 23),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MLPGlassCard(
              padding: 16,
              accent: true,
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 66,
                        height: 66,
                        child: CircularProgressIndicator(
                          value: momentum,
                          strokeWidth: 6.5,
                          backgroundColor: Colors.white.withValues(alpha: .08),
                          valueColor: AlwaysStoppedAnimation(
                            momentum >= 1.0
                                ? MLPColors.success
                                : MLPColors.turquoise,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(momentum * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: MLPColors.text,
                            ),
                          ),
                          const Text(
                            'Natija',
                            style: TextStyle(
                              fontSize: 9,
                              color: MLPColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: MLPColors.turquoise.withValues(
                                  alpha: .15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isToday
                                    ? 'KUNLIK INTIZOM'
                                    : '${day.day}.${day.month} INTIZOM',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: MLPColors.turquoise,
                                  letterSpacing: .5,
                                ),
                              ),
                            ),
                            if (maxStreak > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: .15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.flame_fill,
                                      size: 10,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '$maxStreak kun',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          momentum >= 1.0
                              ? 'Ajoyib natija! Barcha rejalar bajarildi! 🎉'
                              : '$completedTasks/${tasks.length} vazifa · $completedHabits/${habits.length} odat bajarildi',
                          style: const TextStyle(
                            fontSize: 12,
                            color: MLPColors.secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '⚡ Jami ${e.store.xp} XP',
                          style: const TextStyle(
                            fontSize: 11,
                            color: MLPColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (focusSeconds > 0
                                        ? MLPColors.turquoise
                                        : Colors.white)
                                    .withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  (focusSeconds > 0
                                          ? MLPColors.turquoise
                                          : Colors.white)
                                      .withValues(alpha: .18),
                            ),
                          ),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            runSpacing: 2,
                            children: [
                              Icon(
                                Icons.timelapse_rounded,
                                size: 12,
                                color: focusSeconds > 0
                                    ? MLPColors.turquoise
                                    : MLPColors.secondaryText,
                              ),
                              Text(
                                focusSeconds > 0
                                    ? '${focusSeconds ~/ 60} daqiqa fokus 🔥'
                                    : 'Fokus: 0 daq',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: focusSeconds > 0
                                      ? MLPColors.turquoise
                                      : MLPColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            MLPGlassCard(
              padding: 12,
              accent: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.track_changes_rounded,
                        color: MLPColors.turquoise,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isToday
                              ? 'Bugungi eng muhim vazifa'
                              : '${day.day}.${day.month} · eng muhim vazifa',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (next == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        tasks.isEmpty
                            ? 'Birinchi qadamingizni tanlang'
                            : 'Rejadagi vazifalar topshirildi',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  else
                    MLPCompactTaskCard(
                      title: next.title,
                      subtitle:
                          '${next.project}${isToday && next.dueDate.isBefore(e.store.today) ? ' · oldingi kundan' : ''}',
                      seconds: _taskSeconds(e, next.id),
                      plannedMinutes: next.minutes,
                      onPlay: () => mlpStartTask(context, e, next),
                      onOpen: () => mlpTaskActions(context, e, next),
                      onMenu: () => mlpTaskActions(context, e, next),
                    ),
                  const SizedBox(height: 10),
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
                      style: TextButton.styleFrom(
                        textStyle: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(fontSize: 11),
                      ),
                      onPressed: () =>
                          mlpStartTask(context, e, next, minutes: 5),
                      child: const Text('Faqat 5 daqiqadan boshlayman'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            MLPCompactMetrics(
              items: [
                (
                  value: '${tasks.length}',
                  label: 'Vazifalar',
                  icon: Icons.task_alt_rounded,
                  color: MLPColors.primary,
                ),
                (
                  value: _focusText(focusSeconds),
                  label: 'Fokus vaqti',
                  icon: Icons.timelapse_rounded,
                  color: MLPColors.turquoise,
                ),
                (
                  value: '${goals.length}',
                  label: 'Faol maqsadlar',
                  icon: Icons.flag_rounded,
                  color: MLPColors.success,
                ),
              ],
            ),
            const SizedBox(height: 12),
            MLPGlassCard(
              padding: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => showWeek = !showWeek),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    isToday
                                        ? 'Bugungi reja'
                                        : '${day.day}.${day.month} · reja',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  showWeek
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 17,
                                  color: MLPColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => e.go(MLPScreen.calendar),
                        child: const Text(
                          'Taqvim ›',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  if (showWeek) ...[
                    MLPWeekStrip(
                      selected: day,
                      onChanged: (v) => setState(() => selected = v),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (tasks.isEmpty && schedules.isEmpty)
                    MLPEmptyState(
                      title: 'Rejangiz ochiq',
                      message: 'Bitta aniq natijani qo‘shing.',
                      action: 'Vazifa qo‘shish',
                      onAction: () => DemoForms.task(context, e.store),
                    ),
                  ...schedules.take(5).map((s) {
                    final task = e.store.tasks
                        .where((t) => t.id == s.taskId)
                        .firstOrNull;
                    return _TimelineRow(
                      time: mlpTime(s.startMinute),
                      title: s.title,
                      completed: task?.completed ?? false,
                      onOpen: () => e.go(
                        MLPScreen.scheduleEditor,
                        args: MLPRouteArgs(scheduleId: s.id),
                      ),
                      onPlay: task == null
                          ? null
                          : () => mlpStartTask(context, e, task),
                    );
                  }),
                  ...tasks
                      .where((t) => !represented.contains(t.id))
                      .take(5)
                      .map(
                        (t) => _TimelineRow(
                          title: t.title,
                          completed: t.completed,
                          onOpen: () => mlpTaskActions(context, e, t),
                          onPlay: t.completed
                              ? () => e.go(
                                  MLPScreen.verification,
                                  args: MLPRouteArgs(taskId: t.id),
                                )
                              : () => mlpStartTask(context, e, t),
                        ),
                      ),
                  if (tasks.isNotEmpty)
                    TextButton(
                      onPressed: () => e.tab(3),
                      child: const Text(
                        'Barcha vazifalar',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Reja: $load / ${e.ui.preferences.minutes} daq.\nSoat faqat taqvimda belgilangan mashg‘ulotlarda ko‘rsatiladi.',
                    style: TextStyle(
                      color: load > e.ui.preferences.minutes
                          ? MLPColors.warning
                          : MLPColors.muted,
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionLine(
              title: 'Kundalik odatlar & intizom',
              action: 'Yangi odat',
              onAction: () => DemoForms.habit(context, e.store),
            ),
            const SizedBox(height: 8),
            if (habits.isEmpty)
              MLPGlassCard(
                padding: 16,
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.sparkles,
                      color: MLPColors.primaryLight,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Hali odatlar kiritilmagan. O‘zingizga mos odat belgilang.',
                        style: TextStyle(
                          color: MLPColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => DemoForms.habit(context, e.store),
                      child: const Text(
                        'Qo‘shish ›',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...habits.map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _HabitGlassCard(
                    habit: h,
                    e: e,
                    day: day,
                    isToday: isToday,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (!e.ui.assistantHidden)
              MLPGlassCard(
                padding: 12,
                onTap: () => e.go(MLPScreen.chat),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: MLPColors.primaryLight,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ustoz AI',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${e.ui.preferences.nickname} bilan keyingi qadamni tanlang',
                            style: const TextStyle(
                              color: MLPColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ustoz bilan suhbat',
                      onPressed: () => e.go(MLPScreen.chat),
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    ),
                    IconButton(
                      tooltip: 'Ustoz tezkor tugmasini yashirish',
                      onPressed: () =>
                          e.act(context, () => e.ui.hideAssistant(true)),
                      icon: const Icon(Icons.close_rounded, size: 16),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _SectionLine(
              title: 'Maqsadlarim',
              action: 'Barchasi',
              onAction: () => e.tab(1),
            ),
            const SizedBox(height: 8),
            ...goals
                .take(2)
                .map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _GoalSummary(goal: g, e: e),
                  ),
                ),
            if (goals.isEmpty)
              MLPSecondaryButton(
                label: 'Birinchi maqsadni qo‘shish',
                onPressed: () => e.go(MLPScreen.goalDiscovery),
                icon: Icons.add,
              ),
            if (e.store.isSampleData)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Namuna va mahalliy qaydlar. Fokus — faollik; topshirilgan natija — o‘z hisoboti. Ular ko‘nikma bahosi emas.',
                  style: TextStyle(
                    fontSize: 10,
                    color: MLPColors.muted,
                    height: 1.5,
                  ),
                ),
              ),
            if (e.store.storageError != null) ...[
              const SizedBox(height: 12),
              MLPMenuTile(
                title: 'Saqlov xatosi · qayta urinish',
                subtitle: e.store.storageError,
                icon: Icons.sync_problem,
                onTap: () => e.act(context, e.store.retrySave),
              ),
            ],
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
  final search = TextEditingController();
  int filter = 0;
  bool searching = false, archived = false, dateScoped = false;
  DateTime? selected;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    return ListenableBuilder(
      listenable: Listenable.merge([e.store, e.ui]),
      builder: (context, _) {
        final day = selected ?? e.store.today;
        final query = search.text.trim().toLowerCase();
        final tasks = e.store.tasks
            .where((t) => !dateScoped || mlpDayKey(t.dueDate) == mlpDayKey(day))
            .toList();
        final grouped = <String, List<DemoTask>>{};
        for (final task in tasks) {
          grouped.putIfAbsent(task.project, () => []).add(task);
        }
        final entries = grouped.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        final activeCount = entries
            .where((p) => p.value.any((t) => !t.completed))
            .length;
        final doneCount = entries.length - activeCount;
        final visible = entries.where((p) {
          final complete = p.value.every((t) => t.completed);
          final matches =
              p.key.toLowerCase().contains(query) ||
              p.value.any((t) => t.title.toLowerCase().contains(query));
          return matches &&
              (filter == 0 || (filter == 1 ? !complete : complete));
        }).toList();
        final goals = e.store.goals.where((g) {
          final inArchive = e.ui.goalPlan(g.id)?['archived'] == true;
          return inArchive == archived && g.title.toLowerCase().contains(query);
        }).toList();
        return MLPPage(
          children: [
            MLPCompactHeader(
              title: 'Loyihalar',
              actions: [
                IconButton(
                  tooltip: 'Loyihalardan qidirish',
                  onPressed: () => setState(() {
                    searching = !searching;
                    if (!searching) search.clear();
                  }),
                  icon: const Icon(Icons.search_rounded, size: 21),
                ),
                IconButton(
                  tooltip: 'Loyiha amallari',
                  onPressed: () => _workspaceActions(context, e),
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
            if (searching) ...[
              TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                decoration: const InputDecoration(
                  hintText: 'Loyiha yoki vazifa nomi',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
            ],
            MLPWeekStrip(
              selected: day,
              onChanged: (v) => setState(() {
                selected = v;
                dateScoped = true;
              }),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateScoped
                        ? '${day.day}.${day.month} sanali vazifalar'
                        : 'Barcha sanalardagi vazifalar',
                    style: const TextStyle(
                      color: MLPColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ),
                Flexible(
                  child: TextButton(
                    onPressed: () => setState(() => dateScoped = !dateScoped),
                    child: Text(
                      dateScoped ? 'Barcha sanalar' : 'Faqat tanlangan kun',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            MLPSegmented(
              labels: [
                'Barchasi (${entries.length})',
                'Faol ($activeCount)',
                'Tugallangan ($doneCount)',
              ],
              selected: filter,
              onChanged: (i) => setState(() => filter = i),
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              MLPEmptyState(
                title: 'Loyiha topilmadi',
                message:
                    'Qidiruv yoki sanani o‘zgartiring. Loyiha vazifalardagi loyiha nomidan tuziladi.',
                action: 'Vazifa qo‘shish',
                onAction: () => DemoForms.task(context, e.store),
              ),
            ...visible.map((p) {
              final ordered = [...p.value]..sort(_priorityOrder);
              final next = ordered.where((t) => !t.completed).firstOrNull;
              final ids = ordered.map((t) => t.id).toSet();
              final seconds = e.store.focusSessions
                  .where((f) => ids.contains(f.taskId))
                  .fold<int>(0, (sum, f) => sum + f.seconds);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MLPCompactTaskCard(
                  title: p.key,
                  subtitle:
                      '${ordered.length} vazifa · ${ordered.where((t) => t.completed).length} topshirilgan',
                  seconds: seconds,
                  plannedMinutes: ordered.fold<int>(
                    0,
                    (sum, t) => sum + t.minutes,
                  ),
                  color: _projectColor(p.key),
                  completed: next == null,
                  onPlay: () => next == null
                      ? _projectTasks(context, e, p.key, ordered)
                      : mlpStartTask(context, e, next),
                  onOpen: () => _projectTasks(context, e, p.key, ordered),
                  onMenu: () => _projectTasks(context, e, p.key, ordered),
                ),
              );
            }),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Foiz: saqlangan fokus / rejalangan vaqt. Bu ko‘nikma bahosi emas.',
                style: TextStyle(
                  fontSize: 10,
                  color: MLPColors.muted,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionLine(
              title: archived ? 'Arxivdagi maqsadlar' : 'Maqsadlarim',
              action: archived ? 'Faol maqsadlar' : 'Arxiv',
              onAction: () => setState(() => archived = !archived),
            ),
            const SizedBox(height: 8),
            if (goals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  archived
                      ? 'Arxivdagi maqsadlar yo‘q.'
                      : 'Maqsad hali yo‘q. Istagan natijangizni yozing.',
                  style: const TextStyle(
                    color: MLPColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
            ...goals.map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _GoalSummary(goal: g, e: e),
              ),
            ),
            MLPSecondaryButton(
              label: 'Yangi maqsad',
              icon: Icons.add_rounded,
              onPressed: () => e.go(MLPScreen.goalDiscovery),
            ),
            const SizedBox(height: 14),
            MLPMenuTile(
              title: 'Odatlar va barcha ma’lumotlar',
              subtitle: 'Saqlangan reja va odatlarni boshqarish',
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

class MLPTasksPage extends StatefulWidget {
  const MLPTasksPage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  State<MLPTasksPage> createState() => _TasksState();
}

class _TasksState extends State<MLPTasksPage> {
  final search = TextEditingController();
  int filter = 0;
  bool searching = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    return ListenableBuilder(
      listenable: Listenable.merge([e.store, e.ui]),
      builder: (context, _) {
        final query = search.text.trim().toLowerCase();
        final today = e.store.todayTasks;
        final important = e.store.tasks.where((t) => t.priority == 1).toList();
        final source = filter == 0
            ? today
            : filter == 1
            ? e.store.tasks
            : important;
        final tasks =
            source
                .where(
                  (t) =>
                      t.title.toLowerCase().contains(query) ||
                      t.project.toLowerCase().contains(query),
                )
                .toList()
              ..sort((a, b) {
                if (a.completed != b.completed) return a.completed ? 1 : -1;
                return _priorityOrder(a, b);
              });
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: tasks.length + 2,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MLPCompactHeader(
                        title: 'Vazifalar',
                        actions: [
                          IconButton(
                            tooltip: 'Vazifalardan qidirish',
                            onPressed: () => setState(() {
                              searching = !searching;
                              if (!searching) search.clear();
                            }),
                            icon: const Icon(Icons.search_rounded, size: 21),
                          ),
                          IconButton(
                            tooltip: 'Yangi vazifa',
                            onPressed: () => DemoForms.task(context, e.store),
                            icon: const Icon(
                              Icons.add_rounded,
                              color: MLPColors.turquoise,
                            ),
                          ),
                        ],
                      ),
                      if (searching) ...[
                        TextField(
                          controller: search,
                          onChanged: (_) => setState(() {}),
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          decoration: const InputDecoration(
                            hintText: 'Vazifa yoki loyiha nomi',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      MLPSegmented(
                        labels: [
                          'Bugun (${today.length})',
                          'Barchasi (${e.store.tasks.length})',
                          'Muhim (${important.length})',
                        ],
                        selected: filter,
                        onChanged: (i) => setState(() => filter = i),
                      ),
                      const SizedBox(height: 12),
                      if (tasks.isEmpty)
                        MLPEmptyState(
                          title: 'Vazifa topilmadi',
                          message:
                              'Boshqa filtrni tanlang yoki yangi vazifa qo‘shing.',
                          action: 'Vazifa qo‘shish',
                          onAction: () => DemoForms.task(context, e.store),
                        ),
                    ],
                  );
                }
                if (i == tasks.length + 1) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Fokus vaqti — qayd etilgan faollik. Belgilash natijani o‘z hisobotingiz bilan topshirish oynasini ochadi.',
                      style: TextStyle(
                        color: MLPColors.muted,
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TaskRow(task: tasks[i - 1], e: e),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

int _priorityOrder(DemoTask a, DemoTask b) {
  final priority = a.priority.compareTo(b.priority);
  return priority != 0 ? priority : a.dueDate.compareTo(b.dueDate);
}

int _taskSeconds(MLPEnvironment e, String id) => e.store.focusSessions
    .where((f) => f.taskId == id)
    .fold<int>(0, (sum, f) => sum + f.seconds);
String _focusText(int seconds) =>
    seconds < 60 ? '${seconds}s' : mlpCompactTime(seconds);
Color _projectColor(String project) {
  const palette = [
    MLPColors.turquoise,
    MLPColors.primary,
    MLPColors.success,
    MLPColors.warning,
  ];
  return palette[project.codeUnits.fold<int>(0, (sum, c) => sum + c) %
      palette.length];
}

Future<void> _workspaceActions(BuildContext context, MLPEnvironment e) =>
    mlpShowSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheet) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MLPMenuTile(
              title: 'Yangi maqsad',
              icon: Icons.flag_outlined,
              onTap: () {
                Navigator.pop(sheet);
                e.go(MLPScreen.goalDiscovery);
              },
            ),
            MLPMenuTile(
              title: 'Vazifa qo‘shish',
              subtitle: 'Loyiha nomini vazifa formasida kiriting',
              icon: Icons.add_task_rounded,
              onTap: () {
                Navigator.pop(sheet);
                DemoForms.task(context, e.store);
              },
            ),
            MLPMenuTile(
              title: 'Taqvim',
              icon: Icons.calendar_month_rounded,
              onTap: () {
                Navigator.pop(sheet);
                e.go(MLPScreen.calendar);
              },
            ),
          ],
        ),
      ),
    );

Future<void> _projectTasks(
  BuildContext context,
  MLPEnvironment e,
  String project,
  List<DemoTask> tasks,
) => mlpShowSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (sheet) => FractionallySizedBox(
    heightFactor: .8,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(project, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text(
          'Vazifa yoki uning amallarini tanlang.',
          style: TextStyle(color: MLPColors.secondaryText, fontSize: 12),
        ),
        const SizedBox(height: 16),
        ...tasks.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MLPCompactTaskCard(
              title: t.title,
              subtitle:
                  '${mlpDayKey(t.dueDate)} · ${t.completed ? 'topshirilgan' : 'rejalangan'}',
              seconds: _taskSeconds(e, t.id),
              plannedMinutes: t.minutes,
              color: _projectColor(project),
              completed: t.completed,
              onOpen: () {
                Navigator.pop(sheet);
                mlpTaskActions(context, e, t);
              },
              onMenu: () {
                Navigator.pop(sheet);
                mlpTaskActions(context, e, t);
              },
              onPlay: () {
                Navigator.pop(sheet);
                if (t.completed) {
                  e.go(
                    MLPScreen.verification,
                    args: MLPRouteArgs(taskId: t.id),
                  );
                } else {
                  mlpStartTask(context, e, t);
                }
              },
            ),
          ),
        ),
        MLPSecondaryButton(
          label: 'Vazifa qo‘shish',
          icon: Icons.add_rounded,
          onPressed: () {
            Navigator.pop(sheet);
            DemoForms.task(context, e.store);
          },
        ),
      ],
    ),
  ),
);

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.e});
  final DemoTask task;
  final MLPEnvironment e;
  @override
  Widget build(BuildContext context) {
    final seconds = _taskSeconds(e, task.id);
    final progress = (seconds / (task.minutes * 60)).clamp(0.0, 1.0);
    final color = _projectColor(task.project);
    final priority = task.priority == 1
        ? 'Muhim'
        : task.priority == 2
        ? 'O‘rta'
        : 'Past';
    final priorityColor = task.priority == 1
        ? const Color(0xFFFF7D9B)
        : task.priority == 2
        ? MLPColors.warning
        : MLPColors.success;
    void report() {
      MLPHaptics.medium();
      e.go(MLPScreen.verification, args: MLPRouteArgs(taskId: task.id));
    }

    return Dismissible(
      key: ValueKey('task_${task.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          MLPHaptics.success();
          report();
          return false;
        } else {
          MLPHaptics.medium();
          mlpTaskActions(context, e, task);
          return false;
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: MLPColors.success.withValues(alpha: .22),
          border: Border.all(color: MLPColors.success.withValues(alpha: .4)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: MLPColors.success,
              size: 26,
            ),
            SizedBox(width: 8),
            Text(
              'Topshirish',
              style: TextStyle(
                color: MLPColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: MLPColors.primary.withValues(alpha: .22),
          border: Border.all(color: MLPColors.primary.withValues(alpha: .4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Boshqarish',
              style: TextStyle(
                color: MLPColors.primaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.tune_rounded, color: MLPColors.primaryLight, size: 24),
          ],
        ),
      ),
      child: MLPGlassCard(
        padding: 10,
        onTap: () {
          MLPHaptics.light();
          mlpTaskActions(context, e, task);
        },
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip:
                      '${task.completed ? 'Hisobotni ko‘rish' : 'Natijani topshirish'}: ${task.title}',
                  onPressed: report,
                  icon: Icon(
                    task.completed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: task.completed
                        ? MLPColors.success
                        : MLPColors.secondaryText,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          MLPBadge(
                            priority,
                            color: priorityColor,
                            icon: Icons.star_rounded,
                          ),
                          MLPBadge(
                            task.project,
                            color: color,
                            icon: Icons.folder_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    SizedBox(
                      height: 34,
                      child: IconButton(
                        tooltip: 'Amallar: ${task.title}',
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          MLPHaptics.light();
                          mlpTaskActions(context, e, task);
                        },
                        icon: const Icon(Icons.more_horiz_rounded, size: 19),
                      ),
                    ),
                    MLPCircleAction(
                      label: task.completed
                          ? 'Hisobot: ${task.title}'
                          : 'Fokusni boshlash: ${task.title}',
                      icon: Icons.play_arrow_rounded,
                      size: 34,
                      onPressed: () {
                        MLPHaptics.heavy();
                        if (task.completed) {
                          report();
                        } else {
                          mlpStartTask(context, e, task);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 56, top: 6),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final label = Text(
                        '${_focusText(seconds)} / ${task.minutes}m',
                        style: const TextStyle(
                          fontSize: 10,
                          color: MLPColors.secondaryText,
                        ),
                      );
                      final date = Text(
                        mlpDayKey(task.dueDate),
                        style: const TextStyle(
                          fontSize: 9,
                          color: MLPColors.muted,
                        ),
                      );
                      return MediaQuery.textScalerOf(context).scale(1) > 1.4 ||
                              constraints.maxWidth < 180
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [label, date],
                            )
                          : Row(
                              children: [
                                Expanded(child: label),
                                date,
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 5),
                  Semantics(
                    label: 'Saqlangan fokus ${(progress * 100).round()} foiz',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        color: MLPColors.turquoise,
                        backgroundColor: Colors.white.withValues(alpha: .08),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitGlassCard extends StatelessWidget {
  const _HabitGlassCard({
    required this.habit,
    required this.e,
    required this.day,
    required this.isToday,
  });
  final DemoHabit habit;
  final MLPEnvironment e;
  final DateTime day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final value = e.store.habitValue(habit.id, day);
    final target = habit.targetForDate(day);
    final scheduled = habit.scheduledOn(day);
    final isDone = value >= target;
    final streak = e.store.habitStreak(habit.id);

    return MLPGlassCard(
      padding: 12,
      child: Row(
        children: [
          IconButton(
            tooltip: isDone
                ? '${habit.title}: bajarilishni qaytarish'
                : '${habit.title}: +1 qo‘shish',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: const EdgeInsets.all(6),
            onPressed: !isToday || !scheduled
                ? null
                : () => e.act(context, () async {
                    if (!isDone) {
                      MLPHaptics.medium();
                      await e.store.incrementHabit(habit.id);
                      if (context.mounted && value + 1 >= target) {
                        MLPConfetti.show(
                          context,
                          title: '${habit.title} bajarildi! 🔥',
                          subtitle: '+15 XP hisobingizda',
                        );
                      }
                    } else {
                      MLPHaptics.selection();
                      await e.store.undoHabit(habit.id);
                    }
                  }),
            icon: AnimatedContainer(
              duration: MLPDimensions.motion(context),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? MLPColors.success.withValues(alpha: .2)
                    : Colors.white.withValues(alpha: .06),
                border: Border.all(
                  color: isDone
                      ? MLPColors.success
                      : Colors.white.withValues(alpha: .2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isDone
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
                color: isDone ? MLPColors.success : MLPColors.secondaryText,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      habit.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone
                            ? MLPColors.secondaryText
                            : MLPColors.text,
                      ),
                    ),
                    if (streak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: .4),
                            width: .8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.flame_fill,
                              size: 10,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$streak kun',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$value / $target ${habit.unitForDate(day)}${scheduled ? '' : ' · Dam kuni'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: MLPColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (isToday && scheduled && !isDone)
            IconButton(
              tooltip: '+1 qo‘shish',
              onPressed: () => e.act(context, () async {
                MLPHaptics.medium();
                await e.store.incrementHabit(habit.id);
                if (context.mounted && value + 1 >= target) {
                  MLPConfetti.show(
                    context,
                    title: '${habit.title} bajarildi! 🔥',
                    subtitle: '+15 XP hisobingizda',
                  );
                }
              }),
              icon: const Icon(
                CupertinoIcons.add_circled,
                color: MLPColors.turquoise,
                size: 24,
              ),
            ),
          if (isToday && value > 0)
            IconButton(
              tooltip: 'Qaytarish',
              onPressed: () => e.act(context, () async {
                MLPHaptics.selection();
                await e.store.undoHabit(habit.id);
              }),
              icon: const Icon(
                CupertinoIcons.arrow_counterclockwise,
                color: MLPColors.secondaryText,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.onOpen,
    this.time,
    this.onPlay,
    this.completed = false,
  });
  final String title;
  final String? time;
  final VoidCallback onOpen;
  final VoidCallback? onPlay;
  final bool completed;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: onOpen,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_checked_rounded,
            color: completed ? MLPColors.success : MLPColors.turquoise,
            size: 13,
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 48,
            child: Text(
              time ?? 'Vaqt\nberilmagan',
              style: const TextStyle(
                color: MLPColors.secondaryText,
                fontSize: 9,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          IconButton(
            tooltip: onPlay == null
                ? 'Jadvalni ochish: $title'
                : 'Fokus yoki hisobot: $title',
            onPressed: onPlay ?? onOpen,
            icon: Icon(
              onPlay == null
                  ? Icons.chevron_right_rounded
                  : completed
                  ? Icons.check_circle_outline_rounded
                  : Icons.play_circle_fill_rounded,
              color: MLPColors.turquoise,
              size: 23,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionLine extends StatelessWidget {
  const _SectionLine({
    required this.title,
    required this.action,
    required this.onAction,
  });
  final String title, action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      TextButton(
        onPressed: onAction,
        child: Text(action, style: const TextStyle(fontSize: 11)),
      ),
    ],
  );
}

class _GoalSummary extends StatelessWidget {
  const _GoalSummary({required this.goal, required this.e});
  final DemoGoal goal;
  final MLPEnvironment e;
  @override
  Widget build(BuildContext context) => MLPGlassCard(
    padding: 12,
    onTap: () =>
        e.go(MLPScreen.goalDetail, args: MLPRouteArgs(goalId: goal.id)),
    child: Row(
      children: [
        Icon(Icons.flag_rounded, color: _projectColor(goal.category), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${goal.current}/${goal.target} ${goal.metric} · o‘z hisoboti',
                style: const TextStyle(
                  fontSize: 10,
                  color: MLPColors.secondaryText,
                ),
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: goal.progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  color: MLPColors.primaryLight,
                  backgroundColor: Colors.white.withValues(alpha: .08),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: MLPColors.secondaryText,
        ),
      ],
    ),
  );
}
