import 'package:go_router/go_router.dart';

import '../screens/add_habit_screen.dart';
import '../screens/create_goal_screen.dart';
import '../screens/dashboard_shell.dart';
import '../screens/diagnostic_screen.dart';
import '../screens/habit_detail_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/xp_level_screen.dart';
import '../models/learning_goal.dart';

class AppRouter {
  const AppRouter._();

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardShell(index: 0)),
      GoRoute(
          path: '/roadmap',
          builder: (context, state) => const DashboardShell(index: 1)),
      GoRoute(
          path: '/learning',
          builder: (context, state) => const DashboardShell(index: 2)),
      GoRoute(
          path: '/ai-tutor',
          builder: (context, state) => const DashboardShell(index: 3)),
      GoRoute(
          path: '/profile',
          builder: (context, state) => const DashboardShell(index: 4)),
      GoRoute(
          path: '/add-habit',
          builder: (context, state) => const AddHabitScreen()),
      GoRoute(
          path: '/create-goal',
          builder: (context, state) => const CreateGoalScreen()),
      GoRoute(
        path: '/diagnostic',
        builder: (context, state) => DiagnosticScreen(goal: state.extra as LearningGoal),
      ),
      GoRoute(
        path: '/habit/:id',
        builder: (context, state) =>
            HabitDetailScreen(habitId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(path: '/xp', builder: (context, state) => const XPLevelScreen()),
      GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen()),
    ],
  );
}
