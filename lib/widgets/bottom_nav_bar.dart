import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home', route: '/home'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Stats', route: '/stats'),
    _NavItem(icon: Icons.flag_rounded, label: 'Journey', route: '/journey'),
    _NavItem(icon: Icons.emoji_events_rounded, label: 'Badges', route: '/badges'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile', route: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.96),
        border: Border(top: BorderSide(color: AppColors.borderSoft.withOpacity(0.8))),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.paddingOf(context).bottom + 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final active = index == currentIndex;
          return GestureDetector(
            onTap: () => context.go(item.route),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 52 : 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppColors.primary.withOpacity(0.18) : Colors.transparent,
                boxShadow: active ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 24)] : null,
              ),
              child: Icon(item.icon, color: active ? AppColors.primary : AppColors.textMuted, size: 22),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;
}
