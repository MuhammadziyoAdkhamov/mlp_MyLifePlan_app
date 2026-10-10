import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/progress_ring.dart';
import '../widgets/xp_history_tile.dart';

class XPLevelScreen extends StatelessWidget {
  const XPLevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return PremiumScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            AppHeader(
              title: 'Level ${app.level}',
              subtitle: 'Growth Seeker',
              leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
            ),
            const SizedBox(height: 24),
            GlassCard(
              glowColor: AppColors.primary,
              child: Column(
                children: [
                  ProgressRing(
                    progress: app.levelProgress,
                    size: 170,
                    strokeWidth: 14,
                    center: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 42)],
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, size: 46, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('${app.xpInCurrentLevel}/1000 XP', style: Theme.of(context).textTheme.titleLarge),
                  Text('${1000 - app.xpInCurrentLevel} XP to next level', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('XP History', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                children: app.xpHistory.take(18).map((item) => XPHistoryTile(item: item)).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
