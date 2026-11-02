import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme/mlp_design_system.dart';
import '../core/design_system/mlp_liquid_glass.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  static const _items = [
    _NavItem(
      icon: Icons.home_rounded,
      label: 'Bosh sahifa',
      route: '/home',
    ),
    _NavItem(
      icon: Icons.map_rounded,
      label: 'Yo‘l xaritasi',
      route: '/roadmap',
    ),
    _NavItem(
      icon: Icons.school_rounded,
      label: 'O‘rganish',
      route: '/learning',
    ),
    _NavItem(
      icon: Icons.psychology_rounded,
      label: 'AI Ustoz',
      route: '/ai-tutor',
    ),
    _NavItem(
      icon: Icons.person_rounded,
      label: 'Profil',
      route: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MLPColors.elevated.withValues(alpha: 0.7),
                        MLPColors.secondary.withValues(alpha: 0.65),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.7,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_items.length, (index) {
                      final item = _items[index];
                      final active = index == currentIndex;
                      return Expanded(
                        child: MLPPressResponse(
                          child: GestureDetector(
                            onTap: () => context.go(item.route),
                            child: AnimatedContainer(
                              duration: MLPDimensions.compactMotion,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                gradient: active
                                    ? const LinearGradient(
                                        colors: [
                                          MLPColors.turquoise,
                                          MLPColors.primary,
                                        ],
                                      )
                                    : null,
                                boxShadow: active
                                    ? [
                                        BoxShadow(
                                          color: MLPColors.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 16,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    item.icon,
                                    color: active
                                        ? MLPColors.text
                                        : MLPColors.secondaryText,
                                    size: 24,
                                  ),
                                  if (active) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: MLPColors.text,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
  final IconData icon;
  final String label;
  final String route;
}
