import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mylife_plan/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorageService();
  });

  test('guest and cloud accounts use separate storage scopes', () async {
    await storage.saveAppData({'owner': 'guest'});
    await storage.saveAppData({'owner': 'account-a'}, userId: 'account-a');
    await storage.saveAppData({'owner': 'account-b'}, userId: 'account-b');

    expect(await storage.loadAppData(), {'owner': 'guest'});
    expect(await storage.loadAppData(userId: 'account-a'), {
      'owner': 'account-a',
    });
    expect(await storage.loadAppData(userId: 'account-b'), {
      'owner': 'account-b',
    });
  });

  test('legacy data is not implicitly assigned to a storage scope', () async {
    SharedPreferences.setMockInitialValues({
      'mylife_plan_app_data_v1': '{"owner":"unknown"}',
    });

    expect(await storage.loadAppData(), isNull);
    expect(await storage.loadAppData(userId: 'account-b'), isNull);
    expect(await storage.loadLegacyAppData(), {'owner': 'unknown'});
  });

  test('legacy migration does not overwrite an existing scoped profile',
      () async {
    SharedPreferences.setMockInitialValues({
      'mylife_plan_app_data_v1':
          '{"profile":{"id":"account-a"},"owner":"legacy"}',
      'mylife_plan_app_data_v2_user_account-a': '{"owner":"account-a"}',
    });

    expect(await storage.migrateLegacyAppData(userId: 'account-a'), isFalse);

    expect(await storage.loadAppData(userId: 'account-a'), {
      'owner': 'account-a',
    });
    expect(await storage.loadLegacyAppData(), {
      'profile': {'id': 'account-a'},
      'owner': 'legacy',
    });
  });

  test('legacy account data only migrates to its matching user', () async {
    SharedPreferences.setMockInitialValues({
      'mylife_plan_app_data_v1': '{"profile":{"id":"account-a"}}',
    });

    expect(await storage.migrateLegacyAppData(userId: 'account-b'), isFalse);
    expect(await storage.loadAppData(userId: 'account-b'), isNull);
    expect(await storage.migrateLegacyAppData(userId: 'account-a'), isTrue);
    expect(await storage.loadAppData(userId: 'account-a'), {
      'profile': {'id': 'account-a'},
    });
  });
}
