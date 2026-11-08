import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/config/api_config.dart';
import 'package:FilERP/pages/home_page.dart';
import 'package:FilERP/pages/login/login_page.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/services/login/login_service.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'report_center_screens_test.dart' as previews;

void main() {
  setUpAll(() async {
    for (final font in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
          'logout reaches login before server responds and preserves credentials ${design.name} ${brightness.name}',
          (tester) async {
        SharedPreferences.setMockInitialValues({
          'token': 'initial',
          'token_final': 'final',
          'firma_id': 5,
          'sirket_id': 3,
          'sube_id': 4,
          'kullanici_adi': 'remembered-user',
          'dev_username': 'remembered-user',
          'dev_password': 'fake-remembered-password',
          'dev_autofill': true,
          'erp_design': design.name,
          'erp_brightness': brightness.name,
          'printer_mac': 'fake-printer',
          'permission_login_v1': '{}',
          'permission_active_v1': '{}'
        });
        designNotifier.value = design;
        AuthorizationSession.instance.activate([],
            branch: 4,
            company: 3,
            environment: ApiConfig.serverType.name,
            account: '5:1',
            token: 'final');
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final server = Completer<http.Response>();
        var requests = 0;
        http.Request? logoutRequest;
        final boundary = GlobalKey();
        await http.runWithClient(() async {
          await tester.pumpWidget(RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.build(brightness, design: design),
                  home: const PermissionPage(child: HomePage()))));
          await tester.pumpAndSettle();
          final dynamic state = tester.state(find.byType(HomePage));
          final Future<void> logout = state.logout();
          await tester.pumpAndSettle();
          expect(
              find.widgetWithText(FilledButton, 'Çıkış Yap'), findsOneWidget);
          expect(find.widgetWithText(OutlinedButton, 'Vazgeç'), findsOneWidget);
          await previews.captureReport(
              tester, boundary, 'logout_${design.name}_${brightness.name}');
          await tester.tap(find.widgetWithText(FilledButton, 'Çıkış Yap'));
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 30));
          });
          await tester.pumpAndSettle();
          expect(find.byType(LoginPage), findsOneWidget);
          expect(
              find.textContaining('Bu ekran için yetkiniz yok'), findsNothing);
          expect(find.text('Yetkisiz İşlem'), findsNothing);
          expect(find.byType(HomePage), findsNothing);
          expect(AuthorizationSession.instance.signedIn, isFalse);
          expect(requests, 1);
          expect(logoutRequest!.url.path, '/api/Login/Logout');
          expect(logoutRequest!.headers['authorization'], 'Bearer final');
          final prefs = await SharedPreferences.getInstance();
          for (final key in [
            'token',
            'token_final',
            'firma_id',
            'sirket_id',
            'sube_id',
            'permission_login_v1',
            'permission_active_v1'
          ]) {
            expect(prefs.containsKey(key), isFalse, reason: key);
          }
          expect(prefs.getString('dev_username'), 'remembered-user');
          expect(prefs.getString('dev_password'), 'fake-remembered-password');
          expect(prefs.getBool('dev_autofill'), isTrue);
          expect(prefs.getString('erp_design'), design.name);
          expect(prefs.getString('printer_mac'), 'fake-printer');
          expect(
              tester
                  .widget<TextField>(find.byType(TextField).first)
                  .controller!
                  .text,
              'remembered-user');
          expect(
              tester
                  .widget<TextField>(find.byType(TextField).last)
                  .controller!
                  .text,
              'fake-remembered-password');
          server.complete(http.Response('{}', 200));
          await tester.runAsync(() => logout);
          final loginContext = tester.element(find.byType(LoginPage));
          Navigator.of(loginContext).maybePop();
          await tester.pumpAndSettle();
          expect(find.byType(LoginPage), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
            () => MockClient((request) async {
                  logoutRequest = request;
                  requests++;
                  return server.future;
                }));
      });
    }
  }
  test('failed server logout still clears only local session', () async {
    SharedPreferences.setMockInitialValues({
      'token': 'one',
      'token_final': 'two',
      'dev_username': 'user',
      'dev_password': 'fake-password',
      'dev_autofill': true
    });
    await http.runWithClient(() => LoginService().logout('two'),
        () => MockClient((_) async => throw http.ClientException('offline')));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('token_final'), isNull);
    expect(prefs.getString('dev_password'), 'fake-password');
    expect(prefs.getBool('dev_autofill'), isTrue);
  });
  testWidgets(
      'migrated dialog has contrasting primary and outlined cancellation at large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.build(Brightness.dark),
        home: Builder(
            builder: (ctx) => MediaQuery(
                data: MediaQuery.of(ctx)
                    .copyWith(textScaler: const TextScaler.linear(1.6)),
                child: Scaffold(
                    body: AlertDialog(
                        title: const Text('Kaydı Sil'),
                        content: const Text('Kaydı silmek istiyor musunuz?'),
                        actions: [
                      ErpDialogAction(
                          secondary: true,
                          onPressed: () {},
                          child: const Text('Vazgeç')),
                      ErpDialogAction(
                          onPressed: () {},
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Sil')),
                    ]))))));
    await tester.pumpAndSettle();
    final button =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Sil'));
    final context = tester.element(find.widgetWithText(FilledButton, 'Sil'));
    expect(button.style!.backgroundColor!.resolve({}),
        Theme.of(context).colorScheme.error);
    expect(button.style!.foregroundColor!.resolve({}),
        Theme.of(context).colorScheme.onError);
    expect(find.widgetWithText(OutlinedButton, 'Vazgeç'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Turkish cancellation label uses the secondary button',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ErpDialogAction(
                onPressed: () {}, child: const Text('İptal')))));
    expect(find.widgetWithText(OutlinedButton, 'İptal'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('cancelling logout keeps session and allows another confirmation',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'token_final': 'final',
      'dev_username': 'user',
      'dev_password': 'fake-password'
    });
    AuthorizationSession.instance.activate([],
        branch: 1, company: 1, environment: ApiConfig.serverType.name);
    await tester
        .pumpWidget(MaterialApp(home: const PermissionPage(child: HomePage())));
    await tester.pumpAndSettle();
    final dynamic state = tester.state(find.byType(HomePage));
    for (var attempt = 0; attempt < 2; attempt++) {
      final Future<void> logout = state.logout();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Vazgeç'));
      await tester.pumpAndSettle();
      await logout;
      expect(AuthorizationSession.instance.signedIn, isTrue);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token_final'), 'final');
      expect(prefs.getString('dev_password'), 'fake-password');
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
