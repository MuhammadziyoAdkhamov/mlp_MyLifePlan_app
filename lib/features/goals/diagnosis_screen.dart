import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/mlp_colors.dart';
import '../../core/design/mlp_text_styles.dart';
import '../../core/domain/goal_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/mock_data.dart';
import '../../core/widgets/mlp_button.dart';

class DiagnosisScreen extends ConsumerStatefulWidget {
  const DiagnosisScreen({super.key, required this.goal});
  final MlpGoal goal;

  @override
  ConsumerState<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends ConsumerState<DiagnosisScreen> {
  int _questionIndex = 0;
  final Map<int, int> _answers = {};
  bool _isDone = false;
  bool _isGenerating = false;

  static List<Map<String, dynamic>> _questions(MlpGoal goal) => [
    {
      'q': '${goal.title} sohasida qancha tajribangiz bor?',
      'options': ['Umuman yo\'q', '1-3 oy', '3-12 oy', '1+ yil'],
    },
    {
      'q': 'Kuniga qancha vaqt ajrata olasiz?',
      'options': ['15 daqiqa', '30 daqiqa', '1 soat', '2+ soat'],
    },
    {
      'q': 'Qanday o\'rganish uslubini afzal ko\'rasiz?',
      'options': ['Video darslar', 'Kitob o\'qish', 'Amaliyot qilish', 'Murabbiy bilan'],
    },
  ];

  Future<void> _generateRoadmap() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 1));
    final roadmap = MockData.generateRoadmap(widget.goal);
    await ref.read(roadmapsProvider.notifier).addRoadmap(roadmap);
    await ref.read(goalsProvider.notifier).updateGoal(
      widget.goal.copyWith(roadmapId: roadmap.id),
    );
    await ref.read(userProvider.notifier).earnXp(30, label: 'Diagnostika yakunlandi');
    if (!mounted) return;
    context.go('/roadmap-preview', extra: roadmap.id);
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions(widget.goal);

    return Scaffold(
      backgroundColor: MlpColors.bg1,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: MlpColors.text1, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Diagnostika', style: MlpTextStyles.h3),
                        Text(widget.goal.title, style: MlpTextStyles.body2),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MlpColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('DEMO', style: TextStyle(color: MlpColors.warning, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (!_isDone) ...[
                Row(
                  children: List.generate(questions.length, (i) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < questions.length - 1 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: i <= _questionIndex ? MlpColors.purple : MlpColors.bg4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                Text(
                  'Savol ${_questionIndex + 1}/${questions.length}',
                  style: MlpTextStyles.label.copyWith(color: MlpColors.purpleLight),
                ),
                const SizedBox(height: 12),
                Text(questions[_questionIndex]['q'] as String, style: MlpTextStyles.h3),
                const SizedBox(height: 24),
                ...(questions[_questionIndex]['options'] as List<String>).asMap().entries.map((e) {
                  final isSelected = _answers[_questionIndex] == e.key;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _answers[_questionIndex] = e.key);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (!mounted) return;
                        if (_questionIndex < questions.length - 1) {
                          setState(() => _questionIndex++);
                        } else {
                          setState(() => _isDone = true);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? MlpColors.purple.withValues(alpha: 0.2) : MlpColors.bg2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? MlpColors.purple : MlpColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? MlpColors.purple : Colors.transparent,
                              border: Border.all(color: isSelected ? MlpColors.purple : MlpColors.border),
                            ),
                            child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                          ),
                          const SizedBox(width: 14),
                          Text(e.value, style: MlpTextStyles.body1.copyWith(
                            color: isSelected ? MlpColors.text1 : MlpColors.text2,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          )),
                        ],
                      ),
                    ),
                  );
                }),
              ] else ...[
                const Spacer(),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [MlpColors.purple, MlpColors.blue]),
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 24),
                      Text('Diagnostika tugadi!', style: MlpTextStyles.h2),
                      const SizedBox(height: 12),
                      Text(
                        'AI sizning darajangizni tahlil qildi va\nshaxsiy yo\'l xaritasini tuzmoqda...',
                        textAlign: TextAlign.center,
                        style: MlpTextStyles.body2,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                MlpButton(
                  label: 'Yo\'l xaritasini ko\'rish',
                  icon: Icons.map_rounded,
                  isLoading: _isGenerating,
                  onPressed: _generateRoadmap,
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
