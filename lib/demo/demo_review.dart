import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo_store.dart';
import '../app/theme/mlp_design_system.dart';

const _panel = MLPColors.secondary;
const _line = MLPColors.border;
const _muted = MLPColors.secondaryText;
const _mint = MLPColors.primaryLight;
const _cyan = MLPColors.turquoise;

/// Plain, portable exports. Calendar export is a local .ics file, not OAuth.
class DemoExports {
  static String csv(DemoStore store) {
    final rows = <List<Object>>[
      [
        'id',
        'vazifa',
        'loyiha',
        'sana',
        'daqiqa',
        'ustuvorlik',
        'holat',
        'natija_dalili',
        'dalil_havolasi',
      ],
      for (final task in store.tasks)
        [
          task.id,
          task.title,
          task.project,
          DemoStore.dayKey(task.dueDate),
          task.minutes,
          task.priority,
          task.completed ? 'bajarilgan' : 'rejalangan',
          task.proof,
          task.evidenceUrl,
        ],
    ];
    // BOM lets spreadsheet apps identify Uzbek UTF-8 text correctly.
    return '\uFEFF${rows.map((row) => row.map(_csvCell).join(',')).join('\r\n')}\r\n';
  }

  static String _csvCell(Object value) {
    var text = value.toString();
    // Quoting alone does not prevent spreadsheet formula execution.
    if (RegExp(r'^[\s\x00-\x1F]*[=+\-@]').hasMatch(text) ||
        RegExp(r'^[\t\r\n]').hasMatch(text)) {
      text = "'$text";
    }
    return '"${text.replaceAll('"', '""')}"';
  }

  static String ics(DemoStore store, {DateTime? generatedAt}) {
    final stamp = (generatedAt ?? DateTime.now()).toUtc();
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//MPL//LifeOS Offline Demo//UZ',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'X-WR-CALNAME:MPL reja',
      for (final task in store.tasks) ...[
        'BEGIN:VEVENT',
        'UID:${Uri.encodeComponent(task.id)}@mpl.local',
        'DTSTAMP:${_calendarDate(stamp)}T${_two(stamp.hour)}${_two(stamp.minute)}${_two(stamp.second)}Z',
        'DTSTART;VALUE=DATE:${_calendarDate(task.dueDate)}',
        // RFC 5545: DTEND is exclusive, including for all-day events.
        'DTEND;VALUE=DATE:${_calendarDate(DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day + 1))}',
        'SUMMARY:${_icsText(task.title)}',
        'CATEGORIES:${_icsText(task.project)}',
        'DESCRIPTION:${_icsText('Rejalangan: ${task.minutes} daqiqa\nUstuvorlik: ${task.priority}\nHolat: ${task.completed ? 'bajarilgan' : 'rejalangan'}${task.proof.isEmpty ? '' : '\nNatija dalili: ${task.proof}'}')}',
        if (task.evidenceUrl.isNotEmpty) 'URL:${Uri.parse(task.evidenceUrl)}',
        'STATUS:CONFIRMED', 'TRANSP:TRANSPARENT',
        'X-MPL-COMPLETED:${task.completed ? 'TRUE' : 'FALSE'}',
        'END:VEVENT',
      ],
      'END:VCALENDAR',
    ];
    return '${lines.map(_foldCalendarLine).join('\r\n')}\r\n';
  }

  static String _two(int number) => number.toString().padLeft(2, '0');
  static String _calendarDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}${_two(date.month)}${_two(date.day)}';

  static String _icsText(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\n', r'\n')
      .replaceAll(',', r'\,')
      .replaceAll(';', r'\;');

  /// Fold at 75 octets without splitting a UTF-8 code point. Continuation space
  /// consumes one byte of the next physical line's allowance.
  static String _foldCalendarLine(String line) {
    final chunks = <String>[];
    var part = StringBuffer();
    var bytes = 0;
    for (final rune in line.runes) {
      final char = String.fromCharCodes([rune]);
      final size = utf8.encode(char).length;
      if (bytes + size > 75) {
        chunks.add(part.toString());
        part = StringBuffer(' ');
        bytes = 1;
      }
      part.write(char);
      bytes += size;
    }
    chunks.add(part.toString());
    return chunks.join('\r\n');
  }

  static String report(DemoStore store) {
    final stats = _WeekStats(store);
    final lines = <String>[
      'MPL · Haftalik mentor hisoboti',
      '${DemoStore.dayKey(stats.start)} — ${store.todayKey}',
      if (store.isSampleData) 'DEMO: hisobotda namunaviy ma’lumotlar bor.',
      'Dalillar foydalanuvchi tomonidan kiritilgan; avtomatik tasdiqlanmagan.',
      '',
      'Topshirilgan vazifalar: ${stats.completed.length}',
      'Fokus: ${stats.focusMinutes} daqiqa',
      'Odatlar: ${stats.habitsDone}/${stats.habitsPlanned} reja bajarildi',
      'Faol kunlar seriyasi: ${store.streak} kun',
      '',
      'NATIJALAR',
      if (stats.completed.isEmpty) 'Bu 7 kunda hali topshirilgan vazifa yo‘q.',
      for (final task in stats.completed) ...[
        '• ${task.title} (${task.project})',
        '  Dalil: ${task.proof}',
        if (task.evidenceUrl.isNotEmpty) '  Havola: ${task.evidenceUrl}',
      ],
      '',
      'MAQSADLAR',
      if (store.goals.isEmpty) 'Hali maqsad qo‘shilmagan.',
      for (final goal in store.goals)
        '• ${goal.title}: ${goal.current}/${goal.target} ${goal.metric}; muddat ${DemoStore.dayKey(goal.deadline)}',
      '',
      'KEYINGI QADAMLAR',
      ...store.weeklyReview.map((text) => '• $text'),
    ];
    return lines.join('\n');
  }
}

class _WeekStats {
  _WeekStats(this.store);
  final DemoStore store;
  DateTime get start => _previous(store.today, 6);
  List<DateTime> get days =>
      List.generate(7, (index) => _previous(store.today, 6 - index));
  List<DemoTask> get completed =>
      store.tasks.where((task) {
        final date = task.completedAt ?? task.dueDate;
        return task.completed &&
            !date.isBefore(start) &&
            DemoStore.dayKey(date).compareTo(store.todayKey) <= 0;
      }).toList()..sort(
        (a, b) =>
            (b.completedAt ?? b.dueDate).compareTo(a.completedAt ?? a.dueDate),
      );
  int get focusMinutes =>
      days.fold(0, (sum, day) => sum + store.focusMinutesForDay(day));
  int get habitsPlanned =>
      days.fold(0, (sum, day) => sum + store.scheduledHabits(day).length);
  int get habitsDone => days.fold(
    0,
    (sum, day) =>
        sum +
        store
            .scheduledHabits(day)
            .where(
              (habit) =>
                  (habit.logs[DemoStore.dayKey(day)] ?? 0) >= habit.target,
            )
            .length,
  );
  int plannedFor(DemoHabit habit) =>
      days.where((day) => habit.weekdays.contains(day.weekday)).length;
  int doneFor(DemoHabit habit) => days
      .where(
        (day) =>
            habit.weekdays.contains(day.weekday) &&
            (habit.logs[DemoStore.dayKey(day)] ?? 0) >= habit.target,
      )
      .length;
}

DateTime _previous(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day - days);

class DemoReview extends StatelessWidget {
  const DemoReview({super.key, required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final stats = _WeekStats(store);
      return _ReviewPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow('O‘SISHNI KO‘RING'),
            const SizedBox(height: 10),
            Text(
              'Harakatlaringiz iz qoldiradi.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Oxirgi 7 kun · ${_dateLabel(stats.start)} — ${_dateLabel(store.today)}',
              style: const TextStyle(color: _muted),
            ),
            const SizedBox(height: 26),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 600
                    ? 1
                    : constraints.maxWidth < 950
                    ? 2
                    : 4;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children:
                      [
                            _Metric(
                              value: '${stats.completed.length}',
                              label: 'Topshirilgan vazifa',
                              icon: Icons.task_alt_rounded,
                              color: _mint,
                            ),
                            _Metric(
                              value: '${stats.focusMinutes}',
                              label: 'Fokus daqiqasi',
                              icon: Icons.timelapse_rounded,
                              color: _cyan,
                            ),
                            _Metric(
                              value: stats.habitsPlanned == 0
                                  ? '—'
                                  : '${(stats.habitsDone / stats.habitsPlanned * 100).round()}%',
                              label: 'Odatlarga amal qilish',
                              icon: Icons.loop_rounded,
                              color: _mint,
                            ),
                            _Metric(
                              value: '${store.streak} kun',
                              label: '${store.xp} XP · ${store.level}-daraja',
                              icon: Icons.local_fire_department_outlined,
                              color: MLPColors.warning,
                            ),
                          ]
                          .map(
                            (card) => SizedBox(
                              width:
                                  (constraints.maxWidth - 14 * (columns - 1)) /
                                  columns,
                              child: card,
                            ),
                          )
                          .toList(),
                );
              },
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final panels = [
                  Expanded(
                    child: _FocusChart(store: store, stats: stats),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _HabitReview(store: store, stats: stats),
                  ),
                ];
                return constraints.maxWidth >= 900
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: panels,
                      )
                    : Column(
                        children: [
                          _FocusChart(store: store, stats: stats),
                          const SizedBox(height: 20),
                          _HabitReview(store: store, stats: stats),
                        ],
                      );
              },
            ),
            const SizedBox(height: 22),
            _ReviewPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    'Haftalik ko‘rib chiqish',
                    'Ma’lumotlaringizdan hisoblangan xulosa',
                  ),
                  const SizedBox(height: 18),
                  ...store.weeklyReview.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _mint.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: _mint,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(height: 1.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Text(
                    'Qoidalar asosidagi xulosa · AI tahlili ulanmagan',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _Portfolio(store: store),
          ],
        ),
      );
    },
  );
}

class _FocusChart extends StatelessWidget {
  const _FocusChart({required this.store, required this.stats});
  final DemoStore store;
  final _WeekStats stats;

  @override
  Widget build(BuildContext context) {
    final values = stats.days.map(store.focusMinutesForDay).toList();
    final max = values.fold<int>(25, (a, b) => a > b ? a : b);
    const weekdays = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    return _ReviewPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            'Fokus ritmi',
            'Faqat saqlangan fokus sessiyalari',
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 205,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                7,
                (index) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${values[index]}',
                          style: TextStyle(
                            fontSize: 11,
                            color: index == 6 ? _mint : _muted,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          height: values[index] == 0
                              ? 2
                              : 120 * values[index] / max,
                          width: 34,
                          decoration: BoxDecoration(
                            color: values[index] == 0
                                ? _line
                                : index == 6
                                ? _mint
                                : _cyan.withValues(alpha: .65),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          weekdays[stats.days[index].weekday - 1],
                          style: TextStyle(
                            color: index == 6 ? _mint : _muted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${stats.days[index].day}',
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitReview extends StatelessWidget {
  const _HabitReview({required this.store, required this.stats});
  final DemoStore store;
  final _WeekStats stats;

  @override
  Widget build(BuildContext context) => _ReviewPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          'Kichik qadamlar, katta yo‘l',
          'Joriy jadval bo‘yicha 7 kunlik odatlar',
        ),
        const SizedBox(height: 25),
        if (store.habits.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 45),
            child: Text(
              'Bitta kichik odat qo‘shing. Natijalaringiz shu yerda ko‘rinadi.',
              style: TextStyle(color: _muted, height: 1.5),
            ),
          ),
        ...store.habits.map((habit) {
          final planned = stats.plannedFor(habit);
          final done = stats.doneFor(habit);
          return Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        habit.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$done / $planned kun',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: planned == 0 ? 0 : done / planned,
                    minHeight: 6,
                    backgroundColor: _line,
                    color: _cyan,
                  ),
                ),
              ],
            ),
          );
        }),
        Text(
          '${stats.habitsDone} / ${stats.habitsPlanned} reja bajarildi',
          style: const TextStyle(color: _muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _Portfolio extends StatelessWidget {
  const _Portfolio({required this.store});
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final tasks = store.tasks.where((task) => task.completed).toList()
      ..sort(
        (a, b) =>
            (b.completedAt ?? b.dueDate).compareTo(a.completedAt ?? a.dueDate),
      );
    return _ReviewPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            'Natijalar portfeli',
            '${tasks.length} ta topshirilgan vazifa · Oxirgi 10 ta natija',
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'Vazifani natija dalili bilan topshiring. Sizning amaliy portfelingiz shu yerda yig‘iladi.',
                style: TextStyle(color: _muted, height: 1.6),
              ),
            ),
          ...tasks
              .take(10)
              .map(
                (task) => Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(
                      left: 38,
                      bottom: 18,
                    ),
                    leading: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: _mint,
                      size: 23,
                    ),
                    title: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${task.project} · ${_dateLabel(task.completedAt ?? task.dueDate)}',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              task.proof,
                              style: const TextStyle(
                                color: _muted,
                                height: 1.7,
                              ),
                            ),
                            if (task.evidenceUrl.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SelectableText(
                                task.evidenceUrl,
                                style: const TextStyle(
                                  color: _cyan,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 8),
          const Text(
            'Dalillar foydalanuvchi kiritgan hisobot; avtomatik tasdiqlanmagan.',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class DemoHub extends StatelessWidget {
  const DemoHub({super.key, required this.store, this.onDataReplaced});
  final DemoStore store;
  final VoidCallback? onDataReplaced;
  static const _starterProject = 'Junior start · 7 kun';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => _ReviewPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('BIRGA O‘SISH'),
          const SizedBox(height: 10),
          Text(
            'O‘sishingizga yo‘l oching.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Reja boshlang, natijani ulashing va ma’lumotlaringizni o‘zingiz bilan olib yuring.',
            style: TextStyle(color: _muted, height: 1.6),
          ),
          const SizedBox(height: 26),
          _ReviewPanel(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Eyebrow('7 KUNLIK TAYYOR SHABLON'),
                    const SizedBox(height: 12),
                    Text(
                      'Junior’dan amaliy natijaga.',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Yo‘nalishni tanlashdan portfolio case study’sigacha. Har kunga bitta aniq vazifa va natija.',
                      style: TextStyle(color: _muted, height: 1.6),
                    ),
                    const SizedBox(height: 17),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Tag('7 ta vazifa'),
                        _Tag('25–50 daqiqa / kun'),
                        _Tag('AI yaratmagan shablon'),
                      ],
                    ),
                  ],
                );
                final button = FilledButton.icon(
                  onPressed: () => _addStarter(context),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    store.tasks.any((task) => task.project == _starterProject)
                        ? 'Rejaga qo‘shilgan'
                        : '7 kunlik rejani ko‘rish',
                  ),
                );
                return constraints.maxWidth < 700
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [content, const SizedBox(height: 24), button],
                      )
                    : Row(
                        children: [
                          Expanded(child: content),
                          const SizedBox(width: 35),
                          button,
                        ],
                      );
              },
            ),
          ),
          const SizedBox(height: 26),
          const _SectionTitle(
            'Ma’lumotlaringiz siz bilan',
            'Barchasi qo‘lda boshqariladi. Hisob ulash talab qilinmaydi.',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 600 ? 1 : 2;
              final width =
                  (constraints.maxWidth - 16 * (columns - 1)) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _HubAction(
                    icon: Icons.backup_outlined,
                    title: 'JSON zaxira nusxasi',
                    body:
                        'Vazifalar, dalillar, odatlar, fokus va maqsadlarning to‘liq nusxasi.',
                    button: 'JSON eksport',
                    onPressed: () => _showExport(
                      context,
                      title: 'Zaxira nusxasini saqlash',
                      filename: 'mpl-${store.todayKey}.json',
                      content: store.exportJson(),
                      description:
                          'Matnni nusxalang va .json fayl sifatida saqlang. Bu faylni keyin MPL’ga qayta import qilish mumkin.',
                    ),
                  ),
                  _HubAction(
                    icon: Icons.restore_page_outlined,
                    title: 'Zaxiradan qayta tiklash',
                    body:
                        'MPL JSON nusxasini joylashtiring. Joriy demo ma’lumotlari almashtiriladi.',
                    button: 'JSON import',
                    onPressed: () => _showImport(context),
                  ),
                  _HubAction(
                    icon: Icons.table_chart_outlined,
                    title: 'Excel va Google Sheets',
                    body:
                        'Vazifalar va natija dalillarini UTF-8 CSV formatiga o‘tkazing.',
                    button: 'CSV eksport',
                    onPressed: () => _showExport(
                      context,
                      title: 'Vazifalarni jadvalga olib chiqish',
                      filename: 'mpl-vazifalar-${store.todayKey}.csv',
                      content: DemoExports.csv(store),
                      description:
                          'Matnni .csv faylga UTF-8 formatida saqlang. Excel yoki Google Sheets orqali oching. Formulaga o‘xshash matnlar xavfsiz matn sifatida chiqariladi.',
                    ),
                  ),
                  _HubAction(
                    icon: Icons.calendar_month_outlined,
                    title: 'Taqvimga olib chiqish',
                    body:
                        'Vazifalarni kunlik hodisa sifatida Google, Apple yoki Outlook taqvimiga import qiling.',
                    button: 'ICS eksport',
                    onPressed: () => _showExport(
                      context,
                      title: 'Taqvim faylini tayyorlash',
                      filename: 'mpl-reja-${store.todayKey}.ics',
                      content: DemoExports.ics(store),
                      description:
                          'Nusxalab, .ics faylga UTF-8 formatida saqlang va taqvim ilovangizda import qiling. Bu bir martalik eksport; avtomatik sinxronlash emas. Takroriy import ayrim taqvimlarda dublikat yaratishi mumkin.',
                    ),
                  ),
                ].map((card) => SizedBox(width: width, child: card)).toList(),
              );
            },
          ),
          const SizedBox(height: 22),
          _ReviewPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(
                  'Mentor bilan mazmunli suhbat',
                  'Natijalar bilan boshlang',
                ),
                const SizedBox(height: 13),
                const Text(
                  '7 kunlik vazifalar, dalillar, fokus va maqsadlardan tayyor matnli hisobot. Nusxalang va kim bilan bo‘lishishni o‘zingiz tanlang.',
                  style: TextStyle(color: _muted, height: 1.7),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => _showExport(
                    context,
                    title: 'Mentor uchun haftalik hisobot',
                    filename: 'mpl-hisobot-${store.todayKey}.txt',
                    content: DemoExports.report(store),
                    description:
                        'Hisobot faqat ko‘rsatiladi va nusxalanadi. MPL uni hech kimga yubormaydi.',
                  ),
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Hisobotni ko‘rish'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _ReviewPanel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.link_rounded, color: _muted, size: 22),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keyingi bosqich: haqiqiy ulanishlar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Google Calendar, Notion, GitHub va mentor hamkorligi uchun server, OAuth va rozilik boshqaruvi keyin yaratiladi. Hozir avtomatik ulanish mavjud emas.',
                        style: TextStyle(
                          color: _muted,
                          height: 1.7,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _addStarter(BuildContext context) async {
    if (store.storageError != null) {
      _message(
        context,
        'Avval zaxira nusxasini tiklang yoki sozlamalarda saqlovni tozalang.',
      );
      return;
    }
    if (store.tasks.any((task) => task.project == _starterProject)) {
      _message(
        context,
        'Bu 7 kunlik reja allaqachon qo‘shilgan. Reja bo‘limida ko‘ring.',
      );
      return;
    }
    const titles = [
      'Yo‘nalish va birinchi aniq natijani tanlash',
      'Tanlangan roldagi 5 ta vakansiyani tahlil qilish',
      'Kichik loyiha muammosi va yechimini yozish',
      'Loyihaning birinchi ishlaydigan qismini yaratish',
      'Natijani tekshirish va 3 ta xatoni tuzatish',
      'Portfolio uchun qisqa case study yozish',
      'Natijani baholash va keyingi haftani rejalash',
    ];
    const minutes = [25, 30, 25, 50, 50, 40, 25];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('7 kunlik rejani qo‘shish'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bugundan boshlab 7 kunning har biriga bitta vazifa qo‘shiladi. Bu tayyor junior shabloni; mavjud vazifalaringiz saqlanadi.',
                  style: TextStyle(color: _muted, height: 1.6),
                ),
                const SizedBox(height: 18),
                ...List.generate(
                  7,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${index + 1}. ${titles[index]} · ${minutes[index]} daqiqa',
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('7 ta vazifani qo‘shish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // One validated transaction keeps a failed write from leaving half a plan.
    try {
      if (store.tasks.any((task) => task.project == _starterProject)) return;
      final snapshot = jsonDecode(store.exportJson()) as Map<String, dynamic>;
      final rows = snapshot['tasks'] as List;
      final ids = store.tasks.map((task) => task.id).toSet();
      for (var index = 0; index < titles.length; index++) {
        var id = 'starter-${store.todayKey}-$index';
        while (!ids.add(id)) {
          id = '$id-x';
        }
        rows.add(
          DemoTask(
            id: id,
            title: titles[index],
            project: _starterProject,
            minutes: minutes[index],
            priority: index == 0 ? 1 : 2,
            dueDate: DateTime(
              store.today.year,
              store.today.month,
              store.today.day + index,
            ),
          ).toJson(),
        );
      }
      await store.importJson(jsonEncode(snapshot));
      if (context.mounted) {
        _message(context, '7 kunlik reja qo‘shildi. Reja bo‘limida boshlang.');
      }
    } catch (error) {
      if (context.mounted) _message(context, _errorText(error));
    }
  }

  Future<void> _showImport(BuildContext context) async {
    final imported = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ImportDialog(store: store),
    );
    if (imported == true) {
      onDataReplaced?.call();
      if (context.mounted) {
        _message(context, 'Zaxira nusxasi muvaffaqiyatli tiklandi.');
      }
    }
  }
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.store});
  final DemoStore store;
  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = 'JSON matnini joylashtiring.');
      return;
    }
    final replace = await showDialog<bool>(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: const Text('Joriy ma’lumotlar almashtirilsinmi?'),
        content: const Text(
          'Avval JSON eksport bilan zaxira oling. Import vazifalar, dalillar, odatlar, maqsadlar va fokus tarixini nusxadagisi bilan almashtiradi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext, false),
            child: const Text('Orqaga'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(confirmContext, true),
            child: const Text('Almashtirish'),
          ),
        ],
      ),
    );
    if (replace != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.store.importJson(_controller.text);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _errorText(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('MPL JSON nusxasini import qilish'),
    content: SizedBox(
      width: 570,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Faqat MPL demo v1 JSON nusxasi qabul qilinadi. Maksimum 2 MB. Import joriy demo ma’lumotlarini almashtiradi.',
              style: TextStyle(color: _muted, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 17),
            TextField(
              controller: _controller,
              enabled: !_busy,
              minLines: 6,
              maxLines: 10,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                hintText: 'JSON matnini shu yerga joylashtiring',
                border: const OutlineInputBorder(),
                errorText: _error,
                errorMaxLines: 4,
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context, false),
        child: const Text('Bekor qilish'),
      ),
      FilledButton(
        onPressed: _busy ? null : _import,
        child: Text(_busy ? 'Tekshirilmoqda…' : 'Tekshirish va import'),
      ),
    ],
  );
}

Future<void> _showExport(
  BuildContext context, {
  required String title,
  required String filename,
  required String content,
  required String description,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: Text(title),
    content: SizedBox(
      width: 650,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(dialogContext).height * .6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 12),
            Text(filename, style: const TextStyle(color: _mint, fontSize: 12)),
            const SizedBox(height: 12),
            Flexible(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1014),
                  border: Border.all(color: _line),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    content,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: const Text('Yopish'),
      ),
      FilledButton.icon(
        onPressed: () async {
          try {
            await Clipboard.setData(ClipboardData(text: content));
            if (dialogContext.mounted) {
              _message(dialogContext, 'Matn nusxalandi.');
            }
          } catch (_) {
            if (dialogContext.mounted) {
              _message(
                dialogContext,
                'Nusxalab bo‘lmadi. Matnni belgilang va qo‘lda nusxalang.',
              );
            }
          }
        },
        icon: const Icon(Icons.copy_rounded, size: 16),
        label: const Text('Nusxalash'),
      ),
    ],
  ),
);

String _errorText(Object error) => error is FormatException
    ? error.message
    : error is ArgumentError
    ? '${error.message}'
    : 'Ma’lumotni saqlab bo‘lmadi. Nusxani tekshirib, qayta urinib ko‘ring.';

void _message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

String _dateLabel(DateTime date) {
  const months = [
    'yan',
    'fev',
    'mar',
    'apr',
    'may',
    'iyun',
    'iyul',
    'avg',
    'sen',
    'okt',
    'noy',
    'dek',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

class _ReviewPage extends StatelessWidget {
  const _ReviewPage({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1260),
        child: Padding(padding: const EdgeInsets.all(28), child: child),
      ),
    ),
  );
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: _panel,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: _line),
      borderRadius: BorderRadius.circular(18),
    ),
    child: SizedBox(
      width: double.infinity,
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _mint,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.subtitle);
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 7),
      Text(
        subtitle,
        style: const TextStyle(color: _muted, fontSize: 11, height: 1.5),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value, label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => _ReviewPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 23),
        const SizedBox(height: 20),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
  );
}

class _HubAction extends StatelessWidget {
  const _HubAction({
    required this.icon,
    required this.title,
    required this.body,
    required this.button,
    required this.onPressed,
  });
  final IconData icon;
  final String title, body, button;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => _ReviewPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _cyan, size: 26),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(color: _muted, fontSize: 12, height: 1.7),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_outward_rounded, size: 15),
          label: Text(button),
        ),
      ],
    ),
  );
}
