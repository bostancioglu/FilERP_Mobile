import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/pages/home_page.dart';
import 'package:FilERP/pages/login/sirket_sube_secim_page.dart';
import 'package:FilERP/models/entities/yonetim/sube_dto.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/services/login/login_service.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'package:FilERP/widgets/permission_page.dart';

Map<String, dynamic> branch(int id) => {
      'Id': id,
      'Ad': id == 1 ? 'Merkez' : 'Kars',
      'Sirketid': 3,
      'Sirket': {
        'Id': 3,
        'Ad': 'Test Şirketi',
        'Efaturaentegratorsifre': 'never-cache-secret'
      }
    };
final user = {
  'Id': 42,
  'Firmaid': 5,
  'Kullaniciadi': 'demo',
  'Firma': {'Ad': 'Test Firma'},
  'Yetki': [
    {'Subeid': 1, 'Modulaltid': 101, 'TumunuOkuma': true, 'Sube': branch(1)},
    {'Subeid': 2, 'Modulaltid': 301, 'TumunuOkuma': true, 'Sube': branch(2)},
  ]
};
http.Response data(dynamic value) =>
    http.Response(jsonEncode({'Data': value}), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
Future<SharedPreferences> seed() async {
  SharedPreferences.setMockInitialValues({
    'firma_id': 5,
    'sirket_id': 3,
    'sube_id': 1,
    'token': 'initial',
    'firma_adi': 'Test Firma',
    'sirket_adi': 'Test Şirketi',
    'sube_adi': 'Merkez',
    'kullanici_adi': 'demo',
    'dev_username': 'remembered',
    'dev_password': 'fake-saved-password',
    'printer_mac': 'printer',
    'varsayilan_depo_id': 10,
    'varsayilan_proje_id': 20
  });
  await AuthorizationSession.instance.login(user);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token_final', 'old-active');
  await AuthorizationSession.instance.selectBranch(3, 1);
  return prefs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final e in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  test(
      'SS reuses current server session, filters grants and restores branch defaults',
      () async {
    final prefs = await seed();
    final oldScope = AuthorizationSession.instance.cacheScope;
    final headers = <String?>[];
    await http.runWithClient(() async {
      await LoginService().loginSirketSube(3, 2);
      expect(AuthorizationSession.instance.can(101), false);
      expect(AuthorizationSession.instance.can(301, Access.read), true);
      expect(AuthorizationSession.instance.cacheScope, isNot(oldScope));
      expect(prefs.getInt('varsayilan_depo_id'), null);
      expect(prefs.getInt('varsayilan_proje_id'), null);
      await prefs.setInt('varsayilan_depo_id', 22);
      await LoginService().loginSirketSube(3, 1);
      expect(prefs.getInt('varsayilan_depo_id'), 10);
      expect(prefs.getInt('varsayilan_proje_id'), 20);
      expect(prefs.getString('token'), 'initial');
      expect(prefs.getString('dev_password'), 'fake-saved-password');
    },
        () => MockClient((r) async {
              expect(r.url.path, endsWith('/Login/SS'));
              headers.add(r.headers['Authorization']);
              return data({
                'Token': headers.length == 1 ? 'new-active' : 'back-active'
              });
            }));
    expect(headers, ['Bearer old-active', 'Bearer new-active']);
  });
  for (final response in [http.Response('{}', 400), data({})]) {
    test(
        'failed or incomplete SS preserves active identity ${response.statusCode}',
        () async {
      final prefs = await seed();
      final revision = AuthorizationSession.instance.revision;
      await http.runWithClient(() async {
        await LoginService().loginSirketSube(3, 2);
      }, () => MockClient((_) async => response));
      expect(prefs.getString('token_final'), 'old-active');
      expect(prefs.getInt('sube_id'), 1);
      expect(AuthorizationSession.instance.signedIn, true);
      expect(AuthorizationSession.instance.can(101, Access.read), true);
      expect(AuthorizationSession.instance.revision, revision);
      expect(prefs.getInt('varsayilan_depo_id'), 10);
    });
  }
  test(
      'legacy sessions recover only granted branch IDs and retain no nested secrets',
      () async {
    final prefs = await seed();
    final envelope = jsonDecode(prefs.getString('permission_login_v1')!) as Map;
    envelope.remove('branchChoices');
    await prefs.setString('permission_login_v1', jsonEncode(envelope));
    final requests = <String>[];
    await http.runWithClient(() async {
      final recovered = await LoginService().branchSelectionUser();
      expect(recovered.yetkiler!.map((r) => r.subeId), [1, 2]);
      await LoginService().branchSelectionUser();
    },
        () => MockClient((r) async {
              requests.add(r.url.path);
              return data(branch(int.parse(r.url.path.split('/').last)));
            }));
    expect(requests.length, 2);
    expect(prefs.getString('permission_login_v1'),
        isNot(contains('never-cache-secret')));
    await http.runWithClient(() async {
      await expectLater(LoginService().loginSirketSube(3, 99), throwsException);
    },
        () => MockClient((_) async {
              fail('Unauthorized branch must not reach API');
            }));
  });
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
          'header opens selection, cancel preserves session, success clears old routes ${design.name} ${brightness.name}',
          (tester) async {
        final prefs = await seed();
        designNotifier.value = design;
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final requests = <http.Request>[];
        await http.runWithClient(() async {
          await tester.pumpWidget(MaterialApp(
              theme: AppTheme.build(brightness, design: design),
              home: const PermissionPage(child: HomePage())));
          await flush(tester);
          await tester.tap(find.byKey(const ValueKey('branch-switch')));
          await flush(tester);
          expect(find.byType(SirketSubeSecimPage), findsOneWidget);
          final initial = tester.widget<DropdownButtonFormField<SubeDto>>(
              find.byType(DropdownButtonFormField<SubeDto>));
          expect(initial.initialValue?.id, 1);
          expect(find.text('Giriş Ekranı'), findsNothing);
          await tester.tap(find.text('Vazgeç'));
          await tester.pumpAndSettle();
          expect(prefs.getString('token_final'), 'old-active');
          expect(requests, isEmpty);
          await tester.tap(find.byKey(const ValueKey('branch-switch')));
          await flush(tester);
          await tester.tap(find.byType(DropdownButtonFormField<SubeDto>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Kars').last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Şubeyi Değiştir'));
          await flush(tester);
          expect(requests.length, 1);
          expect(requests.single.url.path, endsWith('/Login/SS'));
          expect(requests.single.headers['Authorization'], 'Bearer old-active');
          expect(jsonDecode(requests.single.body), {'Sid': 3, 'Suid': 2});
          expect(find.byType(SirketSubeSecimPage), findsNothing);
          expect(find.byType(HomePage), findsOneWidget);
          expect(find.textContaining('Kars'), findsOneWidget);
          expect(find.text('Yetkisiz İşlem'), findsNothing);
          expect(Navigator.of(tester.element(find.byType(HomePage))).canPop(),
              false);
          expect(prefs.getInt('sube_id'), 2);
          expect(prefs.getString('token_final'), 'new-active');
          expect(prefs.getString('dev_password'), 'fake-saved-password');
          expect(prefs.getString('printer_mac'), 'printer');
          expect(AuthorizationSession.instance.can(101), false);
          expect(AuthorizationSession.instance.can(301, Access.read), true);
          expect(tester.takeException(), null);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
            () => MockClient((r) async {
                  if (r.method == 'GET') {
                    expect(r.headers['Authorization'], 'Bearer new-active');
                    return data([]);
                  }
                  requests.add(r);
                  expect(r.url.path, endsWith('/Login/SS'));
                  return data({'Token': 'new-active'});
                }));
      });
    }
  }
}

Future<void> flush(WidgetTester tester) async {
  await tester.pump();
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
  await tester.pumpAndSettle();
}
