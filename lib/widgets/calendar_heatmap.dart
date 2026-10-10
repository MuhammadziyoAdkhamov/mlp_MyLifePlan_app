import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/date_helper.dart';

class CalendarHeatmap extends StatelessWidget {
  const CalendarHeatmap({super.key, required this.values});

  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    final days = values.keys.map(DateHelper.parseDateOnly).toList()..sort();
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: days.map((day) {
        final value = values[DateHelper.key(day)] ?? 0;
        final color = Color.lerp(AppColors.surface3, AppColors.emerald, value.clamp(0, 1))!;
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color.withOpacity(value == 0 ? 0.46 : 0.95),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.borderSoft.withOpacity(0.7)),
          ),
        );
      }).toList(),
    );
  }
}
