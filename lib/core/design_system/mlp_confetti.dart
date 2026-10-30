import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/mlp_design_system.dart';
import 'mlp_haptics.dart';

/// High-performance Canvas Confetti & Celebration Burst for Apple-grade dopamine feedback
class MLPConfetti {
  const MLPConfetti._();

  /// Trigger celebration burst across the current screen overlay
  static void show(
    BuildContext context, {
    String title = 'Natija qayd etildi! 🎉',
    String subtitle = 'Natijangiz saqlandi',
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    MLPHaptics.success();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _CelebrationOverlay(
        title: title,
        subtitle: subtitle,
        duration: duration,
        reducedMotion: reducedMotion,
        onDismiss: () {
          entry.remove();
          entry.dispose();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.reducedMotion,
    required this.onDismiss,
  });

  final String title;
  final String subtitle;
  final Duration duration;
  final bool reducedMotion;
  final VoidCallback onDismiss;

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  Timer? dismissTimer;
  final List<_Particle> particles = [];
  final math.Random random = math.Random();

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: widget.duration);

    // Generate 42 vibrant particles
    const colors = [
      MLPColors.turquoise,
      MLPColors.primary,
      MLPColors.primaryLight,
      MLPColors.warning,
      MLPColors.success,
      Colors.white,
    ];

    for (var i = 0; i < (widget.reducedMotion ? 0 : 42); i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 120.0 + random.nextDouble() * 280.0;
      particles.add(
        _Particle(
          color: colors[random.nextInt(colors.length)],
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 60.0, // slight upward boost
          size: 6.0 + random.nextDouble() * 8.0,
          rotationSpeed: (random.nextDouble() - 0.5) * 12.0,
          isCircle: random.nextBool(),
        ),
      );
    }

    if (widget.reducedMotion) {
      dismissTimer = Timer(widget.duration, widget.onDismiss);
    } else {
      controller.forward().whenComplete(widget.onDismiss);
    }
  }

  @override
  void dispose() {
    dismissTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = widget.reducedMotion ? .5 : controller.value;
        final badgeScale = t < 0.2
            ? Curves.elasticOut.transform(t / 0.2)
            : t > 0.75
            ? Curves.easeIn.transform(1.0 - (t - 0.75) / 0.25)
            : 1.0;
        final badgeOpacity = t > 0.8
            ? (1.0 - (t - 0.8) / 0.2).clamp(0.0, 1.0)
            : 1.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Particle Canvas
            if (!widget.reducedMotion)
              CustomPaint(
                painter: _ParticlePainter(particles: particles, progress: t),
              ),

            // Center Floating XP Badge
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Semantics(
                    liveRegion: true,
                    child: Transform.scale(
                      scale: badgeScale,
                      child: Opacity(
                        opacity: badgeOpacity,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 360),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xE60F172A),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: MLPColors.turquoise.withValues(alpha: .5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: MLPColors.turquoise.withValues(
                                  alpha: .35,
                                ),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: MLPColors.primary.withValues(alpha: .25),
                                blurRadius: 40,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        MLPColors.turquoise,
                                        MLPColors.primary,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: MLPColors.turquoise.withValues(
                                          alpha: .4,
                                        ),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.bolt_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: MLPColors.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.subtitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: MLPColors.warning,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .5,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _Particle {
  _Particle({
    required this.color,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotationSpeed,
    required this.isCircle,
  });

  final Color color;
  final double vx, vy;
  final double size;
  final double rotationSpeed;
  final bool isCircle;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const gravity = 320.0; // Gravity pulling particles downwards
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final dx = center.dx + p.vx * progress;
      final dy =
          center.dy + p.vy * progress + 0.5 * gravity * progress * progress;
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(progress * p.rotationSpeed);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.6,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
