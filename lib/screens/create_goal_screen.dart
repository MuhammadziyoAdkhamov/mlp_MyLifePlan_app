import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../core/app_colors.dart';
import '../models/learning_goal.dart';
import '../widgets/gradient_button.dart';
import '../widgets/premium_scaffold.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _titleController = TextEditingController();
  final _outcomeController = TextEditingController();
  
  String _currentLevel = 'Beginner (Boshlang\'ich)';
  double _minutesPerDay = 30;


  @override
  void dispose() {
    _titleController.dispose();
    _outcomeController.dispose();
    super.dispose();
  }

  void _proceedToDiagnostic() {
    if (_titleController.text.trim().isEmpty || _outcomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, barcha maydonlarni to‘ldiring')),
      );
      return;
    }

    final goal = LearningGoal(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      outcome: _outcomeController.text.trim(),
      currentLevel: _currentLevel,
      availableMinutesPerDay: _minutesPerDay.toInt(),
      createdAt: DateTime.now(),
    );

    // Pass the goal directly as an extra to the diagnostic screen
    context.push('/diagnostic', extra: goal);
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Yangi maqsad',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              Text(
                'Nima o‘rganmoqchisiz?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Masalan: Flutter, Ingliz tili (IELTS 7.0)...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
              
              const SizedBox(height: 28),
              
              Text(
                'Natija qanday bo‘lishini xohlaysiz?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _outcomeController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Masalan: Kichik mobil ilovalar yarata olish yoki erkin gaplashish...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),

              const SizedBox(height: 28),
              Text(
                'Hozirgi bilim darajangiz:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  'Beginner (Boshlang\'ich)',
                  'Intermediate (O\'rta)',
                  'Advanced (Kuchli)'
                ].map((level) {
                  final isSelected = _currentLevel == level;
                  return GestureDetector(
                    onTap: () => setState(() => _currentLevel = level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        level,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kunda qancha vaqt ajratasiz?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${_minutesPerDay.toInt()} daq',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _minutesPerDay,
                min: 15,
                max: 180,
                divisions: 11,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.surface2,
                onChanged: (val) => setState(() => _minutesPerDay = val),
              ),

              const SizedBox(height: 48),
              GradientButton(
                text: 'AI Ustoz bilan analiz qilish',
                icon: Icons.psychology_rounded,
                onPressed: _proceedToDiagnostic,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
