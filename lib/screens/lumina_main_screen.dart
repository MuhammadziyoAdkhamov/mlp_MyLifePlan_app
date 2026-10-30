import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
// We will reuse this inside ActionTab
// We will reuse this inside ActionTab
import 'home_tab.dart';
import 'quests_tab.dart';
import 'action_tab.dart';
import 'wallet_tab.dart'; // We use WalletTab directly for ShopTab for now
import 'portfolio_tab.dart';

class LuminaMainScreen extends StatefulWidget {
  const LuminaMainScreen({super.key});

  @override
  State<LuminaMainScreen> createState() => _LuminaMainScreenState();
}

class _LuminaMainScreenState extends State<LuminaMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const QuestsTab(),
    const ActionTab(),
    const WalletTab(),
    const PortfolioTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.primary.withValues(alpha: 0.2),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                );
              }
              return const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
                label: 'Asosiy',
              ),
              NavigationDestination(
                icon: Icon(Icons.work_outline_rounded, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.work_rounded, color: AppColors.primary),
                label: 'Kvestlar',
              ),
              NavigationDestination(
                icon: Icon(Icons.bolt_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.bolt_rounded, color: AppColors.primary),
                label: 'Action',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.shopping_bag_rounded, color: AppColors.primary),
                label: 'Market',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                label: 'Karyera',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
