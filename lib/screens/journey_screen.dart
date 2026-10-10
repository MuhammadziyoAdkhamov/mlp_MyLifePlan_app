import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/journey_task_tile.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final completed = app.journeyTasks.where((task) => task.isCompleted).length;
    final progress = app.journeyTasks.isEmpty ? 0.0 : completed / app.journeyTasks.length;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppHeader(title: '30 Day Focus Journey', subtitle: 'Build discipline with one small task daily'),
                  const SizedBox(height: 20),
                  GlassCard(
                    glowColor: AppColors.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Day ${completed + 1}/30', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text('Discipline is Freedom', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            color: AppColors.primary,
                            backgroundColor: AppColors.surface3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: app.journeyTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = app.journeyTasks[index];
                return JourneyTaskTile(
                  task: task,
                  onTap: () => context.read<AppState>().toggleJourneyTask(task.id),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
