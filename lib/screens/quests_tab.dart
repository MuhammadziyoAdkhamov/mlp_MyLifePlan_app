import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class QuestsTab extends StatelessWidget {
  const QuestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Kvestlar', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ),
            ),
            const TabBar(
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              dividerColor: AppColors.surface,
              tabs: [
                Tab(text: 'HR Kvestlar (B2B)'),
                Tab(text: 'EdTech Vaucherlar'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildHRQuests(),
                  _buildEdTechVouchers(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHRQuests() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildQuestCard(
          company: 'EPAM Systems',
          role: 'Junior Flutter Developer',
          task: 'Rest API ulab, kichik E-commerce app yozish',
          reward: 'To\'g\'ridan-to\'g\'ri intervyu',
          icon: Icons.work_outline_rounded,
        ),
        const SizedBox(height: 16),
        _buildQuestCard(
          company: 'Uzum Market',
          role: 'Frontend stajor',
          task: 'Figma dizaynini React\'da terish',
          reward: 'Pullik amaliyot',
          icon: Icons.shopping_bag_outlined,
        ),
      ],
    );
  }

  Widget _buildEdTechVouchers() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildQuestCard(
          company: 'Najot Ta\'lim',
          role: '10% Chegirma',
          task: 'Flutter foundation kursini boshlash uchun 500 Coin yig\'ing',
          reward: 'Lead Gen',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 16),
        _buildQuestCard(
          company: 'Mohirdev',
          role: 'Bepul 1 oylik obuna',
          task: 'Python backend kvestini tugating',
          reward: 'Vaucher',
          icon: Icons.computer_rounded,
        ),
      ],
    );
  }

  Widget _buildQuestCard({required String company, required String role, required String task, required String reward, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(role, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(task, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.emerald.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('Mukofot: $reward', style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
