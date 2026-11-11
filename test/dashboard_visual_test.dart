import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/pages/admin_dashboard_page.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/services/auth/backend_authorization_catalog.dart';
import 'package:FilERP/widgets/dashboard_donut.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    await loader.load();
  });
  for (final width in [320.0, 390.0]) {
    testWidgets(
        'dashboard cards, donut selections and periods render at $width',
        (tester) async {
      SharedPreferences.setMockInitialValues({'firma_id': 1});
      await tester.binding.setSurfaceSize(Size(width, 1000));
      addTearDown(() {
        AuthorizationSession.instance.reset();
        return tester.binding.setSurfaceSize(null);
      });
      await AuthorizationSession.instance.login({
        'Id': 1,
        'Firmaid': 1,
        'Admin': true,
        'Yetki': [
          for (final id in sharedModuleIds.values)
            {'Subeid': 1, 'Modulaltid': id, 'TumunuOkuma': true}
        ]
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token_final', 'test');
      await AuthorizationSession.instance.selectBranch(1, 1);
      final date = DateTime.now().toIso8601String();
      final client = MockClient((r) async {
        final path = r.url.path;
        final List data;
        if (path.endsWith('WithoutAuth')) {
          data = [
            {'Id': 1}
          ];
        } else if (path.contains('GetBy')) {
          data = [
            {'Tarih': date, 'Giriscikis': 1, 'Tutar': 48000},
            {'Tarih': date, 'Giriscikis': 2, 'Tutar': 32000}
          ];
        } else {
          data = [
            for (var i = 0; i < 6; i++)
              {
                'Tarih': date,
                'Belgedurum': 1,
                'Belgeturu': path.endsWith('Irsaliye') ? 3 : 1,
                'Giriscikis': 2,
                'Geneltoplam': 12500.0 * (i + 1),
                'Songeneltoplam': 12500.0 * (i + 1),
                'Cari': {'Ad': 'Örnek Müşteri ${i + 1}'}
              }
          ];
        }
        return http.Response(jsonEncode({'Data': data}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });
      const key = ValueKey('preview');
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                fontFamily: 'Roboto',
                useMaterial3: true,
                colorScheme:
                    ColorScheme.fromSeed(seedColor: const Color(0xFF294875))),
            home: RepaintBoundary(key: key, child: AdminDashboardPage())));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Bugün'), findsNothing);
        expect(find.textContaining('Seçili şirket/şube'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('dashboard-date-range')));
        await tester.pumpAndSettle();
        expect(find.byType(DateRangePickerDialog), findsOneWidget);
        await tester.tap(find.text('Uygula'));
        await tester.pumpAndSettle();
        expect(find.byType(DateRangePickerDialog), findsNothing);
        expect(tester.takeException(), isNull);
        if (Platform.environment['UPDATE_DASHBOARD_PREVIEW'] == '1' &&
            width == 390) {
          await tester.runAsync(() async {
            final boundary =
                tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await File('/tmp/filerp-dashboard-dates-preview.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.scrollUntilVisible(
            find.text('Ödemeler nereden yapıldı?'), 250);
        await Scrollable.ensureVisible(
            tester.element(find.text('Ödemeler nereden yapıldı?')),
            alignment: 0.05);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final payment = find.byType(DashboardDonut).first;
        await tester.tap(
            find.descendant(of: payment, matching: find.text('Kasa')).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (Platform.environment['UPDATE_DASHBOARD_PREVIEW'] == '1' &&
            width == 390) {
          await tester.runAsync(() async {
            final boundary =
                tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await File('/tmp/filerp-dashboard-preview.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }, () => client);
    });
  }
  testWidgets('missing and zero datasets do not invent donut percentages',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: DashboardDonut(
                title: 'Dağılım', subtitle: 'TL', slices: null))));
    expect(find.textContaining('tüm kaynakların'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body:
                DashboardDonut(title: 'Dağılım', subtitle: 'TL', slices: []))));
    expect(
        find.text('Bu dönemde dağılım oluşturacak işlem yok.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
