import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';

class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.height = 54,
    this.enabled = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool enabled;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _pressed = false;
  bool _hovered = false;

  bool get _active => widget.enabled && widget.onPressed != null;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_active) return;

    setState(() => _pressed = false);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scale = !_active
        ? 1.0
        : _pressed
            ? 0.965
            : _hovered
                ? 1.012
                : 1.0;

    return MouseRegion(
      cursor: _active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: _active ? (_) => setState(() => _hovered = true) : null,
      onExit: _active ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _active ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: _active ? () => setState(() => _pressed = false) : null,
        onTapUp: _active ? _handleTapUp : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          scale: scale,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _active ? 1 : 0.48,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final value = _controller.value;
                final pulse = (math.sin(value * math.pi * 2) + 1) / 2;
                final shimmerAlignment = -1.45 + (value * 2.9);

                return Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: _active
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(
                                0.28 + (pulse * 0.12),
                              ),
                              blurRadius: 26 + (pulse * 18),
                              spreadRadius: 1 + (pulse * 2),
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: AppColors.cyan.withOpacity(
                                0.10 + (pulse * 0.08),
                              ),
                              blurRadius: 34 + (pulse * 14),
                              offset: const Offset(0, 18),
                            ),
                          ]
                        : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: _active
                                  ? AppColors.primaryGradient
                                  : LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.25),
                                        AppColors.primary.withOpacity(0.18),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        if (_active)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.18),
                                    Colors.white.withOpacity(0.02),
                                    Colors.black.withOpacity(0.05),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (_active)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment(shimmerAlignment, 0),
                              child: FractionallySizedBox(
                                widthFactor: 0.28,
                                heightFactor: 1,
                                child: Transform.rotate(
                                  angle: -0.45,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0),
                                          Colors.white.withOpacity(0.34),
                                          Colors.white.withOpacity(0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: Colors.white.withOpacity(
                                  _hovered ? 0.28 : 0.16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  AnimatedScale(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutBack,
                                    scale: _hovered ? 1.12 : 1.0,
                                    child: Icon(
                                      widget.icon,
                                      size: 20,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.white.withOpacity(0.35),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                ],
                                Flexible(
                                  child: Text(
                                    widget.text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.1,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.22),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
