import 'package:flutter/material.dart';
import 'package:mylife_plan/models/habit_enums.dart';

import '../core/app_colors.dart';
import '../models/habit.dart';
import 'glass_card.dart';

class HabitTile extends StatefulWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.completed,
    required this.onToggle,
    required this.onTap,
    this.onDelete,
  });

  final Habit habit;
  final bool completed;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  State<HabitTile> createState() => _HabitTileState();
}

class _HabitTileState extends State<HabitTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(widget.habit.category.label);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      opacity: widget.completed ? 0.78 : 1,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: _pressed
            ? 0.975
            : widget.completed
                ? 0.985
                : 1,
        child: GlassCard(
          onTap: widget.onTap,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          borderColor:
              widget.completed ? AppColors.emerald.withValues(alpha: 0.55) : null,
          glowColor: widget.completed ? AppColors.emerald : color,
          child: Stack(
            children: [
              if (widget.completed)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.emerald.withValues(alpha: 0.12),
                            Colors.transparent,
                            AppColors.cyan.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (_) => setState(() => _pressed = true),
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) {
                  setState(() => _pressed = false);
                  widget.onTap();
                },
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: widget.completed
                            ? AppColors.emerald.withValues(alpha: 0.18)
                            : color.withValues(alpha: 0.16),
                        border: Border.all(
                          color: widget.completed
                              ? AppColors.emerald.withValues(alpha: 0.55)
                              : color.withValues(alpha: 0.24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.completed
                                    ? AppColors.emerald
                                    : color)
                                .withValues(alpha: widget.completed ? 0.22 : 0.10),
                            blurRadius: widget.completed ? 24 : 16,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.completed
                            ? Icons.check_circle_rounded
                            : IconData(
                                // ignore: non_const_argument_for_const_parameter
                                widget.habit.iconCodePoint,
                                fontFamily: 'MaterialIcons',
                              ),
                        color: widget.completed ? AppColors.emerald : color,
                        size: widget.completed ? 24 : 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  color: widget.completed
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  decoration: widget.completed
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationColor:
                                      AppColors.emerald.withValues(alpha: 0.8),
                                  decorationThickness: 2,
                                ),
                            child: Text(
                              widget.habit.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.completed
                                      ? 'Completed today'
                                      : widget.habit.category.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: widget.completed
                                            ? AppColors.emerald
                                            : AppColors.textMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              if (!widget.completed &&
                                  widget.habit.reminder != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.notifications_none_rounded,
                                  size: 14,
                                  color: AppColors.textMuted.withValues(alpha: 0.8),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.onDelete != null)
                      PopupMenuButton<String>(
                        tooltip: 'Habit options',
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.textMuted,
                        ),
                        color: AppColors.surface2,
                        onSelected: (value) {
                          if (value == 'delete') {
                            widget.onDelete?.call();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text('Delete habit'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutBack,
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.completed
                              ? AppColors.emerald
                              : Colors.transparent,
                          border: Border.all(
                            color: widget.completed
                                ? AppColors.emerald
                                : AppColors.borderSoft,
                            width: 1.4,
                          ),
                          boxShadow: widget.completed
                              ? [
                                  BoxShadow(
                                    color: AppColors.emerald.withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                        ),
                        child: widget.completed
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              )
                            : const Icon(
                                Icons.add_rounded,
                                color: AppColors.textMuted,
                                size: 18,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
