import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';
import '../models/app_badge.dart';
import 'glass_card.dart';

class AppBadgeCard extends StatelessWidget {
  const AppBadgeCard({super.key, required this.badge});

  final AppBadge badge;

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.isUnlocked;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: unlocked
          ? AppColors.gold.withOpacity(0.38)
          : AppColors.borderSoft,
      glowColor: unlocked ? AppColors.gold : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unlocked ? AppColors.goldGradient : null,
              color: unlocked ? null : AppColors.surface3.withOpacity(0.7),
            ),
            child: Icon(
              _iconForBadge(badge.id),
              color: unlocked ? Colors.white : AppColors.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(badge.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(badge.description, style: Theme.of(context).textTheme.bodySmall),
          if (badge.unlockedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d').format(badge.unlockedAt!),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.gold),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForBadge(String id) => switch (id) {
    'first_step' => Icons.flag_rounded,
    'seven_day_streak' => Icons.local_fire_department_rounded,
    'focus_master' => Icons.center_focus_strong_rounded,
    'bookworm' => Icons.menu_book_rounded,
    'unstoppable' => Icons.bolt_rounded,
    'perfect_week' => Icons.workspace_premium_rounded,
    _ => Icons.emoji_events_rounded,
  };
}
