import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/mlp_colors.dart';
import '../../core/design/mlp_text_styles.dart';
import '../../core/domain/roadmap_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/mlp_button.dart';
import '../../core/widgets/mlp_card.dart';

class RoadmapPreviewScreen extends ConsumerStatefulWidget {
  const RoadmapPreviewScreen({super.key, required this.roadmapId});
  final String roadmapId;

  @override
  ConsumerState<RoadmapPreviewScreen> createState() => _RoadmapPreviewScreenState();
}

class _RoadmapPreviewScreenState extends ConsumerState<RoadmapPreviewScreen> {
  bool _isConfirming = false;

  Future<void> _confirm(MlpRoadmap roadmap) async {
    setState(() => _isConfirming = true);
    await ref.read(roadmapsProvider.notifier).updateRoadmap(
      roadmap.copyWith(isApproved: true),
    );
    await ref.read(userProvider.notifier).earnXp(50, label: 'Reja tasdiqlandi');
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final roadmaps = ref.watch(roadmapsProvider);
    final roadmap = roadmaps.where((r) => r.id == widget.roadmapId).firstOrNull;

    if (roadmap == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final goals = ref.watch(goalsProvider);
    final goal = goals.where((g) => g.id == roadmap.goalId).firstOrNull;

    return Scaffold(
      backgroundColor: MlpColors.bg1,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Yo\'l xaritasi', style: MlpTextStyles.h2)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: MlpColors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: MlpColors.purple),
                        ),
                        child: Text('AI tomonidan', style: MlpTextStyles.caption.copyWith(color: MlpColors.purpleLight)),
                      ),
                    ],
                  ),
                  if (goal != null) ...[
                    const SizedBox(height: 4),
                    Text(goal.title, style: MlpTextStyles.body2),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatPill(icon: Icons.calendar_today_rounded,
                          label: '${roadmap.totalEstimatedDays} kun'),
                      const SizedBox(width: 10),
                      _StatPill(icon: Icons.flag_rounded,
                          label: '${roadmap.milestones.length} bosqich'),
                      const SizedBox(width: 10),
                      _StatPill(icon: Icons.task_alt_rounded,
                          label: '${roadmap.milestones.fold(0, (s, m) => s + m.tasks.length)} vazifa'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: roadmap.milestones.length,
                itemBuilder: (context, i) {
                  final milestone = roadmap.milestones[i];
                  return _MilestoneCard(milestone: milestone, index: i);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  MlpButton(
                    label: 'Rejani tasdiqlash',
                    icon: Icons.check_circle_rounded,
                    isLoading: _isConfirming,
                    onPressed: () => _confirm(roadmap),
                  ),
                  const SizedBox(height: 12),
                  Text('Siz keyinchalik rejani o\'zgartira olasiz', style: MlpTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.milestone, required this.index});
  final MlpMilestone milestone;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: MlpCard(
        glowColor: index == 0 ? MlpColors.purple : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [MlpColors.purple, MlpColors.blue]),
                  ),
                  child: Center(
                    child: Text('${index + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(milestone.title, style: MlpTextStyles.h4),
                      Text('~${milestone.estimatedDays} kun', style: MlpTextStyles.caption),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: MlpColors.text3),
              ],
            ),
            const SizedBox(height: 12),
            Text(milestone.objective, style: MlpTextStyles.body2),
            if (milestone.tasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: MlpColors.border, height: 1),
              const SizedBox(height: 12),
              ...milestone.tasks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.radio_button_unchecked_rounded, color: MlpColors.text3, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t.title, style: MlpTextStyles.body2)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: MlpColors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('+${t.xpReward} XP',
                          style: const TextStyle(color: MlpColors.purpleLight, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MlpColors.bg3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MlpColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: MlpColors.purpleLight, size: 13),
          const SizedBox(width: 5),
          Text(label, style: MlpTextStyles.caption.copyWith(color: MlpColors.text2, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
