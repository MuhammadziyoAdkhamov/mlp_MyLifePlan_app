import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/design/mlp_colors.dart';
import '../../core/design/mlp_text_styles.dart';
import '../../core/domain/goal_model.dart';
import '../../core/domain/roadmap_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/mlp_button.dart';
import '../../core/widgets/mlp_card.dart';
import '../../core/widgets/xp_chip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final goals = ref.watch(goalsProvider);
    final roadmaps = ref.watch(roadmapsProvider);
    final now = DateTime.now();
    final greeting = _greeting(now.hour, user?.name ?? 'Foydalanuvchi');

    MlpTask? topTask;
    MlpMilestone? topMilestone;
    MlpRoadmap? activeRoadmap;
    for (final roadmap in roadmaps.where((r) => r.isApproved)) {
      final milestone = roadmap.currentMilestone;
      if (milestone != null) {
        final task = milestone.tasks.where((t) => !t.isCompleted).firstOrNull;
        if (task != null) {
          topTask = task;
          topMilestone = milestone;
          activeRoadmap = roadmap;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: MlpColors.bg1,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: MlpColors.gradientBg),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(greeting, style: MlpTextStyles.h2),
                                Text(
                                  DateFormat('EEEE, d MMMM', 'uz').format(now),
                                  style: MlpTextStyles.body2,
                                ),
                              ],
                            ),
                          ),
                          if (user != null) ...[
                            GestureDetector(
                              onTap: () => context.go('/natijalar'),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [MlpColors.purple, MlpColors.blue]),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded, color: MlpColors.gold, size: 16),
                                        const SizedBox(width: 4),
                                        Text('${user.xp} XP', style: const TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13,
                                        )),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Daraja ${user.level}', style: MlpTextStyles.caption),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 7,
                          itemBuilder: (context, i) {
                            final day = now.subtract(Duration(days: 3 - i));
                            final isToday = i == 3;
                            return Container(
                              width: 48,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isToday ? MlpColors.purple : MlpColors.bg2,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isToday ? MlpColors.purple : MlpColors.border,
                                ),
                                boxShadow: isToday ? [
                                  BoxShadow(color: MlpColors.purple.withValues(alpha: 0.3), blurRadius: 12),
                                ] : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('E', 'uz').format(day)[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w600,
                                      color: isToday ? Colors.white : MlpColors.text3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w800,
                                      color: isToday ? Colors.white : MlpColors.text2,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (topTask != null && activeRoadmap != null && topMilestone != null) ...[
                  const SizedBox(height: 8),
                  const _SectionLabel(label: 'Bugungi eng muhim vazifa'),
                  const SizedBox(height: 10),
                  _PriorityTaskCard(
                    task: topTask,
                    milestone: topMilestone,
                    roadmap: activeRoadmap,
                    onComplete: () async {
                      await ref.read(roadmapsProvider.notifier).completeTask(
                        activeRoadmap!.id, topMilestone!.id, topTask!.id,
                      );
                      await ref.read(userProvider.notifier).earnXp(
                        topTask!.xpReward, label: topTask.title,
                      );
                    },
                    onLearn: () => context.go('/learning/${topMilestone!.id}', extra: topMilestone),
                  ),
                ] else if (goals.isEmpty) ...[
                  const SizedBox(height: 24),
                  _EmptyGoalCard(onTap: () => context.go('/goal-setup')),
                ] else ...[
                  const SizedBox(height: 24),
                  MlpCard(
                    glowColor: MlpColors.success,
                    child: Column(
                      children: [
                        const Icon(Icons.celebration_rounded, color: MlpColors.gold, size: 40),
                        const SizedBox(height: 12),
                        Text('Barcha vazifalar bajarildi!', style: MlpTextStyles.h4, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text('Ajoyib ish! Yo\'l xaritangizni ko\'ring.', style: MlpTextStyles.body2, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        MlpButton(label: 'Yo\'l xaritasi', isSmall: true, onPressed: () => context.go('/roadmap')),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (goals.isNotEmpty) ...[
                  const _SectionLabel(label: 'Faol maqsadlar'),
                  const SizedBox(height: 12),
                  ...goals.where((g) => g.isActive).map((goal) {
                    final roadmap = roadmaps.where((r) => r.goalId == goal.id).firstOrNull;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GoalCard(goal: goal, roadmap: roadmap),
                    );
                  }),
                ],
                const SizedBox(height: 16),
                _AiUstozEntry(onTap: () => context.go('/ustoz')),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(int hour, String name) {
    if (hour < 6) return 'Tungi mashq, $name';
    if (hour < 12) return 'Xayrli tong, $name';
    if (hour < 17) return 'Xayrli kun, $name';
    if (hour < 21) return 'Xayrli kech, $name';
    return 'Yaxshi tun, $name';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: MlpTextStyles.label.copyWith(color: MlpColors.text2, letterSpacing: 0.8));
  }
}

class _PriorityTaskCard extends StatefulWidget {
  const _PriorityTaskCard({
    required this.task, required this.milestone, required this.roadmap,
    required this.onComplete, required this.onLearn,
  });
  final MlpTask task;
  final MlpMilestone milestone;
  final MlpRoadmap roadmap;
  final VoidCallback onComplete;
  final VoidCallback onLearn;

  @override
  State<_PriorityTaskCard> createState() => _PriorityTaskCardState();
}

class _PriorityTaskCardState extends State<_PriorityTaskCard> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return MlpCard(
      glowColor: MlpColors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: MlpColors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(widget.milestone.title,
                    style: MlpTextStyles.caption.copyWith(color: MlpColors.purpleLight, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              XpChip(xp: widget.task.xpReward, isSmall: true),
            ],
          ),
          const SizedBox(height: 14),
          Text(widget.task.title, style: MlpTextStyles.h3),
          if (widget.task.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(widget.task.description, style: MlpTextStyles.body2),
          ],
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.milestone.progress,
              backgroundColor: MlpColors.bg4,
              valueColor: const AlwaysStoppedAnimation(MlpColors.purple),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.milestone.completedTasks}/${widget.milestone.tasks.length} vazifa bajarildi',
            style: MlpTextStyles.caption,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: MlpButton(
                  label: 'O\'rganish',
                  isSmall: true,
                  colors: const [MlpColors.bg3, MlpColors.bg4],
                  onPressed: widget.onLearn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MlpButton(
                  label: _done ? 'Bajarildi!' : 'Bajarildi',
                  icon: _done ? Icons.check_circle_rounded : Icons.check_rounded,
                  isSmall: true,
                  colors: _done ? const [MlpColors.success, MlpColors.success] : const [MlpColors.purple, MlpColors.blue],
                  onPressed: _done ? null : () {
                    setState(() => _done = true);
                    widget.onComplete();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, this.roadmap});
  final MlpGoal goal;
  final MlpRoadmap? roadmap;

  @override
  Widget build(BuildContext context) {
    final progress = roadmap?.overallProgress ?? 0.0;
    return MlpCard(
      child: Row(
        children: [
          Text(goal.category.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title, style: MlpTextStyles.h4),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: MlpColors.bg4,
                    valueColor: const AlwaysStoppedAnimation(MlpColors.purple),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${(progress * 100).toInt()}% yakunlandi', style: MlpTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGoalCard extends StatelessWidget {
  const _EmptyGoalCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MlpCard(
      glowColor: MlpColors.purple,
      child: Column(
        children: [
          const Icon(Icons.add_circle_outline_rounded, color: MlpColors.purpleLight, size: 48),
          const SizedBox(height: 16),
          Text('Birinchi maqsadingizni qo\'ying!', style: MlpTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'AI sizga shaxsiy yo\'l xaritasi tuzib beradi',
            style: MlpTextStyles.body2, textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          MlpButton(
            label: 'Maqsad qo\'yish',
            icon: Icons.add_rounded,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _AiUstozEntry extends StatelessWidget {
  const _AiUstozEntry({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1040), Color(0xFF0F1E40)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: MlpColors.purple.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [MlpColors.purple, MlpColors.blue]),
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Ustoz', style: MlpTextStyles.h4),
                  Text('Savol ber, reja tuz, yordam ol', style: MlpTextStyles.body2),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: MlpColors.text3, size: 16),
          ],
        ),
      ),
    );
  }
}
