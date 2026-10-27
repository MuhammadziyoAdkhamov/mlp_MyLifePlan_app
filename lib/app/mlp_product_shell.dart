import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/design_system/mlp_widgets.dart';
import '../data/repositories/mlp_ui_repository.dart';
import '../demo/demo_store.dart';
import '../features/ai_companion/mlp_companion_pages.dart';
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
  Timer? dateTicker;
  late String day;
  @override
  void initState() {
    super.initState();
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
      MLPScreen.focus: 2,
      MLPScreen.chat: 3,
      MLPScreen.profile: 4,
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
        MLPScreen.rewards => MLPRewardsPage(e: e),
        MLPScreen.weather => MLPWeatherPage(e: e),
        MLPScreen.soundspace => MLPSoundspacePage(e: e),
        MLPScreen.settings => MLPSettingsPage(e: e),
        MLPScreen.notifications => MLPNotificationsPage(e: e),
        MLPScreen.today ||
        MLPScreen.focus ||
        MLPScreen.chat ||
        MLPScreen.profile => _TabFrame(key: frame, e: e),
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
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        transitionDuration: MLPDimensions.motion(context, route: true),
        reverseTransitionDuration: MLPDimensions.motion(context, route: true),
        pageBuilder: (context, _, __) => settings.name == '/'
            ? _TabFrame(key: frame, e: e)
            : page(
                MLPScreen.parse(settings.name),
                settings.arguments is MLPRouteArgs
                    ? settings.arguments as MLPRouteArgs
                    : const MLPRouteArgs(),
                settings.arguments,
              ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
  );
}

class _TabFrame extends StatefulWidget {
  const _TabFrame({super.key, required this.e});
  final MLPEnvironment e;
  @override
  State<_TabFrame> createState() => _TabFrameState();
}

class _TabFrameState extends State<_TabFrame> {
  int index = 0;
  void select(int value) {
    if (mounted) setState(() => index = value.clamp(0, 4));
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
          actions: [
            IconButton(
              tooltip: 'Sozlamalar',
              onPressed: () => e.go(MLPScreen.settings),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
          title: index == 0 || index == 4
              ? null
              : MLPFloatingTabBar.labels[index],
          body: Column(
            children: [
              Expanded(
                child: switch (index) {
                  0 => MLPTodayPage(key: ValueKey(e.store.todayKey), e: e),
                  1 => MLPGoalsPage(e: e),
                  2 => MLPFocusHub(e: e),
                  3 => MLPChatPage(e: e),
                  _ => MLPProfilePage(e: e),
                },
              ),
            ],
          ),
          bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index != 3 && !e.ui.assistantHidden)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => select(3),
                              icon: const Icon(Icons.auto_awesome, size: 18),
                              label: const Text('Ustozni ochish'),
                            ),
                            IconButton(
                              tooltip: 'Ustoz tezkor tugmasini yashirish',
                              onPressed: () => e.act(
                                context,
                                () => e.ui.hideAssistant(true),
                              ),
                              icon: const Icon(Icons.close, size: 16),
                            ),
                          ],
                        ),
                      ),
                    MLPFloatingTabBar(index: index, onChanged: select),
                  ],
                ),
        ),
      ),
    );
  }
}
