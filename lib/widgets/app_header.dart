import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'glow_icon_button.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actionIcon,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 10)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
        if (actionIcon != null) GlowIconButton(icon: actionIcon!, onPressed: onAction),
      ],
    );
  }
}
