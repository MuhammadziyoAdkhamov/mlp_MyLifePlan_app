import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../data/models/mlp_schedule.dart';
import '../../data/repositories/mlp_ui_repository.dart';
import '../../demo/demo_store.dart';
import 'mlp_schedule_editor.dart';

Future<void> openMLPCalendar(
  BuildContext context,
  DemoStore store,
  MLPLocalUiRepository ui, {
  DateTime Function()? clock,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/calendar'),
    builder: (_) => MLPCalendarScreen(store: store, ui: ui, clock: clock),
  ),
);

class MLPCalendarScreen extends StatefulWidget {
  const MLPCalendarScreen({
    super.key,
    required this.store,
    required this.ui,
    this.clock,
  });
  final DemoStore store;
  final MLPLocalUiRepository ui;
  final DateTime Function()? clock;
  @override
  State<MLPCalendarScreen> createState() => _CalendarState();
}

class _CalendarState extends State<MLPCalendarScreen>
    with WidgetsBindingObserver {
  late DateTime selected;
  int mode = 0;
  DateTime get now => (widget.clock ?? DateTime.now)();
  @override
  void initState() {
    super.initState();
    selected = widget.store.today;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  Future<void> _external(MLPSchedule item) => showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('Tashqi ilovani ochish'),
      content: SingleChildScrollView(
        child: SelectableText(
          'Avtomatik ochish bu prototipga ulanmagan. Telefoningiz boshqarilmadi.\n\n${item.appLink.isEmpty ? 'Havola kiritilmagan. Jadvalni tahrirlab havola qo‘shishingiz mumkin.' : item.appLink}',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Yopish'),
        ),
        if (item.appLink.isNotEmpty)
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: item.appLink));
              if (dialog.mounted) Navigator.pop(dialog);
              if (mounted) {
                MLPToast.show(
                  context,
                  'Havola nusxalandi. Brauzerga qo‘yishingiz mumkin.',
                );
              }
            },
            child: const Text('Havolani nusxalash'),
          ),
      ],
    ),
  );

  Widget _controls(List<MLPSchedule> all) {
    final tasks = {
      for (final t in widget.store.tasks.where(
        (t) => mlpDay(t.dueDate) == selected,
      ))
        t.id: t.minutes,
    };
    final load = MLPPlannerMath.loadMinutes(all, selected, tasks);
    final available = widget.ui.preferences.minutes;
    final monday = DateTime(
      selected.year,
      selected.month,
      selected.day - selected.weekday + 1,
    );
    const weekdays = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Reja — bajarilgan ish emas.',
          style: TextStyle(
            color: MLPColors.turquoise,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Eslatma xohishi mahalliy saqlanadi. Haqiqiy bildirishnoma hali yuborilmaydi.',
          style: TextStyle(color: MLPColors.secondaryText),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            3,
            (i) => ChoiceChip(
              label: Text(['Kun', 'Hafta', 'Oy'][i]),
              selected: mode == i,
              onSelected: (_) => setState(() => mode = i),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (mode == 2)
          SizedBox(
            height: 360,
            child: CalendarDatePicker(
              key: ValueKey('month-${mlpDayKey(selected)}'),
              initialDate: selected,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100, 12, 31),
              onDateChanged: (day) => setState(() => selected = day),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (i) {
                final day = DateTime(monday.year, monday.month, monday.day + i);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${weekdays[i]} ${day.day}'),
                    selected: day == selected,
                    onSelected: (_) => setState(() => selected = day),
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            MLPPrimaryButton(
              label: 'Yangi mashg‘ulot',
              icon: Icons.add,
              onPressed: () => openMLPScheduleEditor(
                context,
                widget.store,
                widget.ui,
                day: selected,
              ),
            ),
            MLPSecondaryButton(
              label: 'Bugunga qaytish',
              onPressed: () => setState(() => selected = widget.store.today),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MLPGlassCard(
          child: Text(
            '${mlpDayKey(selected)} · reja $load daqiqa / imkoniyat $available daqiqa.\n${load > available ? 'Yuk ${load - available} daqiqaga oshgan. Jadval yoki bog‘langan vazifa sanasini tahrirlang.' : 'Kunlik yuk imkoniyatingizga mos.'}\nVazifa taxmini va unga ajratilgan jadval bir marta hisoblanadi.',
            style: TextStyle(
              color: load > available
                  ? MLPColors.warning
                  : MLPColors.secondaryText,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _card(
    DateTime day,
    MLPSchedule item,
    Map<String, MLPScheduleResult> results,
    Map<String, DemoTask> tasks,
  ) {
    final result = results['${item.id}@${mlpDayKey(day)}'];
    final ended = !now.isBefore(item.endOn(day));
    final task = tasks[item.taskId];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MLPGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${mlpTime(item.startMinute)}–${mlpTime(item.endMinute)} · ${item.minutes} daqiqa',
              style: const TextStyle(color: MLPColors.turquoise),
            ),
            const SizedBox(height: 8),
            Text(item.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${item.repeat.label}${item.until == null ? '' : ' · ${mlpDayKey(item.until!)} gacha'}',
            ),
            if (item.taskId != null)
              Text(
                'Vazifa: ${task?.title ?? 'Bog‘lanish topilmadi — tahrirlang'}',
                style: const TextStyle(color: MLPColors.secondaryText),
              ),
            if (item.goalId != null)
              Text(
                'Maqsad: ${widget.store.goals.where((g) => g.id == item.goalId).firstOrNull?.title ?? 'Bog‘lanish topilmadi — tahrirlang'}',
                style: const TextStyle(color: MLPColors.secondaryText),
              ),
            const SizedBox(height: 12),
            Text(
              item.reminderMinutes == null
                  ? 'Eslatma tanlanmagan.'
                  : 'Eslatma xohishi: ${item.reminderMinutes == 0 ? 'boshlanish vaqtida' : '${item.reminderMinutes} daqiqa oldin'}. Tizimga rejalashtirilmagan.',
              style: const TextStyle(
                color: MLPColors.secondaryText,
                fontSize: 12,
              ),
            ),
            if (result != null) ...[
              const SizedBox(height: 12),
              Text(
                'O‘z hisoboti: ${result.note}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Text(
                'Mustaqil tekshiruv emas. Vazifa avtomatik bajarilmadi.',
                style: TextStyle(color: MLPColors.secondaryText, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                MLPSecondaryButton(
                  label: 'Tahrirlash',
                  icon: Icons.edit_outlined,
                  onPressed: () => openMLPScheduleEditor(
                    context,
                    widget.store,
                    widget.ui,
                    existing: item,
                  ),
                ),
                TextButton(
                  onPressed: () => _external(item),
                  child: const Text('Ilovani ochish'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MLPPrimaryButton(
              label: result == null
                  ? 'Natijani qayd qilish'
                  : 'Natijani tahrirlash',
              icon: Icons.edit_note_rounded,
              onPressed: ended
                  ? () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      routeSettings: const RouteSettings(
                        name: '/calendar/result',
                      ),
                      builder: (_) => _ResultSheet(
                        ui: widget.ui,
                        item: item,
                        day: day,
                        previous: result,
                        clock: widget.clock ?? DateTime.now,
                      ),
                    )
                  : null,
            ),
            if (!ended)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Natija ${mlpDayKey(day)} ${mlpTime(item.endMinute)} dan keyin ochiladi. Soat o‘tgach yuqoridagi yangilash tugmasini bosing.',
                  style: const TextStyle(
                    color: MLPColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.store, widget.ui]),
    builder: (context, _) {
      final all = widget.ui.schedules;
      final days = mode == 1
          ? List.generate(7, (i) {
              final monday = DateTime(
                selected.year,
                selected.month,
                selected.day - selected.weekday + 1,
              );
              return DateTime(monday.year, monday.month, monday.day + i);
            })
          : [selected];
      final rows = <({DateTime day, MLPSchedule? item, bool header})>[];
      for (final day in days) {
        rows.add((day: day, item: null, header: true));
        final entries = all.where((s) => s.occursOn(day)).toList()
          ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
        if (entries.isEmpty) rows.add((day: day, item: null, header: false));
        for (final item in entries) {
          rows.add((day: day, item: item, header: false));
        }
      }
      final results = {
        for (final r in widget.ui.scheduleResults)
          '${r.scheduleId}@${mlpDayKey(r.day)}': r,
      };
      final tasks = {for (final t in widget.store.tasks) t.id: t};
      return MLPScaffold(
        title: 'Taqvim',
        actions: [
          MLPIconButton(
            label: 'Yangilash',
            icon: Icons.refresh_rounded,
            onPressed: () => setState(() {}),
          ),
        ],
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: rows.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _controls(all);
                final row = rows[index - 1];
                if (row.header) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: MLPSectionHeader(title: mlpDayKey(row.day)),
                  );
                }
                if (row.item == null) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: MLPEmptyState(
                      title: 'Bu kun uchun jadval yo‘q',
                      message:
                          'Yangi mashg‘ulot yarating yoki boshqa kunni tanlang.',
                    ),
                  );
                }
                return _card(row.day, row.item!, results, tasks);
              },
            ),
          ),
        ),
      );
    },
  );
}

class _ResultSheet extends StatefulWidget {
  const _ResultSheet({
    required this.ui,
    required this.item,
    required this.day,
    required this.clock,
    this.previous,
  });
  final MLPLocalUiRepository ui;
  final MLPSchedule item;
  final DateTime day;
  final DateTime Function() clock;
  final MLPScheduleResult? previous;
  @override
  State<_ResultSheet> createState() => _ResultState();
}

class _ResultState extends State<_ResultSheet> {
  final form = GlobalKey<FormState>();
  late final TextEditingController note, evidence;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    note = TextEditingController(text: widget.previous?.note);
    evidence = TextEditingController(text: widget.previous?.evidenceUrl);
  }

  @override
  void dispose() {
    note.dispose();
    evidence.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.ui.saveScheduleResult(
        MLPScheduleResult(
          scheduleId: widget.item.id,
          day: widget.day,
          note: note.text.trim(),
          evidenceUrl: evidence.text.trim(),
          reportedAt: widget.clock(),
        ),
      );
      if (mounted) {
        setState(() => busy = false);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error =
              'Natija saqlanmadi. Mashg‘ulot tugaganini tekshirib, qayta urinib ko‘ring.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mashg‘ulot natijasi',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text('${widget.item.title} · ${mlpDayKey(widget.day)}'),
              const SizedBox(height: 12),
              const Text(
                'Bu o‘z hisoboti. Mustaqil baholash emas va bog‘langan vazifani avtomatik bajarmaydi.',
                style: TextStyle(color: MLPColors.secondaryText),
              ),
              const SizedBox(height: 20),
              MLPTextField(
                controller: note,
                label: 'Nima bajardingiz?',
                maxLength: 2000,
                maxLines: 3,
                enabled: !busy,
                validator: (v) => (v ?? '').trim().length < 10
                    ? 'Kamida 10 belgi bilan yozing.'
                    : null,
              ),
              const SizedBox(height: 16),
              MLPTextField(
                controller: evidence,
                label: 'Dalil havolasi (ixtiyoriy)',
                maxLength: 1000,
                enabled: !busy,
                keyboardType: TextInputType.url,
                validator: (v) => mlpWebLink((v ?? '').trim())
                    ? null
                    : 'To‘g‘ri http yoki https havola kiriting.',
              ),
              const SizedBox(height: 20),
              if (error != null) ...[
                Text(error!, style: const TextStyle(color: MLPColors.error)),
                const SizedBox(height: 12),
              ],
              MLPPrimaryButton(
                label: 'Natijani saqlash',
                onPressed: _save,
                busy: busy,
              ),
              const SizedBox(height: 8),
              MLPSecondaryButton(
                label: 'Bekor qilish',
                onPressed: busy ? null : () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
