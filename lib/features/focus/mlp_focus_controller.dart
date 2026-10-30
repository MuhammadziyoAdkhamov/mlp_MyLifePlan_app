import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../data/repositories/mlp_ui_repository.dart';
import '../../demo/demo_store.dart';

class MLPFocusController extends ChangeNotifier with WidgetsBindingObserver {
  MLPFocusController(this.store, this.ui, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now {
    final draft = ui.focusDraft;
    if (draft != null) {
      try {
        duration = (draft['duration'] as int).clamp(60, 10800);
        elapsed = (draft['elapsed'] as int).clamp(0, duration);
        breakSeconds = (draft['breakSeconds'] as int).clamp(60, 1800);
        sessionId = draft['id'] as String;
        taskId = store.tasks.any((t) => t.id == draft['taskId'])
            ? draft['taskId'] as String?
            : null;
        isBreak = draft['break'] == true;
      } catch (_) {
        error = 'Oldingi taymer holati mos emas. Qayta boshlashingiz mumkin.';
      }
    } else {
      final savedMinutes = ui.prefs.getInt('mlp_preferred_focus_minutes');
      if (savedMinutes != null && savedMinutes >= 1 && savedMinutes <= 180) {
        duration = savedMinutes * 60;
      }
    }
    WidgetsBinding.instance.addObserver(this);
  }
  final DemoStore store;
  final MLPLocalUiRepository ui;
  final DateTime Function() clock;
  int duration = 1500, elapsed = 0, breakSeconds = 300, _anchorElapsed = 0;
  String sessionId = 'focus-${DateTime.now().microsecondsSinceEpoch}';
  String? taskId, error;
  bool running = false, isBreak = false, saving = false, _disposed = false;
  DateTime? _anchor;
  Timer? _timer;
  static int _serial = 0;
  String _newId() => 'focus-${clock().microsecondsSinceEpoch}-${_serial++}';
  DemoTask? get task => store.tasks.where((t) => t.id == taskId).firstOrNull;
  int get remaining => (duration - elapsed).clamp(0, duration);
  Map<String, dynamic> get draft => {
    'id': sessionId,
    'duration': duration,
    'elapsed': elapsed,
    'breakSeconds': breakSeconds,
    'taskId': taskId,
    'break': isBreak,
  };
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> persist() async {
    try {
      await ui.saveFocusDraft(draft);
      error = null;
    } catch (_) {
      error =
          'Taymer holati saqlanmadi. Sessiyani yopmay, qayta urinib ko‘ring.';
    }
    _emit();
  }

  void configure(
    int minutes,
    int pauseMinutes, {
    String? task,
    bool rest = false,
  }) {
    if (running || elapsed > 0) {
      throw StateError(
        'Avval joriy sessiyani saqlang yoki tasdiqlab tozalang.',
      );
    }
    if (minutes < 1 || minutes > 180 || pauseMinutes < 1 || pauseMinutes > 30) {
      throw ArgumentError('Fokus 1–180, tanaffus 1–30 daqiqa bo‘lsin.');
    }
    duration = minutes * 60;
    breakSeconds = pauseMinutes * 60;
    taskId = task;
    isBreak = rest;
    sessionId = _newId();
    error = null;
    if (!rest) {
      unawaited(ui.prefs.setInt('mlp_preferred_focus_minutes', minutes));
    }
    _emit();
    unawaited(persist());
  }

  void start() {
    if (running || saving || elapsed >= duration) return;
    running = true;
    _anchor = clock();
    _anchorElapsed = elapsed;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    _emit();
    unawaited(persist());
  }

  void tick() {
    if (!running || _anchor == null) return;
    final value = (_anchorElapsed + clock().difference(_anchor!).inSeconds)
        .clamp(0, duration);
    if (value > elapsed) elapsed = value;
    if (remaining == 0) {
      pause();
    } else {
      _emit();
      if (elapsed % 5 == 0) unawaited(persist());
    }
  }

  void pause() {
    if (running && _anchor != null) {
      final value = (_anchorElapsed + clock().difference(_anchor!).inSeconds)
          .clamp(0, duration);
      if (value > elapsed) elapsed = value;
    }
    running = false;
    _timer?.cancel();
    _timer = null;
    _anchor = null;
    _emit();
    unawaited(persist());
  }

  Future<void> discard() async {
    _timer?.cancel();
    _timer = null;
    running = false;
    _anchor = null;
    await ui.saveFocusDraft(null);
    elapsed = 0;
    isBreak = false;
    sessionId = _newId();
    error = null;
    _emit();
  }

  Future<void> save(String note, String evidence) async {
    if (saving) return;
    pause();
    if (elapsed < 1) throw StateError('Hali faol vaqt qayd etilmadi.');
    saving = true;
    _emit();
    try {
      await ui.saveFocusDraft(draft);
      if (!isBreak) {
        await store.saveDetailedFocus(
          id: sessionId,
          taskId: task?.id,
          seconds: elapsed,
          note: note,
          evidenceUrl: evidence,
        );
      }
      await ui.saveFocusDraft(null);
      elapsed = 0;
      isBreak = false;
      sessionId = _newId();
      error = null;
    } finally {
      saving = false;
      _emit();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && running) pause();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
