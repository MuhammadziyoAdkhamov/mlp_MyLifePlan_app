import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/design_system/mlp_widgets.dart';
import '../core/design_system/mlp_liquid_glass.dart';
import '../demo/demo_forms.dart';
import '../data/repositories/mlp_ui_repository.dart';
import '../demo/demo_store.dart';
import '../features/ai_companion/mlp_companion_pages.dart';
import '../features/ai_companion/mlp_gemini_adapter.dart';
import '../features/focus/mlp_focus_controller.dart';
import '../features/focus/mlp_focus_pages.dart';
import '../features/goals/mlp_goal_detail.dart';
import '../features/goals/mlp_goal_flow.dart';
import '../features/lifestyle/mlp_lifestyle_pages.dart';
import '../features/onboarding/mlp_account_flow.dart';
import '../features/planner/mlp_calendar.dart';
import '../features/planner/mlp_schedule_editor.dart';
import '../features/progress/mlp_progress_pages.dart';
import '../features/workspace/mlp_workspace_pages.dart';
import 'mlp_environment.dart';
import 'router/mlp_routes.dart';
import 'theme/mlp_design_system.dart';
import '../core/design_system/mlp_haptics.dart';

class MLPProductShell extends StatefulWidget {
  const MLPProductShell({
    super.key,
    required this.store,
    required this.ui,
    required this.prefs,
    required this.clock,
    required this.legacyBuilder,
  });
  final DemoStore store;
  final MLPLocalUiRepository ui;
  final SharedPreferences prefs;
  final DateTime Function() clock;
  final Widget Function() legacyBuilder;
  @override
  State<MLPProductShell> createState() => _ProductShellState();
}

class _ProductShellState extends State<MLPProductShell>
    with WidgetsBindingObserver {
  final navigator = GlobalKey<NavigatorState>();
  final frame = GlobalKey<_TabFrameState>();
  late final MLPFocusController focus;
  late final MLPEnvironment e;
  late final MLPGeminiAdapter _gemini;
  Timer? dateTicker;
  late String day;
  @override
  void initState() {
    super.initState();
    _gemini = MLPGeminiAdapter();
    focus = MLPFocusController(widget.store, widget.ui, clock: widget.clock);
    e = MLPEnvironment(
      store: widget.store,
      ui: widget.ui,
      prefs: widget.prefs,
      focus: focus,
      clock: widget.clock,
      go: open,
      tab: tab,
      legacy: widget.legacyBuilder,
    );
    day = widget.store.todayKey;
    WidgetsBinding.instance.addObserver(this);
    dateTicker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => refreshDay(),
    );
  }

  void refreshDay() {
    if (mounted && day != widget.store.todayKey) {
      setState(() => day = widget.store.todayKey);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshDay();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    dateTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    focus.dispose();
    super.dispose();
  }

  void tab(int index) {
    navigator.currentState?.popUntil((r) => r.isFirst);
    frame.currentState?.select(index);
  }

  Future<void> open(MLPScreen screen, {MLPRouteArgs? args}) async {
    final root = {
      MLPScreen.today: 0,
      MLPScreen.projects: 1,
      MLPScreen.focus: 2,
      MLPScreen.tasks: 3,
      MLPScreen.analytics: 4,
      MLPScreen.profile: 5,
      MLPScreen.chat: 6,
    }[screen];
    if (root != null) {
      tab(root);
      return;
    }
    await navigator.currentState?.pushNamed<void>(screen.path, arguments: args);
  }

  Widget page(MLPScreen? screen, MLPRouteArgs args, Object? raw) =>
      switch (screen) {
        MLPScreen.splash => const MLPSplashScreen(),
        MLPScreen.welcome => MLPWelcomeScreen(repository: e.ui),
        MLPScreen.registration => MLPRegistrationScreen(repository: e.ui),
        MLPScreen.login => MLPLoginScreen(repository: e.ui),
        MLPScreen.preferences => MLPPreferencesScreen(repository: e.ui),
        MLPScreen.goalDiscovery => MLPGoalDiscoveryScreen(
          store: e.store,
          ui: e.ui,
        ),
        MLPScreen.goalClarification =>
          raw is MLPGoalDraft
              ? MLPGoalClarificationScreen(store: e.store, ui: e.ui, draft: raw)
              : missingDraft(),
        MLPScreen.diagnosis =>
          raw is MLPGoalDraft
              ? MLPDiagnosticScreen(store: e.store, ui: e.ui, draft: raw)
              : missingDraft(),
        MLPScreen.roadmap =>
          raw is MLPGoalDraft
              ? MLPRoadmapScreen(store: e.store, ui: e.ui, draft: raw)
              : missingDraft(),
        MLPScreen.goalDetail => MLPGoalDetailScreen(
          store: e.store,
          ui: e.ui,
          goalId: args.goalId ?? '',
          onFocus: (t) => mlpStartTask(navigator.currentContext!, e, t),
        ),
        MLPScreen.calendar => MLPCalendarScreen(
          store: e.store,
          ui: e.ui,
          clock: e.clock,
        ),
        MLPScreen.scheduleEditor =>
          args.scheduleId != null &&
                  !e.ui.schedules.any((s) => s.id == args.scheduleId)
              ? const MLPPage(
                  title: 'Mashg‘ulot',
                  children: [
                    MLPEmptyState(
                      title: 'Mashg‘ulot topilmadi',
                      message: 'Orqaga qaytib boshqa jadvalni tanlang.',
                    ),
                  ],
                )
              : MLPScheduleEditor(
                  store: e.store,
                  ui: e.ui,
                  existing: e.ui.schedules
                      .where((s) => s.id == args.scheduleId)
                      .firstOrNull,
                ),
        MLPScreen.activeFocus => MLPActiveFocusPage(e: e),
        MLPScreen.focusSummary => MLPFocusSummaryPage(e: e),
        MLPScreen.voice => MLPVoicePage(e: e),
        MLPScreen.aiPersonalization => MLPAIPreferencesPage(e: e),
        MLPScreen.verification => MLPVerificationPage(
          e: e,
          initialTaskId: args.taskId,
        ),
        MLPScreen.passport => MLPPassportPage(e: e),
        MLPScreen.analytics => MLPGrowthPage(e: e),
        MLPScreen.chat => MLPScaffold(body: MLPChatPage(e: e, adapter: _gemini, showBack: true)),
        MLPScreen.profile => MLPScaffold(
          body: MLPProfilePage(e: e, showBack: true),
        ),
        MLPScreen.rewards => MLPRewardsPage(e: e),
        MLPScreen.weather => MLPWeatherPage(e: e),
        MLPScreen.soundspace => MLPSoundspacePage(e: e),
        MLPScreen.settings => MLPSettingsPage(e: e),
        MLPScreen.notifications => MLPNotificationsPage(e: e),
        MLPScreen.today => MLPScaffold(body: MLPTodayPage(e: e)),
        MLPScreen.projects => MLPScaffold(body: MLPGoalsPage(e: e)),
        MLPScreen.tasks => MLPScaffold(body: MLPTasksPage(e: e)),
        MLPScreen.focus => MLPScaffold(
          title: 'Fokus sessiyasi',
          body: MLPFocusHub(e: e),
        ),
        null => const MLPPage(
          title: 'Sahifa topilmadi',
          children: [
            MLPEmptyState(
              title: 'Bu manzil mavjud emas',
              message: 'Orqaga qaytib asosiy menyudan davom eting.',
            ),
          ],
        ),
      };
  Widget missingDraft() => MLPPage(
    title: 'Maqsad loyihasi',
    children: [
      MLPEmptyState(
        title: 'Avval maqsadni kiriting',
        message:
            'Aniqlashtirish, baholash va yo‘l xaritasi maqsad yaratish ketma-ketligida ochiladi.',
        action: 'Maqsad tanlash',
        onAction: () => open(MLPScreen.goalDiscovery),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => NavigatorPopHandler<void>(
    onPopWithResult: (_) {
      final nav = navigator.currentState;
      if (nav?.canPop() == true) {
        nav!.maybePop();
      } else {
        tab(0);
      }
    },
    child: Navigator(
      key: navigator,
      observers: [MLPRouteFeedbackObserver()],
      onGenerateRoute: (settings) => _MLPPageRoute(
        reducedMotion: MediaQuery.disableAnimationsOf(context),
        settings: settings,
        builder: (context) => settings.name == '/'
            ? _TabFrame(key: frame, e: e, adapter: _gemini)
            : page(
                MLPScreen.parse(settings.name),
                settings.arguments is MLPRouteArgs
                    ? settings.arguments as MLPRouteArgs
                    : const MLPRouteArgs(),
                settings.arguments,
              ),
      ),
    ),
  );
}

class _MLPPageRoute extends CupertinoPageRoute<void> {
  _MLPPageRoute({
    required super.builder,
    super.settings,
    required this.reducedMotion,
  });
  final bool reducedMotion;
  @override
  Duration get transitionDuration =>
      reducedMotion ? Duration.zero : super.transitionDuration;
  @override
  Duration get reverseTransitionDuration =>
      reducedMotion ? Duration.zero : super.reverseTransitionDuration;
}

class _TabFrame extends StatefulWidget {
  const _TabFrame({super.key, required this.e, required this.adapter});
  final MLPEnvironment e;
  final MLPAssistantAdapter adapter;
  @override
  State<_TabFrame> createState() => _TabFrameState();
}

class _TabFrameState extends State<_TabFrame> {
  int index = 0;
  void select(int value) {
    MLPHaptics.selection();
    if (mounted) setState(() => index = value.clamp(0, 6));
  }

  Future<void> add(BuildContext context) {
    MLPHaptics.medium();
    return mlpShowSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheet) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Keyingi qadamingiz',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            for (final action in <(String, IconData, VoidCallback)>[
              (
                'Yangi vazifa',
                CupertinoIcons.add_circled,
                () => DemoForms.task(context, widget.e.store),
              ),
              (
                'Yangi maqsad',
                CupertinoIcons.scope,
                () => widget.e.go(MLPScreen.goalDiscovery),
              ),
              ('Fokus sessiyasi', CupertinoIcons.timer, () => select(2)),
              (
                'Taqvim',
                CupertinoIcons.calendar,
                () => widget.e.go(MLPScreen.calendar),
              ),
              (
                'Ustoz AI',
                CupertinoIcons.sparkles,
                () => widget.e.go(MLPScreen.chat),
              ),
              (
                'Mening profilim',
                CupertinoIcons.person_crop_circle,
                () => widget.e.go(MLPScreen.profile),
              ),
            ])
              MLPMenuTile(
                title: action.$1,
                icon: action.$2,
                onTap: () {
                  Navigator.pop(sheet);
                  action.$3();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    return ListenableBuilder(
      listenable: e.ui,
      builder: (context, _) => PopScope(
        canPop: index == 0,
        onPopInvokedWithResult: (popped, _) {
          if (!popped && index != 0) select(0);
        },
        child: MLPScaffold(
          title: index == 2 ? 'Fokus' : null,
          leading: index == 2
              ? IconButton(
                  tooltip: 'Orqaga',
                  icon: const Icon(CupertinoIcons.chevron_back),
                  onPressed: () => select(3),
                )
              : null,
          actions: index == 2
              ? [
                  IconButton(
                    tooltip: 'Boshqa amallar',
                    onPressed: () => add(context),
                    icon: const Icon(CupertinoIcons.slider_horizontal_3),
                  ),
                ]
              : null,
          body: AnimatedSwitcher(
            duration: MLPDimensions.motion(context),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey(index),
              child: switch (index) {
                0 => MLPTodayPage(key: ValueKey(e.store.todayKey), e: e),
                1 => MLPIosPlanPage(e: e, initialGoals: true),
                2 => MLPFocusHub(e: e),
                3 => MLPIosPlanPage(e: e),
                4 => MLPGrowthPage(e: e, embedded: true),
                6 => MLPChatPage(e: e, adapter: widget.adapter),
                _ => MLPProfilePage(e: e),
              },
            ),
          ),
          bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
              ? null
              : ListenableBuilder(
                  listenable: e.focus,
                  builder: (context, _) {
                    final hasLiveFocus =
                        (e.focus.running || e.focus.elapsed > 0) && index != 2;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasLiveFocus)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: GestureDetector(
                              onTap: () {
                                MLPHaptics.medium();
                                select(2);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF131D38),
                                      Color(0xFF1E2F56),
                                    ],
                                  ),
                                  border: Border.all(
                                    color:
                                        (e.focus.running
                                                ? MLPColors.turquoise
                                                : MLPColors.warning)
                                            .withValues(alpha: .5),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (e.focus.running
                                                  ? MLPColors.turquoise
                                                  : MLPColors.warning)
                                              .withValues(alpha: .25),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: e.focus.running
                                            ? MLPColors.turquoise
                                            : MLPColors.warning,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      e.focus.running
                                          ? 'Fokus faol'
                                          : 'Fokus pauzada',
                                      style: const TextStyle(
                                        color: MLPColors.text,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(e.focus.remaining ~/ 60).toString().padLeft(2, '0')}:${(e.focus.remaining % 60).toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: e.focus.running
                                            ? MLPColors.turquoise
                                            : MLPColors.warning,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 11,
                                      color: MLPColors.secondaryText,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        MLPFloatingTabBar(index: index, onChanged: select),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
