import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  int _step = 0;
  bool _isLoading = false;

  Future<void> _completeLesson() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    
    final app = context.read<AppState>();
    if (app.learningRoadmaps.isEmpty) return;

    final roadmap = app.learningRoadmaps.last;
    final stageIndex = roadmap.stages.indexWhere((s) => !s.isCompleted);
    
    if (stageIndex != -1) {
      final updatedStage = roadmap.stages[stageIndex].copyWith(isCompleted: true);
      final updatedStages = List.of(roadmap.stages);
      updatedStages[stageIndex] = updatedStage;
      
      final updatedRoadmap = roadmap.copyWith(stages: updatedStages);
      final updatedRoadmaps = List.of(app.learningRoadmaps);
      updatedRoadmaps[updatedRoadmaps.length - 1] = updatedRoadmap;
      
      app.learningRoadmaps = updatedRoadmaps;
      
      // We earn some XP for completing a learning stage
      await app.earnCoins(100, '${updatedStage.title} bosqichi tugatildi');
      // For XP we could add a method to AppState or just wait for dual-write implementation.
    }
    
    setState(() {
      _isLoading = false;
      _step = 2; // Success screen
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final hasRoadmap = app.learningRoadmaps.isNotEmpty;

    if (!hasRoadmap) {
      return const SafeArea(
        child: Center(
          child: Text('Avval Yo‘l xaritasi bo‘limida maqsad yarating.'),
        ),
      );
    }

    final roadmap = app.learningRoadmaps.last;
    final stageIndex = roadmap.stages.indexWhere((s) => !s.isCompleted);

    if (stageIndex == -1) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 64),
              const SizedBox(height: 16),
              Text('Tabriklaymiz!', style: Theme.of(context).textTheme.headlineMedium),
              const Text('Barcha bosqichlarni tugatdingiz.'),
            ],
          ),
        ),
      );
    }

    final stage = roadmap.stages[stageIndex];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: AppHeader(
              title: 'O‘rganish: ${stage.title}',
              subtitle: 'Faol dars: ${stage.objective}',
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_step == 0) ...[
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.menu_book_rounded, color: AppColors.cyan),
                              SizedBox(width: 8),
                              Text('Dars qismi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'AI Ustoz materialni moslashtirdi:\n\nSiz kiritgan darajaga mos tarzda ushbu mavzu asoslarini o‘rganamiz. Bu bosqichda siz ${stage.objective}ni to‘liq o‘zlashtirishingiz kutiladi.\n\nYodda tuting: Faqatgina o‘qish emas, balki amaliyot ham juda muhim.',
                            style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.9), fontSize: 15, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          GradientButton(
                            text: 'Davom etish (Tushundim)',
                            onPressed: () => setState(() => _step = 1),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_step == 1) ...[
                    GlassCard(
                      glowColor: AppColors.emerald,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.quiz_rounded, color: AppColors.emerald),
                              SizedBox(width: 8),
                              Text('Tekshirish (Assessment)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bilasizmi? Qabul qilingan ma\'lumotni darhol eslab qolish 70% gacha xotirani kuchaytiradi. Sizdan qisqacha savol:\n\nSiz nima uchun aynan shu maqsadni qo‘ydingiz?',
                            style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.9), fontSize: 15, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            maxLines: 4,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'O‘z so‘zlaringiz bilan tushuntiring...',
                              hintStyle: const TextStyle(color: AppColors.textMuted),
                              filled: true,
                              fillColor: AppColors.surface2,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator(color: AppColors.emerald))
                          else
                            GradientButton(
                              text: 'Javobni topshirish',
                              icon: Icons.check_circle_rounded,
                              colors: const [AppColors.emerald, Color(0xFF00C853)],
                              onPressed: _completeLesson,
                            ),
                        ],
                      ),
                    ),
                  ] else if (_step == 2) ...[
                    GlassCard(
                      glowColor: AppColors.gold,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.gold, size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'Muvaffaqiyat!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Siz "${stage.title}" bosqichini muvaffaqiyatli yakunladingiz va 100 coin ishladingiz!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          GradientButton(
                            text: 'Yo‘l xaritasiga qaytish',
                            onPressed: () {
                              setState(() => _step = 0);
                              context.go('/roadmap');
                            },
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
