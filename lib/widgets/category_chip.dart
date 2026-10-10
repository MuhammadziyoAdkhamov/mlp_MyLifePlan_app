import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/habit_enums.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final HabitCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(category.label);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.22) : AppColors.surface2.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : AppColors.borderSoft),
        ),
        child: Text(
          category.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? color : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
