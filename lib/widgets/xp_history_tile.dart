import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';
import '../models/xp_history_item.dart';

class XPHistoryTile extends StatelessWidget {
  const XPHistoryTile({super.key, required this.item});

  final XPHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.14),
            ),
            child: const Icon(Icons.star_rounded, color: AppColors.cyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${item.subtitle} • ${DateFormat('MMM d').format(item.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '+${item.amount} XP',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.emerald),
          ),
        ],
      ),
    );
  }
}
