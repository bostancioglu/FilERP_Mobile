import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/config/api_config.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/pages/login/login_page.dart';
import 'package:FilERP/pages/login/sirket_sube_secim_page.dart';
import 'package:FilERP/models/entities/yonetim/sirket_dto.dart';
import 'package:FilERP/models/entities/yonetim/sube_dto.dart';
import 'package:FilERP/models/entities/yonetim/kullanici_dto.dart';
import 'report_center_screens_test.dart' as previews;

void main() {
  setUpAll(() async {
    for (final e in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  for (final brightness in Brightness.values) {
    for (final scenario in ['login', 'autofill', 'company']) {
      testWidgets('auth $scenario ${brightness.name}', (tester) async {
        SharedPreferences.setMockInitialValues({
          'token': 'preview-token',
          if (scenario == 'autofill') ...{
            'dev_autofill': true,
            'dev_username': 'demo',
            'dev_password': 'preview-pass'
          }
        });
        await ApiConfig.setServer(ServerType.canli, save: false);
        if (scenario == 'company') {
          await (await SharedPreferences.getInstance()).setInt('firma_id', 5);
          await AuthorizationSession.instance.login({
            'Id': 1,
            'Firmaid': 5,
            'Yetki': [
              {'Subeid': 11, 'Modulaltid': 101},
              {'Subeid': 22, 'Modulaltid': 101}
            ]
          });
        }
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final key = GlobalKey();
        final requests = <http.Request>[];
        var loginSuccess = false;
        await http.runWithClient(() async {
          await tester.pumpWidget(RepaintBoundary(
              key: key,
              child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.build(brightness),
                  home: scenario == 'company'
                      ? SirketSubeSecimPage(sirketler: [
                          SirketDto(id: 1, ad: 'FilERP Ticaret'),
                          SirketDto(id: 2, ad: 'FilERP Dağıtım')
                        ], subeler: [
                          SubeDto(id: 11, sirketId: 1, ad: 'Kars Şubesi'),
                          SubeDto(id: 22, sirketId: 2, ad: 'Erzurum Şubesi')
                        ], kullaniciDetay: KullaniciDto(kullaniciAdi: 'demo'))
                      : const LoginPage())));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final authContext = tester.element(find.byType(Scaffold).first);
          expect(Theme.of(authContext).brightness, brightness);
          expect(
              Theme.of(authContext).scaffoldBackgroundColor,
              brightness == Brightness.dark
                  ? const Color(0xFF080809)
                  : AppTheme.build(brightness).scaffoldBackgroundColor);
          await previews.captureReport(
              tester, key, 'auth_${scenario}_${brightness.name}');
          if (scenario == 'company') {
            expect(find.text('Kars Şubesi'), findsOneWidget);
            expect(find.text('demo'), findsNothing);
            await tester.tap(find.byType(DropdownButtonFormField<SirketDto>));
            await tester.pumpAndSettle();
            await tester.tap(find.text('FilERP Dağıtım').last);
            await tester.pumpAndSettle();
            expect(
                tester
                    .widget<DropdownButtonFormField<SubeDto>>(
                        find.byType(DropdownButtonFormField<SubeDto>))
                    .initialValue!
                    .id,
                22);
            await tester.tap(find.text('Devam Et'));
            await tester.pumpAndSettle();
            expect(find.text('Şube girişi başarısız.'), findsOneWidget);
            expect(jsonDecode(requests.single.body), {'Sid': 2, 'Suid': 22});
          } else {
            if (scenario == 'autofill') {
              expect(
                  tester
                      .widget<TextField>(find.byType(TextField).first)
                      .controller!
                      .text,
                  'demo');
              await tester.tap(find.byType(Switch));
              await tester.pumpAndSettle();
              final prefs = await SharedPreferences.getInstance();
              expect(prefs.getString('dev_password'), isNull);
              expect(prefs.getBool('dev_autofill'), isFalse);
            }
            await tester.enterText(find.byType(TextField).first, '');
            await tester.enterText(find.byType(TextField).last, '');
            await tester.ensureVisible(find.text('Giriş Yap').last);
            await tester.tap(find.text('Giriş Yap').last);
            await tester.pumpAndSettle();
            expect(
                find.text('Kullanıcı adı ve şifre boş olamaz'), findsOneWidget);
            expect(requests, isEmpty);
            await tester.tap(find.text('Tamam'));
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(TextField).first, 'demo');
            await tester.enterText(find.byType(TextField).last, 'preview-pass');
            await tester.tap(find.byTooltip('Şifreyi Göster'));
            await tester.pumpAndSettle();
            expect(
                tester
                    .widget<TextField>(find.byType(TextField).last)
                    .obscureText,
                isFalse);
            await tester.tap(find.byTooltip('Şifreyi Gizle'));
            tester.view.physicalSize = const Size(320, 740);
            tester.view.viewInsets = const FakeViewPadding(bottom: 300);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            tester.view.resetViewInsets();
            FocusManager.instance.primaryFocus?.unfocus();
            await tester.pumpAndSettle();
            await tester
                .ensureVisible(find.byKey(const ValueKey('auth-brand')));
            await tester.tap(find.byKey(const ValueKey('auth-brand')));
            await tester.pumpAndSettle();
            expect(find.text('Bağlantı Ortamı'), findsNothing);
            await tester
                .ensureVisible(find.byKey(const ValueKey('auth-environment')));
            await tester.tap(find.byKey(const ValueKey('auth-environment')));
            await tester.pumpAndSettle();
            expect(find.text('Bağlantı Ortamı'), findsNothing);
            await tester
                .longPress(find.byKey(const ValueKey('auth-environment')));
            await tester.pumpAndSettle();
            expect(find.text('Canlı'), findsOneWidget);
            expect(find.text('Test'), findsOneWidget);
            final environmentText = tester.widget<Text>(find.text('Test'));
            expect(
                environmentText.style?.color,
                brightness == Brightness.dark
                    ? const Color(0xFFF4F4F5)
                    : AppTheme.build(brightness).colorScheme.onSurface);
            expect(
                tester
                    .widget<Material>(find
                        .ancestor(
                          of: find.text('Bağlantı Ortamı'),
                          matching: find.byType(Material),
                        )
                        .first)
                    .color,
                brightness == Brightness.dark
                    ? const Color(0xFF111113)
                    : AppTheme.build(brightness).colorScheme.surface);
            await previews.captureReport(
                tester, key, 'auth_environment_${brightness.name}');
            await tester.tap(find.text('Test'));
            await tester.pumpAndSettle();
            expect(ApiConfig.serverType, ServerType.test);
            await tester.ensureVisible(find.text('Giriş Yap').last);
            await tester.tap(find.text('Giriş Yap').last);
            await tester.pumpAndSettle();
            expect(
                find.text('Kullanıcı adı veya şifre hatalı'), findsOneWidget);
            await tester.tap(find.text('Tamam'));
            await tester.pumpAndSettle();
            expect(jsonDecode(requests.single.body),
                {'Kullaniciadi': 'demo', 'Sifre': 'preview-pass'});
            loginSuccess = true;
            await tester.tap(find.text('Giriş Yap').last);
            await tester.pumpAndSettle();
            expect(find.byType(SirketSubeSecimPage), findsOneWidget);
          }
          tester.view.physicalSize = const Size(320, 740);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
            () => MockClient((r) async {
                  requests.add(r);
                  if (r.url.path.endsWith('/Login/SS'))
                    return http.Response('{}', 500);
                  return http.Response(
                      jsonEncode(loginSuccess
                          ? {
                              'Data': {
                                'Kullaniciadi': 'demo',
                                'Token': 'preview-token',
                                'Firmaid': 1,
                                'Yetki': []
                              }
                            }
                          : {}),
                      loginSuccess ? 200 : 401,
                      headers: {
                        'content-type': 'application/json; charset=utf-8'
                      });
                }));
      });
    }
  }
}
