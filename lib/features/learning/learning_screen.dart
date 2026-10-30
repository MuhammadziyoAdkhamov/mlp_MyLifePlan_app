import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/mlp_colors.dart';
import '../../core/design/mlp_text_styles.dart';
import '../../core/domain/lesson_model.dart';
import '../../core/domain/roadmap_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/mock_data.dart';
import '../../core/widgets/mlp_button.dart';
import '../../core/widgets/mlp_card.dart';
import '../../core/widgets/xp_chip.dart';

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key, required this.milestoneId, required this.milestone});
  final String milestoneId;
  final MlpMilestone milestone;

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  late List<MlpLesson> _lessons;
  int _lessonIndex = 0;
  int _step = 0; // 0=read, 1=practice, 2=success
  int? _selectedAnswer;
  final _answerCtrl = TextEditingController();
  bool _showFeedback = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _lessons = MockData.lessonsForMilestone(widget.milestoneId, widget.milestone.title);
  }

  MlpLesson get _lesson => _lessons[_lessonIndex];

  Future<void> _submitAnswer() async {
    final q = _lesson.questions.firstOrNull;
    bool correct = true;
    if (q != null && q.type == QuestionType.multipleChoice) {
      correct = _selectedAnswer == q.correctIndex;
    } else if (_answerCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, ko\'proq yozing (kamida 10 belgi)')),
      );
      return;
    }
    setState(() { _showFeedback = true; _isCorrect = correct; });
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    await ref.read(userProvider.notifier).earnXp(_lesson.xpReward, label: _lesson.title);
    setState(() { _step = 2; });
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MlpColors.bg1,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.close_rounded, color: MlpColors.text2, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(widget.milestone.title, style: MlpTextStyles.h4,
                        overflow: TextOverflow.ellipsis),
                  ),
                  XpChip(xp: _lesson.xpReward),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= _step ? MlpColors.purple : MlpColors.bg4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _step == 0
                    ? _ReadStep(lesson: _lesson, onContinue: () => setState(() => _step = 1))
                    : _step == 1
                        ? _PracticeStep(
                            lesson: _lesson,
                            selectedAnswer: _selectedAnswer,
                            onAnswerSelect: (i) => setState(() => _selectedAnswer = i),
                            answerCtrl: _answerCtrl,
                            showFeedback: _showFeedback,
                            isCorrect: _isCorrect,
                            onSubmit: _submitAnswer,
                          )
                        : _SuccessStep(
                            xp: _lesson.xpReward,
                            onNext: () {
                              if (_lessonIndex < _lessons.length - 1) {
                                setState(() {
                                  _lessonIndex++;
                                  _step = 0;
                                  _selectedAnswer = null;
                                  _showFeedback = false;
                                  _answerCtrl.clear();
                                });
                              } else {
                                context.pop();
                              }
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadStep extends StatelessWidget {
  const _ReadStep({required this.lesson, required this.onContinue});
  final MlpLesson lesson;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lesson.title, style: MlpTextStyles.h3),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: MlpColors.text3, size: 14),
              const SizedBox(width: 4),
              Text('~${lesson.estimatedMinutes} daqiqa', style: MlpTextStyles.caption),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: MlpColors.bg2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MlpColors.border),
            ),
            child: Text(lesson.content, style: MlpTextStyles.body1),
          ),
          const SizedBox(height: 24),
          MlpButton(
            label: 'Amaliyotga o\'tish',
            icon: Icons.arrow_forward_rounded,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _PracticeStep extends StatelessWidget {
  const _PracticeStep({
    required this.lesson, required this.selectedAnswer,
    required this.onAnswerSelect, required this.answerCtrl,
    required this.showFeedback, required this.isCorrect, required this.onSubmit,
  });
  final MlpLesson lesson;
  final int? selectedAnswer;
  final ValueChanged<int> onAnswerSelect;
  final TextEditingController answerCtrl;
  final bool showFeedback, isCorrect;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final q = lesson.questions.firstOrNull;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MlpCard(
            color: MlpColors.purple.withValues(alpha: 0.1),
            border: Border.all(color: MlpColors.purple.withValues(alpha: 0.3)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.task_rounded, color: MlpColors.purpleLight, size: 18),
                    SizedBox(width: 8),
                    Text('Amaliy vazifa', style: TextStyle(color: MlpColors.purpleLight, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(lesson.practicalTask, style: MlpTextStyles.body1),
              ],
            ),
          ),
          if (q != null) ...[
            const SizedBox(height: 20),
            Text(q.question, style: MlpTextStyles.h4),
            const SizedBox(height: 14),
            if (q.type == QuestionType.multipleChoice)
              ...q.options.asMap().entries.map((e) {
                final isSelected = selectedAnswer == e.key;
                Color? feedbackColor;
                if (showFeedback && isSelected) feedbackColor = isCorrect ? MlpColors.success : MlpColors.error;
                return GestureDetector(
                  onTap: showFeedback ? null : () => onAnswerSelect(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: feedbackColor?.withValues(alpha: 0.2) ?? (isSelected ? MlpColors.purple.withValues(alpha: 0.2) : MlpColors.bg2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: feedbackColor ?? (isSelected ? MlpColors.purple : MlpColors.border),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(e.value, style: MlpTextStyles.body2.copyWith(
                      color: isSelected ? MlpColors.text1 : MlpColors.text2,
                    )),
                  ),
                );
              })
            else
              TextField(
                controller: answerCtrl,
                maxLines: 4,
                style: const TextStyle(color: MlpColors.text1),
                decoration: const InputDecoration(hintText: 'Javobingizni yozing...'),
              ),
          ],
          if (showFeedback && q != null) ...[
            const SizedBox(height: 12),
            MlpCard(
              color: isCorrect ? MlpColors.success.withValues(alpha: 0.1) : MlpColors.error.withValues(alpha: 0.1),
              border: Border.all(color: isCorrect ? MlpColors.success : MlpColors.error),
              child: Row(
                children: [
                  Icon(isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
                      color: isCorrect ? MlpColors.success : MlpColors.error),
                  const SizedBox(width: 10),
                  Expanded(child: Text(q.explanation, style: MlpTextStyles.body2)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (!showFeedback)
            MlpButton(label: 'Javobni topshirish', icon: Icons.check_rounded, onPressed: onSubmit),
        ],
      ),
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({required this.xp, required this.onNext});
  final int xp;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [MlpColors.purple, MlpColors.blue]),
            ),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 52),
          ),
          const SizedBox(height: 24),
          Text('Ajoyib!', style: MlpTextStyles.h1),
          const SizedBox(height: 8),
          Text('Dars muvaffaqiyatli yakunlandi', style: MlpTextStyles.body2),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [MlpColors.purple, MlpColors.blue]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('+$xp XP', style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800,
            )),
          ),
          const SizedBox(height: 40),
          MlpButton(label: 'Davom etish', icon: Icons.arrow_forward_rounded, onPressed: onNext),
        ],
      ),
    );
  }
}
