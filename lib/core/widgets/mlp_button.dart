import 'package:flutter/material.dart';
import '../design/mlp_colors.dart';
import '../design/mlp_text_styles.dart';

class MlpButton extends StatelessWidget {
  const MlpButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isSecondary = false,
    this.isSmall = false,
    this.colors,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isSecondary;
  final bool isSmall;
  final List<Color>? colors;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 14.0;
    final gradColors = colors ?? (isSecondary ? [MlpColors.bg3, MlpColors.bg4] : [MlpColors.purple, MlpColors.blue]);

    return GestureDetector(
      onTap: (isLoading || onPressed == null) ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: isSmall ? 42 : 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(radius),
          border: isSecondary ? Border.all(color: MlpColors.border) : null,
          boxShadow: isSecondary ? null : [
            BoxShadow(color: MlpColors.purple.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[Icon(icon, color: Colors.white, size: isSmall ? 16 : 20), const SizedBox(width: 8)],
                    Text(label, style: MlpTextStyles.buttonLabel.copyWith(fontSize: isSmall ? 13 : 15)),
                  ],
                ),
        ),
      ),
    );
  }
}
