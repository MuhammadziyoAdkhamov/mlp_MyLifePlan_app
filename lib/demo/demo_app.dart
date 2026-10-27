import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'demo_store.dart';
import 'demo_forms.dart';
import 'demo_review.dart';
import '../app/theme/mlp_design_system.dart';
import '../features/onboarding/mlp_account_flow.dart';
import '../data/repositories/mlp_ui_repository.dart';
import '../features/goals/mlp_goal_flow.dart';
import '../features/goals/mlp_goal_detail.dart';
import '../app/router/mlp_routes.dart';

const _bg = MLPColors.background,
    _panel = MLPColors.secondary,
    _line = MLPColors.border;
const _ink = MLPColors.text,
    _muted = MLPColors.secondaryText,
    _mint = MLPColors.primaryLight;
const _cyan = MLPColors.turquoise, _orange = MLPColors.warning;
const _week = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
const _months = [
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
String _date(DateTime d) => '${d.day} ${_months[d.month - 1]}';
String _clock(int s) =>
    '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

class MplDemoApp extends StatelessWidget {
  const MplDemoApp({
    super.key,
    required this.store,
    required this.prefs,
    this.clock,
    this.enableOnboarding = true,
  });
  final DemoStore store;
  final SharedPreferences prefs;
  final DateTime Function()? clock;
  final bool enableOnboarding;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'MLP — Har kuni natija',
    theme: MLPTheme.dark,
    locale: const Locale('uz'),
    supportedLocales: const [Locale('uz'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    navigatorObservers: [MLPRouteFeedbackObserver()],
    home: enableOnboarding
        ? MLPEntryGate(
            prefs: prefs,
            homeBuilder: (ui) => _Workspace(
              store: store,
              prefs: prefs,
              clock: clock ?? DateTime.now,
              ui: ui,
            ),
          )
        : _Workspace(store: store, prefs: prefs, clock: clock ?? DateTime.now),
  );
}

class _Workspace extends StatefulWidget {
  const _Workspace({
    required this.store,
    required this.prefs,
    required this.clock,
    this.ui,
  });
  final DemoStore store;
  final SharedPreferences prefs;
  final DateTime Function() clock;
  final MLPLocalUiRepository? ui;
  @override
  State<_Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<_Workspace> with WidgetsBindingObserver {
  DemoStore get s => widget.store;
  int page = 0, planTab = 0, filter = 0;
  late String name;
  String? focusTask;
  int length = 1500, elapsed = 0, anchorElapsed = 0;
  bool running = false, saving = false;
  Timer? ticker;
  Timer? dayTicker;
  late String renderedDay;
  int dailyBudget = 90;
  DateTime? anchor;
  int get remaining => length - elapsed;
  static const titles = [
    'Bugun',
    'Mening rejam',
    'Fokus xonasi',
    'Natijalar',
    'Markaz',
  ];
  static const icons = [
    Icons.grid_view_rounded,
    Icons.checklist_rounded,
    Icons.timelapse_rounded,
    Icons.bar_chart_rounded,
    Icons.hub_outlined,
  ];

  @override
  void initState() {
    super.initState();
    name =
        widget.ui?.profile?.name ??
        widget.prefs.getString('mpl_demo_name') ??
        'Foydalanuvchi';
    dailyBudget =
        widget.ui?.preferences.minutes ??
        widget.prefs.getInt('mpl_demo_daily_budget') ??
        90;
    renderedDay = s.todayKey;
    dayTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && renderedDay != s.todayKey) {
        setState(() => renderedDay = s.todayKey);
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    ticker?.cancel();
    dayTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (running && state != AppLifecycleState.resumed) _pause();
  }

  void _toast(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
  Future<void> _act(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      if (mounted) _toast('$e');
    }
  }

  Future<void> _createGoal() => widget.ui == null
      ? DemoForms.goal(context, s)
      : openMLPGoalFlow(context, s, widget.ui!);

  void _start() {
    if (running || saving) return;
    setState(() {
      running = true;
      anchor = widget.clock();
      anchorElapsed = elapsed;
    });
    ticker?.cancel();
    ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || !running) return;
      setState(
        () => elapsed =
            (anchorElapsed + widget.clock().difference(anchor!).inSeconds)
                .clamp(0, length),
      );
      if (remaining <= 0) unawaited(_saveFocus());
    });
  }

  void _pause() {
    ticker?.cancel();
    setState(() {
      if (running && anchor != null) {
        elapsed = (anchorElapsed + widget.clock().difference(anchor!).inSeconds)
            .clamp(0, length);
      }
      running = false;
    });
  }

  Future<void> _saveFocus() async {
    if (saving) return;
    _pause();
    if (elapsed <= 0) return;
    setState(() => saving = true);
    try {
      await s.addFocusSession(taskId: focusTask, seconds: elapsed);
      if (!mounted) return;
      _toast(
        '${elapsed ~/ 60} daq ${elapsed % 60} soniya saqlandi. Natijani topshirishni unutmang.',
      );
      setState(() => elapsed = 0);
    } catch (e) {
      if (mounted) _toast('$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _focusOn(DemoTask task) {
    if (running || elapsed > 0) {
      setState(() => page = 2);
      _toast('Avval joriy fokusni saqlang yoki qayta boshlang.');
      return;
    }
    setState(() {
      focusTask = task.id;
      length = task.minutes * 60;
      page = 2;
    });
  }

  void _goPlan(int tab) => setState(() {
    page = 1;
    planTab = tab;
  });

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: s,
    builder: (context, _) => LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1050;
        return Scaffold(
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  backgroundColor: _panel,
                  indicatorColor: _mint.withValues(alpha: .16),
                  selectedIndex: page,
                  onDestinationSelected: (i) => setState(() => page = i),
                  destinations: List.generate(
                    5,
                    (i) => NavigationDestination(
                      icon: Icon(icons[i], color: page == i ? _mint : _muted),
                      label: ['Bugun', 'Reja', 'Fokus', 'Natija', 'Markaz'][i],
                    ),
                  ),
                ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide) _sidebar(),
                Expanded(
                  child: Column(
                    children: [
                      _topbar(wide),
                      if (s.storageError != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: _notice(s.storageError!),
                        ),
                      if (running && page != 2)
                        InkWell(
                          onTap: () => setState(() => page = 2),
                          child: Container(
                            width: double.infinity,
                            color: _mint.withValues(alpha: .10),
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Fokus davom etmoqda · ${_clock(remaining)} →',
                              style: const TextStyle(color: _mint),
                            ),
                          ),
                        ),
                      Expanded(
                        child: page == 3
                            ? DemoReview(store: s)
                            : page == 4
                            ? DemoHub(
                                store: s,
                                onDataReplaced: () {
                                  _pause();
                                  setState(() {
                                    focusTask = null;
                                    elapsed = 0;
                                  });
                                },
                              )
                            : SingleChildScrollView(
                                key: ValueKey('page-$page'),
                                padding: EdgeInsets.all(wide ? 32 : 18),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 1260,
                                    ),
                                    child: switch (page) {
                                      0 => _today(wide),
                                      1 => _plan(),
                                      _ => _focus(),
                                    },
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _sidebar() => Container(
    width: 224,
    decoration: const BoxDecoration(
      color: MLPColors.secondary,
      border: Border(right: BorderSide(color: _line)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.arrow_outward_rounded, color: _bg),
            ),
            const SizedBox(width: 12),
            const Text(
              'MLP',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 10, bottom: 32),
          child: Text(
            'Har kuni. Haqiqiy natija.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        FilledButton.icon(
          onPressed: () => DemoForms.task(context, s),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Yangi vazifa'),
        ),
        const SizedBox(height: 28),
        ...List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: page == i
                  ? _mint.withValues(alpha: .10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => page = i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icons[i],
                        size: 20,
                        color: page == i ? _mint : _muted,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          titles[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: page == i ? _mint : _muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        _box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.local_fire_department_outlined, color: _orange),
              const SizedBox(height: 9),
              Text(
                '${s.streak} kunlik davomiylik',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kichik qadam ham hisoblanadi.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 14),
              _progress((s.xp % 250) / 250),
              const SizedBox(height: 7),
              Text(
                '${s.level}-daraja · ${s.xp} XP',
                style: const TextStyle(fontSize: 11, color: _mint),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            Icon(Icons.lock_outline, size: 14, color: _muted),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                'Mahalliy demo · v1.0',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _topbar(bool wide) => Container(
    padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 18, vertical: 15),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _line)),
    ),
    child: Row(
      children: [
        if (!wide)
          const Text(
            'MLP',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _mint,
            ),
          ),
        if (wide) ...[
          const Text(
            'Mening makonim',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('/', style: TextStyle(color: _line)),
          ),
          Text(titles[page], style: const TextStyle(fontSize: 12)),
        ],
        const Spacer(),
        _tag(
          s.isSampleData ? 'NAMUNA MA’LUMOTLAR' : 'QURILMADA SAQLANADI',
          _muted,
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Sozlamalar',
          onPressed: _settings,
          icon: const Icon(Icons.tune_rounded, size: 20, color: _muted),
        ),
        if (wide) ...[
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 17,
            backgroundColor: _line,
            child: Text(
              name.isEmpty ? 'M' : name[0].toUpperCase(),
              style: const TextStyle(fontSize: 13, color: _mint),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _today(bool wide) {
    final top = s.todayTasks.where((t) => !t.completed).firstOrNull;
    final now = DateTime.now(), habits = s.scheduledHabits();
    final done = habits
        .where((h) => s.habitValue(h.id) >= h.targetForDate(s.today))
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('${_week[now.weekday - 1]}, ${_date(now)} ${now.year}'),
        const SizedBox(height: 9),
        _heading('Xayrli kun, $name.', wide ? 34 : 28),
        const SizedBox(height: 9),
        const Text(
          'Bugun band bo‘lish uchun emas — oldinga yurish uchun.',
          style: TextStyle(color: _muted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 28),
        _columns(wide, [
          Expanded(
            flex: 7,
            child: _box(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.north_east_rounded,
                        color: _mint,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'BUGUNGI ASOSIY QADAM',
                          style: TextStyle(
                            color: _mint,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
                      if (top != null) _tag('${top.minutes} DAQ', _mint),
                    ],
                  ),
                  const SizedBox(height: 23),
                  _heading(
                    top?.title ?? 'Birinchi aniq qadamingizni tanlang.',
                    wide ? 27 : 23,
                  ),
                  const SizedBox(height: 11),
                  Text(
                    top == null
                        ? 'Natijasi ko‘rinadigan bitta ish yozing. Kichik boshlash mumkin.'
                        : '${top.project} · ${_date(top.dueDate)} · ${top.priority == 1 ? 'Muhim vazifa' : 'Rejadagi vazifa'}',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: top == null
                            ? () => DemoForms.task(context, s)
                            : () => _focusOn(top),
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: Text(
                          top == null
                              ? 'Birinchi vazifani yozish'
                              : 'Fokusni boshlash',
                        ),
                      ),
                      if (top != null)
                        OutlinedButton.icon(
                          onPressed: () => DemoForms.submit(context, s, top),
                          icon: const Icon(Icons.upload_rounded, size: 18),
                          label: const Text('Natijani topshirish'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    'Reja → Fokus → Dalil → Tahlil',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
              color: MLPColors.elevated,
            ),
          ),
          const SizedBox(width: 20, height: 20),
          Expanded(
            flex: 4,
            child: _box(
              Row(
                children: [
                  _ring(
                    s.score / 100,
                    '${s.score}%',
                    'kun ritmi',
                    size: wide ? 124 : 108,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bugungi harakat',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 17),
                        _metric('${s.todayCompleted}', 'topshirilgan ish'),
                        const SizedBox(height: 14),
                        _metric(
                          '${s.todayFocusMinutes} daq',
                          'jamlangan fokus',
                        ),
                        const SizedBox(height: 14),
                        _metric('$done / ${habits.length}', 'kundalik odat'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
        const SizedBox(height: 26),
        _columns(wide, [
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section(
                  'Kun tartibi',
                  '${s.todayTasks.length} vazifa',
                  () => _goPlan(0),
                ),
                const SizedBox(height: 14),
                _box(
                  Column(
                    children: [
                      if (s.todayTasks.isEmpty)
                        _empty(
                          'Bugun uchun reja ochiq.',
                          'Bitta muhim ish qo‘shing.',
                          () => DemoForms.task(context, s),
                        ),
                      ...s.todayTasks.take(4).map((t) => _taskRow(t)),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextButton.icon(
                          onPressed: () => DemoForms.task(context, s),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Vazifa qo‘shish'),
                        ),
                      ),
                    ],
                  ),
                  padding: 6,
                ),
                const SizedBox(height: 24),
                _section('30 kunlik yo‘nalish', 'Maqsadlar', () => _goPlan(2)),
                const SizedBox(height: 14),
                if (s.goals.isEmpty)
                  _box(
                    _empty(
                      'Qayerga bormoqchisiz?',
                      'O‘lchanadigan natija belgilang.',
                      _createGoal,
                    ),
                  )
                else
                  ...s.goals
                      .take(2)
                      .map(
                        (g) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _goal(g),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(width: 22, height: 22),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('Kichik odatlar', 'Jadval', () => _goPlan(1)),
                const SizedBox(height: 14),
                _box(
                  Column(
                    children: [
                      if (habits.isEmpty)
                        _empty(
                          'Bugungi odatlar yo‘q.',
                          'O‘zingizga mos jadval tuzing.',
                          () => DemoForms.habit(context, s),
                        ),
                      ...habits.take(4).map((h) => _habit(h, compact: true)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _box(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.wb_sunny_outlined,
                            color: _orange,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _heading('O‘zingizni tekshiring', 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.todayCheckin == null
                            ? 'Bugun qancha kuchingiz bor? Rejangiz sizga mos bo‘lsin.'
                            : 'Kayfiyat: ${s.todayCheckin!.mood}/5 · energiya: ${s.todayCheckin!.energy}/5',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () => DemoForms.checkin(context, s),
                        child: const Text('Kunlik qayd →'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  Widget _plan() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _eyebrow('ANIQ NIYAT. KICHIK QADAM.'),
      const SizedBox(height: 10),
      _heading('Natijaga olib boradigan reja.', 28),
      const SizedBox(height: 11),
      const Text(
        'Vazifalar, odatlar va maqsadlar — bitta joyda.',
        style: TextStyle(color: _muted),
      ),
      const SizedBox(height: 26),
      Wrap(
        spacing: 8,
        runSpacing: 10,
        children: List.generate(
          3,
          (i) => ChoiceChip(
            label: Text(['Vazifalar', 'Odatlar', 'Maqsadlar'][i]),
            selected: planTab == i,
            onSelected: (_) => setState(() => planTab = i),
          ),
        ),
      ),
      const SizedBox(height: 22),
      if (planTab == 0) ...[
        _notice(
          'Bugungi ochiq reja: ${s.todayTasks.where((t) => !t.completed).fold<int>(0, (sum, t) => sum + t.minutes)} daqiqa / kunlik sig‘im: $dailyBudget daqiqa. ${s.todayTasks.where((t) => !t.completed).fold<int>(0, (sum, t) => sum + t.minutes) > dailyBudget ? 'Yuk ko‘p: kam muhim ishni menyudan ertaga ko‘chiring.' : 'Bitta muhim natijadan boshlang.'} Sig‘imni Sozlamalarda o‘zgartirasiz.',
        ),
        const SizedBox(height: 14),
      ],
      if (planTab == 0) ...[
        Wrap(
          spacing: 8,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...List.generate(
              3,
              (i) => TextButton(
                onPressed: () => setState(() => filter = i),
                child: Text(
                  ['Bugun', 'Hammasi', 'Topshirilgan'][i],
                  style: TextStyle(color: filter == i ? _mint : _muted),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => DemoForms.task(context, s),
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Yangi vazifa'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _box(
          Builder(
            builder: (_) {
              final tasks = filter == 0
                  ? s.todayTasks
                  : s.tasks.where((t) => filter == 1 || t.completed).toList();
              return tasks.isEmpty
                  ? _empty(
                      'Bu ro‘yxat hozir bo‘sh.',
                      'Keyingi qadamingizni yozing.',
                      () => DemoForms.task(context, s),
                    )
                  : Column(
                      children: tasks
                          .map((t) => _taskRow(t, details: true))
                          .toList(),
                    );
            },
          ),
          padding: 8,
        ),
      ],
      if (planTab == 1) ...[
        _section(
          'Muntazamlik tizimi',
          'Odat qo‘shish',
          () => DemoForms.habit(context, s),
        ),
        const SizedBox(height: 14),
        _notice(
          'Minimal qadam ham progress. Dam kunlari streakni buzmaydi; jadvalingiz hisobga olinadi.',
        ),
        const SizedBox(height: 14),
        if (s.habits.isEmpty)
          _box(
            _empty(
              'Birinchi odatingiz.',
              'Miqdor va hafta kunlarini tanlang.',
              () => DemoForms.habit(context, s),
            ),
          ),
        ...s.habits.map(
          (h) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _box(_habit(h)),
          ),
        ),
      ],
      if (planTab == 2) ...[
        _section('O‘lchanadigan maqsadlar', 'Yangi maqsad', _createGoal),
        const SizedBox(height: 14),
        if (s.goals.isEmpty)
          _box(
            _empty(
              'Maqsadni raqam bilan belgilang.',
              'Masalan: 30 kunda 12 vazifa.',
              _createGoal,
            ),
          ),
        ...s.goals.map(
          (g) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _goal(g),
          ),
        ),
      ],
    ],
  );

  Widget _taskRow(DemoTask t, {bool details = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _line, width: .5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: t.completed
              ? 'Topshirilgan natijani ko‘rish'
              : 'Natijani topshirish',
          onPressed: () => DemoForms.submit(context, s, t),
          icon: Icon(
            t.completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: t.completed ? _mint : _muted,
            size: 23,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: t.completed ? _muted : _ink,
                    decoration: t.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${t.project} · ${t.minutes} daq · ${_date(t.dueDate)}${t.priority == 1 ? ' · Muhim' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: t.priority == 1 && !t.completed ? _orange : _muted,
                  ),
                ),
                if (details && t.proof.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      t.proof,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!t.completed)
          IconButton(
            tooltip: 'Vazifaga fokus',
            onPressed: () => _focusOn(t),
            icon: const Icon(
              Icons.play_circle_outline_rounded,
              size: 22,
              color: _cyan,
            ),
          ),
        if (details)
          PopupMenuButton<String>(
            tooltip: 'Vazifa amallari',
            onSelected: (v) {
              if (v == 'edit') DemoForms.task(context, s, existing: t);
              if (v == 'defer') _act(() => s.deferTask(t.id));
              if (v == 'reopen') _act(() => s.reopenTask(t.id));
              if (v == 'delete') {
                _confirm(
                  'Vazifa o‘chirilsinmi?',
                  'Vazifa va topshirilgan matni o‘chadi.',
                  () => s.deleteTask(t.id),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
              if (!t.completed)
                const PopupMenuItem(
                  value: 'defer',
                  child: Text('Ertaga ko‘chirish'),
                ),
              if (t.completed)
                const PopupMenuItem(
                  value: 'reopen',
                  child: Text('Qayta ochish'),
                ),
              const PopupMenuItem(value: 'delete', child: Text('O‘chirish')),
            ],
          ),
      ],
    ),
  );

  Widget _habit(DemoHabit h, {bool compact = false}) {
    final value = s.habitValue(h.id), scheduled = h.scheduledOn(s.today);
    final target = h.targetForDate(s.today);
    final done = value >= target;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: (done ? _mint : _cyan).withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  done ? Icons.check_rounded : Icons.eco_outlined,
                  color: done ? _mint : _cyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$value / $target ${h.unitForDate(s.today)} · ${s.habitStreak(h.id)} kun${scheduled ? '' : ' · Dam kuni'}',
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Odatga +1',
                onPressed: done || !scheduled
                    ? null
                    : () => _act(() => s.incrementHabit(h.id)),
                icon: Icon(
                  done
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  color: done
                      ? _mint
                      : scheduled
                      ? _ink
                      : _muted,
                  size: 25,
                ),
              ),
              if (!compact)
                PopupMenuButton<String>(
                  tooltip: 'Odat amallari',
                  onSelected: (v) {
                    if (v == 'edit') DemoForms.habit(context, s, existing: h);
                    if (v == 'delete') {
                      _confirm(
                        'Odat o‘chirilsinmi?',
                        'Odat va uning kunlik yozuvlari o‘chadi.',
                        () => s.deleteHabit(h.id),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
                    PopupMenuItem(value: 'delete', child: Text('O‘chirish')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          _progress((value / target).clamp(0, 1), color: done ? _mint : _cyan),
          if (!compact) ...[
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(child: _habitWeek(h)),
                if (value > 0)
                  IconButton(
                    tooltip: 'Bugungi qiymatni qaytarish',
                    onPressed: () => _act(() => s.undoHabit(h.id)),
                    icon: const Icon(
                      Icons.undo_rounded,
                      size: 18,
                      color: _muted,
                    ),
                  ),
                if (scheduled && !done)
                  IconButton(
                    tooltip: 'Tanaffus sababini yozish',
                    onPressed: () => DemoForms.skip(context, s, h),
                    icon: const Icon(Icons.more_horiz, color: _muted),
                  ),
              ],
            ),
            if (h.reasons[s.todayKey] != null)
              Text(
                'Bugungi qayd: ${h.reasons[s.todayKey]}',
                style: const TextStyle(fontSize: 11, color: _orange),
              ),
          ],
        ],
      ),
    );
  }

  Widget _habitWeek(DemoHabit h) => Wrap(
    spacing: 7,
    runSpacing: 7,
    children: List.generate(7, (i) {
      final d = s.today.subtract(Duration(days: 6 - i));
      final active = h.scheduledOn(d), v = s.habitValue(h.id, d);
      return Column(
        children: [
          Text(
            _week[d.weekday - 1],
            style: const TextStyle(fontSize: 9, color: _muted),
          ),
          const SizedBox(height: 5),
          Tooltip(
            message:
                '${_date(d)}: $v/${h.targetForDate(d)} ${h.unitForDate(d)}',
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: !active
                    ? _bg
                    : v >= h.targetForDate(d)
                    ? _mint
                    : v > 0
                    ? _cyan.withValues(alpha: .35)
                    : _line,
                borderRadius: BorderRadius.circular(6),
              ),
              child: active
                  ? null
                  : const Icon(Icons.remove, size: 10, color: _muted),
            ),
          ),
        ],
      );
    }),
  );
  Widget _goal(DemoGoal g) => _box(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _tag(g.category.toUpperCase(), _cyan),
            const Spacer(),
            Text(
              _date(g.deadline),
              style: const TextStyle(fontSize: 11, color: _muted),
            ),
            PopupMenuButton<String>(
              tooltip: 'Maqsad amallari',
              onSelected: (v) {
                if (v == 'edit') DemoForms.goal(context, s, existing: g);
                if (v == 'delete') {
                  _confirm(
                    'Maqsad o‘chirilsinmi?',
                    'Bog‘langan vazifalar saqlanadi, maqsadga bog‘lanish uziladi.',
                    () => s.deleteGoal(g.id),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Tahrirlash')),
                PopupMenuItem(value: 'delete', child: Text('O‘chirish')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          g.title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        if (widget.ui != null)
          TextButton.icon(
            icon: const Icon(Icons.arrow_outward_rounded, size: 18),
            label: Text(
              widget.ui!.goalPlan(g.id)?['archived'] == true
                  ? 'Arxiv · tafsilotlar'
                  : 'Yo‘l xaritasi va tafsilotlar',
            ),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/goals/detail'),
                builder: (detailContext) => MLPGoalDetailScreen(
                  store: s,
                  ui: widget.ui!,
                  goalId: g.id,
                  onFocus: (task) {
                    Navigator.of(detailContext).pop();
                    _focusOn(task);
                  },
                ),
              ),
            ),
          ),
        const SizedBox(height: 19),
        Text(
          'Bog‘langan ishlar: ${s.goalCompletedTaskCount(g.id)} / ${s.goalTaskCount(g.id)} · quyidagi raqam qo‘lda qayd etiladi',
          style: const TextStyle(color: _muted, fontSize: 11, height: 1.5),
        ),
        const SizedBox(height: 12),
        _progress(g.progress.clamp(0, 1)),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: Text(
                '${g.current} / ${g.target} ${g.metric}',
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ),
            Text(
              '${(g.progress * 100).round()}%',
              style: const TextStyle(color: _mint, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () => DemoForms.goalProgress(context, s, g),
              child: const Text('Yangilash'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _focus() {
    final chosen = s.tasks.where((t) => t.id == focusTask).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow('BIR VAQTDA BITTA ISH'),
        const SizedBox(height: 10),
        _heading('Diqqat — eng yaxshi sarmoya.', 28),
        const SizedBox(height: 12),
        const Text(
          'Haqiqiy vaqt hisoblanadi. Ilova fon rejimiga o‘tganda taymer pauzaga tushadi.',
          style: TextStyle(color: _muted, height: 1.5),
        ),
        const SizedBox(height: 28),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _box(
              Column(
                children: [
                  _tag(
                    running
                        ? 'FOKUS DAVOM ETMOQDA'
                        : elapsed > 0
                        ? 'PAUZA'
                        : 'SIZNING FOKUS XONANGIZ',
                    running ? _mint : _muted,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    key: ValueKey('focus-$focusTask'),
                    initialValue: chosen?.id ?? '',
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Nimaga vaqt ajratamiz?',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Erkin fokus'),
                      ),
                      ...s.tasks
                          .where((t) => !t.completed || t.id == focusTask)
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(
                                t.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                    ],
                    onChanged: running || elapsed > 0
                        ? null
                        : (v) => setState(() => focusTask = v == '' ? null : v),
                  ),
                  const SizedBox(height: 25),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [25, 50, 5, 1]
                        .map(
                          (m) => ChoiceChip(
                            label: Text(m == 1 ? '1 daq · sinov' : '$m daq'),
                            selected: length == m * 60,
                            onSelected: running || elapsed > 0
                                ? null
                                : (_) => setState(() => length = m * 60),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 34),
                  _ring(
                    elapsed / length,
                    _clock(remaining),
                    running ? 'chuqur ishlash' : 'tayyormisiz?',
                    size: 242,
                    time: true,
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: saving
                            ? null
                            : running
                            ? _pause
                            : _start,
                        icon: Icon(
                          running
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          running
                              ? 'Pauza'
                              : elapsed > 0
                              ? 'Davom etish'
                              : 'Boshlash',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: elapsed <= 0 || saving ? null : _saveFocus,
                        child: const Text('Sessiyani saqlash'),
                      ),
                      IconButton(
                        tooltip: 'Qayta boshlash',
                        onPressed: elapsed == 0 && !running
                            ? null
                            : () => _confirm(
                                'Fokus qayta boshlansinmi?',
                                'Saqlanmagan $elapsed soniya hisobdan chiqadi.',
                                () async {
                                  _pause();
                                  setState(() => elapsed = 0);
                                },
                              ),
                        icon: const Icon(
                          Icons.restart_alt_rounded,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bugun ${s.todayFocusMinutes} daqiqa saqlandi. Sessiya tugashi vazifani avtomatik bajarmaydi.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _muted,
                      height: 1.6,
                    ),
                  ),
                  if (chosen != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 13),
                      child: TextButton.icon(
                        onPressed: () => DemoForms.submit(context, s, chosen),
                        icon: const Icon(Icons.upload_outlined, size: 18),
                        label: const Text('Ish tugadimi? Natijani topshirish'),
                      ),
                    ),
                ],
              ),
              padding: 28,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _notice(
          'Fokus — vaqt hisobi. Topshirilgan ish — natija hisobi. Saqlanmagan sessiya sahifa qayta yuklanganda tiklanmaydi; yakunlashda “Sessiyani saqlash”ni bosing.',
        ),
      ],
    );
  }

  Future<void> _settings() async {
    final input = TextEditingController(text: name);
    final capacity = TextEditingController(text: '$dailyBudget');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        title: const Text('Sizning makoningiz'),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: input,
                  maxLength: 40,
                  decoration: const InputDecoration(labelText: 'Ismingiz'),
                ),
                TextField(
                  controller: capacity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Kunlik vaqt sig‘imi (daqiqa, 5–720)',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ma’lumotlar shu qurilma/brauzerda saqlanadi. Markazdan JSON zaxira oling. Demo hech kimga ma’lumot yubormaydi.',
                  style: TextStyle(color: _muted, fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.auto_awesome_outlined,
                    color: _cyan,
                  ),
                  title: const Text('Namuna ma’lumotlarni yuklash'),
                  subtitle: const Text(
                    'Joriy demo holatini almashtiradi',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirm(
                      'Namuna yuklansinmi?',
                      'Avval Markazdan zaxira oling. Joriy demo ma’lumoti almashtiriladi.',
                      () async {
                        _pause();
                        await s.loadSample();
                        if (mounted) {
                          setState(() {
                            focusTask = null;
                            elapsed = 0;
                          });
                        }
                      },
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: _orange),
                  title: const Text('Toza sahifadan boshlash'),
                  subtitle: const Text(
                    'Faqat yangi demo ma’lumoti o‘chadi',
                    style: TextStyle(fontSize: 11, color: _muted),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirm(
                      'Demo ma’lumoti o‘chirilsinmi?',
                      'Vazifa, odat, maqsad, fokus va qaydlar o‘chadi. Eski MPL hisoblari saqlanadi.',
                      () async {
                        _pause();
                        await s.clearAll();
                        await widget.prefs.remove('mpl_demo_name');
                        await widget.prefs.remove('mpl_demo_daily_budget');
                        if (mounted) {
                          setState(() {
                            name = widget.ui?.profile?.name ?? 'Foydalanuvchi';
                            dailyBudget = widget.ui?.preferences.minutes ?? 90;
                            focusTask = null;
                            elapsed = 0;
                          });
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (widget.ui != null)
            TextButton(
              child: const Text('Shaxsiy tanlovlar'),
              onPressed: () async {
                Navigator.pop(ctx);
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(name: '/preferences'),
                    builder: (_) =>
                        MLPPreferencesScreen(repository: widget.ui!),
                  ),
                );
                if (mounted) {
                  setState(() => dailyBudget = widget.ui!.preferences.minutes);
                }
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Yopish'),
          ),
          FilledButton(
            onPressed: () async {
              final next = input.text.trim();
              if (next.length < 2 || next.length > 60) {
                _toast('Ism 2–60 belgidan iborat bo‘lsin.');
                return;
              }
              final budget = int.tryParse(capacity.text);
              if (budget == null || budget < 5 || budget > 720) {
                _toast('Kunlik sig‘im 5–720 daqiqa orasida bo‘lsin.');
                return;
              }
              try {
                if (widget.ui != null) {
                  await widget.ui!.saveWorkspaceIdentity(next, budget);
                } else {
                  if (!await widget.prefs.setString('mpl_demo_name', next) ||
                      !await widget.prefs.setInt(
                        'mpl_demo_daily_budget',
                        budget,
                      )) {
                    throw StateError('Saqlov yozuvni qabul qilmadi.');
                  }
                }
              } catch (_) {
                if (mounted) {
                  _toast('Tanlovlar saqlanmadi. Qayta urinib ko‘ring.');
                }
                return;
              }
              if (!mounted) return;
              setState(() {
                name = next;
                dailyBudget = budget;
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Ismni saqlash'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    String title,
    String message,
    Future<void> Function() fn,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tasdiqlash'),
          ),
        ],
      ),
    );
    if (yes == true) await _act(fn);
  }

  Widget _box(Widget child, {double padding = 23, Color color = _panel}) =>
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: _line.withValues(alpha: .7)),
        ),
        child: child,
      );
  Widget _columns(bool wide, List<Widget> children) => wide
      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: children)
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children.map((w) => w is Expanded ? w.child : w).toList(),
        );
  Widget _heading(String title, double size) => Text(
    title,
    style: TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -.5,
    ),
  );
  Widget _eyebrow(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: _muted,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.8,
    ),
  );
  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 9,
        letterSpacing: .5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  Widget _progress(double v, {Color color = _mint}) => ClipRRect(
    borderRadius: BorderRadius.circular(5),
    child: LinearProgressIndicator(
      value: v,
      minHeight: 5,
      backgroundColor: _line,
      color: color,
    ),
  );
  Widget _metric(String v, String label) => Row(
    children: [
      Text(
        v,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
      ),
    ],
  );
  Widget _section(String title, String action, VoidCallback tap) => Row(
    children: [
      Expanded(child: _heading(title, 18)),
      TextButton(
        onPressed: tap,
        child: Text(
          action,
          style: const TextStyle(fontSize: 11, color: _muted),
        ),
      ),
    ],
  );
  Widget _notice(String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _cyan.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: _cyan, size: 19),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.6),
          ),
        ),
      ],
    ),
  );
  Widget _empty(String title, String detail, VoidCallback tap) => Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      children: [
        const Icon(Icons.add_task, color: _cyan, size: 30),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        Text(detail, style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 12),
        TextButton(onPressed: tap, child: const Text('Qo‘shish →')),
      ],
    ),
  );
  Widget _ring(
    double value,
    String title,
    String subtitle, {
    double size = 130,
    bool time = false,
  }) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: value.clamp(0, 1),
            strokeWidth: time ? 10 : 8,
            strokeCap: StrokeCap.round,
            backgroundColor: _line,
            color: _mint,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: time ? 51 : 29,
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(fontSize: time ? 12 : 10, color: _muted),
            ),
          ],
        ),
      ],
    ),
  );
}
