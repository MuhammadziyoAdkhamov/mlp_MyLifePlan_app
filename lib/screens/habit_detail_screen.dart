import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mylife_plan/models/habit_enums.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/date_helper.dart';
import '../models/habit.dart';
import '../providers/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/calendar_heatmap.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/stat_card.dart';

class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  void _goBack(BuildContext context) {
    HapticFeedback.selectionClick();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _confirmDeleteHabit(
    BuildContext context,
    String habitId,
    String habitName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Habitni o‘chiraymi?'),
          content: Text(
              '"$habitName" butunlay o‘chadi. Bu amalni ortga qaytarib bo‘lmaydi.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Bekor qilish')),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('O‘chirish',
                  style: TextStyle(color: AppColors.rose)),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      HapticFeedback.mediumImpact();
      await context.read<AppState>().deleteHabit(habitId);
      if (context.mounted) context.go('/home');
    }
  }

  Future<void> _confirmUndoToday(
    BuildContext context,
    String habitId,
    String habitName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Bajarilganni bekor qilaymi?'),
          content: Text(
              '"$habitName" bugun bajarilgan deb belgilangan. Uni bajarilmagan holatga qaytaraymi?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Yo‘q')),
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Ha, qaytar')),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      HapticFeedback.lightImpact();
      await context.read<AppState>().clearHabitToday(habitId);
    }
  }

  Future<void> _completeWithMode(
    BuildContext context,
    Habit habit,
    String mode,
  ) async {
    final mood = await _askMoodAndEnergy(context, mode);
    if (mood == null || !context.mounted) return;

    final duration =
        mode == 'minimal' ? 2 : _durationFromGoal(habit.goal ?? habit.name);

    await context.read<AppState>().markHabitCompletedToday(
          habit.id,
          mode: mode,
          mood: mood.$1,
          energy: mood.$2,
          durationMinutes: duration,
        );

    if (!context.mounted) return;
    final stacked = context.read<AppState>().stackedHabitAfter(habit.id);
    if (stacked != null && !stacked.isCompletedOn(DateTime.now())) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Habit zanjiri tayyor'),
            content: Text(
                '${habit.name} tugadi. Endi "${stacked.name}"ga tayyormisan?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Keyinroq')),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.go('/habit/${stacked.id}');
                },
                child: const Text('Ochish'),
              ),
            ],
          );
        },
      );
    }
  }

  int _durationFromGoal(String text) {
    final lower = text.toLowerCase();
    final match = RegExp(r'(\d+)').firstMatch(lower);
    final value = match == null ? null : int.tryParse(match.group(1)!);
    if (value == null) return 10;
    if (lower.contains('hour') || lower.contains('soat')) return value * 60;
    if (lower.contains('page') || lower.contains('sahifa'))
      return (value / 2).round().clamp(5, 120).toInt();
    if (lower.contains('glass') || lower.contains('cup')) return 2;
    return value.clamp(2, 180).toInt();
  }

  Future<(int, int)?> _askMoodAndEnergy(
      BuildContext context, String mode) async {
    var mood = 3;
    var energy = 3;
    return showDialog<(int, int)>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: Text(mode == 'minimal'
                  ? 'Minimal win'
                  : mode == 'recovery'
                      ? 'Recovery Mode'
                      : 'Bugungi holating'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Kayfiyat: $mood/5'),
                  Slider(
                    value: mood.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$mood',
                    onChanged: (value) =>
                        setDialogState(() => mood = value.round()),
                  ),
                  const SizedBox(height: 8),
                  Text('Energiya: $energy/5'),
                  Slider(
                    value: energy.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$energy',
                    onChanged: (value) =>
                        setDialogState(() => energy = value.round()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Bekor')),
                TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, (mood, energy)),
                    child: const Text('Saqlash')),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _skipWithReason(BuildContext context, Habit habit) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final reasons = ['Charchadim', 'Band edim', 'Unutdim', 'Xohlamadim'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nega bugun o‘tkazib yubording?',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                    'Bu shame emas. Bu keyingi safar senga yordam beradigan data.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 18),
                for (final item in reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, item),
                        child: Text(item),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (reason != null && context.mounted) {
      HapticFeedback.selectionClick();
      await context.read<AppState>().markHabitSkippedToday(habit.id, reason);
    }
  }

  Map<String, double> _habitMonthHeatmap(Habit habit) {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month);
    final totalDays = DateTime(now.year, now.month + 1, 0).day;

    return {
      for (var i = 0; i < totalDays; i++)
        DateHelper.key(first.add(Duration(days: i))):
            habit.isCompletedOn(first.add(Duration(days: i)))
                ? 1
                : habit.isSkippedOn(first.add(Duration(days: i)))
                    ? .25
                    : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final habit = app.habitById(habitId);

    if (habit == null) {
      return PremiumScaffold(
        body: Center(
          child: EmptyState(
            title: 'Habit not found',
            message: 'This habit does not exist anymore.',
            buttonText: 'Back Home',
            onButtonPressed: () => context.go('/home'),
          ),
        ),
      );
    }

    final color = AppColors.categoryColor(habit.category.label);
    final weekDays = DateHelper.lastDays(7);
    final todayEntry = habit.entryForDay(DateTime.now());
    final completedToday = habit.isCompletedOn(DateTime.now());
    final skippedToday = habit.isSkippedOn(DateTime.now());
    final futureLetter = app.futureLetterDue(habit);

    return PremiumScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              AppHeader(
                title: habit.name,
                subtitle:
                    '${habit.category.label} • ${app.identityTitleForCategory(habit.category)}',
                leading: IconButton(
                    onPressed: () => _goBack(context),
                    icon: const Icon(Icons.arrow_back_rounded)),
                actionIcon: Icons.delete_outline_rounded,
                onAction: () =>
                    _confirmDeleteHabit(context, habit.id, habit.name),
              ),
              const SizedBox(height: 18),
              _TodayStatusCard(
                habit: habit,
                color: color,
                completedToday: completedToday,
                skippedToday: skippedToday,
                todayEntryType: todayEntry?.type,
                compassionateText: app.compassionateStreakMessage(habit),
                onUndo: () => _confirmUndoToday(context, habit.id, habit.name),
              ),
              const SizedBox(height: 14),
              _ActionGrid(
                habit: habit,
                completedToday: completedToday,
                skippedToday: skippedToday,
                canRecover: app.canRecoverHabit(habit),
                onFull: () => _completeWithMode(context, habit, 'full'),
                onMinimal: () => _completeWithMode(context, habit, 'minimal'),
                onRecovery: () => _completeWithMode(context, habit, 'recovery'),
                onSkip: () => _skipWithReason(context, habit),
              ),
              if (futureLetter != null) ...[
                const SizedBox(height: 18),
                _InsightCard(
                    icon: Icons.mail_rounded,
                    title: 'Future Self Letter',
                    text: futureLetter,
                    color: AppColors.gold),
              ],
              const SizedBox(height: 18),
              _InsightCard(
                  icon: Icons.psychology_rounded,
                  title: 'Nega boshlagan eding?',
                  text: habit.whyNote ??
                      'Sabab yozilmagan. Keyingi habit yaratishda “why” yozish motivatsiyani qaytaradi.',
                  color: color),
              const SizedBox(height: 18),
              _InsightCard(
                  icon: Icons.analytics_rounded,
                  title: 'Skip pattern',
                  text: app.skipPatternInsight(habit),
                  color: AppColors.rose),
              const SizedBox(height: 18),
              _InsightCard(
                  icon: Icons.tune_rounded,
                  title: 'Tiny Habits suggestion',
                  text: app.difficultySuggestion(habit),
                  color: AppColors.cyan),
              const SizedBox(height: 18),
              _InsightCard(
                  icon: Icons.schedule_rounded,
                  title: 'Adaptive reminder',
                  text: app.adaptiveReminderSuggestion(habit),
                  color: AppColors.primary),
              const SizedBox(height: 18),
              _InsightCard(
                  icon: Icons.savings_rounded,
                  title: 'Investment visualization',
                  text: app.investmentInsight(habit),
                  color: AppColors.emerald),
              const SizedBox(height: 18),
              _InsightCard(
                  icon: Icons.handshake_rounded,
                  title: 'Accountability',
                  text: app.partnerContractMessage(habit),
                  color: AppColors.gold),
              const SizedBox(height: 18),
              GlassCard(
                glowColor: completedToday ? AppColors.emerald : color,
                borderColor:
                    completedToday ? AppColors.emerald.withOpacity(0.52) : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Last 7 Days',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 14),
                    Row(
                      children: weekDays.map((day) {
                        return Expanded(
                          child: _WeekDayDot(
                            label: [
                              'M',
                              'T',
                              'W',
                              'T',
                              'F',
                              'S',
                              'S'
                            ][day.weekday - 1],
                            done: habit.isCompletedOn(day),
                            skipped: habit.isSkippedOn(day),
                            color: color,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                            child: StatCard(
                                title: 'Streak',
                                value: '${habit.currentStreak}',
                                subtitle: 'Best ${habit.bestStreak}',
                                color: AppColors.gold,
                                icon: Icons.local_fire_department_rounded)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: StatCard(
                                title: 'Identity votes',
                                value:
                                    '${app.identityVoteCountForCategory(habit.category)}',
                                subtitle: app
                                    .identityTitleForCategory(habit.category),
                                color: AppColors.emerald,
                                icon: Icons.how_to_reg_rounded)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GlassCard(
                glowColor: AppColors.cyan,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Heatmap',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('Green = completed, dim = skipped/recovery data.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 14),
                    CalendarHeatmap(values: _habitMonthHeatmap(habit)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GlassCard(
                glowColor: color,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Habit Info',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 14),
                    _InfoRow(
                        label: 'Full goal', value: habit.goal ?? 'No goal'),
                    _InfoRow(
                        label: 'Minimal version',
                        value: habit.minimalGoal ?? 'Not set'),
                    _InfoRow(label: 'Frequency', value: habit.frequency.label),
                    _InfoRow(
                        label: 'Reminder', value: habit.reminder ?? 'Not set'),
                    _InfoRow(
                        label: 'Total completions',
                        value: '${habit.completionCount}'),
                    _InfoRow(
                        label: 'Minimal wins', value: '${habit.minimalCount}'),
                    _InfoRow(label: 'Skipped', value: '${habit.skipCount}'),
                    _InfoRow(
                        label: 'Created',
                        value: DateHelper.key(habit.createdAt)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _DangerDeleteCard(
                  habitName: habit.name,
                  onDelete: () =>
                      _confirmDeleteHabit(context, habit.id, habit.name)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayStatusCard extends StatelessWidget {
  const _TodayStatusCard({
    required this.habit,
    required this.color,
    required this.completedToday,
    required this.skippedToday,
    required this.todayEntryType,
    required this.compassionateText,
    required this.onUndo,
  });

  final Habit habit;
  final Color color;
  final bool completedToday;
  final bool skippedToday;
  final String? todayEntryType;
  final String compassionateText;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final statusColor = completedToday
        ? AppColors.emerald
        : skippedToday
            ? AppColors.rose
            : color;
    final title = completedToday
        ? todayEntryType == 'minimal'
            ? 'Minimal version completed'
            : todayEntryType == 'recovery'
                ? 'Recovered today'
                : 'Completed today'
        : skippedToday
            ? 'Skipped without shame'
            : 'Not completed today';

    return GlassCard(
      onTap: completedToday || skippedToday ? onUndo : null,
      glowColor: statusColor,
      borderColor: statusColor.withOpacity(0.48),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: completedToday
                  ? const LinearGradient(
                      colors: [AppColors.emerald, AppColors.cyan])
                  : AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                    color: statusColor.withOpacity(0.30),
                    blurRadius: 32,
                    offset: const Offset(0, 12))
              ],
            ),
            child: Icon(
                completedToday
                    ? Icons.check_rounded
                    : skippedToday
                        ? Icons.favorite_rounded
                        : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900, color: statusColor)),
                const SizedBox(height: 4),
                Text(compassionateText,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (completedToday || skippedToday)
            const Icon(Icons.undo_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.habit,
    required this.completedToday,
    required this.skippedToday,
    required this.canRecover,
    required this.onFull,
    required this.onMinimal,
    required this.onRecovery,
    required this.onSkip,
  });

  final Habit habit;
  final bool completedToday;
  final bool skippedToday;
  final bool canRecover;
  final VoidCallback onFull;
  final VoidCallback onMinimal;
  final VoidCallback onRecovery;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final locked = completedToday || skippedToday;
    return GlassCard(
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today actions',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
              'All-or-nothing emas. Og‘ir kunda minimal versiya streakni saqlaydi.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: GradientButton(
                      text: 'Full',
                      icon: Icons.check_rounded,
                      enabled: !locked,
                      onPressed: locked ? null : onFull)),
              const SizedBox(width: 10),
              Expanded(
                  child: GradientButton(
                      text: 'Minimal',
                      icon: Icons.bolt_rounded,
                      enabled: !locked,
                      onPressed: locked ? null : onMinimal)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: locked ? null : onSkip,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Skip reason'))),
              const SizedBox(width: 10),
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: (!locked && canRecover) ? onRecovery : null,
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('Recovery'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard(
      {required this.icon,
      required this.title,
      required this.text,
      required this.color});

  final IconData icon;
  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: color,
      borderColor: color.withOpacity(0.24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color.withOpacity(0.14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDayDot extends StatelessWidget {
  const _WeekDayDot(
      {required this.label,
      required this.done,
      required this.skipped,
      required this.color});

  final String label;
  final bool done;
  final bool skipped;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final displayColor = done
        ? AppColors.emerald
        : skipped
            ? AppColors.rose
            : color;
    return Column(
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: done ? 32 : 28,
          height: done ? 32 : 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? AppColors.emerald
                : skipped
                    ? AppColors.rose.withOpacity(0.22)
                    : AppColors.surface3,
            border: Border.all(color: displayColor.withOpacity(0.75)),
          ),
          child: done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : skipped
                  ? const Icon(Icons.favorite_rounded,
                      color: AppColors.rose, size: 16)
                  : Icon(Icons.circle_outlined,
                      color: color.withOpacity(0.55), size: 14),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
          color: AppColors.surface2.withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSoft.withOpacity(0.78))),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _DangerDeleteCard extends StatelessWidget {
  const _DangerDeleteCard({required this.habitName, required this.onDelete});

  final String habitName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: AppColors.rose,
      borderColor: AppColors.rose.withOpacity(0.32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Danger Zone',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.rose, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Delete "$habitName" if you no longer need this habit.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary, height: 1.35)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.rose),
              label: const Text('Delete Habit',
                  style: TextStyle(
                      color: AppColors.rose, fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.rose.withOpacity(0.55)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18))),
            ),
          ),
        ],
      ),
    );
  }
}
