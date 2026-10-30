import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../domain/goal_model.dart';
import '../domain/roadmap_model.dart';

import '../../features/onboarding/welcome_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/goals/goal_setup_screen.dart';
import '../../features/goals/diagnosis_screen.dart';
import '../../features/roadmap/roadmap_preview_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/roadmap/roadmap_tab_screen.dart';
import '../../features/ustoz/ustoz_screen.dart';
import '../../features/natijalar/natijalar_screen.dart';
import '../../features/profil/profil_screen.dart';
import '../../features/learning/learning_screen.dart';

final mlpRouterProvider = Provider<GoRouter>((ref) {
  final isOnboarded = ref.watch(isOnboardedProvider);

  return GoRouter(
    initialLocation: isOnboarded ? '/home' : '/welcome',
    redirect: (context, state) {
      final onboarded = ref.read(isOnboardedProvider);
      final onWelcomePath = state.matchedLocation.startsWith('/welcome') ||
          state.matchedLocation.startsWith('/onboarding');
      if (!onboarded && !onWelcomePath) return '/welcome';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', name: 'welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/onboarding', name: 'onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/goal-setup', name: 'goal-setup', builder: (_, __) => const GoalSetupScreen()),
      GoRoute(
        path: '/diagnosis',
        name: 'diagnosis',
        builder: (_, s) => DiagnosisScreen(goal: s.extra as MlpGoal),
      ),
      GoRoute(
        path: '/roadmap-preview',
        name: 'roadmap-preview',
        builder: (_, s) => RoadmapPreviewScreen(roadmapId: s.extra as String),
      ),
      ShellRoute(
        builder: (context, state, child) => MlpShell(child: child),
        routes: [
          GoRoute(path: '/home', name: 'home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/roadmap', name: 'roadmap', builder: (_, __) => const RoadmapTabScreen()),
          GoRoute(path: '/ustoz', name: 'ustoz', builder: (_, __) => const UstozScreen()),
          GoRoute(path: '/natijalar', name: 'natijalar', builder: (_, __) => const NatijalarScreen()),
          GoRoute(path: '/profil', name: 'profil', builder: (_, __) => const ProfilScreen()),
        ],
      ),
      GoRoute(
        path: '/learning/:milestoneId',
        name: 'learning',
        builder: (_, s) => LearningScreen(
          milestoneId: s.pathParameters['milestoneId']!,
          milestone: s.extra as MlpMilestone,
        ),
      ),
    ],
  );
});

class MlpShell extends StatelessWidget {
  const MlpShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(icon: Icons.wb_sunny_outlined, activeIcon: Icons.wb_sunny_rounded, label: 'Bugun', path: '/home'),
    _TabItem(icon: Icons.map_outlined, activeIcon: Icons.map_rounded, label: 'Yo\'l xaritasi', path: '/roadmap'),
    _TabItem(icon: Icons.psychology_outlined, activeIcon: Icons.psychology_rounded, label: 'Ustoz', path: '/ustoz'),
    _TabItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Natijalar', path: '/natijalar'),
    _TabItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil', path: '/profil'),
  ];

  int _tabIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/roadmap')) return 1;
    if (location.startsWith('/ustoz')) return 2;
    if (location.startsWith('/natijalar')) return 3;
    if (location.startsWith('/profil')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabIndex(location);

    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: _MlpBottomNavBar(
        currentIndex: currentIndex,
        onTap: (i) => context.go(_tabs[i].path),
        tabs: _tabs,
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.activeIcon, required this.label, required this.path});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
}

class _MlpBottomNavBar extends StatelessWidget {
  const _MlpBottomNavBar({required this.currentIndex, required this.onTap, required this.tabs});
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_TabItem> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: 20, right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111836).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF26326A), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(tabs.length, (i) {
            final isActive = i == currentIndex;
            return _NavItem(
              tab: tabs[i], isActive: isActive,
              onTap: () => onTap(i),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.isActive, required this.onTap});
  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? tab.activeIcon : tab.icon,
                key: ValueKey(isActive),
                color: isActive ? const Color(0xFF7C5CFF) : const Color(0xFF64748B),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? const Color(0xFF7C5CFF) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
