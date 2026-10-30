import 'package:flutter/material.dart';
import '../../app/theme/mlp_design_system.dart';
import 'mlp_widgets.dart';
import 'mlp_liquid_glass.dart';

String mlpCompactTime(int seconds) {
  final minutes = seconds ~/ 60;
  if (seconds < 60) return '${seconds}s';
  return minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';
}

class MLPCompactHeader extends StatelessWidget {
  const MLPCompactHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        ...actions,
      ],
    ),
  );
}

class MLPWeekStrip extends StatelessWidget {
  const MLPWeekStrip({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;
  @override
  Widget build(BuildContext context) {
    final start = DateTime(
      selected.year,
      selected.month,
      selected.day - selected.weekday + 1,
    );
    return Row(
      children: List.generate(7, (i) {
        final date = start.add(Duration(days: i));
        final active = date.day == selected.day;
        final textColor = active ? MLPColors.background : MLPColors.text;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Semantics(
              selected: active,
              button: true,
              label: '${date.day}.${date.month} kunini tanlash',
              child: MLPPressResponse(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onChanged(date),
                  child: AnimatedContainer(
                    duration: MLPDimensions.motion(context),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active
                          ? MLPColors.turquoise
                          : Colors.white.withValues(alpha: .05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? MLPColors.turquoise
                            : Colors.white.withValues(alpha: .08),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'][i],
                          style: TextStyle(fontSize: 10, color: textColor),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class MLPCompactMetrics extends StatelessWidget {
  const MLPCompactMetrics({super.key, required this.items});
  final List<({String value, String label, IconData icon, Color color})> items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns =
          box.maxWidth < 310 || MediaQuery.textScalerOf(context).scale(1) > 1.4
          ? 2
          : 3;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map(
              (m) => SizedBox(
                width: (box.maxWidth - 8 * (columns - 1)) / columns,
                child: MLPGlassCard(
                  padding: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(m.icon, color: m.color, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              m.value,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m.label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: MLPColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class MLPCompactTaskCard extends StatelessWidget {
  const MLPCompactTaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.seconds,
    required this.plannedMinutes,
    required this.onPlay,
    required this.onOpen,
    this.color = MLPColors.turquoise,
    this.completed = false,
    this.onMenu,
    this.badges = const [],
  });
  final String title, subtitle;
  final int seconds, plannedMinutes;
  final VoidCallback onPlay, onOpen;
  final VoidCallback? onMenu;
  final Color color;
  final bool completed;
  final List<Widget> badges;
  @override
  Widget build(BuildContext context) {
    final progress = plannedMinutes == 0
        ? 0.0
        : (seconds / (plannedMinutes * 60)).clamp(0.0, 1.0);
    return MLPGlassCard(
      padding: 10,
      onTap: onOpen,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MLPCircleAction(
                label: completed
                    ? 'Hisobotni ko‘rish: $title'
                    : 'Fokusni boshlash: $title',
                icon: completed
                    ? Icons.check_rounded
                    : Icons.play_arrow_rounded,
                onPressed: onPlay,
                color: completed ? MLPColors.success : color,
                size: 42,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (badges.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: badges,
                        ),
                      )
                    else if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: MLPColors.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
              if (onMenu != null)
                SizedBox(
                  width: 40,
                  child: IconButton(
                    tooltip: 'Amallar: $title',
                    onPressed: onMenu,
                    icon: const Icon(Icons.more_horiz, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 58),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${mlpCompactTime(seconds)} / ${plannedMinutes}m',
                        style: const TextStyle(
                          color: MLPColors.secondaryText,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: MLPColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Semantics(
                  container: true,
                  label: 'Qayd etilgan fokus ${(progress * 100).round()} foiz',
                  child: ExcludeSemantics(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: .09),
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MLPBadge extends StatelessWidget {
  const MLPBadge(
    this.label, {
    super.key,
    this.color = MLPColors.turquoise,
    this.icon,
  });
  final String label;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 9),
          ),
        ),
      ],
    ),
  );
}
