import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/design/mlp_colors.dart';
import '../../core/design/mlp_text_styles.dart';
import '../../core/domain/goal_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/mlp_button.dart';

const _uuid = Uuid();

class GoalSetupScreen extends ConsumerStatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  ConsumerState<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends ConsumerState<GoalSetupScreen> {
  GoalCategory? _selectedCategory;
  final _customTitleCtrl = TextEditingController();
  final _outcomeCtrl = TextEditingController();
  GoalPriority _priority = GoalPriority.medium;
  double _minutesPerDay = 30;
  bool _isLoading = false;
  int _step = 0; // 0=category, 1=details

  bool get _isCustom => _selectedCategory == GoalCategory.custom;

  @override
  void dispose() {
    _customTitleCtrl.dispose();
    _outcomeCtrl.dispose();
    super.dispose();
  }

  String _goalTitle() {
    if (_isCustom) return _customTitleCtrl.text.trim();
    return _selectedCategory?.uzLabel ?? '';
  }

  Future<void> _submit() async {
    final title = _goalTitle();
    final outcome = _outcomeCtrl.text.trim();
    if (title.isEmpty || outcome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, barcha maydonlarni to\'ldiring')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final goal = MlpGoal(
      id: _uuid.v4(),
      title: title,
      outcome: outcome,
      category: _selectedCategory ?? GoalCategory.custom,
      priority: _priority,
      minutesPerDay: _minutesPerDay.toInt(),
      createdAt: DateTime.now(),
    );
    await ref.read(goalsProvider.notifier).addGoal(goal);
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.go('/diagnosis', extra: goal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MlpColors.bg1,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  if (_step > 0)
                    GestureDetector(
                      onTap: () => setState(() => _step = 0),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: MlpColors.text1, size: 20),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_step == 0 ? 'Maqsad tanlang' : 'Batafsil ma\'lumot',
                            style: MlpTextStyles.h2),
                        Text(_step == 0 ? 'Qaysi yo\'nalishda o\'smoqchisiz?' : 'Natijani aniq belgilang',
                            style: MlpTextStyles.body2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  _StepDot(isActive: _step == 0, isDone: _step > 0),
                  Expanded(child: Container(height: 2, color: _step > 0 ? MlpColors.purple : MlpColors.border)),
                  _StepDot(isActive: _step == 1, isDone: false),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _step == 0 ? _buildCategoryStep() : _DetailsStep(
                  category: _selectedCategory!,
                  customCtrl: _customTitleCtrl,
                  outcomeCtrl: _outcomeCtrl,
                  priority: _priority,
                  onPriorityChanged: (p) => setState(() => _priority = p),
                  minutesPerDay: _minutesPerDay,
                  onMinutesChanged: (v) => setState(() => _minutesPerDay = v),
                  isLoading: _isLoading,
                  onSubmit: _submit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStep() {
    return SingleChildScrollView(
      key: const ValueKey('cat'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: GoalCategory.values.map((cat) {
              final sel = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: sel ? MlpColors.purple.withValues(alpha: 0.2) : MlpColors.bg2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? MlpColors.purple : MlpColors.border,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(cat.uzLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: sel ? MlpColors.purpleLight : MlpColors.text2,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          MlpButton(
            label: 'Davom etish',
            icon: Icons.arrow_forward_rounded,
            onPressed: _selectedCategory == null ? null : () => setState(() => _step = 1),
          ),
        ],
      ),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.category, required this.customCtrl, required this.outcomeCtrl,
    required this.priority, required this.onPriorityChanged,
    required this.minutesPerDay, required this.onMinutesChanged,
    required this.isLoading, required this.onSubmit,
  });
  final GoalCategory category;
  final TextEditingController customCtrl, outcomeCtrl;
  final GoalPriority priority;
  final ValueChanged<GoalPriority> onPriorityChanged;
  final double minutesPerDay;
  final ValueChanged<double> onMinutesChanged;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('details'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category == GoalCategory.custom) ...[
            Text('Maqsad nomi', style: MlpTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: customCtrl,
              style: const TextStyle(color: MlpColors.text1),
              decoration: const InputDecoration(hintText: 'Masalan: Gitara chalishni o\'rganish'),
            ),
            const SizedBox(height: 20),
          ],
          Text('Kutilayotgan natija', style: MlpTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: outcomeCtrl,
            maxLines: 3,
            style: const TextStyle(color: MlpColors.text1),
            decoration: InputDecoration(
              hintText: '${category.uzLabel} bo\'yicha erishmoqchi bo\'lgan natijangiz...',
            ),
          ),
          const SizedBox(height: 24),
          Text('Ustuvorlik', style: MlpTextStyles.label),
          const SizedBox(height: 12),
          Row(
            children: GoalPriority.values.map((p) {
              final labels = {GoalPriority.high: 'Yuqori', GoalPriority.medium: 'O\'rta', GoalPriority.low: 'Past'};
              final colors = {GoalPriority.high: MlpColors.error, GoalPriority.medium: MlpColors.warning, GoalPriority.low: MlpColors.success};
              final isSelected = priority == p;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onPriorityChanged(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? colors[p]!.withValues(alpha: 0.2) : MlpColors.bg2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? colors[p]! : MlpColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      labels[p]!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? colors[p] : MlpColors.text3,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kunlik vaqt', style: MlpTextStyles.label),
              Text('${minutesPerDay.toInt()} daqiqa',
                  style: MlpTextStyles.body2.copyWith(color: MlpColors.purpleLight, fontWeight: FontWeight.w700)),
            ],
          ),
          Slider(
            value: minutesPerDay, min: 15, max: 120, divisions: 7,
            activeColor: MlpColors.purple, inactiveColor: MlpColors.bg4,
            onChanged: onMinutesChanged,
          ),
          const SizedBox(height: 32),
          MlpButton(
            label: 'AI Diagnostika',
            icon: Icons.psychology_rounded,
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.isActive, required this.isDone});
  final bool isActive, isDone;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (isActive || isDone) ? MlpColors.purple : MlpColors.bg3,
        border: Border.all(color: isActive ? MlpColors.purpleLight : MlpColors.border),
      ),
      child: isDone ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
    );
  }
}
