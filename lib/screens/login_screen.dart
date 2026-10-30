import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/app_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/premium_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..forward();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _introController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final app = context.read<AppState>();

    try {
      await app.signInWithGoogle();

      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            app.errorMessage ?? 'Google orqali kirishda xatolik bo‘ldi.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _continueAsGuest() async {
    final app = context.read<AppState>();

    try {
      await app.continueAsGuest();

      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            app.errorMessage ?? 'Guest rejimga kirishda xatolik bo‘ldi.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return PremiumScaffold(
      body: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, _) {
          final t = _ambientController.value;

          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned(
                    top: -120 + (t * 28),
                    right: -100 + (t * 20),
                    child: const _AnimatedOrb(
                      size: 270,
                      opacity: 0.28,
                      color: AppColors.primary,
                    ),
                  ),
                  Positioned(
                    bottom: -130 + (t * 22),
                    left: -100 - (t * 18),
                    child: const _AnimatedOrb(
                      size: 250,
                      opacity: 0.18,
                      color: AppColors.cyan,
                    ),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.34,
                    left: -70 + (t * 30),
                    child: const _AnimatedOrb(
                      size: 150,
                      opacity: 0.12,
                      color: AppColors.emerald,
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 48,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StaggeredFadeSlide(
                                controller: _introController,
                                intervalStart: 0.00,
                                intervalEnd: 0.45,
                                offsetY: -16,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _StatusPill(
                                    isCloudUser: app.isCloudUser,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _StaggeredScaleFade(
                                controller: _introController,
                                intervalStart: 0.08,
                                intervalEnd: 0.58,
                                child: _LogoMark(
                                  progress: t,
                                ),
                              ),
                              const SizedBox(height: 26),
                              _StaggeredFadeSlide(
                                controller: _introController,
                                intervalStart: 0.20,
                                intervalEnd: 0.66,
                                offsetY: 18,
                                child: Text(
                                  'MYLife Plan',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.3,
                                        height: 1.0,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _StaggeredFadeSlide(
                                controller: _introController,
                                intervalStart: 0.30,
                                intervalEnd: 0.72,
                                offsetY: 18,
                                child: Text(
                                  'Build discipline. Track habits.\nLevel up your life.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        height: 1.5,
                                        fontSize: 15.5,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _StaggeredFadeSlide(
                                controller: _introController,
                                intervalStart: 0.42,
                                intervalEnd: 0.92,
                                offsetY: 30,
                                child: GlassCard(
                                  padding: const EdgeInsets.all(18),
                                  glowColor: AppColors.primary,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          _AnimatedMiniStat(
                                            controller: _introController,
                                            intervalStart: 0.54,
                                            icon: Icons
                                                .local_fire_department_rounded,
                                            title: 'Streak',
                                            value: '${app.currentStreak}',
                                            color: AppColors.orange,
                                          ),
                                          const SizedBox(width: 10),
                                          _AnimatedMiniStat(
                                            controller: _introController,
                                            intervalStart: 0.61,
                                            icon: Icons.bolt_rounded,
                                            title: 'Level',
                                            value: '${app.level}',
                                            color: AppColors.cyan,
                                          ),
                                          const SizedBox(width: 10),
                                          _AnimatedMiniStat(
                                            controller: _introController,
                                            intervalStart: 0.68,
                                            icon:
                                                Icons.workspace_premium_rounded,
                                            title: 'XP',
                                            value: '${app.totalXp}',
                                            color: AppColors.gold,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      _PulseGlow(
                                        progress: t,
                                        enabled: !app.isSyncing,
                                        child: GradientButton(
                                          text: app.isSyncing
                                              ? 'Connecting...'
                                              : 'Continue with Google',
                                          icon: Icons.g_mobiledata_rounded,
                                          onPressed: app.isSyncing
                                              ? null
                                              : _signInWithGoogle,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _GuestModeButton(
                                        enabled: !app.isSyncing,
                                        onTap: _continueAsGuest,
                                      ),
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        child: app.isSyncing
                                            ? Padding(
                                                key: const ValueKey('loading'),
                                                padding: const EdgeInsets.only(
                                                  top: 16,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    999,
                                                  ),
                                                  child:
                                                      const LinearProgressIndicator(
                                                    minHeight: 3,
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(
                                                key: ValueKey('empty'),
                                              ),
                                      ),
                                      const SizedBox(height: 18),
                                      const _TrustRow(
                                        icon: Icons.cloud_done_rounded,
                                        text: 'Google Auth + Firestore sync',
                                      ),
                                      const SizedBox(height: 11),
                                      const _TrustRow(
                                        icon: Icons.lock_rounded,
                                        text:
                                            'Your habits are saved to your account',
                                      ),
                                      const SizedBox(height: 11),
                                      const _TrustRow(
                                        icon: Icons.phone_android_rounded,
                                        text: 'Tested on real Android device',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _StaggeredFadeSlide(
                                controller: _introController,
                                intervalStart: 0.78,
                                intervalEnd: 1.00,
                                offsetY: 12,
                                child: Text(
                                  'Start today. Your future self is watching.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final floatY = math.sin(progress * math.pi) * 7;
    final rotate = math.sin(progress * math.pi * 2) * 0.035;

    return Transform.translate(
      offset: Offset(0, -floatY),
      child: Transform.rotate(
        angle: rotate,
        child: Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.46),
                blurRadius: 58,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.18),
                blurRadius: 80,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 52,
              ),
              Positioned(
                top: 24,
                right: 24,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.45),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.isCloudUser,
  });

  final bool isCloudUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.borderSoft.withValues(alpha: 0.95),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BreathingDot(
            color: isCloudUser ? AppColors.emerald : AppColors.cyan,
          ),
          const SizedBox(width: 9),
          Text(
            isCloudUser ? 'Cloud Sync' : 'Google Ready',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
          ),
        ],
      ),
    );
  }
}

class _BreathingDot extends StatefulWidget {
  const _BreathingDot({
    required this.color,
  });

  final Color color;

  @override
  State<_BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<_BreathingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final glow = 0.35 + (_controller.value * 0.45);

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: glow),
                blurRadius: 10 + (_controller.value * 10),
                spreadRadius: _controller.value * 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedMiniStat extends StatelessWidget {
  const _AnimatedMiniStat({
    required this.controller,
    required this.intervalStart,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final AnimationController controller;
  final double intervalStart;
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _StaggeredScaleFade(
        controller: controller,
        intervalStart: intervalStart,
        intervalEnd: 1.0,
        child: Container(
          height: 104,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface2.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.borderSoft.withValues(alpha: 0.9),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 23,
              ),
              const SizedBox(height: 9),
              FittedBox(
                child: Text(
                  value,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _GuestModeButton extends StatefulWidget {
  const _GuestModeButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_GuestModeButton> createState() => _GuestModeButtonState();
}

class _GuestModeButtonState extends State<_GuestModeButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = !widget.enabled
        ? 1.0
        : _pressed
            ? 0.97
            : _hovered
                ? 1.01
                : 1.0;

    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: widget.enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: widget.enabled ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap();
              }
            : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          scale: scale,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: widget.enabled ? 1 : 0.5,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.surface2.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _hovered
                      ? AppColors.cyan.withValues(alpha: 0.42)
                      : AppColors.borderSoft.withValues(alpha: 0.92),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: _hovered ? 0.16 : 0.08),
                    blurRadius: _hovered ? 28 : 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Continue as Guest',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.emerald,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

class _PulseGlow extends StatelessWidget {
  const _PulseGlow({
    required this.progress,
    required this.enabled,
    required this.child,
  });

  final double progress;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pulse = enabled ? math.sin(progress * math.pi) : 0.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22 + (pulse * 0.12)),
            blurRadius: 24 + (pulse * 18),
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AnimatedOrb extends StatelessWidget {
  const _AnimatedOrb({
    required this.size,
    required this.opacity,
    required this.color,
  });

  final double size;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaggeredFadeSlide extends StatelessWidget {
  const _StaggeredFadeSlide({
    required this.controller,
    required this.intervalStart,
    required this.intervalEnd,
    required this.offsetY,
    required this.child,
  });

  final AnimationController controller;
  final double intervalStart;
  final double intervalEnd;
  final double offsetY;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        intervalStart,
        intervalEnd,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final value = animation.value;

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

class _StaggeredScaleFade extends StatelessWidget {
  const _StaggeredScaleFade({
    required this.controller,
    required this.intervalStart,
    required this.intervalEnd,
    required this.child,
  });

  final AnimationController controller;
  final double intervalStart;
  final double intervalEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        intervalStart,
        intervalEnd,
        curve: Curves.easeOutBack,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final value = animation.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.88 + (value * 0.12),
            child: child,
          ),
        );
      },
    );
  }
}
