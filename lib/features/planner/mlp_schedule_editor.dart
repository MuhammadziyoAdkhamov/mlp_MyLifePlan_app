import 'package:flutter/material.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../data/models/mlp_schedule.dart';
import '../../data/repositories/mlp_ui_repository.dart';
import '../../demo/demo_store.dart';
import '../../demo/demo_forms.dart';

Future<void> openMLPScheduleEditor(
  BuildContext context,
  DemoStore store,
  MLPLocalUiRepository ui, {
  MLPSchedule? existing,
  DateTime? day,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/calendar/edit'),
    builder: (_) => MLPScheduleEditor(
      store: store,
      ui: ui,
      existing: existing,
      initialDay: day,
    ),
  ),
);

class MLPScheduleEditor extends StatefulWidget {
  const MLPScheduleEditor({
    super.key,
    required this.store,
    required this.ui,
    this.existing,
    this.initialDay,
  });
  final DemoStore store;
  final MLPLocalUiRepository ui;
  final MLPSchedule? existing;
  final DateTime? initialDay;
  @override
  State<MLPScheduleEditor> createState() => _EditorState();
}

class _EditorState extends State<MLPScheduleEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, link;
  late final String id;
  late DateTime date, until;
  late int start, end, reminder;
  late MLPRepeat repeat;
  late bool hasUntil;
  String? goalId, taskId, error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final value = widget.existing;
    id = value?.id ?? widget.ui.newScheduleId();
    title = TextEditingController(text: value?.title ?? '');
    link = TextEditingController(text: value?.appLink ?? '');
    date = value?.date ?? widget.initialDay ?? widget.store.today;
    until = value?.until ?? DateTime(date.year, date.month + 1, date.day);
    start = value?.startMinute ?? widget.ui.preferences.startMinute;
    end =
        value?.endMinute ??
        (start + widget.ui.preferences.minutes.clamp(5, 25)).clamp(
          start + 1,
          1440,
        );
    reminder = value?.reminderMinutes ?? -1;
    repeat = value?.repeat ?? MLPRepeat.once;
    hasUntil = value?.until != null;
    goalId = widget.store.goals.any((g) => g.id == value?.goalId)
        ? value?.goalId
        : null;
    taskId = widget.store.tasks.any((t) => t.id == value?.taskId)
        ? value?.taskId
        : null;
  }

  @override
  void dispose() {
    title.dispose();
    link.dispose();
    super.dispose();
  }

  MLPSchedule _value() => MLPSchedule(
    id: id,
    title: title.text.trim(),
    date: date,
    startMinute: start,
    endMinute: end,
    repeat: repeat,
    until: hasUntil && repeat != MLPRepeat.once ? until : null,
    goalId: goalId,
    taskId: taskId,
    reminderMinutes: reminder < 0 ? null : reminder,
    appLink: link.text.trim(),
  );
  Future<void> _day({bool ending = false}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ending ? until : date,
      firstDate: ending ? date : DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: ending ? 'Takrorlash tugash sanasi' : 'Mashg‘ulot sanasi',
      cancelText: 'Bekor qilish',
      confirmText: 'Tanlash',
    );
    if (picked != null && mounted) {
      setState(() {
        if (ending) {
          until = picked;
        } else {
          date = picked;
          if (until.isBefore(date)) until = date;
        }
      });
    }
  }

  Future<void> _time(bool first) async {
    final n = (first ? start : end).clamp(0, 1439);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: n ~/ 60, minute: n % 60),
      helpText: first ? 'Boshlanish soati' : 'Tugash soati',
      cancelText: 'Bekor qilish',
      confirmText: 'Tanlash',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (first) {
          start = picked.hour * 60 + picked.minute;
        } else {
          end = picked.hour * 60 + picked.minute;
        }
      });
    }
  }

  List<String> _warnings(MLPSchedule value) {
    final warnings = <String>[];
    final conflicts = MLPPlannerMath.conflicts(value, widget.ui.schedules);
    for (final conflict in conflicts.take(3)) {
      warnings.add(
        '${mlpDayKey(conflict.day)}: ${conflict.schedule.title} bilan vaqt to‘qnashuvi.',
      );
    }
    if (conflicts.length > 3) {
      warnings.add('Yana ${conflicts.length - 3} ta to‘qnashuv bor.');
    }
    final all = [...widget.ui.schedules.where((s) => s.id != id), value];
    final anchor =
        value.repeat != MLPRepeat.once && date.isBefore(widget.store.today)
        ? widget.store.today
        : date;
    final days = List.generate(
      value.repeat == MLPRepeat.once ? 1 : 7,
      (i) => DateTime(anchor.year, anchor.month, anchor.day + i),
    );
    for (final day in days.where(value.occursOn)) {
      final tasks = {
        for (final t in widget.store.tasks.where(
          (t) => mlpDay(t.dueDate) == day,
        ))
          t.id: t.minutes,
      };
      final load = MLPPlannerMath.loadMinutes(all, day, tasks);
      if (load > widget.ui.preferences.minutes) {
        warnings.add(
          '${mlpDayKey(day)}: reja $load daqiqa / imkoniyat ${widget.ui.preferences.minutes}. Yuk ${load - widget.ui.preferences.minutes} daqiqaga oshgan.',
        );
      }
    }
    return warnings;
  }

  Future<void> _save() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    try {
      final value = _value();
      if (goalId != null && !widget.store.goals.any((g) => g.id == goalId)) {
        throw StateError('Maqsad o‘chirilgan. Boshqasini tanlang.');
      }
      if (taskId != null && !widget.store.tasks.any((t) => t.id == taskId)) {
        throw StateError('Vazifa o‘chirilgan. Boshqasini tanlang.');
      }
      final warnings = _warnings(value);
      if (warnings.isNotEmpty) {
        final yes = await MLPConfirmationSheet.show(
          context,
          title: 'Rejada ogohlantirish bor',
          message:
              '${warnings.join('\n\n')}\n\nVaqt yoki sanani tahrirlab qayta taqsimlashingiz mumkin. Yuk yaqin 7 kun uchun hisoblandi.',
          confirm: 'Baribir saqlash',
        );
        if (!yes || !mounted) return;
      }
      setState(() {
        busy = true;
        error = null;
      });
      await widget.ui.saveSchedule(value);
      if (mounted) {
        setState(() => busy = false);
        MLPToast.show(context, 'Mashg‘ulot saqlandi.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e is ArgumentError
              ? '${e.message}'
              : e is StateError
              ? e.message
              : 'Saqlab bo‘lmadi. Kiritganlaringizni saqlab, qayta urinib ko‘ring.';
        });
      }
    }
  }

  Future<void> _delete() async {
    final yes = await MLPConfirmationSheet.show(
      context,
      title: 'Jadval o‘chirilsinmi?',
      message:
          'Ushbu mashg‘ulotning barcha takrorlari va mahalliy natija qaydlari o‘chadi. Bog‘langan vazifa saqlanadi.',
    );
    if (!yes || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.ui.deleteSchedule(id);
      if (mounted) {
        setState(() => busy = false);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Jadval o‘chmadi. Qayta urinib ko‘ring.';
        });
      }
    }
  }

  Future<void> _redistribute() async {
    final tasks = widget.store.tasks
        .where((t) => mlpDay(t.dueDate) == date)
        .toList();
    if (tasks.isEmpty) {
      MLPToast.show(
        context,
        'Shu kun uchun alohida vazifa yo‘q. Jadval sanasi yoki davomiyligini o‘zgartiring.',
      );
      return;
    }
    final task = await showModalBottomSheet<DemoTask>(
      context: context,
      useSafeArea: true,
      builder: (sheet) => ListView.builder(
        itemCount: tasks.length + 1,
        itemBuilder: (_, i) => i == 0
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sanasini o‘zgartirish uchun vazifani tanlang'),
              )
            : ListTile(
                title: Text(tasks[i - 1].title),
                subtitle: Text('${tasks[i - 1].minutes} daqiqa'),
                onTap: () => Navigator.pop(sheet, tasks[i - 1]),
              ),
      ),
    );
    if (task != null && mounted) {
      await DemoForms.task(context, widget.store, existing: task);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.store.tasks
        .where((t) => goalId == null || t.goalId == goalId || t.id == taskId)
        .toList();
    return PopScope(
      canPop: !busy,
      child: MLPScaffold(
        title: widget.existing == null
            ? 'Mashg‘ulot rejalash'
            : 'Jadvalni tahrirlash',
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const MLPGlassCard(
                        child: Text(
                          'Mahalliy jadval. Eslatma tanlovi saqlanadi; haqiqiy tizim bildirishnomasi va tashqi ilovani ochish hali ulanmagan.',
                        ),
                      ),
                      const SizedBox(height: 20),
                      MLPTextField(
                        controller: title,
                        label: 'Mashg‘ulot nomi',
                        hint: 'Duolingo mashg‘uloti',
                        maxLength: 160,
                        enabled: !busy,
                        validator: (v) => (v ?? '').trim().length < 2
                            ? 'Kamida 2 belgi kiriting.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey('goal-$goalId'),
                        initialValue: goalId ?? '',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Bog‘langan maqsad',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Alohida mashg‘ulot'),
                          ),
                          ...widget.store.goals.map(
                            (g) => DropdownMenuItem(
                              value: g.id,
                              child: Text(
                                g.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: busy
                            ? null
                            : (v) => setState(() {
                                goalId = v == '' ? null : v;
                                if (!widget.store.tasks.any(
                                  (t) =>
                                      t.id == taskId &&
                                      (goalId == null || t.goalId == goalId),
                                )) {
                                  taskId = null;
                                }
                              }),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey('task-$taskId-$goalId'),
                        initialValue: taskId ?? '',
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Bog‘langan vazifa',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Vazifaga bog‘lanmagan'),
                          ),
                          ...tasks.map(
                            (t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(
                                t.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: busy
                            ? null
                            : (v) => setState(() {
                                taskId = v == '' ? null : v;
                                final task = widget.store.tasks
                                    .where((t) => t.id == taskId)
                                    .firstOrNull;
                                if (task?.goalId != null) goalId = task!.goalId;
                              }),
                      ),
                      const SizedBox(height: 20),
                      MLPSecondaryButton(
                        label: 'Sana · ${mlpDayKey(date)}',
                        icon: Icons.calendar_today_outlined,
                        onPressed: busy ? null : _day,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          MLPSecondaryButton(
                            label: 'Boshlash · ${mlpTime(start)}',
                            onPressed: busy ? null : () => _time(true),
                          ),
                          MLPSecondaryButton(
                            label: 'Tugash · ${mlpTime(end)}',
                            onPressed: busy ? null : () => _time(false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<MLPRepeat>(
                        isExpanded: true,
                        initialValue: repeat,
                        decoration: const InputDecoration(
                          labelText: 'Takrorlash',
                        ),
                        items: MLPRepeat.values
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(
                                  r.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (v) => setState(() => repeat = v ?? repeat),
                      ),
                      if (repeat != MLPRepeat.once) ...[
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Takrorlashga muddat qo‘yish'),
                          value: hasUntil,
                          onChanged: busy
                              ? null
                              : (v) => setState(() => hasUntil = v),
                        ),
                        if (hasUntil)
                          MLPSecondaryButton(
                            label: 'Oxirgi kun · ${mlpDayKey(until)}',
                            onPressed: busy ? null : () => _day(ending: true),
                          ),
                      ],
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: reminder,
                        decoration: const InputDecoration(
                          labelText: 'Eslatma xohishi',
                        ),
                        items: [-1, 0, 5, 10, 15, 30, 60]
                            .map(
                              (n) => DropdownMenuItem(
                                value: n,
                                child: Text(
                                  n < 0
                                      ? 'Eslatmasiz'
                                      : n == 0
                                      ? 'Boshlanish vaqtida'
                                      : '$n daqiqa oldin',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (v) => setState(() => reminder = v ?? -1),
                      ),
                      const SizedBox(height: 20),
                      MLPTextField(
                        controller: link,
                        label: 'Tashqi ilova havolasi (ixtiyoriy)',
                        hint: 'https://...',
                        keyboardType: TextInputType.url,
                        maxLength: 1000,
                        enabled: !busy,
                        validator: (v) => mlpWebLink((v ?? '').trim())
                            ? null
                            : 'To‘g‘ri http yoki https havola kiriting.',
                      ),
                      const SizedBox(height: 12),
                      MLPGlassCard(
                        child: Text(
                          'Kunlik imkoniyat: ${widget.ui.preferences.minutes} daqiqa. Saqlashdan oldin takroriy vaqtlar va yaqin 7 kunlik sig‘im tekshiriladi. Bog‘langan vazifa taxmini va jadval vaqti ikki marta hisoblanmaydi.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      MLPSecondaryButton(
                        label: 'Vazifalarni qayta taqsimlash',
                        onPressed: busy ? null : _redistribute,
                      ),
                      const SizedBox(height: 20),
                      if (error != null) ...[
                        Text(
                          error!,
                          style: const TextStyle(color: MLPColors.error),
                        ),
                        const SizedBox(height: 16),
                      ],
                      MLPPrimaryButton(
                        label: 'Jadvalni saqlash',
                        onPressed: _save,
                        busy: busy,
                      ),
                      const SizedBox(height: 12),
                      MLPSecondaryButton(
                        label: 'Bekor qilish',
                        onPressed: busy ? null : () => Navigator.pop(context),
                      ),
                      if (widget.existing != null) ...[
                        const SizedBox(height: 12),
                        MLPSecondaryButton(
                          label: 'Jadvalni o‘chirish',
                          icon: Icons.delete_outline,
                          onPressed: busy ? null : _delete,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
