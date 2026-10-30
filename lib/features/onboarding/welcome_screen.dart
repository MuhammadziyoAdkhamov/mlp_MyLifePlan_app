import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/mlp_colors.dart';
import '../../core/design/mlp_text_styles.dart';
import '../../core/widgets/mlp_button.dart';
import '../../core/widgets/demo_banner.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MlpColors.bg0,
      body: Column(
        children: [
          const DemoBanner(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: MlpColors.gradientBg),
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          // Logo area
                          Container(
                            width: 90, height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [MlpColors.purple, MlpColors.blue],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(color: MlpColors.purple.withValues(alpha: 0.4), blurRadius: 32, spreadRadius: 4),
                              ],
                            ),
                            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 48),
                          ),
                          const SizedBox(height: 32),
                          Text('MYLife Plan', style: MlpTextStyles.h1.copyWith(fontSize: 32)),
                          const SizedBox(height: 12),
                          Text(
                            'Maqsadlaringizni\nreal natijalarga aylantiring',
                            textAlign: TextAlign.center,
                            style: MlpTextStyles.body1.copyWith(color: MlpColors.text2, height: 1.6),
                          ),
                          const SizedBox(height: 48),
                          // Feature pills
                          const Wrap(
                            spacing: 10, runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              _Pill(emoji: '📋', label: 'AI Reja'),
                              _Pill(emoji: '🎯', label: 'Maqsad'),
                              _Pill(emoji: '⚡', label: 'XP tizimi'),
                              _Pill(emoji: '🤖', label: 'AI Ustoz'),
                            ],
                          ),
                          const Spacer(flex: 3),
                          MlpButton(
                            label: 'Boshlash',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () => context.go('/onboarding'),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Demo prototip — backend ulangan emas',
                            style: MlpTextStyles.caption,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.emoji, required this.label});
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: MlpColors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MlpColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label, style: MlpTextStyles.chip),
        ],
      ),
    );
  }
}
