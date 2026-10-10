import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/journey_task.dart';
import 'glass_card.dart';

class JourneyTaskTile extends StatelessWidget {
  const JourneyTaskTile({
    super.key,
    required this.task,
    required this.onTap,
  });

  final JourneyTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = task.isLocked;
    final completed = task.isCompleted;
    return Opacity(
      opacity: locked ? 0.58 : 1,
      child: GlassCard(
        onTap: locked ? null : onTap,
        borderColor: completed ? AppColors.emerald.withOpacity(0.4) : null,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed ? AppColors.emerald.withOpacity(0.18) : AppColors.surface3,
              ),
              child: Icon(
                locked ? Icons.lock_rounded : completed ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
                color: completed ? AppColors.emerald : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Day ${task.day}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                  Text(task.title, style: Theme.of(context).textTheme.titleMedium),
                  Text(task.description, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text('+${task.xpReward}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.gold)),
          ],
        ),
      ),
    );
  }
}
