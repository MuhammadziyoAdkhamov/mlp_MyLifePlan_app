import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo_store.dart';

/// All demo edits are validated and saved locally before the dialog closes.
abstract final class DemoForms {
  static Future<void> task(
    BuildContext context,
    DemoStore store, {
    DemoTask? existing,
    String? initialGoalId,
  }) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final project = TextEditingController(text: existing?.project ?? 'Shaxsiy');
    var minutes = existing?.minutes ?? 25;
    var priority = existing?.priority ?? 2;
    var due = existing?.dueDate ?? store.today;
    String? goalId = existing?.goalId ?? initialGoalId;
    final durations = {5, 15, 25, 45, 60, 90, minutes}.toList()..sort();
    await _open(
      context,
      title: existing == null ? 'Yangi vazifa' : 'Vazifani tahrirlash',
      subtitle: 'Bugun erishmoqchi bo‘lgan aniq natijangizni yozing.',
      controllers: [title, project],
      body: (context, update) => [
        _text(
          title,
          'Vazifa nomi',
          hint: 'Masalan, portfolio kirish qismini yozish',
          min: 2,
          max: 160,
          autofocus: true,
        ),
        _text(project, 'Loyiha yoki yo‘nalish', min: 1, max: 80),
        DropdownButtonFormField<int>(
          initialValue: minutes,
          decoration: const InputDecoration(labelText: 'Taxminiy vaqt'),
          items: durations
              .map((m) => DropdownMenuItem(value: m, child: Text('$m daqiqa')))
              .toList(),
          onChanged: (value) => update(() => minutes = value ?? minutes),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: priority,
          decoration: const InputDecoration(labelText: 'Ustuvorlik'),
          items: const [
            DropdownMenuItem(value: 1, child: Text('1 · Eng muhim')),
            DropdownMenuItem(value: 2, child: Text('2 · Muhim')),
            DropdownMenuItem(value: 3, child: Text('3 · Keyinroq')),
          ],
          onChanged: (value) => update(() => priority = value ?? priority),
        ),
        const SizedBox(height: 16),
        _dateButton(context, 'Bajarish sanasi', due, () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: due,
            firstDate: DateTime(
              due.year < store.today.year - 5 ? due.year : store.today.year - 5,
            ),
            lastDate: DateTime(
              due.year > store.today.year + 10
                  ? due.year
                  : store.today.year + 10,
              12,
              31,
            ),
            helpText: 'Bajarish sanasini tanlang',
            cancelText: 'Bekor qilish',
            confirmText: 'Tanlash',
          );
          if (picked != null && context.mounted) update(() => due = picked);
        }),
        if (store.goals.isNotEmpty) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: goalId ?? '',
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Bog‘langan maqsad'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Alohida vazifa')),
              ...store.goals.map(
                (goal) => DropdownMenuItem(
                  value: goal.id,
                  child: Text(goal.title, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) =>
                update(() => goalId = value == '' ? null : value),
          ),
        ],
      ],
      save: () => existing == null
          ? store.addTask(
              title: title.text,
              project: project.text,
              minutes: minutes,
              priority: priority,
              dueDate: due,
              goalId: goalId,
            )
          : store.editTask(
              existing.id,
              title: title.text,
              project: project.text,
              minutes: minutes,
              priority: priority,
              dueDate: due,
              goalId: goalId,
              clearGoal: goalId == null,
            ),
    );
  }

  static Future<void> habit(
    BuildContext context,
    DemoStore store, {
    DemoHabit? existing,
  }) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final target = TextEditingController(text: '${existing?.target ?? 1}');
    final unit = TextEditingController(text: existing?.unit ?? 'marta');
    final weekdays = {...?existing?.weekdays};
    if (existing == null) weekdays.addAll([1, 2, 3, 4, 5, 6, 7]);
    String? goalId = existing?.goalId;
    await _open(
      context,
      title: existing == null ? 'Yangi odat' : 'Odatni tahrirlash',
      subtitle: 'Kichik, o‘lchanadigan va takrorlanadigan qadam tanlang.',
      controllers: [title, target, unit],
      validate: () =>
          weekdays.isEmpty ? 'Kamida bitta hafta kunini tanlang.' : null,
      body: (context, update) => [
        _text(
          title,
          'Odat nomi',
          hint: 'Masalan, kitob o‘qish',
          min: 2,
          max: 160,
          autofocus: true,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _number(target, 'Kunlik miqdor', min: 1, max: 1000000),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _text(
                unit,
                'Birlik',
                hint: 'bet, stakan, daqiqa',
                min: 1,
                max: 30,
              ),
            ),
          ],
        ),
        Text(
          'Takrorlanadigan kunlar',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var day = 1; day <= 7; day++)
              FilterChip(
                label: Text(
                  const ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'][day - 1],
                ),
                selected: weekdays.contains(day),
                onSelected: (selected) => update(() {
                  selected ? weekdays.add(day) : weekdays.remove(day);
                }),
              ),
          ],
        ),
        if (store.goals.isNotEmpty) ...[
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: goalId ?? '',
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Bog‘langan maqsad'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Alohida odat')),
              ...store.goals.map(
                (goal) => DropdownMenuItem(
                  value: goal.id,
                  child: Text(goal.title, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) =>
                update(() => goalId = value == '' ? null : value),
          ),
          const SizedBox(height: 8),
          _hint(
            context,
            'Bog‘lanish odatning maqsadini ko‘rsatadi. Maqsad natijasi alohida yangilanadi.',
          ),
        ],
      ],
      save: () => existing == null
          ? store.addHabit(
              title: title.text,
              target: int.parse(target.text),
              unit: unit.text,
              weekdays: weekdays.toList()..sort(),
              goalId: goalId,
            )
          : store.editHabit(
              existing.id,
              title: title.text,
              target: int.parse(target.text),
              unit: unit.text,
              weekdays: weekdays.toList()..sort(),
              goalId: goalId,
              clearGoal: goalId == null,
            ),
    );
  }

  static Future<void> goal(
    BuildContext context,
    DemoStore store, {
    DemoGoal? existing,
  }) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final metric = TextEditingController(text: existing?.metric ?? '');
    final target = TextEditingController(
      text: existing?.target.toString() ?? '',
    );
    var category = existing?.category ?? 'Shaxsiy';
    var deadline =
        existing?.deadline ?? store.today.add(const Duration(days: 90));
    await _open(
      context,
      title: existing == null ? 'Yangi maqsad' : 'Maqsadni tahrirlash',
      subtitle: 'Qanday natijaga, qancha va qachongacha erishasiz?',
      controllers: [title, metric, target],
      body: (context, update) => [
        _text(
          title,
          'Maqsad nomi',
          hint: 'Masalan, o‘qish odatini mustahkamlash',
          min: 2,
          max: 160,
          autofocus: true,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _number(target, 'Maqsad miqdori', min: 1, max: 1000000000),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _text(
                metric,
                'O‘lchov birligi',
                hint: 'kitob, dars, loyiha',
                min: 1,
                max: 40,
              ),
            ),
          ],
        ),
        DropdownButtonFormField<String>(
          initialValue: category,
          decoration: const InputDecoration(labelText: 'Yo‘nalish'),
          items:
              {
                    'Shaxsiy',
                    'Ta’lim',
                    'Karyera',
                    'Sog‘liq',
                    'Moliya',
                    'Rivojlanish',
                    category,
                  }
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
          onChanged: (value) => update(() => category = value ?? category),
        ),
        const SizedBox(height: 16),
        _dateButton(context, 'Muddat', deadline, () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: deadline,
            firstDate: deadline.isBefore(store.today) ? deadline : store.today,
            lastDate: DateTime(
              deadline.year > store.today.year + 10
                  ? deadline.year
                  : store.today.year + 10,
              12,
              31,
            ),
            helpText: 'Maqsad muddatini tanlang',
            cancelText: 'Bekor qilish',
            confirmText: 'Tanlash',
          );
          if (picked != null && context.mounted) {
            update(() => deadline = picked);
          }
        }),
      ],
      save: () => existing == null
          ? store.addGoal(
              title: title.text,
              metric: metric.text,
              target: int.parse(target.text),
              deadline: deadline,
              category: category,
            )
          : store.editGoal(
              existing.id,
              title: title.text,
              metric: metric.text,
              target: int.parse(target.text),
              deadline: deadline,
              category: category,
            ),
    );
  }

  static Future<void> submit(
    BuildContext context,
    DemoStore store,
    DemoTask task,
  ) async {
    final current =
        store.tasks.where((item) => item.id == task.id).firstOrNull ?? task;
    final proof = TextEditingController(text: current.proof);
    final url = TextEditingController(text: current.evidenceUrl);
    final completed = current.completed;
    await _open(
      context,
      title: completed ? 'Topshirilgan natija' : 'Natijani topshirish',
      subtitle: current.title,
      controllers: [proof, url],
      saveLabel: 'Topshirish · +40 XP',
      body: (context, update) => [
        _hint(
          context,
          'Bu siz kiritgan hisobot. Mentor tomonidan tekshirilmagan.',
        ),
        const SizedBox(height: 18),
        _text(
          proof,
          'Nima qildingiz? Natija qanday?',
          hint: 'Masalan, kirish qismini yozdim va 3 ta misol qo‘shdim.',
          min: 10,
          max: 4000,
          lines: 5,
          readOnly: completed,
          autofocus: !completed,
        ),
        TextFormField(
          controller: url,
          readOnly: completed,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Dalil havolasi (ixtiyoriy)',
            hintText: 'https://...',
            prefixIcon: Icon(Icons.link_rounded),
          ),
          maxLength: 2048,
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return null;
            final uri = Uri.tryParse(text);
            return uri == null ||
                    !['http', 'https'].contains(uri.scheme) ||
                    uri.host.isEmpty
                ? 'http yoki https bilan boshlangan havola kiriting.'
                : null;
          },
        ),
        if (completed) ...[
          const SizedBox(height: 8),
          _hint(
            context,
            'Vazifa topshirilgan. Bu oynani qayta ochish qo‘shimcha XP bermaydi.',
          ),
        ],
      ],
      save: completed
          ? null
          : () =>
                store.submitTask(current.id, proof.text, evidenceUrl: url.text),
    );
  }

  static Future<void> checkin(BuildContext context, DemoStore store) async {
    final previous = store.todayCheckin;
    var mood = previous?.mood ?? 3;
    var energy = previous?.energy ?? 3;
    final note = TextEditingController(text: previous?.note ?? '');
    await _open(
      context,
      title: 'Bugun o‘zingizni qanday his qilyapsiz?',
      subtitle: previous == null
          ? 'Bir daqiqa to‘xtang va holatingizni qayd eting.'
          : 'Bugungi qaydni yangilayapsiz. XP qayta qo‘shilmaydi.',
      controllers: [note],
      body: (context, update) => [
        _rating(context, 'Kayfiyat', mood, const [
          'Juda past',
          'Past',
          'O‘rtacha',
          'Yaxshi',
          'A’lo',
        ], (value) => update(() => mood = value)),
        const SizedBox(height: 16),
        _rating(context, 'Energiya', energy, const [
          'Juda kam',
          'Kam',
          'O‘rtacha',
          'Yaxshi',
          'Juda ko‘p',
        ], (value) => update(() => energy = value)),
        const SizedBox(height: 18),
        _text(
          note,
          'Bugungi holatingiz haqida (ixtiyoriy)',
          max: 2000,
          lines: 3,
        ),
        _hint(context, 'Qaydingiz shaxsiy kuzatuv uchun saqlanadi.'),
      ],
      save: () =>
          store.saveCheckin(mood: mood, energy: energy, note: note.text),
    );
  }

  static Future<void> goalProgress(
    BuildContext context,
    DemoStore store,
    DemoGoal goal,
  ) async {
    final current =
        store.goals.where((item) => item.id == goal.id).firstOrNull ?? goal;
    final value = TextEditingController(text: current.current.toString());
    await _open(
      context,
      title: 'Natijani yangilash',
      subtitle: current.title,
      controllers: [value],
      body: (context, update) => [
        _hint(
          context,
          'Maqsad: ${current.target} ${current.metric}. Hozirgacha erishgan jami natijangizni kiriting.',
        ),
        const SizedBox(height: 20),
        _number(
          value,
          'Jami natija (${current.metric})',
          min: 0,
          max: current.target,
          autofocus: true,
        ),
        _hint(
          context,
          'Bu siz kiritgan natija. Maqsadga yetilganda 100 XP hisoblanadi.',
        ),
      ],
      save: () => store.progressGoal(current.id, int.parse(value.text)),
    );
  }

  static Future<void> skip(
    BuildContext context,
    DemoStore store,
    DemoHabit habit,
  ) async {
    final note = TextEditingController(
      text: habit.reasons[store.todayKey] ?? '',
    );
    const reasons = [
      'Vaqt yetmadi',
      'Energiya kam',
      'Reja o‘zgardi',
      'Sog‘liq uchun dam',
    ];
    await _open(
      context,
      title: 'Bugun tanaffus',
      subtitle: habit.title,
      controllers: [note],
      saveLabel: 'Sababni saqlash',
      body: (context, update) => [
        _hint(
          context,
          'Sababni qayd etish keyingi rejangizni yaxshilashga yordam beradi. Bugungi bajarilgan miqdor olib tashlanadi.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: reasons
              .map(
                (reason) => ActionChip(
                  label: Text(reason),
                  onPressed: () => update(() => note.text = reason),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        _text(note, 'Sabab', min: 3, max: 500, lines: 3),
      ],
      save: () => store.skipHabit(habit.id, note.text),
    );
  }

  static Future<void> _open(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<TextEditingController> controllers,
    required List<Widget> Function(BuildContext, StateSetter) body,
    required Future<void> Function()? save,
    String saveLabel = 'Saqlash',
    String? Function()? validate,
  }) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DemoFormDialog(
      title: title,
      subtitle: subtitle,
      controllers: controllers,
      body: body,
      save: save,
      saveLabel: saveLabel,
      validate: validate,
    ),
  );

  static Widget _text(
    TextEditingController controller,
    String label, {
    String? hint,
    int min = 0,
    int max = 160,
    int lines = 1,
    bool readOnly = false,
    bool autofocus = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: lines > 1,
      ),
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 2,
      maxLength: max,
      readOnly: readOnly,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) => (value ?? '').trim().length < min
          ? 'Kamida $min ta belgi kiriting.'
          : null,
    ),
  );

  static Widget _number(
    TextEditingController controller,
    String label, {
    required int min,
    required int max,
    bool autofocus = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      autofocus: autofocus,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        final number = int.tryParse(value ?? '');
        return number == null || number < min || number > max
            ? '$min–$max oralig‘ida son kiriting.'
            : null;
      },
    ),
  );

  static Widget _dateButton(
    BuildContext context,
    String label,
    DateTime value,
    VoidCallback onPressed,
  ) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.calendar_today_rounded, size: 18),
    label: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Text(
        '$label: ${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}',
      ),
    ),
  );

  static Widget _hint(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.5,
    ),
  );

  static Widget _rating(
    BuildContext context,
    String title,
    int value,
    List<String> labels,
    ValueChanged<int> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$title · $value / 5 · ${labels[value - 1]}',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      Slider(
        value: value.toDouble(),
        min: 1,
        max: 5,
        divisions: 4,
        label: labels[value - 1],
        onChanged: (next) => onChanged(next.round()),
      ),
    ],
  );
}

class _DemoFormDialog extends StatefulWidget {
  const _DemoFormDialog({
    required this.title,
    required this.subtitle,
    required this.controllers,
    required this.body,
    required this.save,
    required this.saveLabel,
    this.validate,
  });
  final String title, subtitle, saveLabel;
  final List<TextEditingController> controllers;
  final List<Widget> Function(BuildContext, StateSetter) body;
  final Future<void> Function()? save;
  final String? Function()? validate;

  @override
  State<_DemoFormDialog> createState() => _DemoFormDialogState();
}

class _DemoFormDialogState extends State<_DemoFormDialog> {
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StatefulBuilder(
    builder: (context, update) => PopScope(
      canPop: !_saving,
      child: AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(widget.title),
        content: SizedBox(
          width: 500,
          child: Form(
            key: _form,
            child: AbsorbPointer(
              absorbing: _saving,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...widget.body(context, update),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text(widget.save == null ? 'Yopish' : 'Bekor qilish'),
          ),
          if (widget.save != null)
            FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (_saving) return;
                      if (!_form.currentState!.validate()) return;
                      final validationError = widget.validate?.call();
                      if (validationError != null) {
                        update(() => _error = validationError);
                        return;
                      }
                      update(() {
                        _saving = true;
                        _error = null;
                      });
                      try {
                        await widget.save!();
                        if (context.mounted) Navigator.of(context).pop();
                      } catch (error) {
                        if (context.mounted) {
                          update(() {
                            _saving = false;
                            _error = switch (error) {
                              ArgumentError e =>
                                e.message?.toString() ??
                                    'Kiritilgan ma’lumotni tekshiring.',
                              StateError e => e.message,
                              FormatException e => e.message,
                              _ => 'Saqlab bo‘lmadi. Qayta urinib ko‘ring.',
                            };
                          });
                        }
                      }
                    },
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.saveLabel),
            ),
        ],
      ),
    ),
  );
}
