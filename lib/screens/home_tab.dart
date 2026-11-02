import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/mlp_design_system.dart';
import '../core/design_system/mlp_liquid_glass.dart';
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
            // Top Bar: Lives and Streak with glass effect
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Xush kelibsiz,',
                      style: TextStyle(
                        color: MLPColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      profile.name,
                      style: const TextStyle(
                        color: MLPColors.text,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildStatBadge(
                      Icons.favorite_rounded,
                      MLPColors.error,
                      '3',
                      'Jon',
                    ),
                    const SizedBox(width: 12),
                    _buildStatBadge(
                      Icons.local_fire_department_rounded,
                      MLPColors.warning,
                      '12',
                      'Kun',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Staking Section with floating glass effect
            MLPLiquidSurface(
              radius: 24,
              tint: MLPColors.primary.withValues(alpha: 0.15),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      MLPColors.primary.withValues(alpha: 0.25),
                      MLPColors.turquoise.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: MLPColors.turquoise,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Garov (Staking) faol',
                            style: TextStyle(
                              color: MLPColors.text,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '50 Coin garovga tikilgan. Rejani buzsangiz, tangalar kuyadi!',
                            style: TextStyle(
                              color: MLPColors.secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // AI Sprints
            const Text(
              'AI Dekompozitsiya',
              style: TextStyle(
                color: MLPColors.text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sizning 1 yillik maqsadingiz mikro-vazifalarga bo\'lindi',
              style: TextStyle(
                color: MLPColors.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildSprintCard(
              'Flutter: State Management',
              'Bugun soat 20:00 da',
              '45 min',
              true,
            ),
            const SizedBox(height: 12),
            _buildSprintCard(
              'GitHub Repository yaratish',
              'Bugun soat 21:00 da',
              '15 min',
              false,
            ),
            const SizedBox(height: 100), // Bottom padding for navigation
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, Color color, String value, String label) {
    return MLPLiquidSurface(
      radius: 12,
      blur: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: MLPColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSprintCard(String title, String time, String duration, bool isPrimary) {
    return MLPLiquidSurface(
      radius: 20,
      tint: isPrimary ? MLPColors.primary.withValues(alpha: 0.08) : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: isPrimary
                        ? const LinearGradient(
                            colors: [MLPColors.turquoise, MLPColors.primary],
                          )
                        : null,
                    color: isPrimary
                        ? null
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: isPrimary ? MLPColors.text : MLPColors.secondaryText,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: MLPColors.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: MLPColors.secondaryText,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$time • $duration',
                            style: const TextStyle(
                              color: MLPColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: MLPColors.secondaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
