import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/mlp_colors.dart';
import '../../core/design/mlp_text_styles.dart';
import '../../core/domain/goal_model.dart';
import '../../core/domain/roadmap_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/mlp_button.dart';
import '../../core/widgets/mlp_card.dart';

class RoadmapTabScreen extends ConsumerWidget {
  const RoadmapTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roadmaps = ref.watch(roadmapsProvider);
    final goals = ref.watch(goalsProvider);
    final approved = roadmaps.where((r) => r.isApproved).toList();

    return Scaffold(
      backgroundColor: MlpColors.bg1,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Yo'l xaritasi", style: MlpTextStyles.h2),
                        Text('AI tomonidan tuzilgan rejangiz', style: MlpTextStyles.body2),
                      ],
                    ),
                  ),
                  MlpButton(
                    label: 'Yangi',
                    icon: Icons.add_rounded,
                    isSmall: true,
                    onPressed: () => context.go('/goal-setup'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (approved.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_outlined, color: MlpColors.text3, size: 64),
                        const SizedBox(height: 16),
                        Text("Hali yo'l xaritasi yo'q", style: MlpTextStyles.h3),
                        const SizedBox(height: 8),
                        Text('Maqsad qo\'ying va AI rejangizni tuzsin', style: MlpTextStyles.body2, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        MlpButton(
                          label: 'Maqsad qo\'yish',
                          icon: Icons.add_rounded,
                          onPressed: () => context.go('/goal-setup'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  itemCount: approved.length,
                  itemBuilder: (context, ri) {
                    final roadmap = approved[ri];
                    final goal = goals.where((g) => g.id == roadmap.goalId).firstOrNull;
                    return _RoadmapSection(
                      roadmap: roadmap, goal: goal,
                      onTaskComplete: (milestoneId, taskId) async {
                        final task = roadmap.milestones
                            .firstWhere((m) => m.id == milestoneId).tasks
                            .firstWhere((t) => t.id == taskId);
                        await ref.read(roadmapsProvider.notifier)
                            .completeTask(roadmap.id, milestoneId, taskId);
                        await ref.read(userProvider.notifier)
                            .earnXp(task.xpReward, label: task.title);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoadmapSection extends StatelessWidget {
  const _RoadmapSection({required this.roadmap, this.goal, required this.onTaskComplete});
  final MlpRoadmap roadmap;
  final MlpGoal? goal;
  final Future<void> Function(String milestoneId, String taskId) onTaskComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (goal != null) ...[
          Text('${goal!.category.icon} ${goal!.title}', style: MlpTextStyles.h4),
          const SizedBox(height: 4),
          Text('${(roadmap.overallProgress * 100).toInt()}% yakunlandi',
              style: MlpTextStyles.body2.copyWith(color: MlpColors.purpleLight)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: roadmap.overallProgress,
              backgroundColor: MlpColors.bg4,
              valueColor: const AlwaysStoppedAnimation(MlpColors.purple),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
        ],
        ...roadmap.milestones.asMap().entries.map((e) {
          return _MilestoneExpansion(
            milestone: e.value, index: e.key,
            roadmapId: roadmap.id,
            onTaskComplete: onTaskComplete,
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MilestoneExpansion extends StatefulWidget {
  const _MilestoneExpansion({
    required this.milestone, required this.index, required this.roadmapId,
    required this.onTaskComplete,
  });
  final MlpMilestone milestone;
  final int index;
  final String roadmapId;
  final Future<void> Function(String milestoneId, String taskId) onTaskComplete;

  @override
  State<_MilestoneExpansion> createState() => _MilestoneExpansionState();
}

class _MilestoneExpansionState extends State<_MilestoneExpansion> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = !widget.milestone.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.milestone;
    final isActive = !m.isCompleted && widget.index == 0;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: MlpCard(
        margin: const EdgeInsets.only(bottom: 12),
        glowColor: m.isCompleted ? MlpColors.success : (isActive ? MlpColors.purple : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: m.isCompleted ? MlpColors.success : (isActive ? MlpColors.purple : MlpColors.bg4),
                  ),
                  child: Center(
                    child: m.isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                        : Text('${widget.index + 1}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.title, style: MlpTextStyles.h4.copyWith(
                        color: m.isCompleted ? MlpColors.success : MlpColors.text1,
                      )),
                      Text('~${m.estimatedDays} kun | ${m.completedTasks}/${m.tasks.length} vazifa',
                          style: MlpTextStyles.caption),
                    ],
                  ),
                ),
                Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: MlpColors.text3),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(color: MlpColors.border, height: 1),
              const SizedBox(height: 12),
              Text(m.objective, style: MlpTextStyles.body2),
              const SizedBox(height: 12),
              ...m.tasks.map((t) => _TaskTile(
                task: t,
                onComplete: t.isCompleted ? null : () => widget.onTaskComplete(m.id, t.id),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatefulWidget {
  const _TaskTile({required this.task, this.onComplete});
  final MlpTask task;
  final VoidCallback? onComplete;

  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  bool _localDone = false;

  @override
  Widget build(BuildContext context) {
    final isDone = widget.task.isCompleted || _localDone;
    return GestureDetector(
      onTap: (isDone || widget.onComplete == null) ? null : () {
        setState(() => _localDone = true);
        widget.onComplete!();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDone ? MlpColors.success.withValues(alpha: 0.1) : MlpColors.bg3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDone ? MlpColors.success.withValues(alpha: 0.3) : MlpColors.border),
        ),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isDone ? MlpColors.success : MlpColors.text3,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.task.title, style: MlpTextStyles.body2.copyWith(
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? MlpColors.text3 : MlpColors.text1,
              )),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: MlpColors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('+${widget.task.xpReward}XP',
                  style: const TextStyle(color: MlpColors.purpleLight, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
