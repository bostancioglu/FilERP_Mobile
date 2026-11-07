import 'package:FilERP/theme/theme_controller.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/widgets/erp_negotiable_report.dart';
import 'package:FilERP/pages/finans/cek/cekalinan_rapor_page.dart';
import 'package:FilERP/pages/finans/senet/senetalinan_rapor_page.dart';
import 'package:FilERP/pages/finans/borc/cekverilen_rapor_genel_page.dart';
import 'package:FilERP/pages/finans/borc/cekverilen_rapor_odenecek_page.dart';
import 'package:FilERP/pages/finans/borc/senetverilen_rapor_genel_page.dart';
import 'package:FilERP/pages/finans/borc/senetverilen_rapor_odenecek_page.dart';
import 'package:FilERP/services/finans/vw_finanscekalinan_service.dart';
import 'package:FilERP/services/finans/vw_finanssenetalinan_service.dart';

final records = [
  {
    'Cariad': 'Marmara Gıda Ltd. Şti.',
    'Cekno': 'CK202600001',
    'Senetno': 'SN202600001',
    'Bordrono': 'BR2026000000001',
    'Asilborclu': 'Marmara Ticaret',
    'Bankaadi': 'Örnek Banka',
    'Vadetarihi': '2026-11-15',
    'SuandaEvrakyeri': 'Portföy',
    'SuandaEvrakdurum': 'Beklemede',
    'Tutar': 24580.75,
    'Doviztutar': 0.0,
    'Parabirimi': 'TL'
  },
  {
    'Cariad': 'Kuzey Market',
    'Cekno': 'CK202600002',
    'Senetno': 'SN202600002',
    'Bordrono': 'BR2026000000002',
    'Asilborclu': 'Kuzey Ticaret',
    'Bankaadi': 'Örnek Banka',
    'Vadetarihi': '2026-12-01',
    'SuandaEvrakyeri': 'Banka',
    'SuandaEvrakdurum': 'Tahsilde',
    'Tutar': 3380.0,
    'Doviztutar': 100.0,
    'Parabirimi': 'USD'
  },
];

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
  final screens = <String, Widget Function()>{
    'cheque_general': () => CekalinanRaporPage(
        title: 'Genel Çekler',
        fetcher: (t) => VwFinanscekalinanService().getGenel(t),
        showAsilBorclu: false),
    'cheque_endorsed': () => CekalinanRaporPage(
        title: 'Verilene Göre Çekler',
        fetcher: (t) => VwFinanscekalinanService().getVerilenegore(t),
        showAsilBorclu: true),
    'cheque_portfolio': () => CekalinanRaporPage(
        title: 'Portföydeki Çekler',
        fetcher: (t) => VwFinanscekalinanService().getPortfoy(t),
        showAsilBorclu: true),
    'cheque_collection': () => CekalinanRaporPage(
        title: 'Tahsildeki Çekler',
        fetcher: (t) => VwFinanscekalinanService().getTahsil(t),
        showAsilBorclu: true),
    'cheque_collateral': () => CekalinanRaporPage(
        title: 'Teminattaki Çekler',
        fetcher: (t) => VwFinanscekalinanService().getTeminat(t),
        showAsilBorclu: true),
    'cheque_protested': () => CekalinanRaporPage(
        title: 'Karşılıksız Çekler',
        fetcher: (t) => VwFinanscekalinanService().getKarsiliksiz(t),
        showAsilBorclu: true),
    'note_general': () => SenetalinanRaporPage(
        title: 'Genel Senetler',
        fetcher: (t) => VwFinanssenetalinanService().getGenel(t),
        showAsilBorclu: false),
    'note_endorsed': () => SenetalinanRaporPage(
        title: 'Verilene Göre Senetler',
        fetcher: (t) => VwFinanssenetalinanService().getVerilenegore(t),
        showAsilBorclu: true),
    'note_portfolio': () => SenetalinanRaporPage(
        title: 'Portföydeki Senetler',
        fetcher: (t) => VwFinanssenetalinanService().getPortfoy(t),
        showAsilBorclu: true),
    'note_collection': () => SenetalinanRaporPage(
        title: 'Tahsildeki Senetler',
        fetcher: (t) => VwFinanssenetalinanService().getTahsil(t),
        showAsilBorclu: true),
    'note_collateral': () => SenetalinanRaporPage(
        title: 'Teminattaki Senetler',
        fetcher: (t) => VwFinanssenetalinanService().getTeminat(t),
        showAsilBorclu: true),
    'note_protested': () => SenetalinanRaporPage(
        title: 'Karşılıksız Senetler',
        fetcher: (t) => VwFinanssenetalinanService().getKarsiliksiz(t),
        showAsilBorclu: true),
    'issued_cheque_general': () => const CekverilenRaporGenelPage(),
    'issued_cheque_pending': () => const CekverilenRaporOdenecekPage(),
    'issued_note_general': () => const SenetverilenRaporGenelPage(),
    'issued_note_pending': () => const SenetverilenRaporOdenecekPage(),
  };
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final screen in screens.entries) {
        testWidgets('${screen.key} ${design.name}_${brightness.name}',
            (tester) async {
          SharedPreferences.setMockInitialValues({'token_final': 'preview'});
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final shadows = debugDisableShadows;
          debugDisableShadows = false;
          final capture = GlobalKey();
          var writes = 0;
          try {
            await http.runWithClient(() async {
              await tester.pumpWidget(RepaintBoundary(
                  key: capture,
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.build(brightness, design: design),
                    initialRoute: '/report',
                    routes: {
                      '/': (_) => const Scaffold(),
                      '/report': (_) => screen.value()
                    },
                  )));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(find.byType(ErpNegotiableReportCard), findsNWidgets(2));
              expect(find.text('Toplam 27.960,75 ₺'), findsOneWidget);
              expect(find.text('100,00 USD'), findsOneWidget);
              await captureReport(tester, capture,
                  '${screen.key}_${design.name}_${brightness.name}');
              await tester.tap(find.byType(ErpNegotiableReportCard).first);
              await tester.pumpAndSettle();
              expect(find.text('Belge Detayı'), findsOneWidget);
              expect(find.text('Örnek Banka'), findsOneWidget);
              expect(find.text('BR2026000000001'), findsOneWidget);
              final hidesDebtor = !screen.key.startsWith('issued') &&
                  screen.key.endsWith('general');
              expect(find.text('Asıl Borçlu'),
                  hidesDebtor ? findsNothing : findsOneWidget);
              await captureReport(tester, capture,
                  '${screen.key}_detail_${design.name}_${brightness.name}');
              tester.view.physicalSize = const Size(320, 740);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              Navigator.of(tester.element(find.text('Belge Detayı'))).pop();
              await tester.pumpAndSettle();
              await tester.enterText(find.byType(TextField), 'Kuzey');
              await tester.pumpAndSettle();
              expect(find.byType(ErpNegotiableReportCard), findsOneWidget);
              expect(find.text('Toplam 3.380,00 ₺'), findsOneWidget);
              await tester.enterText(find.byType(TextField), 'bulunmayan');
              await tester.pumpAndSettle();
              expect(find.text('0 sonuç bulundu'), findsOneWidget);
              expect(find.text('Toplam 0,00 ₺'), findsOneWidget);
              await tester.tap(find.byTooltip('Yenile'));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(writes, 0);
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pumpAndSettle();
            },
                () => MockClient((request) async {
                      if (request.method != 'GET') writes++;
                      return http.Response(jsonEncode({'Data': records}), 200,
                          headers: {
                            'content-type': 'application/json; charset=utf-8'
                          });
                    }));
          } finally {
            debugDisableShadows = shadows;
          }
        });
      }
    }
  }
}

Future<void> captureReport(
    WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('tool/previews/report_$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}
