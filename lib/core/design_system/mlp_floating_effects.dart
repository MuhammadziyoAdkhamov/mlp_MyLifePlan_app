import 'package:flutter/material.dart';
import '../../app/theme/mlp_design_system.dart';

/// Enhanced floating and antigravity visual effects for cards and surfaces
class MLPFloatingCard extends StatelessWidget {
  const MLPFloatingCard({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 24,
    this.glowColor,
    this.intensity = 1.0,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final Color? glowColor;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final effectiveGlow = glowColor ?? MLPColors.primary;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // Soft outer glow
          BoxShadow(
            color: effectiveGlow.withValues(alpha: 0.15 * intensity),
            blurRadius: 24 * intensity,
            spreadRadius: 2,
            offset: Offset(0, 8 * intensity),
          ),
          // Inner depth shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2 * intensity),
            blurRadius: 16 * intensity,
            offset: Offset(0, 4 * intensity),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Animated hover/press effect for interactive elements
class MLPAntigravityButton extends StatefulWidget {
  const MLPAntigravityButton({
    super.key,
    required this.child,
    this.onTap,
    this.glowColor = MLPColors.turquoise,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color glowColor;

  @override
  State<MLPAntigravityButton> createState() => _AntigravityButtonState();
}

class _AntigravityButtonState extends State<MLPAntigravityButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _glowAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.glowColor.withValues(
                      alpha: 0.2 * _glowAnimation.value,
                    ),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Gradient border with glow effect
class MLPGlowingBorder extends StatelessWidget {
  const MLPGlowingBorder({
    super.key,
    required this.child,
    this.colors = const [MLPColors.turquoise, MLPColors.primary],
    this.width = 1.5,
    this.radius = 20,
    this.glowIntensity = 0.3,
  });

  final Widget child;
  final List<Color> colors;
  final double width;
  final double radius;
  final double glowIntensity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          for (final color in colors)
            BoxShadow(
              color: color.withValues(alpha: glowIntensity),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(width),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius - width),
          color: MLPColors.elevated,
        ),
        child: child,
      ),
    );
  }
}

/// Pulsating glow animation for attention
class MLPPulseGlow extends StatefulWidget {
  const MLPPulseGlow({
    super.key,
    required this.child,
    this.color = MLPColors.turquoise,
    this.duration = const Duration(seconds: 2),
  });

  final Widget child;
  final Color color;
  final Duration duration;

  @override
  State<MLPPulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<MLPPulseGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value),
                blurRadius: 20 + (_animation.value * 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Particle effect background for special moments
class MLPParticleField extends StatelessWidget {
  const MLPParticleField({
    super.key,
    this.particleCount = 20,
    this.colors = const [
      MLPColors.turquoise,
      MLPColors.primary,
      MLPColors.primaryLight,
    ],
  });

  final int particleCount;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(
        particleCount: particleCount,
        colors: colors,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particleCount,
    required this.colors,
  });

  final int particleCount;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < particleCount; i++) {
      final seed = i * 7919; // Prime for distribution
      final x = ((seed * 13) % 1000) / 1000 * size.width;
      final y = ((seed * 17) % 1000) / 1000 * size.height;
      final particleSize = ((seed * 3) % 5) + 1.0;
      final colorIndex = i % colors.length;
      
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        Paint()
          ..color = colors[colorIndex].withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => false;
}
