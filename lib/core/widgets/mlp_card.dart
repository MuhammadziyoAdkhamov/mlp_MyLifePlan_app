import 'package:flutter/material.dart';
import '../design/mlp_colors.dart';

class MlpCard extends StatelessWidget {
  const MlpCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.glowColor,
    this.borderRadius,
    this.margin,
    this.onTap,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? glowColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 18.0;
    final bg = color ?? MlpColors.bg2;

    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: MlpColors.border, width: 1),
        boxShadow: glowColor != null ? [
          BoxShadow(color: glowColor!.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 0),
        ] : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}

class MlpGlassCard extends StatelessWidget {
  const MlpGlassCard({super.key, required this.child, this.padding, this.margin, this.onTap});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MlpCard(
      padding: padding, margin: margin, onTap: onTap,
      color: MlpColors.bg2.withValues(alpha: 0.8),
      border: Border.all(color: MlpColors.borderSoft),
      child: child,
    );
  }
}
