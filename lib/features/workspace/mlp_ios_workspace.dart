part of 'mlp_workspace_pages.dart';

/// Reference-led home: one current task, next actions and contextual help.
class MLPTodayPage extends StatefulWidget {
  const MLPTodayPage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  State<MLPTodayPage> createState() => _ReferenceTodayState();
}

class _ReferenceTodayState extends State<MLPTodayPage> {
  DateTime? selected;
  MLPEnvironment get e => widget.e;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([e.store, e.ui]),
    builder: (context, _) {
      final day = selected ?? e.store.today;
      final pending =
          (selected == null
                  ? e.store.todayTasks
                  : e.store.tasks.where(
                      (t) => mlpDayKey(t.dueDate) == mlpDayKey(day),
                    ))
              .where((t) => !t.completed)
              .toList()
            ..sort(_priorityOrder);
      final current = pending.firstOrNull;
      const weekdays = [
        'Dushanba',
        'Seshanba',
        'Chorshanba',
        'Payshanba',
        'Juma',
        'Shanba',
        'Yakshanba',
      ];
      const months = [
        'yanvar',
        'fevral',
        'mart',
        'aprel',
        'may',
        'iyun',
        'iyul',
        'avgust',
        'sentabr',
        'oktabr',
        'noyabr',
        'dekabr',
      ];
      return MLPPage(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salom, ${e.ui.profile?.name ?? 'Do‘stim'} 👋',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bugun',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.9,
                      ),
                    ),
                  ],
                ),
              ),
              MLPCircleAction(
                label: 'Mening profilim',
                icon: CupertinoIcons.person_fill,
                filled: false,
                size: 52,
                onPressed: () => e.go(MLPScreen.profile),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${weekdays[day.weekday - 1]}, ${day.day}-${months[day.month - 1]}',
            style: const TextStyle(
              color: MLPColors.secondaryText,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 18),
          MLPWeekStrip(
            selected: day,
            onChanged: (date) => setState(() => selected = date),
          ),
          const SizedBox(height: 18),
          if (current != null)
            MLPLiquidSurface(
              radius: 24,
              tint: const Color(0xFF283E83),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 14, color: Color(0xFF00E5FF)),
                            SizedBox(width: 4),
                            Text(
                              'Bugungi eng muhim vazifa',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Hozirgi vazifa',
                        style: TextStyle(color: MLPColors.secondaryText, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          current.title,
                          style: const TextStyle(
                            fontSize: 21,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (MediaQuery.sizeOf(context).width >= 380 &&
                          MediaQuery.textScalerOf(context).scale(1) <= 1.3) ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 70,
                          height: 82,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white38),
                            gradient: const LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Color(0xFF85C6FF),
                                Color(0xFF2949BB),
                                Color(0xFF7837DA),
                              ],
                            ),
                          ),
                          child: Icon(
                            current.project.toLowerCase().contains('flutter')
                                ? Icons.flutter_dash
                                : CupertinoIcons.folder,
                            color: const Color(0xFF89EDFF),
                            size: 42,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  _IosMetadata(
                    icon: CupertinoIcons.folder,
                    text: current.project,
                  ),
                  const SizedBox(height: 10),
                  _IosMetadata(
                    icon: CupertinoIcons.clock,
                    text: '${current.minutes} daqiqa',
                  ),
                  const SizedBox(height: 22),
                  MLPPrimaryButton(
                    label: 'Fokusni boshlash',
                    icon: CupertinoIcons.play_fill,
                    onPressed: () => mlpStartTask(context, e, current),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => mlpStartTask(context, e, current, minutes: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131D38),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, size: 15, color: Color(0xFF00E5FF)),
                            SizedBox(width: 6),
                            Text(
                              '5 daqiqalik variant',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (current != null)
            Center(
              child: TextButton(
                onPressed: () => mlpTaskActions(context, e, current),
                child: const Text('Vazifani ko‘rish  ›'),
              ),
            )
          else
            MLPEmptyState(
              title: 'Bugungi reja tayyor',
              message: 'Yangi vazifa qo‘shing yoki rejangizni ko‘rib chiqing.',
              action: 'Vazifa qo‘shish',
              onAction: () => DemoForms.task(context, e.store),
            ),
          if (current != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: MLPMenuTile(
                title: '5 daqiqalik variant',
                subtitle: 'Shu vazifaning birinchi qadami',
                icon: CupertinoIcons.timer,
                onTap: () => mlpStartTask(context, e, current, minutes: 5),
              ),
            ),
          const SizedBox(height: 16),
          MLPSectionHeader(
            title: 'Keyin',
            action: 'Barchasini ko‘rish',
            onAction: () => e.tab(3),
          ),
          const SizedBox(height: 12),
          if (pending.length < 2)
            const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: Text(
                'Boshqa shoshilinch vazifa yo‘q.',
                style: TextStyle(color: MLPColors.secondaryText),
              ),
            ),
          for (final task in pending.skip(1).take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _IosTaskTile(e: e, task: task, compact: true),
            ),
          if (!e.ui.assistantHidden) ...[
            const SizedBox(height: 4),
            MLPMenuTile(
              title: 'Yordam kerakmi?',
              subtitle: 'Ustoz AI’dan so‘rang · demo',
              icon: CupertinoIcons.chat_bubble_2,
              onTap: () => e.go(MLPScreen.chat),
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(CupertinoIcons.ellipsis, size: 18),
            label: const Text('Kun tafsilotlari va odatlar'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MLPScaffold(
                  title: 'Kun tafsilotlari',
                  body: MLPDetailedTodayPage(e: e),
                ),
              ),
            ),
          ),
          if (e.store.storageError != null)
            MLPErrorState(
              message: e.store.storageError!,
              onRetry: () => e.act(context, e.store.retrySave),
            ),
        ],
      );
    },
  );
}

class _IosMetadata extends StatelessWidget {
  const _IosMetadata({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: MLPColors.secondaryText),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: MLPColors.secondaryText, height: 1.35),
        ),
      ),
    ],
  );
}

class _IosTaskTile extends StatelessWidget {
  const _IosTaskTile({
    required this.e,
    required this.task,
    this.compact = false,
  });
  final MLPEnvironment e;
  final DemoTask task;
  final bool compact;
  @override
  Widget build(BuildContext context) => MLPLiquidSurface(
    radius: 23,
    blur: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(6, 7, 12, 7),
      child: Row(
        children: [
          IconButton(
            tooltip: task.completed
                ? 'Hisobotni ko‘rish'
                : 'Natijani topshirish',
            icon: Icon(
              task.completed
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: task.completed
                  ? MLPColors.success
                  : const Color(0xFFA8B6F0),
              size: 27,
            ),
            onPressed: () => e.go(
              MLPScreen.verification,
              args: MLPRouteArgs(taskId: task.id),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => mlpTaskActions(context, e, task),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        if (!compact)
                          Text(
                            task.project,
                            style: const TextStyle(
                              fontSize: 12,
                              color: MLPColors.secondaryText,
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.clock,
                              size: 15,
                              color: MLPColors.secondaryText,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${task.minutes} daqiqa',
                              style: const TextStyle(
                                fontSize: 12,
                                color: MLPColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Vazifa amallari',
            icon: const Icon(
              CupertinoIcons.chevron_right,
              size: 17,
              color: MLPColors.secondaryText,
            ),
            onPressed: () => mlpTaskActions(context, e, task),
          ),
        ],
      ),
    ),
  );
}

class MLPIosPlanPage extends StatefulWidget {
  const MLPIosPlanPage({super.key, required this.e, this.initialGoals = false});
  final MLPEnvironment e;
  final bool initialGoals;
  @override
  State<MLPIosPlanPage> createState() => _IosPlanState();
}

class _IosPlanState extends State<MLPIosPlanPage> {
  late bool goals = widget.initialGoals;
  bool search = false;
  bool archived = false;
  String query = '';
  final collapsed = <String>{};
  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    return ListenableBuilder(
      listenable: Listenable.merge([e.store, e.ui]),
      builder: (context, _) {
        final today = e.store.today;
        final tomorrow = today.add(const Duration(days: 1));
        final items =
            e.store.tasks
                .where(
                  (t) => '${t.title} ${t.project}'.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
                )
                .toList()
              ..sort(_priorityOrder);
        final groups = <(String, List<DemoTask>)>[
          (
            'Bugun',
            items
                .where((t) => !t.completed && !t.dueDate.isAfter(today))
                .toList(),
          ),
          (
            'Ertaga',
            items
                .where(
                  (t) =>
                      !t.completed &&
                      mlpDayKey(t.dueDate) == mlpDayKey(tomorrow),
                )
                .toList(),
          ),
          (
            'Keyin',
            items
                .where((t) => !t.completed && t.dueDate.isAfter(tomorrow))
                .toList(),
          ),
          ('Bajarilgan', items.where((t) => t.completed).toList()),
        ];
        final goalItems = e.store.goals
            .where(
              (g) =>
                  g.title.toLowerCase().contains(query.toLowerCase()) &&
                  (e.ui.goalPlan(g.id)?['archived'] == true) == archived,
            )
            .toList();
        return MLPPage(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goals ? 'Maqsadlar' : 'Vazifalar',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.9,
                    ),
                  ),
                ),
                MLPCircleAction(
                  label: 'Qidirish',
                  icon: CupertinoIcons.search,
                  filled: false,
                  size: 46,
                  onPressed: () => setState(() {
                    search = !search;
                    if (!search) query = '';
                  }),
                ),
                const SizedBox(width: 8),
                MLPCircleAction(
                  label: 'Taqvim',
                  icon: CupertinoIcons.calendar,
                  filled: false,
                  size: 46,
                  onPressed: () => e.go(MLPScreen.calendar),
                ),
              ],
            ),
            const SizedBox(height: 20),
            MLPSegmented(
              labels: const ['Vazifalar', 'Maqsadlar'],
              selected: goals ? 1 : 0,
              onChanged: (v) => setState(() => goals = v == 1),
            ),
            if (search)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: goals
                        ? 'Maqsadni qidirish'
                        : 'Vazifani qidirish',
                    prefixIcon: const Icon(CupertinoIcons.search),
                  ),
                  onChanged: (v) => setState(() => query = v),
                ),
              ),
            const SizedBox(height: 22),
            MLPSecondaryButton(
              label: goals ? 'Maqsad qo‘shish' : 'Vazifa qo‘shish',
              icon: CupertinoIcons.add,
              onPressed: () => goals
                  ? e.go(MLPScreen.goalDiscovery)
                  : DemoForms.task(context, e.store),
            ),
            const SizedBox(height: 22),
            if (goals) ...[
              MLPSegmented(
                labels: const ['Faol', 'Arxiv'],
                selected: archived ? 1 : 0,
                onChanged: (v) => setState(() => archived = v == 1),
              ),
              const SizedBox(height: 16),
              if (goalItems.isEmpty)
                const MLPEmptyState(
                  title: 'Maqsad topilmadi',
                  message:
                      'Birinchi maqsadingizni yozing yoki qidiruvni o‘zgartiring.',
                ),
              for (final goal in goalItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MLPGlassCard(
                    onTap: () => e.go(
                      MLPScreen.goalDetail,
                      args: MLPRouteArgs(goalId: goal.id),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF00C3EE),
                                Color(0xFF3941C3),
                                Color(0xFFA65AF8),
                              ],
                            ),
                          ),
                          child: Icon(
                            goal.category == 'Dasturlash'
                                ? Icons.code_rounded
                                : CupertinoIcons.scope,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${goal.current} / ${goal.target} ${goal.metric}',
                                style: const TextStyle(
                                  color: MLPColors.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              MLPProgressBar(
                                value: goal.progress,
                                label: 'Maqsad bo‘yicha qayd etilgan natija',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          size: 17,
                          color: MLPColors.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
              MLPSecondaryButton(
                label: 'Loyihalar va odatlar',
                icon: CupertinoIcons.folder,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MLPScaffold(
                      title: 'Loyihalar',
                      body: MLPGoalsPage(e: e),
                    ),
                  ),
                ),
              ),
            ] else ...[
              if (items.isEmpty)
                const MLPEmptyState(
                  title: 'Vazifa topilmadi',
                  message: 'Vazifa qo‘shing yoki qidiruvni o‘zgartiring.',
                ),
              for (final group in groups.where((g) => g.$2.isNotEmpty)) ...[
                InkWell(
                  onTap: () => setState(
                    () => collapsed.contains(group.$1)
                        ? collapsed.remove(group.$1)
                        : collapsed.add(group.$1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${group.$1} · ${group.$2.length} vazifa',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          collapsed.contains(group.$1)
                              ? CupertinoIcons.chevron_down
                              : CupertinoIcons.chevron_up,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!collapsed.contains(group.$1))
                  for (final task in group.$2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _IosTaskTile(e: e, task: task),
                    ),
                const SizedBox(height: 12),
              ],
              MLPSecondaryButton(
                label: 'Fokus taymeri',
                icon: CupertinoIcons.timer,
                onPressed: () => e.go(MLPScreen.focus),
              ),
            ],
          ],
        );
      },
    );
  }
}
