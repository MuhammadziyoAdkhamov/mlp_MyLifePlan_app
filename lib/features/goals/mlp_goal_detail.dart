import 'package:flutter/material.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../core/design_system/mlp_liquid_glass.dart';
import '../../data/repositories/mlp_ui_repository.dart';
import '../../demo/demo_forms.dart';
import '../../demo/demo_store.dart';

class MLPGoalDetailScreen extends StatelessWidget {
  const MLPGoalDetailScreen({
    super.key,
    required this.store,
    required this.ui,
    required this.goalId,
    required this.onFocus,
  });
  final DemoStore store;
  final MLPLocalUiRepository ui;
  final String goalId;
  final ValueChanged<DemoTask> onFocus;

  Future<void> _action(
    BuildContext context,
    Future<void> Function() work,
  ) async {
    try {
      await work();
    } catch (_) {
      if (context.mounted) {
        MLPToast.show(context, 'O‘zgarish saqlanmadi. Qayta urinib ko‘ring.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([store, ui]),
    builder: (context, _) {
      final goal = store.goals.where((g) => g.id == goalId).firstOrNull;
      if (goal == null) {
        return const MLPScaffold(
          title: 'Maqsad',
          body: SingleChildScrollView(
            child: MLPEmptyState(
              title: 'Maqsad topilmadi',
              message:
                  'U o‘chirilgan bo‘lishi mumkin. Orqaga qaytib, boshqa maqsadni tanlang.',
            ),
          ),
        );
      }
      final plan = ui.goalPlan(goalId);
      final archived = plan?['archived'] == true;
      final tasks = store.tasks.where((t) => t.goalId == goalId).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      final done = tasks.where((t) => t.completed).length;
      final next = tasks.where((t) => !t.completed).firstOrNull;
      return MLPScaffold(
        title: 'Maqsad tafsilotlari',
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MLPGlassCard(
                      accent: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            archived
                                ? 'ARXIVLANGAN MAQSAD'
                                : goal.category.toUpperCase(),
                            style: const TextStyle(color: MLPColors.turquoise),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            goal.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 16),
                          Text('Muddat · ${DemoStore.dayKey(goal.deadline)}'),
                          const SizedBox(height: 16),
                          MLPProgressBar(
                            value: tasks.isEmpty ? 0 : done / tasks.length,
                            label: 'O‘z hisoboti bilan topshirilgan vazifalar',
                          ),
                          const SizedBox(height: 12),
                          Text('$done / ${tasks.length} vazifa · o‘z hisoboti'),
                          const SizedBox(height: 8),
                          Text(
                            'Qo‘lda kiritilgan natija: ${goal.current} / ${goal.target} ${goal.metric}. Bu mustaqil tekshirilgan ko‘nikma emas.',
                            style: const TextStyle(
                              color: MLPColors.secondaryText,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          MLPSecondaryButton(
                            label: 'Natijani qayd qilish',
                            onPressed: () =>
                                DemoForms.goalProgress(context, store, goal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (plan != null) ...[
                      MLPGlassCard(
                        child: Text(
                          'Kutilayotgan natija: ${plan['outcome'] ?? 'Kiritilmagan'}\nBoshlang‘ich holat: ${plan['startingLevel'] ?? 'Noma’lum'} · o‘z bahosi\nSabab: ${plan['reason'] ?? 'Kiritilmagan'}\n${plan['prototype'] == true ? 'Yo‘l xaritasi: tahrirlangan prototip reja.' : ''}',
                          style: const TextStyle(height: 1.7),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const MLPSectionHeader(title: 'Hozirgi bosqich'),
                    const SizedBox(height: 12),
                    if (next != null)
                      MLPGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              next.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${next.minutes} daqiqa · ${DemoStore.dayKey(next.dueDate)}',
                            ),
                            const SizedBox(height: 16),
                            MLPPrimaryButton(
                              label: 'Fokusni boshlash',
                              icon: Icons.play_arrow_rounded,
                              onPressed: archived ? null : () => onFocus(next),
                            ),
                          ],
                        ),
                      )
                    else
                      const MLPGlassCard(
                        child: Text(
                          'Ochiq vazifa yo‘q. Topshirilgan ishni baholash — alohida qadam.',
                        ),
                      ),
                    const SizedBox(height: 24),
                    const MLPSectionHeader(title: 'Yo‘l xaritasi va vazifalar'),
                    const SizedBox(height: 12),
                    if (tasks.isEmpty)
                      const MLPEmptyState(
                        title: 'Bosqichlar hali yo‘q',
                        message:
                            'Maqsadga bog‘langan birinchi vazifani kiriting.',
                      ),
                    ...List.generate(tasks.length, (i) {
                      final task = tasks[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MLPTaskCard(
                          title: '${i + 1}. ${task.title}',
                          subtitle:
                              '${DemoStore.dayKey(task.dueDate)} · ${task.minutes} daqiqa · ${task.completed ? 'O‘z hisoboti topshirilgan' : 'Kutilmoqda'}',
                          completed: task.completed,
                          onTap: () {
                            if (!task.completed) {
                              DemoForms.submit(context, store, task);
                            } else {
                              mlpShowDialog<void>(
                                context: context,
                                builder: (dialog) => AlertDialog(
                                  title: const Text('Topshirilgan hisobot'),
                                  content: SingleChildScrollView(
                                    child: SelectableText(
                                      '${task.proof}\n${task.evidenceUrl}\n\nBu o‘z hisoboti; mustaqil baholash tasdig‘i emas.',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialog),
                                      child: const Text('Yopish'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      );
                    }),
                    MLPSecondaryButton(
                      label: 'Bog‘langan vazifa qo‘shish',
                      icon: Icons.add,
                      onPressed: archived
                          ? null
                          : () => DemoForms.task(
                              context,
                              store,
                              initialGoalId: goalId,
                            ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        MLPSecondaryButton(
                          label: 'Maqsadni tahrirlash',
                          icon: Icons.edit_outlined,
                          onPressed: () =>
                              DemoForms.goal(context, store, existing: goal),
                        ),
                        MLPSecondaryButton(
                          label: archived ? 'Arxivdan chiqarish' : 'Arxivlash',
                          icon: Icons.archive_outlined,
                          onPressed: () async {
                            final yes = await MLPConfirmationSheet.show(
                              context,
                              title: archived
                                  ? 'Maqsad tiklansinmi?'
                                  : 'Maqsad arxivlansinmi?',
                              message:
                                  'Maqsad va vazifalar saqlanadi. Arxiv holatini keyin o‘zgartira olasiz.',
                            );
                            if (yes && context.mounted) {
                              await _action(
                                context,
                                () => ui.archiveGoal(goalId, !archived),
                              );
                            }
                          },
                        ),
                        MLPSecondaryButton(
                          label: 'Maqsadni o‘chirish',
                          icon: Icons.delete_outline,
                          onPressed: () async {
                            final yes = await MLPConfirmationSheet.show(
                              context,
                              title: 'Maqsad o‘chirilsinmi?',
                              message:
                                  'Bu amalni bekor qilib bo‘lmaydi. Bog‘langan vazifalar saqlanadi, lekin maqsadga bog‘lanish uziladi.',
                            );
                            if (!yes || !context.mounted) return;
                            await _action(context, () async {
                              await store.deleteGoal(goalId);
                              if (context.mounted &&
                                  Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
