import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../models/habit_enums.dart';
import '../providers/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/mini_line_chart.dart';
import '../widgets/progress_ring.dart';
import '../widgets/stat_card.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final stats = app.stats;
    final weeklyValues = app.weeklyProgressMap.values.toList();
    final priority = app.dailyPriorityHabit;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(
              title: 'Smart Coach',
              subtitle: 'Statistics that understand your behavior',
            ),
            const SizedBox(height: 20),
            GlassCard(
              glowColor: AppColors.emerald,
              child: Column(
                children: [
                  Row(
                    children: [
                      ProgressRing(
                        progress: stats.weeklyProgress,
                        size: 132,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(stats.weeklyProgress * 100).round()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Week',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly auto-summary',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              app.weeklyAutoSummary(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Done',
                          value: '${stats.completedToday}',
                          color: AppColors.emerald,
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          title: 'Missed',
                          value: '${stats.missedThisWeek}',
                          color: AppColors.rose,
                          icon: Icons.favorite_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          title: 'Best',
                          value: '${stats.bestStreak}',
                          color: AppColors.gold,
                          icon: Icons.local_fire_department_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (priority != null)
              _CoachInsight(
                icon: Icons.flag_rounded,
                title: 'Bugungi #1 vazifa',
                text:
                    '${priority.name} — bugun faqat shunga kuchliroq urg‘u ber. Bildirishnoma charchashini kamaytirish uchun bitta asosiy habit tanlandi.',
                color: AppColors.primary,
              ),
            const SizedBox(height: 18),
            _CoachInsight(
              icon: Icons.how_to_reg_rounded,
              title: 'Identity-based hisob',
              text: app.identityProgressSummary(),
              color: AppColors.emerald,
            ),
            const SizedBox(height: 18),
            _CoachInsight(
              icon: Icons.mood_rounded,
              title: 'Mood correlation',
              text: app.moodCorrelationInsight(),
              color: AppColors.cyan,
            ),
            const SizedBox(height: 18),
            GlassCard(
              glowColor: AppColors.cyan,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Progress',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  MiniLineChart(values: weeklyValues),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GlassCard(
              glowColor: AppColors.gold,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identity Votes by Role',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Har completion — sen kim bo‘layotganingga bitta ovoz.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 14),
                  ...HabitCategory.values.map((category) {
                    final votes = app.identityVoteCountForCategory(category);
                    final maxVotes = app.habits.isEmpty
                        ? 1
                        : app.habits
                            .map((habit) => habit.completionCount)
                            .fold(1, (a, b) => a + b);
                    final color = AppColors.categoryColor(category.label);
                    return _RoleProgress(
                      title: app.identityTitleForCategory(category),
                      subtitle: category.label,
                      votes: votes,
                      progress: maxVotes == 0 ? 0 : votes / maxVotes,
                      color: color,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GlassCard(
              glowColor: AppColors.rose,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skip Reason Patterns',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  if (app.activeHabits.isEmpty)
                    Text(
                      'Habit qo‘shilgandan keyin skip patternlar ko‘rinadi.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ...app.activeHabits.take(5).map(
                          (habit) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PatternTile(
                              title: habit.name,
                              text: app.skipPatternInsight(habit),
                            ),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GlassCard(
              glowColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Investment Visualization',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  ...app.activeHabits.take(5).map(
                        (habit) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PatternTile(
                            title: habit.name,
                            text: app.investmentInsight(habit),
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

class _CoachInsight extends StatelessWidget {
  const _CoachInsight({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: color,
      borderColor: color.withOpacity(0.26),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.42,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleProgress extends StatelessWidget {
  const _RoleProgress({
    required this.title,
    required this.subtitle,
    required this.votes,
    required this.progress,
    required this.color,
  });

  final String title;
  final String subtitle;
  final int votes;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                '$votes votes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              color: color,
              backgroundColor: AppColors.surface3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _PatternTile extends StatelessWidget {
  const _PatternTile({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.58),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft.withOpacity(0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}
