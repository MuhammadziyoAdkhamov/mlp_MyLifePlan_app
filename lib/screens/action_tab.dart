import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'focus_tab.dart';
import 'scanner_tab.dart';

class ActionTab extends StatelessWidget {
  const ActionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Fokus Taymer'),
                    Tab(text: 'QR Check-in'),
                  ],
                ),
              ),
            ),
          ),
          const Expanded(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(), // Prevent swipe while scanning
              children: [
                FocusTab(),
                ScannerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
