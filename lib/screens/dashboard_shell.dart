import 'package:flutter/material.dart';

import '../widgets/bottom_nav_bar.dart';
import '../widgets/premium_scaffold.dart';
import 'home_screen.dart';
import 'roadmap_screen.dart';
import 'learning_screen.dart';
import 'ai_tutor_screen.dart';
import 'profile_screen.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      padding: EdgeInsets.zero,
      body: IndexedStack(
        index: index,
        children: const [
          HomeScreen(),
          RoadmapScreen(),
          LearningScreen(),
          AiTutorScreen(),
          ProfileScreen(),
        ],
      ),
      safeArea: false,
      bottomNavigationBar: AppBottomNavBar(currentIndex: index),
    );
  }
}
