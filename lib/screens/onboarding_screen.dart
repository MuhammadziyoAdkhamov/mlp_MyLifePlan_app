import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../models/growth_focus.dart';
import '../providers/app_state.dart';
import '../widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();

  late final AnimationController _backgroundController;
  late final AnimationController _introController;

  int _page = 0;
  GrowthFocus _selectedFocus = GrowthFocus.consistency;
  Set<int> _selectedStarterIndices = {0, 1, 2};

  static const List<_OnboardingData> _pages = [
    _OnboardingData(
      badge: 'MYLife Plan',
      title: 'Build your life system',
      message:
          'Katta o‘zgarish birdan emas, kichik odatlardan boshlanadi. Har kuni aniq reja bilan o‘s.',
      icon: Icons.auto_awesome_rounded,
      color: AppColors.primary,
    ),
    _OnboardingData(
      badge: 'Daily Habits',
      title: 'Track habits easily',
      message:
          'Suv ichish, dars qilish, kitob o‘qish yoki sport — hammasini bitta joyda boshqar.',
      icon: Icons.check_circle_rounded,
      color: AppColors.emerald,
    ),
    _OnboardingData(
      badge: 'XP & Streaks',
      title: 'Stay motivated',
      message:
          'XP yig‘, streak saqla, progressni ko‘r va o‘zingni har kuni kuchliroq his qil.',
      icon: Icons.local_fire_department_rounded,
      color: AppColors.gold,
    ),
    _OnboardingData(
      badge: 'Your first week',
      title: 'Build a week that fits you',
      message:
          'Ismingiz va hozirgi maqsadingizni tanlang. Birinchi odat rejangizni o‘zingiz tahrirlashingiz mumkin.',
      icon: Icons.cloud_done_rounded,
      color: AppColors.cyan,
    ),
  ];

  bool get _isLastPage => _page == _pages.length - 1;

  @override
  void initState() {
    super.initState();

    final savedName = context.read<AppState>().profile.name.trim();
    _selectedFocus = growthFocusFromId(
      context.read<AppState>().profile.growthFocus,
    );
    if (savedName.isNotEmpty && savedName != 'Azizbek') {
      _nameController.text = savedName;
    }

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    )..repeat(reverse: true);

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _backgroundController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _completeAndGoLogin({bool requireName = false}) async {
    HapticFeedback.selectionClick();

    final name = _nameController.text.trim();
    if (requireName && name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ismingizni kiriting.')));
      return;
    }
    if (requireName && _selectedStarterIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamida bitta odatni tanlang.')),
      );
      return;
    }

    await context.read<AppState>().completeOnboarding(
      name: name.isEmpty ? null : name,
      focus: requireName ? _selectedFocus.name : null,
      starterSelections: requireName ? _selectedStarterIndices.toList() : null,
    );

    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _next() async {
    HapticFeedback.lightImpact();

    if (!_isLastPage) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    await _completeAndGoLogin(requireName: true);
  }

  Future<void> _skip() async {
    if (_isLastPage) return;
    await _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _pages[_page];

    return Scaffold(
      backgroundColor: const Color(0xFF020712),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(430.0, constraints.maxWidth);

            return Stack(
              children: [
                _AnimatedOnboardingBackground(
                  controller: _backgroundController,
                  color: current.color,
                ),
                Center(
                  child: SizedBox(
                    width: width,
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: _TopBar(
                            currentPage: _page,
                            totalPages: _pages.length,
                            onSkip: _skip,
                            showSkip: !_isLastPage,
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _pages.length,
                            onPageChanged: (value) {
                              setState(() => _page = value);
                              _introController.forward(from: 0);
                            },
                            itemBuilder: (context, index) {
                              return _OnboardingPage(
                                data: _pages[index],
                                controller: _introController,
                                backgroundController: _backgroundController,
                                pageIndex: index,
                                nameController: _nameController,
                                selectedFocus: _selectedFocus,
                                onFocusChanged: (focus) {
                                  setState(() {
                                    _selectedFocus = focus;
                                    _selectedStarterIndices = {0, 1, 2};
                                  });
                                },
                                selectedStarterIndices: _selectedStarterIndices,
                                onStarterSelectionChanged: (index, selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedStarterIndices.add(index);
                                    } else {
                                      _selectedStarterIndices.remove(index);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _PageDots(
                            activeIndex: _page,
                            count: _pages.length,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GradientButton(
                            text: _isLastPage ? 'Build my plan' : 'Continue',
                            icon: _isLastPage
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                            height: 56,
                            onPressed: _isLastPage
                                ? () => _completeAndGoLogin(requireName: true)
                                : _next,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _page == 0
                              ? TextButton(
                                  key: const ValueKey('account'),
                                  onPressed: _completeAndGoLogin,
                                  child: Text(
                                    'I already have an account',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                )
                              : const SizedBox(
                                  key: ValueKey('empty'),
                                  height: 42,
                                ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentPage,
    required this.totalPages,
    required this.onSkip,
    required this.showSkip,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onSkip;
  final bool showSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surface2.withOpacity(0.62),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderSoft.withOpacity(0.75)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.cyan,
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(
                '${currentPage + 1}/$totalPages',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (showSkip)
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Skip intro',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.controller,
    required this.backgroundController,
    required this.pageIndex,
    required this.nameController,
    required this.selectedFocus,
    required this.onFocusChanged,
    required this.selectedStarterIndices,
    required this.onStarterSelectionChanged,
  });

  final _OnboardingData data;
  final AnimationController controller;
  final AnimationController backgroundController;
  final int pageIndex;
  final TextEditingController nameController;
  final GrowthFocus selectedFocus;
  final ValueChanged<GrowthFocus> onFocusChanged;
  final Set<int> selectedStarterIndices;
  final void Function(int index, bool selected) onStarterSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _FadeSlide(
            controller: controller,
            start: 0.00,
            end: 0.45,
            offsetY: 18,
            child: _Badge(text: data.badge, color: data.color),
          ),
          const SizedBox(height: 20),
          _FadeSlide(
            controller: controller,
            start: 0.08,
            end: 0.58,
            offsetY: 24,
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.1,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _FadeSlide(
            controller: controller,
            start: 0.16,
            end: 0.68,
            offsetY: 20,
            child: Text(
              data.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: _FadeSlide(
              controller: controller,
              start: 0.24,
              end: 0.86,
              offsetY: 30,
              child: pageIndex == _OnboardingScreenState._pages.length - 1
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            key: const ValueKey('onboarding-name'),
                            controller: nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Ismingiz',
                              hintText: 'Masalan, Ali',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Bu hafta nimaga e’tibor berasiz?',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: GrowthFocus.values.map((focus) {
                              return ChoiceChip(
                                label: Text(focus.label),
                                selected: selectedFocus == focus,
                                onSelected: (_) => onFocusChanged(focus),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedFocus.description,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Birinchi 3 odatingiz',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          for (final entry
                              in selectedFocus.starterHabits.asMap().entries)
                            CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: selectedStarterIndices.contains(entry.key),
                              onChanged: (selected) =>
                                  onStarterSelectionChanged(
                                    entry.key,
                                    selected ?? false,
                                  ),
                              title: Text(entry.value.name),
                              subtitle: Text(
                                '${entry.value.goal} · minimal: ${entry.value.minimalGoal}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    )
                  : _PremiumVisual(
                      data: data,
                      backgroundController: backgroundController,
                      pageIndex: pageIndex,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumVisual extends StatelessWidget {
  const _PremiumVisual({
    required this.data,
    required this.backgroundController,
    required this.pageIndex,
  });

  final _OnboardingData data;
  final AnimationController backgroundController;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: backgroundController,
      builder: (context, _) {
        final t = backgroundController.value;
        final floatY = math.sin(t * math.pi) * 10;
        final rotate = math.sin(t * math.pi * 2) * 0.035;

        return Transform.translate(
          offset: Offset(0, -floatY),
          child: Transform.rotate(
            angle: rotate,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        data.color.withOpacity(0.38),
                        data.color.withOpacity(0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface.withOpacity(0.70),
                    border: Border.all(color: data.color.withOpacity(0.38)),
                    boxShadow: [
                      BoxShadow(
                        color: data.color.withOpacity(0.24),
                        blurRadius: 55,
                        offset: const Offset(0, 22),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(190, 190),
                        painter: _OrbitPainter(
                          color: data.color,
                          progress: t,
                          pageIndex: pageIndex,
                        ),
                      ),
                      Container(
                        width: 94,
                        height: 94,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [data.color, AppColors.cyan],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: data.color.withOpacity(0.35),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(data.icon, color: Colors.white, size: 42),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  top: 36,
                  right: 42,
                  child: _FloatingMiniChip(
                    icon: Icons.bolt_rounded,
                    text: '+XP',
                    color: AppColors.gold,
                  ),
                ),
                const Positioned(
                  bottom: 48,
                  left: 30,
                  child: _FloatingMiniChip(
                    icon: Icons.check_rounded,
                    text: 'Done',
                    color: AppColors.emerald,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FloatingMiniChip extends StatelessWidget {
  const _FloatingMiniChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.42)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.42)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.activeIndex, required this.count});

  final int activeIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: active ? 26 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: active ? AppColors.primaryGradient : null,
            color: active ? null : AppColors.surface3,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _AnimatedOnboardingBackground extends StatelessWidget {
  const _AnimatedOnboardingBackground({
    required this.controller,
    required this.color,
  });

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;

          return Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF07122F),
                        Color(0xFF040817),
                        Color(0xFF02040B),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -120 + (t * 30),
                right: -120 + (t * 22),
                child: _Orb(size: 300, color: color, opacity: 0.24),
              ),
              Positioned(
                top: 260 - (t * 24),
                left: -140,
                child: const _Orb(
                  size: 250,
                  color: AppColors.cyan,
                  opacity: 0.12,
                ),
              ),
              Positioned(
                bottom: -150 + (t * 32),
                right: -110,
                child: const _Orb(
                  size: 270,
                  color: AppColors.emerald,
                  opacity: 0.10,
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
            ],
          );
        },
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color, required this.opacity});

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)],
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.color,
    required this.progress,
    required this.pageIndex,
  });

  final Color color;
  final double progress;
  final int pageIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.36;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color.withOpacity(0.30);

    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * 0.72, ringPaint);

    final dotPaint = Paint()..color = color.withOpacity(0.95);
    final secondDotPaint = Paint()..color = AppColors.cyan.withOpacity(0.90);

    final angle = progress * math.pi * 2 + (pageIndex * 0.8);
    final point = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );

    final secondPoint = Offset(
      center.dx + math.cos(-angle) * radius * 0.72,
      center.dy + math.sin(-angle) * radius * 0.72,
    );

    canvas.drawCircle(point, 4.2, dotPaint);
    canvas.drawCircle(secondPoint, 3.4, secondDotPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.pageIndex != pageIndex;
  }
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()..color = Colors.white.withOpacity(0.55);
    final bluePaint = Paint()..color = AppColors.cyan.withOpacity(0.52);

    for (int i = 0; i < 48; i++) {
      final dx = ((i * 43 + 17) % 100) / 100 * size.width;
      final dy = ((i * 61 + 9) % 100) / 100 * size.height;
      final radius = i % 9 == 0 ? 1.35 : 0.75;

      canvas.drawCircle(
        Offset(dx, dy),
        radius,
        i % 6 == 0 ? bluePaint : whitePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FadeSlide extends StatelessWidget {
  const _FadeSlide({
    required this.controller,
    required this.start,
    required this.end,
    required this.offsetY,
    required this.child,
  });

  final AnimationController controller;
  final double start;
  final double end;
  final double offsetY;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final value = animation.value.clamp(0.0, 1.0).toDouble();

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

class _OnboardingData {
  const _OnboardingData({
    required this.badge,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String badge;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
}
