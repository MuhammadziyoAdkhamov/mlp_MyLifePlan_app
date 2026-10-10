import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/date_helper.dart';
import '../models/app_badge.dart';
import '../models/app_stats.dart';
import '../models/focus_session.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../models/habit_enums.dart';
import '../models/growth_focus.dart';
import '../models/journey_task.dart';
import '../models/user_profile.dart';
import '../models/xp_history_item.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

enum GuestDataChoice { useCloud, keepGuest, merge, cancel }

class AppState extends ChangeNotifier {
  AppState({
    LocalStorageService? storage,
    AuthService? authService,
    CloudSyncService? cloudSyncService,
    NotificationService? notificationService,
  }) : _storage = storage ?? LocalStorageService(),
       _auth = authService ?? AuthService(),
       _cloud = cloudSyncService ?? CloudSyncService(),
       _notifications = notificationService ?? NotificationService();

  final LocalStorageService _storage;
  final AuthService _auth;
  final CloudSyncService _cloud;
  final NotificationService _notifications;

  bool isLoading = true;
  bool isSyncing = false;
  bool onboardingCompleted = false;
  bool signedIn = false;
  String? errorMessage;
  DateTime? lastSyncedAt;

  UserProfile profile = UserProfile.demo();
  List<Habit> habits = [];
  List<AppBadge> badges = [];
  List<XPHistoryItem> xpHistory = [];
  List<JourneyTask> journeyTasks = [];
  List<FocusSession> focusSessions = [];

  static const String guestEmail = 'guest@mylife.local';

  bool get isCloudUser => _auth.currentUser != null;

  bool get isGuestUser => signedIn && !isCloudUser;

  String get syncStatusLabel {
    if (isSyncing) return 'Syncing...';
    if (isGuestUser) return 'Guest Mode • Local data';
    if (!isCloudUser) return 'Local mode';
    if (lastSyncedAt == null) return 'Cloud connected';
    return 'Cloud synced';
  }

  Future<void> init() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final firebaseUser = _auth.currentUser;
      await _storage.migrateLegacyAppData(userId: firebaseUser?.uid);
      final localData = await _storage.loadAppData(userId: firebaseUser?.uid);

      if (localData == null) {
        _initializeFreshUser();
        if (firebaseUser == null) await _saveLocalOnly();
      } else {
        _restoreFromData(localData);
      }

      signedIn = firebaseUser != null || signedIn;

      if (firebaseUser != null) {
        await _loadCloudOrCreate(firebaseUser);
      }

      _recalculateProfile();
      _refreshBadges();
    } catch (e) {
      errorMessage = _friendlyError(e);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding({
    String? name,
    String? focus,
    List<int>? starterSelections,
  }) async {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      profile = profile.copyWith(name: trimmedName);
    }
    if (focus != null) {
      final selectedFocus = growthFocusFromId(focus);
      profile = profile.copyWith(growthFocus: selectedFocus.name);
      if (habits.isEmpty) {
        final now = DateTime.now();
        final selectedStarterHabits = selectedFocus.starterHabits
            .asMap()
            .entries
            .where(
              (entry) =>
                  starterSelections == null ||
                  starterSelections.contains(entry.key),
            )
            .map((entry) => entry.value);
        habits = selectedStarterHabits.map((spec) {
          return Habit(
            id: _id('habit'),
            name: spec.name,
            category: spec.category,
            frequency: HabitFrequency.everyday,
            createdAt: now,
            iconCodePoint: _iconForCategory(spec.category),
            xpReward: 40,
            completions: const [],
            goal: spec.goal,
            minimalGoal: spec.minimalGoal,
            whyNote: spec.whyNote,
          );
        }).toList();
      }
    }
    onboardingCompleted = true;
    await _saveAndNotify();
  }

  Future<void> signInWithGoogle({
    Future<GuestDataChoice> Function()? onExistingCloudData,
  }) async {
    final wasGuest = isGuestUser;
    final guestData = wasGuest ? await _storage.loadAppData() : null;
    isSyncing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithGoogle();
      final user = credential.user;

      if (user == null) {
        throw StateError('Firebase user is null after Google sign-in.');
      }

      signedIn = true;
      onboardingCompleted = true;

      final cloudData = wasGuest && guestData != null
          ? await _cloud.loadAppData(user.uid)
          : null;
      final localGuestData = guestData;

      if (cloudData != null && localGuestData != null) {
        final choice =
            await onExistingCloudData?.call() ?? GuestDataChoice.useCloud;
        if (choice == GuestDataChoice.cancel) {
          await _auth.signOut();
          _restoreFromData(localGuestData);
          signedIn = true;
          onboardingCompleted = true;
          return;
        }

        var shouldWriteCloud = false;
        if (choice == GuestDataChoice.useCloud) {
          _restoreFromData(cloudData);
        } else if (choice == GuestDataChoice.keepGuest) {
          _restoreFromData(localGuestData);
          shouldWriteCloud = true;
        } else {
          _restoreFromData(_mergeAppData(cloudData, localGuestData));
          shouldWriteCloud = true;
        }

        signedIn = true;
        onboardingCompleted = true;
        profile = _profileFromFirebaseUser(user, fallback: profile);
        _recalculateProfile();
        _refreshBadges();
        if (shouldWriteCloud) await _saveCloudForUser(user);
        lastSyncedAt = DateTime.now();
        await _saveLocalOnly(userId: user.uid);
      } else {
        await _loadCloudOrCreate(user);
        await _saveLocalOnly(userId: user.uid);
      }
    } catch (e) {
      errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> signIn({String? email}) async {
    signedIn = true;
    onboardingCompleted = true;

    if (email != null && email.trim().isNotEmpty) {
      profile = profile.copyWith(email: email.trim());
    }

    await _saveLocalOnly();
    notifyListeners();
  }

  Future<void> continueAsGuest() async {
    signedIn = true;
    onboardingCompleted = true;
    errorMessage = null;

    final currentName = profile.name.trim();
    final currentEmail = profile.email.trim();

    profile = profile.copyWith(
      id: profile.id.trim().isEmpty ? 'guest_local' : profile.id,
      name: currentName.isEmpty || currentName == 'Azizbek'
          ? 'Guest User'
          : currentName,
      email: currentEmail.isEmpty || currentEmail == 'example@gmail.com'
          ? guestEmail
          : currentEmail,
      avatarUrl: null,
    );

    await _saveLocalOnly();
    notifyListeners();
  }

  Future<void> signOut() async {
    isSyncing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final signedOutUser = _auth.currentUser;
      await _save();
      await _auth.signOut();
      signedIn = false;
      await _saveLocalOnly(userId: signedOutUser?.uid);

      final guestData = await _storage.loadAppData();
      if (guestData == null) {
        _loadDemoData();
      } else {
        _restoreFromData(guestData);
      }
      signedIn = false;
      onboardingCompleted = true;
    } catch (e) {
      errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> syncFromCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    isSyncing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final cloudData = await _cloud.loadAppData(user.uid);

      if (cloudData != null) {
        _restoreFromData(cloudData);
        signedIn = true;
        onboardingCompleted = true;
        profile = _profileFromFirebaseUser(user, fallback: profile);
        lastSyncedAt = DateTime.now();
        await _saveLocalOnly();
      }
    } catch (e) {
      errorMessage = _friendlyError(e);
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> resetDemoData() async {
    final user = _auth.currentUser;
    _loadDemoData();
    onboardingCompleted = true;
    signedIn = user != null;

    if (user != null) {
      profile = _profileFromFirebaseUser(user, fallback: profile);
    }

    await _saveAndNotify();
    await _notifications.cancelAll();
  }

  Map<String, dynamic> exportData() => _toAppData();

  Future<void> deleteMyData() async {
    isSyncing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      final habitIds = habits.map((habit) => habit.id).toList();
      if (user != null) {
        await _cloud.deleteAppData(user.uid);
        await _auth.signOut();
      }

      await _storage.clear(userId: user?.uid);
      for (final habitId in habitIds) {
        try {
          await _notifications.cancelHabitReminder(habitId);
        } catch (_) {
          // A device notification failure should not block data deletion.
        }
      }

      _loadDemoData();
      onboardingCompleted = false;
      signedIn = false;
      lastSyncedAt = null;
    } catch (e) {
      errorMessage = _friendlyError(e);
      rethrow;
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> addHabit({
    required String name,
    required HabitCategory category,
    required HabitFrequency frequency,
    List<int> customWeekdays = const [],
    required String? reminder,
    required String? goal,
    required bool isActive,
    String? whyNote,
    String? minimalGoal,
    String? stackAfterHabitId,
    String? accountabilityPartner,
    String? futureLetter,
    String? commitmentContract,
  }) async {
    final habit = Habit(
      id: _id('habit'),
      name: name.trim(),
      category: category,
      frequency: frequency,
      createdAt: DateTime.now(),
      iconCodePoint: _iconForCategory(category),
      xpReward: 40,
      completions: const [],
      customWeekdays: customWeekdays,
      goal: _clean(goal),
      reminder: _clean(reminder),
      isActive: isActive,
      whyNote: _clean(whyNote),
      minimalGoal: _clean(minimalGoal),
      stackAfterHabitId: _clean(stackAfterHabitId),
      accountabilityPartner: _clean(accountabilityPartner),
      futureLetter: _clean(futureLetter),
      commitmentContract: _clean(commitmentContract),
    );

    habits = [habit, ...habits];
    await _saveAndNotify();
    if (habit.isActive && habit.reminder != null) {
      final weekdays = switch (habit.frequency) {
        HabitFrequency.everyday => const <int>[],
        HabitFrequency.weekdays => const [1, 2, 3, 4, 5],
        HabitFrequency.weekends => const [6, 7],
        HabitFrequency.custom => habit.customWeekdays,
      };
      try {
        final scheduled = await _notifications.scheduleHabitReminder(
          habitId: habit.id,
          habitName: habit.name,
          reminder: habit.reminder,
          weekdays: weekdays,
        );
        if (!scheduled) {
          errorMessage =
              'Habit saqlandi, lekin reminder vaqti yoki ruxsat sozlanmadi.';
          notifyListeners();
        }
      } catch (_) {
        errorMessage = 'Habit saqlandi, ammo eslatmani sozlab bo‘lmadi.';
        notifyListeners();
      }
    }
  }

  Future deleteHabit(String habitId) async {
    habits = habits.where((habit) => habit.id != habitId).toList();

    xpHistory.removeWhere((item) => item.habitId == habitId);
    focusSessions.removeWhere((session) => session.habitId == habitId);

    _recalculateProfile();
    _refreshBadges();

    await _saveAndNotify();
    await _notifications.cancelHabitReminder(habitId);
  }

  Future<void> addFocusSession({
    required String habitId,
    required DateTime startedAt,
    required DateTime completedAt,
    required int durationSeconds,
  }) async {
    if (habitById(habitId) == null || durationSeconds <= 0) return;

    focusSessions = [
      FocusSession(
        id: _id('focus'),
        habitId: habitId,
        startedAt: startedAt,
        completedAt: completedAt,
        durationSeconds: durationSeconds,
      ),
      ...focusSessions,
    ];
    await _saveAndNotify();
  }

  int focusMinutesForHabit(String habitId) {
    final seconds = focusSessions
        .where((session) => session.habitId == habitId)
        .fold<int>(0, (sum, session) => sum + session.durationSeconds);
    return seconds ~/ 60;
  }

  int get totalFocusMinutes =>
      focusSessions.fold<int>(
        0,
        (sum, session) => sum + session.durationSeconds,
      ) ~/
      60;

  int get focusMinutesToday {
    final today = DateTime.now();
    final seconds = focusSessions
        .where((session) => DateHelper.isSameDay(session.completedAt, today))
        .fold<int>(0, (sum, session) => sum + session.durationSeconds);
    return seconds ~/ 60;
  }

  Future<void> toggleHabitToday(String habitId) async {
    final habit = habitById(habitId);
    if (habit == null) return;

    if (habit.isCompletedOn(DateTime.now())) {
      await clearHabitToday(habitId);
      return;
    }

    await markHabitCompletedToday(habitId);
  }

  Future<void> markHabitCompletedToday(
    String habitId, {
    String mode = 'full',
    int? mood,
    int? energy,
    int? durationMinutes,
  }) async {
    final index = habits.indexWhere((habit) => habit.id == habitId);
    if (index == -1) return;

    final today = DateHelper.dateOnly(DateTime.now());
    final now = DateTime.now();
    final habit = habits[index];
    final completions = [...habit.completions]
      ..removeWhere(
        (completion) => DateHelper.isSameDay(completion.date, today),
      );

    final xp = switch (mode) {
      'minimal' => max(8, (habit.xpReward * 0.35).round()),
      'recovery' => max(10, (habit.xpReward * 0.50).round()),
      _ => habit.xpReward,
    };

    completions.add(
      HabitCompletion(
        date: now,
        xpEarned: xp,
        type: mode,
        mood: mood,
        energy: energy,
        durationMinutes: durationMinutes,
      ),
    );

    habits[index] = habit.copyWith(completions: completions);

    xpHistory = [
      XPHistoryItem(
        id: _id('xp'),
        title: mode == 'minimal'
            ? 'Minimal Win'
            : mode == 'recovery'
            ? 'Recovery Win'
            : 'Completed Habit',
        subtitle: habit.name,
        amount: xp,
        createdAt: now,
        habitId: habit.id,
      ),
      ...xpHistory,
    ];

    if (_isPerfectDay(today, overrideHabitId: habitId)) {
      xpHistory = [
        XPHistoryItem(
          id: _id('xp'),
          title: 'Perfect Day',
          subtitle: 'All daily habits completed',
          amount: 100,
          createdAt: now,
        ),
        ...xpHistory,
      ];
    }

    _recalculateProfile();
    _refreshBadges();
    await _saveAndNotify();
  }

  Future<void> clearHabitToday(String habitId) async {
    final index = habits.indexWhere((habit) => habit.id == habitId);
    if (index == -1) return;

    final today = DateHelper.dateOnly(DateTime.now());
    final habit = habits[index];
    final completions = [...habit.completions]
      ..removeWhere(
        (completion) => DateHelper.isSameDay(completion.date, today),
      );

    habits[index] = habit.copyWith(completions: completions);
    xpHistory.removeWhere(
      (item) =>
          DateHelper.isSameDay(item.createdAt, today) &&
          (item.habitId == habitId || item.title == 'Perfect Day'),
    );

    _recalculateProfile();
    _refreshBadges();
    await _saveAndNotify();
  }

  Future<void> markHabitSkippedToday(String habitId, String reason) async {
    final index = habits.indexWhere((habit) => habit.id == habitId);
    if (index == -1) return;

    final today = DateHelper.dateOnly(DateTime.now());
    final habit = habits[index];
    final completions = [...habit.completions]
      ..removeWhere(
        (completion) => DateHelper.isSameDay(completion.date, today),
      );

    completions.add(
      HabitCompletion(
        date: DateTime.now(),
        xpEarned: 0,
        type: 'skip',
        skipReason: reason,
      ),
    );

    habits[index] = habit.copyWith(completions: completions);
    await _saveAndNotify();
  }

  Future<void> recoverHabitToday(String habitId) async {
    final habit = habitById(habitId);
    if (habit == null || !canRecoverHabit(habit)) return;
    await markHabitCompletedToday(habitId, mode: 'recovery');
  }

  Future<void> toggleJourneyTask(String taskId) async {
    final index = journeyTasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return;

    final task = journeyTasks[index];
    if (task.isLocked) return;

    if (task.isCompleted) {
      journeyTasks[index] = task.copyWith(clearCompletedAt: true);
      xpHistory.removeWhere((item) => item.habitId == taskId);
    } else {
      journeyTasks[index] = task.copyWith(completedAt: DateTime.now());

      xpHistory = [
        XPHistoryItem(
          id: _id('xp'),
          title: 'Daily Journey',
          subtitle: 'Day ${task.day}: ${task.title}',
          amount: task.xpReward,
          createdAt: DateTime.now(),
          habitId: task.id,
        ),
        ...xpHistory,
      ];
    }

    _recalculateProfile();
    _refreshBadges();
    await _saveAndNotify();
  }

  Habit? habitById(String id) {
    try {
      return habits.firstWhere((habit) => habit.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Habit> get activeHabits {
    return habits.where((habit) => habit.isActive).toList();
  }

  Habit? get dailyPriorityHabit {
    final today = DateTime.now();
    final dueHabits = activeHabits
        .where((habit) => habit.isScheduledOn(today))
        .toList();
    final openHabits = dueHabits
        .where(
          (habit) => !habit.isCompletedOn(today) && !habit.isSkippedOn(today),
        )
        .toList();
    if (openHabits.isEmpty) {
      return dueHabits.isEmpty ? null : dueHabits.first;
    }
    openHabits.sort((a, b) {
      final aScore =
          a.currentStreak + a.skipCount + (a.whyNote == null ? 0 : 2);
      final bScore =
          b.currentStreak + b.skipCount + (b.whyNote == null ? 0 : 2);
      return bScore.compareTo(aScore);
    });
    return openHabits.first;
  }

  bool canRecoverHabit(Habit habit) {
    return habit.needsRecoveryOn(DateTime.now());
  }

  Habit? stackedHabitAfter(String habitId) {
    try {
      return activeHabits.firstWhere(
        (habit) => habit.stackAfterHabitId == habitId,
      );
    } catch (_) {
      return null;
    }
  }

  String identityTitleForCategory(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return 'Sog‘lom odam';
      case HabitCategory.study:
        return 'Bilimli odam';
      case HabitCategory.mind:
        return 'Tinch va ongli odam';
      case HabitCategory.faith:
        return 'Ma’naviy mustahkam odam';
      case HabitCategory.money:
        return 'Moliyaviy tartibli odam';
      case HabitCategory.other:
        return 'Intizomli odam';
    }
  }

  int identityVoteCountForCategory(HabitCategory category) {
    return habits
        .where((habit) => habit.category == category)
        .fold(0, (sum, habit) => sum + habit.completionCount);
  }

  String identityProgressSummary() {
    final categories = HabitCategory.values.map((category) {
      return MapEntry(category, identityVoteCountForCategory(category));
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    final top = categories.first;
    if (top.value == 0) {
      return 'Hali identity ovozlari yo‘q. Birinchi habitni bajarganingda rol shakllana boshlaydi.';
    }

    return '${identityTitleForCategory(top.key)} roliga ${top.value} marta ovoz berding.';
  }

  String skipPatternInsight(Habit habit) {
    final skips = habit.skippedEntries;
    if (skips.isEmpty) {
      return 'Hali skip pattern yo‘q. O‘tkazib yuborsang sababini belgilasang, men pattern topaman.';
    }

    final reasonCounts = <String, int>{};
    final weekdayCounts = <int, int>{};
    final hourBuckets = <String, int>{};

    for (final skip in skips) {
      final reason = skip.skipReason ?? 'Unknown';
      reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
      weekdayCounts[skip.date.weekday] =
          (weekdayCounts[skip.date.weekday] ?? 0) + 1;
      final bucket = skip.date.hour >= 18
          ? '18:00dan keyin'
          : skip.date.hour >= 12
          ? 'tushdan keyin'
          : 'ertalab';
      hourBuckets[bucket] = (hourBuckets[bucket] ?? 0) + 1;
    }

    String topKey<T>(Map<T, int> map) {
      final entries = map.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return entries.first.key.toString();
    }

    const weekdays = {
      1: 'Dushanba',
      2: 'Seshanba',
      3: 'Chorshanba',
      4: 'Payshanba',
      5: 'Juma',
      6: 'Shanba',
      7: 'Yakshanba',
    };

    final topWeekday = int.tryParse(topKey(weekdayCounts));
    final topReason = topKey(reasonCounts);
    final topTime = topKey(hourBuckets);

    return '${weekdays[topWeekday] ?? 'Ayrim kunlar'} $topTime eng ko‘p tashlab ketasan. Asosiy sabab: $topReason.';
  }

  String moodCorrelationInsight() {
    final withMood = [
      for (final habit in habits)
        for (final item in habit.completedEntries)
          if (item.mood != null) MapEntry(habit, item),
    ];

    if (withMood.length < 4) {
      return 'Kayfiyat bo‘yicha xulosa uchun kamida 4 ta mood check kerak.';
    }

    final byCategory = <HabitCategory, List<int>>{};
    for (final entry in withMood) {
      byCategory
          .putIfAbsent(entry.key.category, () => [])
          .add(entry.value.mood!);
    }

    final averages = byCategory.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return MapEntry(entry.key, avg);
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    final top = averages.first;
    return '${top.key.label} qilgan kunlaring kayfiyating o‘rtacha ${top.value.toStringAsFixed(1)}/5 bo‘lgan.';
  }

  String investmentInsight(Habit habit) {
    final minutes = habit.totalDurationMinutes;
    if (minutes <= 0) return 'Hali investitsiya yig‘ilmadi.';
    final hours = minutes / 60;
    final books = (minutes / 360).clamp(0, 999).toStringAsFixed(1);
    final sessions = habit.completionCount;

    if (habit.category == HabitCategory.study ||
        habit.name.toLowerCase().contains('read')) {
      return '${hours.toStringAsFixed(1)} soat sarflading — taxminan $books ta kichik kitobga teng.';
    }

    return '${hours.toStringAsFixed(1)} soat va $sessions ta kichik g‘alaba yig‘ding.';
  }

  String adaptiveReminderSuggestion(Habit habit) {
    final entries = habit.completedEntries;
    if (entries.length < 3) {
      return habit.reminder ??
          'Odatdagi vaqtingni o‘rganish uchun kamida 3 ta completion kerak.';
    }

    final minutes =
        entries
            .map((item) => item.date.hour * 60 + item.date.minute)
            .reduce((a, b) => a + b) /
        entries.length;
    final remind = (minutes - 15).clamp(0, 1439).round();
    final hour = remind ~/ 60;
    final minute = remind % 60;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix — odatda bajaradigan vaqtingdan 15 daqiqa oldin.';
  }

  String difficultySuggestion(Habit habit) {
    final today = DateHelper.dateOnly(DateTime.now());
    final lastThree = List.generate(
      3,
      (i) => today.subtract(Duration(days: i)),
    );
    final missed = lastThree.where((day) => !habit.isCompletedOn(day)).length;
    if (missed >= 3) {
      return 'Ketma-ket 3 marta qiyin bo‘ldi. Maqsadni kichraytirish yoki minimal versiyadan boshlash yaxshi.';
    }
    return 'Qiyinlik hozircha yaxshi. Minimal versiya og‘ir kunlar uchun zaxira bo‘lib turadi.';
  }

  String weeklyAutoSummary() {
    if (activeHabits.isEmpty) {
      return 'Bu hafta uchun habit yo‘q. Avval bitta kichik habit qo‘sh.';
    }
    final categories = <HabitCategory, int>{};
    final weekStart = DateHelper.dateOnly(
      DateTime.now(),
    ).subtract(const Duration(days: 6));
    for (final habit in activeHabits) {
      final recentCompletions = habit.completedEntries
          .where((entry) => !entry.date.isBefore(weekStart))
          .length;
      categories[habit.category] =
          (categories[habit.category] ?? 0) + recentCompletions;
    }
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first.key.label;
    final low = sorted.last.key.label;
    return 'Bu hafta eng ko‘p $top yo‘nalishiga e’tibor berding. Keyingi hafta $low uchun 2 daqiqalik minimal reja qo‘shib ko‘r.';
  }

  String? futureLetterDue(Habit habit) {
    final letter = habit.futureLetter?.trim();
    if (letter == null || letter.isEmpty) return null;
    final days = DateHelper.dateOnly(
      DateTime.now(),
    ).difference(DateHelper.dateOnly(habit.createdAt)).inDays;
    if (days >= 90) return '90 kun oldingi sendan xat: $letter';
    if (days >= 60) return '60 kun oldingi sendan xat: $letter';
    if (days >= 30) return '30 kun oldingi sendan xat: $letter';
    return null;
  }

  String compassionateStreakMessage(Habit habit) {
    if (habit.currentStreak > 0) {
      return '${habit.currentStreak} kunlik zanjir davom etyapti.';
    }
    if (habit.skipCount > 0) {
      return 'Yangi boshlanish kuni. Sababni bilamiz, endi reja kichrayadi.';
    }
    return 'Bugun boshlash uchun yaxshi kun.';
  }

  String partnerContractMessage(Habit habit) {
    final partner = habit.accountabilityPartner?.trim();
    final contract = habit.commitmentContract?.trim();
    if ((partner == null || partner.isEmpty) &&
        (contract == null || contract.isEmpty)) {
      return 'Hamroh yoki garov yo‘q. Kerak bo‘lsa habit yaratishda bitta odamni qo‘sh.';
    }
    return 'Agar 3 kun ketma-ket o‘tkazib yuborsang, ${partner?.isNotEmpty == true ? partner : 'hamrohing'} uchun mas’uliyat signali tayyor: ${contract?.isNotEmpty == true ? contract : 'Men 3 kun ketma-ket tashlab qo‘ydim, menga eslat.'}';
  }

  int get completedTodayCount {
    final today = DateTime.now();
    return activeHabits.where((habit) => habit.isCompletedOn(today)).length;
  }

  double get dailyProgress {
    final today = DateTime.now();
    final dueHabits = activeHabits
        .where((habit) => habit.isScheduledOn(today))
        .toList();
    if (dueHabits.isEmpty) return 1;
    return dueHabits.where((habit) => habit.isCompletedOn(today)).length /
        dueHabits.length;
  }

  int get totalXp {
    return xpHistory.fold(0, (sum, item) => sum + item.amount);
  }

  int get level {
    return max(1, totalXp ~/ 1000 + 1);
  }

  int get xpInCurrentLevel {
    return totalXp % 1000;
  }

  double get levelProgress {
    return xpInCurrentLevel / 1000;
  }

  int get bestStreak {
    return habits.isEmpty ? 0 : habits.map((h) => h.bestStreak).reduce(max);
  }

  int get currentStreak {
    return habits.isEmpty ? 0 : habits.map((h) => h.currentStreak).reduce(max);
  }

  Map<String, double> get weeklyProgressMap {
    final days = DateHelper.lastDays(7);

    return {for (final day in days) DateHelper.key(day): _progressForDay(day)};
  }

  double _progressForDay(DateTime day) {
    final dueHabits = activeHabits
        .where((habit) => habit.isScheduledOn(day))
        .toList();
    if (dueHabits.isEmpty) return 1;
    return dueHabits.where((habit) => habit.isCompletedOn(day)).length /
        dueHabits.length;
  }

  Map<String, double> get monthHeatmap {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month);
    final totalDays = DateTime(now.year, now.month + 1, 0).day;

    return {
      for (var i = 0; i < totalDays; i++)
        DateHelper.key(first.add(Duration(days: i))): _progressForDay(
          first.add(Duration(days: i)),
        ),
    };
  }

  AppStats get stats {
    final weekDays = DateHelper.lastDays(7);
    final weekValues = [
      for (final day in weekDays)
        if (activeHabits.any((habit) => habit.isScheduledOn(day)))
          weeklyProgressMap[DateHelper.key(day)]!,
    ];
    final weekly = weekValues.isEmpty
        ? 0.0
        : weekValues.reduce((a, b) => a + b) / weekValues.length;

    final now = DateTime.now();
    final monthDays = DateTime(now.year, now.month + 1, 0).day;
    final monthValues = [
      for (var day = 1; day <= monthDays; day++)
        if (activeHabits.any(
          (habit) => habit.isScheduledOn(DateTime(now.year, now.month, day)),
        ))
          monthHeatmap[DateHelper.key(DateTime(now.year, now.month, day))]!,
    ];
    final monthly = monthValues.isEmpty
        ? 0.0
        : monthValues.reduce((a, b) => a + b) / monthValues.length;

    final missed = weekValues.where((value) => value < 1).length;

    return AppStats(
      dailyProgress: dailyProgress,
      weeklyProgress: weekly,
      monthlyProgress: monthly,
      completedToday: completedTodayCount,
      totalHabits: activeHabits.length,
      missedThisWeek: missed,
      bestStreak: bestStreak,
      currentStreak: currentStreak,
      totalXp: totalXp,
      level: level,
    );
  }

  Future<void> _loadCloudOrCreate(User user) async {
    final cloudData = await _cloud.loadAppData(user.uid);

    if (cloudData == null) {
      signedIn = true;
      onboardingCompleted = true;
      profile = _profileFromFirebaseUser(user, fallback: profile);
      _recalculateProfile();
      _refreshBadges();
      await _cloud.saveAppData(user.uid, _toAppData());
    } else {
      _restoreFromData(cloudData);
      signedIn = true;
      onboardingCompleted = true;
      profile = _profileFromFirebaseUser(user, fallback: profile);
      _recalculateProfile();
      _refreshBadges();
      await _saveLocalOnly();
    }

    lastSyncedAt = DateTime.now();
  }

  Future<void> _saveCloudForUser(User user) async {
    await _cloud.saveAppData(user.uid, _toAppData());
  }

  Map<String, dynamic> _mergeAppData(
    Map<String, dynamic> cloudData,
    Map<String, dynamic> guestData,
  ) {
    final merged = Map<String, dynamic>.from(cloudData);
    for (final key in [
      'habits',
      'xpHistory',
      'badges',
      'journeyTasks',
      'focusSessions',
    ]) {
      final cloudItems = cloudData[key];
      final guestItems = guestData[key];
      final itemsById = <String, Map<String, dynamic>>{};

      if (cloudItems is List) {
        for (final item in cloudItems) {
          if (item is Map && item['id'] is String) {
            itemsById[item['id'] as String] = Map<String, dynamic>.from(item);
          }
        }
      }

      if (guestItems is List) {
        for (final item in guestItems) {
          if (item is! Map || item['id'] is! String) continue;
          final id = item['id'] as String;
          final guestItem = Map<String, dynamic>.from(item);
          final cloudItem = itemsById[id];
          if (cloudItem == null) {
            itemsById[id] = guestItem;
          } else if (key == 'habits') {
            cloudItem['completions'] = _mergeCompletions(
              cloudItem['completions'],
              guestItem['completions'],
            );
          } else if (key == 'badges' && guestItem['isUnlocked'] == true) {
            cloudItem['isUnlocked'] = true;
            cloudItem['unlockedAt'] ??= guestItem['unlockedAt'];
          } else if (key == 'journeyTasks' &&
              guestItem['completedAt'] != null) {
            cloudItem['completedAt'] ??= guestItem['completedAt'];
          }
        }
      }

      merged[key] = itemsById.values.toList();
    }

    merged['onboardingCompleted'] = true;
    merged['signedIn'] = true;
    return merged;
  }

  List<Map<String, dynamic>> _mergeCompletions(
    Object? cloudValue,
    Object? guestValue,
  ) {
    final completionsByDay = <String, Map<String, dynamic>>{};
    for (final source in [cloudValue, guestValue]) {
      if (source is! List) continue;
      for (final item in source) {
        if (item is! Map || item['date'] is! String) continue;
        final completion = Map<String, dynamic>.from(item);
        final date = DateTime.tryParse(item['date'] as String);
        if (date == null) continue;
        completionsByDay.putIfAbsent(DateHelper.key(date), () => completion);
      }
    }
    return completionsByDay.values.toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  UserProfile _profileFromFirebaseUser(
    User user, {
    required UserProfile fallback,
  }) {
    return fallback.copyWith(
      id: user.uid,
      name: (user.displayName == null || user.displayName!.trim().isEmpty)
          ? fallback.name
          : user.displayName!.trim(),
      email: (user.email == null || user.email!.trim().isEmpty)
          ? fallback.email
          : user.email!.trim(),
      avatarUrl: user.photoURL,
    );
  }

  void _restoreFromData(Map<String, dynamic> data) {
    onboardingCompleted = data['onboardingCompleted'] as bool? ?? false;
    signedIn = data['signedIn'] as bool? ?? false;

    final profileJson = data['profile'];
    profile = profileJson is Map
        ? UserProfile.fromJson(Map<String, dynamic>.from(profileJson))
        : UserProfile.demo();

    habits = (data['habits'] as List<dynamic>? ?? [])
        .map((item) => Habit.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    badges = (data['badges'] as List<dynamic>? ?? [])
        .map(
          (item) => AppBadge.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    xpHistory = (data['xpHistory'] as List<dynamic>? ?? [])
        .map(
          (item) =>
              XPHistoryItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    journeyTasks = (data['journeyTasks'] as List<dynamic>? ?? [])
        .map(
          (item) =>
              JourneyTask.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    focusSessions = (data['focusSessions'] as List<dynamic>? ?? [])
        .map(
          (item) =>
              FocusSession.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    if (badges.isEmpty) badges = _defaultBadges();
    if (journeyTasks.isEmpty) {
      journeyTasks = _defaultJourneyTasks(DateTime.now());
    }
  }

  Map<String, dynamic> _toAppData() {
    return {
      'onboardingCompleted': onboardingCompleted,
      'signedIn': signedIn,
      'profile': profile.toJson(),
      'habits': habits.map((habit) => habit.toJson()).toList(),
      'badges': badges.map((badge) => badge.toJson()).toList(),
      'xpHistory': xpHistory.map((item) => item.toJson()).toList(),
      'journeyTasks': journeyTasks.map((task) => task.toJson()).toList(),
      'focusSessions': focusSessions
          .map((session) => session.toJson())
          .toList(),
    };
  }

  bool _isPerfectDay(DateTime date, {String? overrideHabitId}) {
    final dueHabits = activeHabits
        .where((habit) => habit.isScheduledOn(date))
        .toList();
    if (dueHabits.isEmpty) return false;

    return dueHabits.every((habit) {
      if (habit.id == overrideHabitId) return true;
      return habit.isCompletedOn(date);
    });
  }

  void _recalculateProfile() {
    profile = profile.copyWith(totalXp: totalXp, level: level);
  }

  void _refreshBadges() {
    badges = badges.map((badge) {
      if (badge.isUnlocked) return badge;

      final unlocked = _badgeUnlocked(badge.id);

      return unlocked
          ? badge.copyWith(isUnlocked: true, unlockedAt: DateTime.now())
          : badge;
    }).toList();
  }

  bool _badgeUnlocked(String id) {
    switch (id) {
      case 'first_step':
        return habits.any((habit) => habit.completions.isNotEmpty);
      case 'seven_day_streak':
        return currentStreak >= 7;
      case 'focus_master':
        return journeyTasks.where((task) => task.isCompleted).length >= 10;
      case 'bookworm':
        return habits.any(
          (habit) =>
              habit.name.toLowerCase().contains('read') &&
              habit.completionCount >= 10,
        );
      case 'unstoppable':
        return totalXp >= 5000;
      case 'perfect_week':
        return weeklyProgressMap.values.every((value) => value >= 1) &&
            activeHabits.isNotEmpty;
      default:
        return false;
    }
  }

  int _iconForCategory(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return Icons.spa_rounded.codePoint;
      case HabitCategory.study:
        return Icons.menu_book_rounded.codePoint;
      case HabitCategory.mind:
        return Icons.psychology_rounded.codePoint;
      case HabitCategory.faith:
        return Icons.auto_awesome_rounded.codePoint;
      case HabitCategory.money:
        return Icons.savings_rounded.codePoint;
      case HabitCategory.other:
        return Icons.star_rounded.codePoint;
    }
  }

  String? _clean(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String _id(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  void _initializeFreshUser() {
    final now = DateTime.now();
    onboardingCompleted = false;
    signedIn = false;
    profile = UserProfile(
      id: 'guest_local',
      name: '',
      email: guestEmail,
      totalXp: 0,
      level: 1,
      createdAt: now,
    );
    habits = [];
    badges = _defaultBadges();
    xpHistory = [];
    journeyTasks = _defaultJourneyTasks(now);
    focusSessions = [];
  }

  Future<void> _saveAndNotify() async {
    await _save();
    notifyListeners();
  }

  Future<void> _saveLocalOnly({String? userId}) async {
    await _storage.saveAppData(
      _toAppData(),
      userId: userId ?? _auth.currentUser?.uid,
    );
  }

  Future<void> _save() async {
    final data = _toAppData();
    final user = _auth.currentUser;
    await _storage.saveAppData(data, userId: user?.uid);

    if (user != null && signedIn) {
      await _cloud.saveAppData(user.uid, data);
      lastSyncedAt = DateTime.now();
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();

    if (error is AuthCancelledException) {
      return 'Google orqali kirish bekor qilindi. Qayta urinib ko‘ring.';
    }

    if (text.contains('network-request-failed')) {
      return 'Internet aloqasini tekshir.';
    }

    if (text.contains('ApiException: 10') || text.contains('DEVELOPER_ERROR')) {
      return 'Google Auth sozlamasida SHA-1 yoki package name xato.';
    }

    if (text.contains('permission-denied')) {
      return 'Firestore rules ruxsat bermayapti.';
    }

    if (text.contains('REPLACE_WITH_FIREBASE')) {
      return 'Firebase hali ulanmagan. flutterfire configure qilish kerak.';
    }

    return text;
  }

  List<AppBadge> _defaultBadges() => const [
    AppBadge(
      id: 'first_step',
      title: 'First Step',
      description: 'Complete 1 habit',
      iconCodePoint: 0xe838,
      requiredValue: 1,
    ),
    AppBadge(
      id: 'seven_day_streak',
      title: '7 Day Streak',
      description: '7 days in row',
      iconCodePoint: 0xef55,
      requiredValue: 7,
    ),
    AppBadge(
      id: 'focus_master',
      title: 'Focus Master',
      description: '10 journey days',
      iconCodePoint: 0xe8d0,
      requiredValue: 10,
    ),
    AppBadge(
      id: 'bookworm',
      title: 'Bookworm',
      description: 'Read 10 days',
      iconCodePoint: 0xe865,
      requiredValue: 10,
    ),
    AppBadge(
      id: 'unstoppable',
      title: 'Unstoppable',
      description: 'Earn 5000 XP',
      iconCodePoint: 0xe3af,
      requiredValue: 5000,
    ),
    AppBadge(
      id: 'perfect_week',
      title: 'Perfect Week',
      description: 'All habits for 7 days',
      iconCodePoint: 0xe885,
      requiredValue: 7,
    ),
  ];

  List<JourneyTask> _defaultJourneyTasks(DateTime now) {
    const journeyTitles = [
      'Wake up early',
      'No phone in morning',
      'Study 2 hours',
      'Read 20 pages',
      'Sleep before 11 PM',
      'Write daily reflection',
      'Clean your room',
      'Walk 20 minutes',
      'Plan tomorrow',
      'Deep work session',
    ];

    return List.generate(30, (index) {
      final day = index + 1;
      return JourneyTask(
        id: 'journey_$day',
        day: day,
        title: journeyTitles[index % journeyTitles.length],
        description: 'Small focused action for day $day.',
        xpReward: 25,
        completedAt: day <= 2 ? now.subtract(Duration(days: 3 - day)) : null,
        isLocked: day > 7,
      );
    });
  }

  void _loadDemoData() {
    onboardingCompleted = false;
    signedIn = false;
    profile = UserProfile.demo();
    focusSessions = [];

    final now = DateTime.now();

    List<HabitCompletion> completionsFor(List<int> daysAgo, int xp) {
      return daysAgo
          .map(
            (d) => HabitCompletion(
              date: DateHelper.dateOnly(now.subtract(Duration(days: d))),
              xpEarned: xp,
            ),
          )
          .toList();
    }

    habits = [
      Habit(
        id: 'habit_morning_exercise',
        name: 'Morning Exercise',
        category: HabitCategory.health,
        frequency: HabitFrequency.everyday,
        createdAt: now.subtract(const Duration(days: 21)),
        iconCodePoint: Icons.spa_rounded.codePoint,
        xpReward: 40,
        completions: completionsFor([
          0,
          1,
          2,
          3,
          4,
          5,
          6,
          8,
          9,
          10,
          12,
          13,
        ], 40),
        goal: '15 minutes',
        reminder: '06:30 AM',
      ),
      Habit(
        id: 'habit_study',
        name: 'Study 2 Hours',
        category: HabitCategory.study,
        frequency: HabitFrequency.everyday,
        createdAt: now.subtract(const Duration(days: 25)),
        iconCodePoint: Icons.menu_book_rounded.codePoint,
        xpReward: 50,
        completions: completionsFor([0, 1, 2, 4, 5, 6, 9, 11, 12, 15], 50),
        goal: '2 hours',
        reminder: '08:00 PM',
      ),
      Habit(
        id: 'habit_read',
        name: 'Read 20 Pages',
        category: HabitCategory.mind,
        frequency: HabitFrequency.everyday,
        createdAt: now.subtract(const Duration(days: 18)),
        iconCodePoint: Icons.auto_stories_rounded.codePoint,
        xpReward: 30,
        completions: completionsFor([0, 1, 3, 4, 7, 8, 10, 14, 16], 30),
        goal: '20 pages',
        reminder: '10:00 PM',
      ),
      Habit(
        id: 'habit_pray',
        name: 'Pray 5 Times',
        category: HabitCategory.faith,
        frequency: HabitFrequency.everyday,
        createdAt: now.subtract(const Duration(days: 30)),
        iconCodePoint: Icons.auto_awesome_rounded.codePoint,
        xpReward: 40,
        completions: completionsFor([1, 2, 3, 4, 5, 7, 9, 10, 11], 40),
        goal: '5 times',
        reminder: 'Every prayer time',
      ),
    ];

    xpHistory = [
      for (final habit in habits)
        for (final completion in habit.completions.take(8))
          XPHistoryItem(
            id: _id('xp'),
            title: 'Completed Habit',
            subtitle: habit.name,
            amount: completion.xpEarned,
            createdAt: completion.date,
            habitId: habit.id,
          ),
      XPHistoryItem(
        id: _id('xp'),
        title: 'Daily Bonus',
        subtitle: 'Consistency reward',
        amount: 20,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    badges = _defaultBadges();
    journeyTasks = _defaultJourneyTasks(now);

    _recalculateProfile();
    _refreshBadges();
  }
}
