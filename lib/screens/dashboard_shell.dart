import 'package:flutter/material.dart';

import '../widgets/bottom_nav_bar.dart';
import '../widgets/premium_scaffold.dart';
import 'badges_screen.dart';
import 'home_screen.dart';
import 'journey_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const StatisticsScreen(),
      const JourneyScreen(),
      const BadgesScreen(),
      const ProfileScreen(),
    ];
    return PremiumScaffold(
      padding: EdgeInsets.zero,
      body: pages[index],
      safeArea: false,
      bottomNavigationBar: AppBottomNavBar(currentIndex: index),
    );
  }
}
