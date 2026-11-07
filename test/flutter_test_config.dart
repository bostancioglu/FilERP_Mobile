import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/config/api_config.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/services/auth/backend_authorization_catalog.dart';

// Existing screen tests are administrator fixtures. Restricted-user tests replace
// this fixture explicitly; production always starts with no permissions.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiConfig.setServer(ServerType.canli, save: false);
    AuthorizationSession.instance.activate([
      for (final id in sharedModuleIds.values)
        {
          'Subeid': 1,
          'Modulaltid': id,
          'TumunuOkuma': true,
          'Ekleme': true,
          'Guncelleme': true,
          'Silme': true,
        }
    ], branch: 1, company: 1, environment: 'canli', account: 'fixture:admin');
  });
  await testMain();
}
