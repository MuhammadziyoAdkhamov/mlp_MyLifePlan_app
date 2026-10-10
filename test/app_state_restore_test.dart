import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mylife_plan/models/user_profile.dart';
import 'package:mylife_plan/providers/app_state.dart';
import 'package:mylife_plan/services/auth_service.dart';
import 'package:mylife_plan/services/cloud_sync_service.dart';
import 'package:mylife_plan/services/local_storage_service.dart';
import 'package:mylife_plan/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('missing catalogs do not replace restored account data', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService();
    await storage.saveAppData({
      'onboardingCompleted': true,
      'signedIn': true,
      'profile': UserProfile(
        id: 'guest_local',
        name: 'Saved profile',
        email: 'guest@mylife.local',
        totalXp: 120,
        level: 1,
        createdAt: DateTime(2026),
      ).toJson(),
      'habits': <Object>[],
      'badges': <Object>[],
      'xpHistory': <Object>[],
      'journeyTasks': <Object>[],
    });
    final state = AppState(
      storage: storage,
      authService: _FakeAuthService(),
      cloudSyncService: _FakeCloudSyncService(),
    );

    await state.init();

    expect(state.profile.name, 'Saved profile');
    expect(state.onboardingCompleted, isTrue);
    expect(state.signedIn, isTrue);
    expect(state.habits, isEmpty);
    expect(state.xpHistory, isEmpty);
    expect(state.badges, isNotEmpty);
    expect(state.journeyTasks, isNotEmpty);
    state.dispose();
  });

  test('onboarding creates and persists the chosen starter plan', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService();
    final state = AppState(
      storage: storage,
      authService: _FakeAuthService(),
      cloudSyncService: _FakeCloudSyncService(),
      notificationService: _FakeNotificationService(),
    );

    await state.init();
    expect(state.habits, isEmpty);

    await state.completeOnboarding(
      name: '  Laylo  ',
      focus: 'energy',
      starterSelections: [0, 2],
    );

    expect(state.profile.name, 'Laylo');
    expect(state.profile.growthFocus, 'energy');
    expect(state.habits, hasLength(2));
    expect(state.habits.map((habit) => habit.name), contains('Suv ichish'));
    expect(
      state.habits.map((habit) => habit.name),
      contains('Uyquga tayyorgarlik'),
    );
    expect(
      state.habits.map((habit) => habit.name),
      isNot(contains('10 daqiqa yurish')),
    );
    final savedData = await storage.loadAppData();
    final savedProfile = savedData?['profile'] as Map<String, dynamic>;
    expect(savedProfile['name'], 'Laylo');
    expect(savedProfile['growthFocus'], 'energy');
    expect(state.onboardingCompleted, isTrue);

    await state.completeOnboarding(
      name: 'Laylo',
      focus: 'energy',
      starterSelections: [0, 2],
    );
    expect(state.habits, hasLength(2));
    state.dispose();
  });

  test('onboarding without a focus does not add starter habits', () async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(
      storage: LocalStorageService(),
      authService: _FakeAuthService(),
      cloudSyncService: _FakeCloudSyncService(),
      notificationService: _FakeNotificationService(),
    );

    await state.init();
    await state.completeOnboarding();

    expect(state.habits, isEmpty);
    state.dispose();
  });

  test(
    'delete my data clears guest storage without saving demo data',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService();
      final state = AppState(
        storage: storage,
        authService: _FakeAuthService(),
        cloudSyncService: _FakeCloudSyncService(),
        notificationService: _FakeNotificationService(),
      );

      await state.init();
      expect(await storage.loadAppData(), isNotNull);

      await state.deleteMyData();

      expect(await storage.loadAppData(), isNull);
      expect(state.signedIn, isFalse);
      expect(state.onboardingCompleted, isFalse);
      state.dispose();
    },
  );
}

class _FakeAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  bool get isSignedIn => false;

  @override
  Stream<User?> get authStateChanges => const Stream<User?>.empty();

  @override
  Future<UserCredential> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

class _FakeCloudSyncService implements CloudSyncService {
  @override
  Future<Map<String, dynamic>?> loadAppData(String uid) async => null;

  @override
  Future<void> saveAppData(String uid, Map<String, dynamic> data) async {}

  @override
  Future<void> deleteAppData(String uid) async {}
}

class _FakeNotificationService extends NotificationService {
  @override
  Future<void> cancelHabitReminder(String habitId) async {}
}
