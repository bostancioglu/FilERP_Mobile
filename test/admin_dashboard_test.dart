import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/config/api_config.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/services/dashboard/admin_dashboard_service.dart';
import 'permission_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthorizationSession.instance.reset();
  });
  tearDown(() => AuthorizationSession.instance.reset());
  test('daily range excludes next midnight and missing dates', () {
    final metric = DashboardMetric('test', [
      {'Tarih': '2026-11-11T00:00:00', 'Geneltoplam': 100},
      {'Tarih': '2026-11-11T23:59:59', 'Geneltoplam': 50},
      {'Tarih': '2026-11-12T00:00:00', 'Geneltoplam': 900},
      {'Geneltoplam': 500},
    ]);
    expect(metric.total(DateTime(2026, 11, 11), DateTime(2026, 11, 12)), 150);
    expect(
        metric.between(DateTime(2026, 11, 11), DateTime(2026, 11, 12)).length,
        2);
  });
  test('signed-out user cannot load dashboard', () async {
    expect(await AdminDashboardService().allowed(), isFalse);
    await expectLater(AdminDashboardService().load(), throwsStateError);
  });
  test('non-admin remains blocked even with module permissions', () async {
    grantAdministratorFixture(token: 'test');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('firma_id', 1);
    await prefs.setString(
        'permission_login_v1',
        jsonEncode({
          'environment': ApiConfig.serverType.name,
          'firm': 1,
          'display': {'user': 'personel'}
        }));
    expect(await AdminDashboardService().allowed(), isFalse);
  });
  test('username admin does not grant administrator access', () async {
    grantAdministratorFixture(token: 'test');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('firma_id', 1);
    await prefs.setString(
        'permission_login_v1',
        jsonEncode({
          'environment': ApiConfig.serverType.name,
          'firm': 1,
          'display': {'user': 'admin'}
        }));
    expect(await AdminDashboardService().allowed(), isFalse);
    await expectLater(AdminDashboardService().load(), throwsStateError);
  });

  Future<void> loginUser(String name, dynamic admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('firma_id', 1);
    await prefs.setInt('sirket_id', 1);
    await prefs.setInt('sube_id', 1);
    await AuthorizationSession.instance.login({
      'Id': 7,
      'Firmaid': 1,
      'Kullaniciadi': name,
      'Admin': admin,
      'Yetki': [
        {'Subeid': 1, 'Modulaltid': 301, 'TumunuOkuma': true}
      ]
    });
    await prefs.setString('token_final', 'test');
    await AuthorizationSession.instance.selectBranch(1, 1);
  }

  test(
      'backend Admin flag grants access regardless of username and survives restore',
      () async {
    await loginUser('ayse', true);
    expect(await AdminDashboardService().allowed(), isTrue);
    await AuthorizationSession.instance.restore();
    expect(await AdminDashboardService().allowed(), isTrue);
    await AuthorizationSession.instance.clear();
    expect(await AdminDashboardService().allowed(), isFalse);
  });
  test('SS admin revocation takes effect on branch selection and restore',
      () async {
    await loginUser('ayse', true);
    await AuthorizationSession.instance.selectBranch(1, 1, admin: false);
    expect(await AdminDashboardService().allowed(), isFalse);
    await AuthorizationSession.instance.restore();
    expect(await AdminDashboardService().allowed(), isFalse);
  });
  test(
      'only boolean true is accepted, username and broad grants do not substitute',
      () async {
    for (final flag in [false, null, 'true', 1]) {
      await loginUser('admin', flag);
      expect(await AdminDashboardService().allowed(), isFalse);
    }
  });
}
