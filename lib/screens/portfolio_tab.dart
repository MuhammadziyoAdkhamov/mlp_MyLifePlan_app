import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/app_state.dart';

class PortfolioTab extends StatelessWidget {
  const PortfolioTab({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>().profile;
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Karyera Pasporti', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
            
            // Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.surface2),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      profile.name[0].toUpperCase(),
                      style: const TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(profile.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Junior Flutter Developer', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.surface2),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('320', 'Soat Fokus'),
                      _buildStat('12', 'Loyihalar'),
                      _buildStat('4.9', 'Reyting'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Integrations
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Tasdiqlangan Ko\'nikmalar', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            _buildIntegrationCard('GitHub', '24 commits this week', Icons.code_rounded, AppColors.emerald),
            const SizedBox(height: 12),
            _buildIntegrationCard('LeetCode', 'Top 15%', Icons.terminal_rounded, AppColors.gold),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                label: const Text('CV PDF yuklab olish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildIntegrationCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.emerald),
        ],
      ),
    );
  }
}
