import 'package:FilERP/services/auth/authorization_session.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'package:FilERP/pages/fatura/Satisfaturasi/satisfatura_detay_page.dart';
import 'package:FilERP/pages/irsaliye/irsaliye_detay_page.dart';
import 'package:FilERP/services/login/login_service.dart';
import 'warehouse_screens_test.dart' as fixtures;
import 'permission_fixtures.dart';
import 'package:FilERP/services/auth/user_parameters.dart';
import 'report_center_screens_test.dart' as previews;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final entry in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });
  test('branch login persists selected company and branch IDs', () async {
    final finalToken = 'header.${base64Url.encode(utf8.encode(jsonEncode({
              UserParameters.claimName:
                  jsonEncode({'Otomatikefaturagonder': true})
            }))).replaceAll('=', '')}.signature';
    SharedPreferences.setMockInitialValues(
        {'token': 'fake-login', 'sirket_id': 0, 'sube_id': 0});
    await AuthorizationSession.instance
        .login({'Id': 1, 'Firmaid': null, 'Yetki': []});
    await http.runWithClient(
        () => LoginService().loginSirketSube(7, 9),
        () => MockClient((_) async => http.Response(
            jsonEncode({
              'Data': {'Token': finalToken}
            }),
            200)));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('sirket_id'), 7);
    expect(prefs.getInt('sube_id'), 9);
    expect(AuthorizationSession.instance.automaticElectronicSend, isTrue);
    await AuthorizationSession.instance.restore();
    expect(AuthorizationSession.instance.automaticElectronicSend, isTrue);
  });

  for (final completed in [false, true]) {
    for (final automatic in [false, true]) {
      for (final invoice in [true, false]) {
        for (final design in ErpDesign.values) {
          for (final brightness in Brightness.values) {
            testWidgets(
                '${invoice ? 'invoice' : 'waybill'} ${design.name} ${brightness.name} completed=$completed automatic=$automatic compact menu and cancellation',
                (tester) async {
              final token = 'header.${base64Url.encode(utf8.encode(jsonEncode({
                        UserParameters.claimName:
                            jsonEncode({'Otomatikefaturagonder': automatic})
                      }))).replaceAll('=', '')}.signature';
              grantAdministratorFixture(token: token);
              SharedPreferences.setMockInitialValues(
                  {'token_final': token, 'sirket_id': 7});
              tester.view.physicalSize = const Size(320, 640);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              final key = GlobalKey();
              final requests = <http.Request>[];
              await http.runWithClient(() async {
                await tester.runAsync(() async {
                  await tester.pumpWidget(RepaintBoundary(
                      key: key,
                      child: MaterialApp(
                        debugShowCheckedModeBanner: false,
                        theme: AppTheme.build(brightness, design: design),
                        initialRoute: '/detail',
                        onGenerateRoute: (settings) => MaterialPageRoute(
                          settings: RouteSettings(
                              name: settings.name, arguments: 'doc-1'),
                          builder: (_) => settings.name == '/'
                              ? const Scaffold()
                              : invoice
                                  ? const SatisFaturaDetayPage()
                                  : const IrsaliyeDetayPage(),
                        ),
                      )));
                  await Future<void>.delayed(const Duration(milliseconds: 80));
                });
                await tester.pumpAndSettle();
                await tester.tap(find.byTooltip('Belge İşlemleri'));
                await tester.pumpAndSettle();
                expect(
                    find.text(
                        invoice ? 'Faturayı Düzenle' : 'İrsaliyeyi Düzenle'),
                    completed ? findsNothing : findsOneWidget);
                expect(find.text(invoice ? 'Faturayı Sil' : 'İrsaliyeyi Sil'),
                    completed ? findsNothing : findsOneWidget);
                if (!completed) {
                  expect(find.text('Belgeyi Tamamla'), findsOneWidget);
                  expect(find.text('Portala Gönder'), findsNothing);
                  expect(
                      find.textContaining('Oluştur ve Gönder'), findsNothing);
                  await tester.pumpWidget(const SizedBox.shrink());
                  await tester.pumpAndSettle();
                  return;
                }
                expect(find.text('Portala Gönder'),
                    automatic ? findsNothing : findsOneWidget);
                final label = invoice
                    ? 'E-Fatura Oluştur ve Gönder'
                    : 'E-İrsaliye Oluştur ve Gönder';
                expect(find.text(label),
                    automatic ? findsOneWidget : findsNothing);
                final selectedLabel = automatic ? label : 'Portala Gönder';
                expect(tester.takeException(), isNull);
                await previews.captureReport(tester, key,
                    'ebelge_${invoice ? 'invoice' : 'waybill'}_${design.name}_${brightness.name}_auto$automatic');
                await tester.ensureVisible(find.text(selectedLabel));
                await tester.tap(find.text(selectedLabel));
                await tester.pumpAndSettle();
                expect(
                    automatic
                        ? find.textContaining('Gönder · CANLI')
                        : find.widgetWithText(FilledButton, 'Portala Gönder'),
                    findsOneWidget);
                await tester.tap(find.text('Vazgeç'));
                await tester.pumpAndSettle();
                expect(requests.where((r) => r.method != 'GET'), isEmpty);
                // İptal sonrası aynı menü yeniden açılabilir (busy kilidi kalkar).
                await tester.tap(find.byTooltip('Belge İşlemleri'));
                await tester.pumpAndSettle();
                expect(find.text('Portala Gönder'),
                    automatic ? findsNothing : findsOneWidget);
                await tester.pumpWidget(const SizedBox.shrink());
                await tester.pumpAndSettle();
              },
                  () => MockClient((request) async {
                        requests.add(request);
                        return http.Response(
                            jsonEncode({
                              'Data': {
                                ...fixtures.documents[0],
                                'Belgedurum': completed ? 1 : 0,
                                'Sirketid': 7,
                                'Cari': {
                                  'Id': 1,
                                  'Kod': 'CR.001',
                                  'Ad': 'Örnek Cari'
                                },
                                'Doviz': {'Id': 1, 'Birim': 'TL'},
                                'Faturahareket': [fixtures.line],
                                'Irsaliyehareket': [fixtures.line],
                                'EFaturadurum': 0,
                                'Eirsaliyedurum': 0,
                              }
                            }),
                            200,
                            headers: {
                              'content-type': 'application/json; charset=utf-8'
                            });
                      }));
            });
          }
        }
      }
    }
  }
}
