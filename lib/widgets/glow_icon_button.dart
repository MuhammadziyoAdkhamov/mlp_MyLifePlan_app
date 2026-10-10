import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class GlowIconButton extends StatelessWidget {
  const GlowIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.13),
        border: Border.all(color: color.withOpacity(0.28)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.18), blurRadius: 24)],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
