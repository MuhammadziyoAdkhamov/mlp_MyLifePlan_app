import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/user_model.dart';
import '../domain/goal_model.dart';
import '../domain/roadmap_model.dart';
import '../domain/reward_model.dart';
import '../services/mock_data.dart';

const _uuid = Uuid();

// ─── Shared Preferences ───────────────────────────────────────────────────────
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

// ─── Session: Is onboarded? ───────────────────────────────────────────────────
final isOnboardedProvider = StateProvider<bool>((ref) {
  final prefs = ref.read(sharedPrefsProvider);
  return prefs.getBool('mlp_onboarded') ?? false;
});

// ─── User ─────────────────────────────────────────────────────────────────────
class UserNotifier extends Notifier<MlpUser?> {
  @override
  MlpUser? build() {
    final prefs = ref.read(sharedPrefsProvider);
    final raw = prefs.getString('mlp_user');
    if (raw == null) return null;
    try { return MlpUser.fromJson(jsonDecode(raw) as Map<String, dynamic>); }
    catch (_) { return null; }
  }

  Future<void> createUser({required String name, required String phone, String? gender}) async {
    final user = MlpUser(id: _uuid.v4(), name: name, phone: phone, gender: gender);
    state = user;
    await _persist(user);
  }

  Future<void> updateUser(MlpUser user) async {
    state = user;
    await _persist(user);
  }

  Future<void> earnXp(int amount, {String label = ''}) async {
    final current = state;
    if (current == null) return;
    var newXp = current.xp + amount;
    var newLevel = current.level;
    while (newXp >= newLevel * 500) {
      newXp -= newLevel * 500;
      newLevel++;
    }
    final rawEvents = ref.read(sharedPrefsProvider).getString('mlp_xp_events');
    final xpEvents = rawEvents != null
        ? List<Map<String, dynamic>>.from(jsonDecode(rawEvents) as List)
        : <Map<String, dynamic>>[];

    xpEvents.add(XpEvent(id: _uuid.v4(), label: label.isEmpty ? '+$amount XP' : label, xp: amount, earnedAt: DateTime.now()).toJson());
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('mlp_xp_events', jsonEncode(xpEvents));
    final updated = current.copyWith(xp: newXp, level: newLevel, coins: current.coins + (amount ~/ 10));
    state = updated;
    await _persist(updated);
  }

  Future<void> _persist(MlpUser user) async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('mlp_user', jsonEncode(user.toJson()));
  }

  Future<void> signOut() async {
    state = null;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.remove('mlp_user');
    await prefs.remove('mlp_onboarded');
    await prefs.remove('mlp_goals');
    await prefs.remove('mlp_roadmaps');
    ref.read(isOnboardedProvider.notifier).state = false;
  }
}

final userProvider = NotifierProvider<UserNotifier, MlpUser?>(() => UserNotifier());

// ─── Goals ────────────────────────────────────────────────────────────────────
class GoalsNotifier extends Notifier<List<MlpGoal>> {
  @override
  List<MlpGoal> build() {
    final prefs = ref.read(sharedPrefsProvider);
    final raw = prefs.getString('mlp_goals');
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => MlpGoal.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  Future<void> addGoal(MlpGoal goal) async {
    state = [...state, goal];
    await _persist();
  }

  Future<void> updateGoal(MlpGoal updated) async {
    state = state.map((g) => g.id == updated.id ? updated : g).toList();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('mlp_goals', jsonEncode(state.map((g) => g.toJson()).toList()));
  }
}

final goalsProvider = NotifierProvider<GoalsNotifier, List<MlpGoal>>(() => GoalsNotifier());

// ─── Roadmaps ─────────────────────────────────────────────────────────────────
class RoadmapsNotifier extends Notifier<List<MlpRoadmap>> {
  @override
  List<MlpRoadmap> build() {
    final prefs = ref.read(sharedPrefsProvider);
    final raw = prefs.getString('mlp_roadmaps');
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => MlpRoadmap.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  Future<void> addRoadmap(MlpRoadmap roadmap) async {
    state = [...state, roadmap];
    await _persist();
  }

  Future<void> updateRoadmap(MlpRoadmap updated) async {
    state = state.map((r) => r.id == updated.id ? updated : r).toList();
    await _persist();
  }

  Future<void> completeTask(String roadmapId, String milestoneId, String taskId) async {
    state = state.map((roadmap) {
      if (roadmap.id != roadmapId) return roadmap;
      final milestones = roadmap.milestones.map((m) {
        if (m.id != milestoneId) return m;
        final tasks = m.tasks.map((t) {
          if (t.id != taskId) return t;
          return t.copyWith(isCompleted: true, completedAt: DateTime.now());
        }).toList();
        final allDone = tasks.every((t) => t.isCompleted);
        return m.copyWith(
          tasks: tasks,
          status: allDone ? MilestoneStatus.completed : MilestoneStatus.inProgress,
          completedAt: allDone ? DateTime.now() : null,
        );
      }).toList();
      return roadmap.copyWith(milestones: milestones);
    }).toList();
    await _persist();
  }

  MlpRoadmap? roadmapForGoal(String goalId) {
    return state.where((r) => r.goalId == goalId).firstOrNull;
  }

  Future<void> _persist() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString('mlp_roadmaps', jsonEncode(state.map((g) => g.toJson()).toList()));
  }
}

final roadmapsProvider = NotifierProvider<RoadmapsNotifier, List<MlpRoadmap>>(() => RoadmapsNotifier());

// ─── XP Events ────────────────────────────────────────────────────────────────
final xpEventsProvider = Provider<List<XpEvent>>((ref) {
  final prefs = ref.read(sharedPrefsProvider);
  final raw = prefs.getString('mlp_xp_events');
  if (raw == null) return [];
  try {
    return (jsonDecode(raw) as List).map((e) => XpEvent.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) { return []; }
});

// ─── Chat Messages ────────────────────────────────────────────────────────────
class ChatMessage {
  ChatMessage({required this.id, required this.text, required this.isUser, required this.timestamp});
  final String id; final String text; final bool isUser; final DateTime timestamp;
}

class ChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [
        ChatMessage(
          id: _uuid.v4(),
          text: 'Salom! Men sizning shaxsiy AI ustozingizman. Bugun nimada yordam bera olaman?\n\n_⚠️ DEMO rejim: Haqiqiy AI ulanmagan. Skriptlangan javoblar._',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];

  Future<void> sendMessage(String text) async {
    final userMsg = ChatMessage(id: _uuid.v4(), text: text, isUser: true, timestamp: DateTime.now());
    state = [...state, userMsg];
    await Future.delayed(const Duration(milliseconds: 1000));
    final aiResponse = MockData.getAiResponse(text);
    final aiMsg = ChatMessage(id: _uuid.v4(), text: aiResponse, isUser: false, timestamp: DateTime.now());
    state = [...state, aiMsg];
  }

  void clear() => state = [
        ChatMessage(
          id: _uuid.v4(),
          text: 'Yangi suhbat boshlandi! Qanday yordam bera olaman?\n\n_⚠️ DEMO rejim_',
          isUser: false, timestamp: DateTime.now(),
        ),
      ];
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(() => ChatNotifier());
final chatIsTypingProvider = StateProvider<bool>((ref) => false);
