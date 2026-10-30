import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mylife_plan/widgets/empty_state.dart';
import 'package:mylife_plan/widgets/glass_card.dart';
import 'package:mylife_plan/widgets/progress_ring.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../models/growth_focus.dart';
import '../models/learning_roadmap.dart';
import '../providers/app_state.dart';
import '../widgets/habit_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _backgroundController;

  bool _hideCompleted = false;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..forward();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _introController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _confirmUndoHabit(
    BuildContext context,
    String habitId,
    String habitName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Bajarilganni bekor qilaymi?'),
          content: Text(
            '"$habitName" bugun bajarilgan deb belgilangan. Uni bajarilmagan holatga qaytaraymi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Yo‘q'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ha, qaytar'),
            ),
          ],
        );
      },
    );

    if (result != true) return;
    if (!context.mounted) return;
    await context.read<AppState>().toggleHabitToday(habitId);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Habitni o‘chiraymi?'),
          content: Text(
            '"$habitName" butunlay o‘chadi. Bu amalni ortga qaytarib bo‘lmaydi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Bekor qilish'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'O‘chirish',
                style: TextStyle(color: AppColors.rose),
              ),
            ),
          ],
        );
      },
    );

    if (result != true) return;
    if (!context.mounted) return;
    await context.read<AppState>().deleteHabit(habitId);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (app.isLoading) {
      return const SafeArea(child: _HomeSkeleton());
    }

    final stats = app.stats;
    final allTodayHabits = app.activeHabits;
    final todayHabits = _hideCompleted
        ? allTodayHabits
              .where((habit) => !habit.isCompletedOn(DateTime.now()))
              .toList()
        : allTodayHabits;

    final weeklyValues = app.weeklyProgressMap.values
        .map((value) => value.toDouble().clamp(0.0, 1.0).toDouble())
        .toList();

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(430.0, constraints.maxWidth);

          return Stack(
            children: [
              _AnimatedBackground(
                controller: _backgroundController,
                height: constraints.maxHeight,
              ),
              Center(
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: _StaggeredFadeSlide(
                            controller: _introController,
                            intervalStart: 0.00,
                            intervalEnd: 0.38,
                            offsetY: -16,
                            child: _PremiumHeader(
                              name: app.profile.name,
                              focusLabel: growthFocusFromId(
                                app.profile.growthFocus,
                              ).label,
                              avatarUrl: app.profile.avatarUrl,
                              syncLabel: app.syncStatusLabel,
                              isCloudUser: app.isCloudUser,
                              onSettings: () {
                                HapticFeedback.selectionClick();
                                context.go('/settings');
                              },
                            ),
                          ),
                        ),
                      ),
                      if (app.learningRoadmaps.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          sliver: SliverToBoxAdapter(
                            child: _StaggeredFadeSlide(
                              controller: _introController,
                              intervalStart: 0.05,
                              intervalEnd: 0.45,
                              offsetY: 20,
                              child: _NextActionCard(
                                roadmap: app.learningRoadmaps.last,
                                onStart: () {
                                  HapticFeedback.lightImpact();
                                  context.go('/learning');
                                },
                              ),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                        sliver: SliverToBoxAdapter(
                          child: _StaggeredFadeSlide(
                            controller: _introController,
                            intervalStart: 0.10,
                            intervalEnd: 0.52,
                            offsetY: 20,
                            child: _SectionHeader(
                              title: 'Today\'s Habits',
                              subtitle: allTodayHabits.isEmpty
                                  ? 'Suv ichish, o‘qish yoki mashqdan boshlang'
                                  : _hideCompleted
                                  ? '${todayHabits.length} unfinished habits left'
                                  : '${stats.completedToday}/${stats.totalHabits} completed today',
                              actionText: 'Add',
                              onAction: () {
                                HapticFeedback.lightImpact();
                                context.go('/add-habit');
                              },
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        sliver: SliverToBoxAdapter(
                          child: _StaggeredFadeSlide(
                            controller: _introController,
                            intervalStart: 0.14,
                            intervalEnd: 0.58,
                            offsetY: 14,
                            child: _CompletedFilterPill(
                              hideCompleted: _hideCompleted,
                              completedCount: stats.completedToday,
                              onChanged: () {
                                HapticFeedback.selectionClick();
                                setState(
                                  () => _hideCompleted = !_hideCompleted,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      if (todayHabits.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverToBoxAdapter(
                            child: _StaggeredFadeSlide(
                              controller: _introController,
                              intervalStart: 0.18,
                              intervalEnd: 0.70,
                              offsetY: 26,
                              child: _LivelyEmptyState(
                                hideCompleted: _hideCompleted,
                                onAddHabit: () {
                                  HapticFeedback.selectionClick();
                                  context.go('/add-habit');
                                },
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList.separated(
                            itemCount: todayHabits.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final habit = todayHabits[index];
                              final completed = habit.isCompletedOn(
                                DateTime.now(),
                              );

                              return _AnimatedHabitItem(
                                controller: _introController,
                                index: index,
                                child: HabitTile(
                                  habit: habit,
                                  completed: completed,
                                  onToggle: () {
                                    HapticFeedback.lightImpact();

                                    if (completed) {
                                      _confirmUndoHabit(
                                        context,
                                        habit.id,
                                        habit.name,
                                      );
                                      return;
                                    }

                                    context.read<AppState>().toggleHabitToday(
                                      habit.id,
                                    );
                                  },
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    context.go('/habit/${habit.id}');
                                  },
                                  onDelete: () {
                                    HapticFeedback.mediumImpact();
                                    _confirmDeleteHabit(
                                      context,
                                      habit.id,
                                      habit.name,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: _StaggeredFadeSlide(
                            controller: _introController,
                            intervalStart: 0.30,
                            intervalEnd: 0.82,
                            offsetY: 28,
                            child: _TodayStatsCard(
                              dailyProgress: stats.dailyProgress,
                              completedToday: stats.completedToday,
                              totalHabits: stats.totalHabits,
                              currentStreak: stats.currentStreak,
                              bestStreak: stats.bestStreak,
                              totalXp: stats.totalXp,
                              weeklyValues: weeklyValues,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: _StaggeredFadeSlide(
                            controller: _introController,
                            intervalStart: 0.42,
                            intervalEnd: 0.90,
                            offsetY: 24,
                            child: _LevelCard(
                              level: app.level,
                              xpInCurrentLevel: app.xpInCurrentLevel,
                              totalXp: app.totalXp,
                              levelProgress: app.levelProgress,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                context.go('/xp');
                              },
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: _StaggeredFadeSlide(
                            controller: _introController,
                            intervalStart: 0.52,
                            intervalEnd: 0.96,
                            offsetY: 22,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _QuickActionCard(
                                    icon: Icons.add_rounded,
                                    title: 'Add Habit',
                                    subtitle: 'New routine',
                                    color: AppColors.primary,
                                    onTap: () => context.go('/add-habit'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _QuickActionCard(
                                    icon: Icons.auto_awesome_rounded,
                                    title: 'Journey',
                                    subtitle: 'Daily tasks',
                                    color: AppColors.gold,
                                    onTap: () => context.go('/journey'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _QuickActionCard(
                                    icon: Icons.insights_rounded,
                                    title: 'Stats',
                                    subtitle: 'Progress',
                                    color: AppColors.cyan,
                                    onTap: () => context.go('/stats'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
                        sliver: SliverToBoxAdapter(
                          child: _StaggeredFadeSlide(
                            controller: _introController,
                            intervalStart: 0.62,
                            intervalEnd: 1.00,
                            offsetY: 18,
                            child: _MotivationCard(
                              completedToday: stats.completedToday,
                              totalHabits: stats.totalHabits,
                              progress: stats.dailyProgress,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({
    required this.name,
    required this.focusLabel,
    required this.avatarUrl,
    required this.syncLabel,
    required this.isCloudUser,
    required this.onSettings,
  });

  final String name;
  final String focusLabel;
  final String? avatarUrl;
  final String syncLabel;
  final bool isCloudUser;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'Do‘stim' : name.trim();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Xayrli tong,'
        : hour < 18
        ? 'Xayrli kun,'
        : 'Xayrli kech,';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BreathingDot(
                    color: isCloudUser ? AppColors.emerald : AppColors.cyan,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    syncLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    size: 13,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Bu hafta: $focusLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _AvatarButton(avatarUrl: avatarUrl, onTap: onSettings),
      ],
    );
  }
}

class _AvatarButton extends StatefulWidget {
  const _AvatarButton({required this.avatarUrl, required this.onTap});

  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  State<_AvatarButton> createState() => _AvatarButtonState();
}

class _AvatarButtonState extends State<_AvatarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        widget.avatarUrl != null && widget.avatarUrl!.trim().isNotEmpty;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.94 : 1,
        child: Container(
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: AppColors.surface2,
            backgroundImage: hasImage ? NetworkImage(widget.avatarUrl!) : null,
            child: hasImage
                ? null
                : const Icon(
                    Icons.person_rounded,
                    color: AppColors.textPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}

class _TodayStatsCard extends StatelessWidget {
  const _TodayStatsCard({
    required this.dailyProgress,
    required this.completedToday,
    required this.totalHabits,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalXp,
    required this.weeklyValues,
  });

  final double dailyProgress;
  final int completedToday;
  final int totalHabits;
  final int currentStreak;
  final int bestStreak;
  final int totalXp;
  final List<double> weeklyValues;

  @override
  Widget build(BuildContext context) {
    final percent = (dailyProgress.clamp(0.0, 1.0) * 100).round();

    return Semantics(
      label:
          'Today statistics. $percent percent progress. $completedToday of $totalHabits habits completed.',
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        glowColor: AppColors.cyan,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'Today\'s Statistics',
              subtitle: 'Your daily energy and consistency',
              actionText: null,
              onAction: null,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                ProgressRing(
                  progress: dailyProgress,
                  size: 132,
                  strokeWidth: 12,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent%',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                      ),
                      Text(
                        'Energy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: [
                      _TinyStatRow(
                        icon: Icons.check_circle_rounded,
                        title: 'Done',
                        value: '$completedToday/$totalHabits',
                        color: AppColors.emerald,
                      ),
                      const SizedBox(height: 10),
                      _TinyStatRow(
                        icon: Icons.local_fire_department_rounded,
                        title: 'Streak',
                        value: '$currentStreak',
                        color: AppColors.orange,
                      ),
                      const SizedBox(height: 10),
                      _TinyStatRow(
                        icon: Icons.workspace_premium_rounded,
                        title: 'Best',
                        value: '$bestStreak',
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _WeekMiniChart(values: weeklyValues),
            const SizedBox(height: 14),
            _MiniInsight(
              icon: Icons.bolt_rounded,
              text: totalXp == 0
                  ? 'Start with one small habit today.'
                  : '$totalXp total XP earned from your discipline.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.xpInCurrentLevel,
    required this.totalXp,
    required this.levelProgress,
    required this.onTap,
  });

  final int level;
  final int xpInCurrentLevel;
  final int totalXp;
  final double levelProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final safeProgress = levelProgress.clamp(0.0, 1.0).toDouble();
    final xpLeft = math.max(0, 1000 - xpInCurrentLevel);

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $level',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$xpInCurrentLevel / 1000 XP • $totalXp total XP',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: safeProgress),
              duration: const Duration(milliseconds: 1150),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 9,
                  backgroundColor: AppColors.surface3.withValues(alpha: 0.72),
                  color: AppColors.primary,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _MiniInsight(
            icon: Icons.bolt_rounded,
            text: '$xpLeft XP left to reach the next level.',
          ),
        ],
      ),
    );
  }
}

class _TinyStatRow extends StatelessWidget {
  const _TinyStatRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekMiniChart extends StatelessWidget {
  const _WeekMiniChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final safeValues = values.isEmpty ? List<double>.filled(7, 0.0) : values;
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft.withValues(alpha: 0.78)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final sourceIndex = math.min(index, safeValues.length - 1);
          final value = safeValues[sourceIndex].clamp(0.0, 1.0).toDouble();
          final label = labels[index];

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: value),
                  duration: Duration(milliseconds: 650 + (index * 70)),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, _) {
                    return Container(
                      height: 58,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 9,
                        height: 10 + (animatedValue * 48),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.65),
                              AppColors.cyan,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withValues(alpha: 0.24),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _MiniInsight extends StatelessWidget {
  const _MiniInsight({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface2.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft.withValues(alpha: 0.72)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.cyan, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.32,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed
        ? 0.96
        : _hovered
        ? 1.02
        : 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _pressed = true);
        },
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          HapticFeedback.selectionClick();
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _hovered
                    ? widget.color.withValues(alpha: 0.38)
                    : AppColors.borderSoft.withValues(alpha: 0.85),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _hovered ? 0.22 : 0.10),
                  blurRadius: _hovered ? 30 : 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.15),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionText!)),
      ],
    );
  }
}

class _CompletedFilterPill extends StatelessWidget {
  const _CompletedFilterPill({
    required this.hideCompleted,
    required this.completedCount,
    required this.onChanged,
  });

  final bool hideCompleted;
  final int completedCount;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final disabled = completedCount == 0;

    return GestureDetector(
      onTap: disabled ? null : onChanged,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: disabled ? 0.55 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: hideCompleted
                ? AppColors.emerald.withValues(alpha: 0.14)
                : AppColors.surface2.withValues(alpha: 0.64),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hideCompleted
                  ? AppColors.emerald.withValues(alpha: 0.55)
                  : AppColors.borderSoft.withValues(alpha: 0.82),
            ),
          ),
          child: Row(
            children: [
              Icon(
                hideCompleted
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: hideCompleted ? AppColors.emerald : AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hideCompleted
                      ? 'Completed hidden — only unfinished habits'
                      : 'Show all habits — $completedCount completed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: hideCompleted
                        ? AppColors.emerald
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Switch.adaptive(
                value: hideCompleted,
                onChanged: disabled ? null : (_) => onChanged(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedHabitItem extends StatelessWidget {
  const _AnimatedHabitItem({
    required this.controller,
    required this.index,
    required this.child,
  });

  final AnimationController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (0.18 + (index * 0.06)).clamp(0.0, 0.78).toDouble();
    final end = (start + 0.28).clamp(0.0, 1.0).toDouble();

    return _StaggeredFadeSlide(
      controller: controller,
      intervalStart: start,
      intervalEnd: end,
      offsetY: 22,
      child: child,
    );
  }
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard({
    required this.completedToday,
    required this.totalHabits,
    required this.progress,
  });

  final int completedToday;
  final int totalHabits;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final done = totalHabits > 0 && completedToday >= totalHabits;
    final hasHabits = totalHabits > 0;

    final title = done
        ? 'Perfect day unlocked!'
        : hasHabits
        ? 'One small win at a time.'
        : 'Build your first system.';

    final message = done
        ? 'You completed all habits today. Keep this energy tomorrow.'
        : hasHabits
        ? 'Complete one more habit and your future self gets stronger.'
        : 'Add “Suv ichish” or any small habit and start today.';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      glowColor: done ? AppColors.gold : AppColors.primary,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: done
                  ? AppColors.goldGradient
                  : AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: (done ? AppColors.gold : AppColors.primary)
                      .withValues(alpha: 0.26),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              done
                  ? Icons.workspace_premium_rounded
                  : Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
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

class _LivelyEmptyState extends StatefulWidget {
  const _LivelyEmptyState({
    required this.hideCompleted,
    required this.onAddHabit,
  });

  final bool hideCompleted;
  final VoidCallback onAddHabit;

  @override
  State<_LivelyEmptyState> createState() => _LivelyEmptyStateState();
}

class _LivelyEmptyStateState extends State<_LivelyEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.hideCompleted
        ? 'All unfinished habits done'
        : 'No habits yet';
    final message = widget.hideCompleted
        ? 'Completed habits are hidden. Turn off the filter to see everything.'
        : 'Create your first habit. Example: Suv ichish.';

    return AnimatedBuilder(
      animation: _controller,
      child: EmptyState(
        title: title,
        message: message,
        buttonText: widget.hideCompleted ? 'Show All' : 'Add Habit',
        onButtonPressed: widget.onAddHabit,
      ),
      builder: (context, child) {
        final floatY = math.sin(_controller.value * math.pi) * 10;

        return Transform.translate(offset: Offset(0, -floatY), child: child);
      },
    );
  }
}

class _BreathingDot extends StatefulWidget {
  const _BreathingDot({required this.color});

  final Color color;

  @override
  State<_BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<_BreathingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final glow = 0.35 + (_controller.value * 0.45);

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: glow),
                blurRadius: 10 + (_controller.value * 10),
                spreadRadius: _controller.value * 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({required this.controller, required this.height});

  final AnimationController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;

        return Stack(
          children: [
            Positioned(
              top: -120 + (t * 28),
              right: -120 + (t * 18),
              child: const _AmbientOrb(
                size: 270,
                color: AppColors.primary,
                opacity: 0.23,
              ),
            ),
            Positioned(
              top: height * 0.36,
              left: -120 - (t * 12),
              child: const _AmbientOrb(
                size: 230,
                color: AppColors.cyan,
                opacity: 0.13,
              ),
            ),
            Positioned(
              bottom: -140 + (t * 25),
              right: -90,
              child: const _AmbientOrb(
                size: 240,
                color: AppColors.emerald,
                opacity: 0.10,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _StaggeredFadeSlide extends StatelessWidget {
  const _StaggeredFadeSlide({
    required this.controller,
    required this.intervalStart,
    required this.intervalEnd,
    required this.offsetY,
    required this.child,
  });

  final AnimationController controller;
  final double intervalStart;
  final double intervalEnd;
  final double offsetY;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final value = animation.value.clamp(0.0, 1.0).toDouble();

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

class _HomeSkeleton extends StatefulWidget {
  const _HomeSkeleton();

  @override
  State<_HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<_HomeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _card(double height) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        final alignment = -1.5 + (value * 3.0);

        return GlassCard(
          padding: EdgeInsets.zero,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment(alignment - 1, 0),
                end: Alignment(alignment + 1, 0),
                colors: [
                  AppColors.surface2.withValues(alpha: 0.70),
                  AppColors.surface3.withValues(alpha: 0.95),
                  AppColors.surface2.withValues(alpha: 0.70),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            children: [
              _card(74),
              const SizedBox(height: 18),
              _card(190),
              const SizedBox(height: 12),
              _card(72),
              const SizedBox(height: 12),
              _card(72),
              const SizedBox(height: 18),
              _card(235),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextActionCard extends StatelessWidget {
  const _NextActionCard({required this.roadmap, required this.onStart});

  final LearningRoadmap roadmap;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final nextStageIndex = roadmap.stages.indexWhere((s) => !s.isCompleted);
    if (nextStageIndex == -1) return const SizedBox.shrink();
    
    final stage = roadmap.stages[nextStageIndex];

    return GlassCard(
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Keyingi qadam',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Bosqich ${nextStageIndex + 1}/${roadmap.stages.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            stage.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            stage.objective,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Darsni boshlash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
