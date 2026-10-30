import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final hasRoadmap = app.learningRoadmaps.isNotEmpty;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(
              child: AppHeader(
                title: 'Yo‘l xaritasi',
                subtitle: 'AI tomonidan tuzilgan shaxsiy rejangiz',
              ),
            ),
          ),
          if (!hasRoadmap)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.map_rounded, size: 54, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Hali o‘quv rejasi yo‘q',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AI ustoz bilan qisqa suhbatlashing va maqsadingizga erishish uchun bosqichma-bosqich yo‘l xaritasini oling.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    GradientButton(
                      text: 'Yangi maqsad yaratish',
                      icon: Icons.add_circle_outline_rounded,
                      onPressed: () => context.push('/create-goal'),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final stage = app.learningRoadmaps.last.stages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GlassCard(
                        glowColor: stage.isCompleted ? AppColors.emerald : AppColors.primary,
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: stage.isCompleted
                                    ? AppColors.emerald.withValues(alpha: 0.2)
                                    : AppColors.primary.withValues(alpha: 0.15),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: stage.isCompleted ? AppColors.emerald : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stage.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    stage.objective,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              stage.isCompleted ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                              color: stage.isCompleted ? AppColors.emerald : AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: app.learningRoadmaps.last.stages.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
