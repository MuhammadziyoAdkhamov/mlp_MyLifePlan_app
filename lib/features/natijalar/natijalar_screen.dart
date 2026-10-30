import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/design/mlp_colors.dart';
import '../../core/design/mlp_text_styles.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/mlp_card.dart';
import '../../core/widgets/xp_chip.dart';

class NatijalarScreen extends ConsumerWidget {
  const NatijalarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final roadmaps = ref.watch(roadmapsProvider);
    final xpEvents = ref.watch(xpEventsProvider);

    final totalTasks = roadmaps.fold(
      0, (s, r) => s + r.milestones.fold(0, (ms, m) => ms + m.tasks.length));
    final completedTasks = roadmaps.fold(
      0, (s, r) => s + r.milestones.fold(0, (ms, m) => ms + m.completedTasks));
    final completedMilestones = roadmaps.fold(
      0, (s, r) => s + r.completedMilestones);

    return Scaffold(
      backgroundColor: MlpColors.bg1,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Natijalar', style: MlpTextStyles.h2),
                    Text('Haqiqiy taraqqiyotingiz', style: MlpTextStyles.body2),
                    const SizedBox(height: 20),
                    if (user != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A1040), Color(0xFF0F1E40)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: MlpColors.purple.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.name, style: MlpTextStyles.h3),
                                      Text('Daraja ${user.level}', style: MlpTextStyles.body2.copyWith(color: MlpColors.purpleLight)),
                                    ],
                                  ),
                                ),
                                XpChip(xp: user.xp),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: user.xpProgress.clamp(0.0, 1.0),
                                backgroundColor: MlpColors.bg4,
                                valueColor: const AlwaysStoppedAnimation(MlpColors.purple),
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${user.xp} XP', style: MlpTextStyles.caption.copyWith(color: MlpColors.purpleLight)),
                                Text('${user.xpToNextLevel} XP (Daraja ${user.level + 1})', style: MlpTextStyles.caption),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _StatCard(value: '$completedTasks', label: 'Vazifa', sublabel: 'dan $totalTasks')),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(value: '$completedMilestones', label: 'Bosqich', sublabel: 'yakunlandi')),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(value: '${user?.coins ?? 0}', label: 'Coin', sublabel: '🪙', isEmoji: true)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Faoliyat tarixi', style: MlpTextStyles.label.copyWith(color: MlpColors.text2)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (xpEvents.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.bar_chart_rounded, color: MlpColors.text3, size: 48),
                        const SizedBox(height: 12),
                        Text('Hali faoliyat yo\'q', style: MlpTextStyles.body2),
                        Text('Birinchi vazifani bajaring!', style: MlpTextStyles.caption),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final event = xpEvents.reversed.toList()[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: MlpColors.bg2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MlpColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: MlpColors.purple.withValues(alpha: 0.2),
                              ),
                              child: const Icon(Icons.star_rounded, color: MlpColors.gold, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.label, style: MlpTextStyles.body2.copyWith(color: MlpColors.text1)),
                                  Text(
                                    DateFormat('d MMM, HH:mm').format(event.earnedAt),
                                    style: MlpTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            Text('+${event.xp} XP',
                                style: const TextStyle(
                                  color: MlpColors.purpleLight,
                                  fontWeight: FontWeight.w700, fontSize: 13,
                                )),
                          ],
                        ),
                      );
                    },
                    childCount: xpEvents.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.sublabel, this.isEmoji = false});
  final String value, label, sublabel;
  final bool isEmoji;

  @override
  Widget build(BuildContext context) {
    return MlpCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, color: MlpColors.text1,
          )),
          Text(label, style: MlpTextStyles.label.copyWith(color: MlpColors.purpleLight)),
          Text(sublabel, style: MlpTextStyles.caption),
        ],
      ),
    );
  }
}
