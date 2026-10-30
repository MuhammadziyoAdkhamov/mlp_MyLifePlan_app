import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/app_state.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>().profile;
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Lives and Streak
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Xush kelibsiz,', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    Text(
                      profile.name,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildStatBadge(Icons.favorite_rounded, AppColors.rose, '3', 'Jon'),
                    const SizedBox(width: 12),
                    _buildStatBadge(Icons.local_fire_department_rounded, AppColors.gold, '12', 'Kun'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Staking Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Garov (Staking) faol', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: 4),
                        Text('50 Coin garovga tikilgan. Rejani buzsangiz, tangalar kuyadi!', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // AI Sprints
            const Text('AI Dekompozitsiya', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Sizning 1 yillik maqsadingiz mikro-vazifalarga bo\'lindi', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 16),
            
            _buildSprintCard('Flutter: State Management', 'Bugun soat 20:00 da', '45 min', true),
            const SizedBox(height: 12),
            _buildSprintCard('GitHub Repository yaratish', 'Bugun soat 21:00 da', '15 min', false),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSprintCard(String title, String time, String duration, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPrimary ? AppColors.primary.withValues(alpha: 0.5) : AppColors.surface2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.bolt_rounded, color: isPrimary ? AppColors.primary : AppColors.textMuted),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text('$time • $duration', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
