import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'package:FilERP/services/cache/list_cache_service.dart';
import 'package:FilERP/services/offline/offline_service.dart';
import 'package:FilERP/pages/fatura/Satisfaturasi/satisfatura_detay_page.dart';
import 'package:FilERP/pages/fatura/Alisfaturasi/alisfatura_detay_page.dart';
import 'package:FilERP/pages/irsaliye/irsaliye_detay_page.dart';
import 'package:FilERP/pages/irsaliye/Alis/alisirsaliye_detay_page.dart';
import 'package:FilERP/pages/siparis/Satis/satissiparis_detay_page.dart';
import 'package:FilERP/pages/siparis/Alis/alissiparis_detay_page.dart';
import 'package:FilERP/pages/depo/ambargc/ambargc_detay_page.dart';
import 'package:FilERP/pages/depo/dat/arac_yukle_ekle_page.dart';
import 'package:FilERP/pages/depo/dat/rapor/malzeme_ambar_durum_raporu.dart';
import 'package:FilERP/pages/fatura/Alisfaturasi/fatura_tarama_page.dart';
import 'package:FilERP/pages/nfc/nfc_deneme_page.dart';
import 'package:FilERP/pages/splash/splash_page.dart';
import 'package:FilERP/pages/login/login_page.dart';
import 'package:FilERP/widgets/fis_onizleme_page.dart';
import 'package:FilERP/widgets/fatura/fatura_kalem_form_sheet.dart';
import 'package:FilERP/models/entities/fatura/faturahareket_dto.dart';
import 'package:FilERP/models/entities/stok/stok_list_dto.dart';
import 'warehouse_screens_test.dart' as warehouse;
import 'report_center_screens_test.dart' as previews;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  setUpAll(() async {
    cache = await Directory.systemTemp.createTemp('theme_completion_');
    Hive.init(cache.path);
    await ListCacheService.instance.init();
    SharedPreferences.setMockInitialValues({'offline_mode': false});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (call) async => call.method == 'check' ? ['none'] : null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        (_) async => null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_nfc_kit/method'),
        (call) async =>
            call.method == 'getNFCAvailability' ? 'not_supported' : null);
    await OfflineService.instance.init();
    for (final e in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  tearDownAll(() async {
    OfflineService.instance.dispose();
    await Hive.close();
    await cache.delete(recursive: true);
  });
  final screens = <String, Widget Function()>{
    'sales_invoice_detail': () => const SatisFaturaDetayPage(),
    'purchase_invoice_detail': () => const AlisFaturaDetayPage(),
    'sales_delivery_detail': () => const IrsaliyeDetayPage(),
    'purchase_delivery_detail': () => const AlisIrsaliyeDetayPage(),
    'sales_order_detail': () => const SatisSiparisDetayPage(),
    'purchase_order_detail': () => const AlisSiparisDetayPage(),
    'warehouse_detail': () => const AmbargcDetayPage(),
    'vehicle_load': () => const AracYukleEklePage(datId: 'doc-1'),
    'warehouse_report': () => const MalzemeAmbarDurumRaporu(),
    'invoice_scan': () => const FaturaTaramaPage(),
    'nfc': () => const NfcDenemePage(),
    'splash': () => const SplashPage(),
  };
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final screen in screens.entries) {
        testWidgets('audit ${design.name} ${screen.key} ${brightness.name}',
            (tester) async {
          SharedPreferences.setMockInitialValues(
              {'token_final': 'preview', 'sube_id': 1});
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          final previous = FlutterError.onError;
          FlutterError.onError = (d) {
            if (d.exceptionAsString().contains('overflowed'))
              debugPrint(d.toString());
            previous?.call(d);
          };
          final capture = GlobalKey();
          final requests = <http.Request>[];
          try {
            await http.runWithClient(() async {
              await tester.runAsync(() async {
                await tester.pumpWidget(RepaintBoundary(
                    key: capture,
                    child: MaterialApp(
                        debugShowCheckedModeBanner: false,
                        theme: AppTheme.build(brightness, design: design),
                        initialRoute: '/screen',
                        onGenerateRoute: (settings) => MaterialPageRoute(
                            settings: RouteSettings(
                                name: settings.name, arguments: 'doc-1'),
                            builder: (_) => settings.name == '/'
                                ? const Scaffold()
                                : screen.value()))));
                await Future<void>.delayed(const Duration(milliseconds: 1600));
              });
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              if (screen.key == 'warehouse_report') {
                await tester.tap(find.text('Sorgula'));
                await tester.pumpAndSettle();
                expect(find.textContaining('Organik Zeytinyağı'), findsWidgets);
              }
              if (screen.key.endsWith('_detail'))
                expect(find.textContaining('DPO2026'), findsWidgets);
              if (screen.key == 'splash') {
                await tester.pump(const Duration(seconds: 2));
                await tester.pumpAndSettle();
                expect(find.byType(LoginPage), findsOneWidget);
              }
              await previews.captureReport(tester, capture,
                  'audit_${design.name}_${screen.key}_${brightness.name}');
              tester.view.physicalSize = const Size(320, 740);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              if (screen.key == 'vehicle_load') {
                await tester.tap(find.text('Kalemler').first);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
              }
              if (screen.key == 'invoice_scan') {
                final context = tester.element(find.byType(FaturaTaramaPage));
                showFisOnizleme(context,
                    baslik: 'Fiş Önizleme',
                    satirlar: ['FilERP Mobile', 'Toplam 240,00 TL'],
                    yazdir: () async => null);
                await tester.pumpAndSettle();
                await tester.tap(find.text('Yazdır'));
                await tester.pumpAndSettle();
                expect(find.text('Fiş yazıcıya gönderildi.'), findsOneWidget);
                expect(tester.takeException(), isNull);
                Navigator.of(tester.element(find.text('Fiş Önizleme').first))
                    .pop();
                await tester.pumpAndSettle();
                await tester.runAsync(() async {
                  showFaturaKalemForm(
                      tester.element(find.byType(FaturaTaramaPage)),
                      kalem: FaturahareketDto.fromJson(
                          {...warehouse.line, 'Kdvorani': 20}),
                      kdvDahil: false,
                      dovizId: 1,
                      kur: 1,
                      stoklar: [StokListDto.fromJson(warehouse.product)]);
                  for (var frame = 0; frame < 8; frame++) {
                    await tester.pump();
                    await Future<void>.delayed(
                        const Duration(milliseconds: 250));
                  }
                });
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                await previews.captureReport(tester, capture,
                    'audit_${design.name}_invoice_line_${brightness.name}');
                tester.view.viewInsets = const FakeViewPadding(bottom: 260);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                tester.view.resetViewInsets();
              }
              expect(
                  requests.where((r) =>
                      r.method != 'GET' &&
                      !(r.method == 'POST' && r.url.path.contains('/VW_'))),
                  isEmpty);
              await tester.pump(const Duration(seconds: 2));
              await tester.runAsync(() async {
                await Future<void>.delayed(const Duration(milliseconds: 800));
              });
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pumpAndSettle();
            },
                () => MockClient((r) async {
                      requests.add(r);
                      Object data;
                      if (r.url.path.contains('/Stok/WithoutAuth/') ||
                          r.url.path.contains('/Stok/StokFull/')) {
                        data = {
                          ...warehouse.product,
                          'Temelolcubrid': 1,
                          'Temelolcubr': {'Id': 1, 'Kod': 'AD', 'Ad': 'Adet'},
                          'Stokolcubr': []
                        };
                      } else if (r.url.path.contains('VW_Stokbakiyesubedepo')) {
                        data = [
                          {'Stokid': 1, 'Bakiye': 150, 'Olcubr': 'Adet'}
                        ];
                      } else if (r.url.path.contains('Full/')) {
                        final line = {
                          ...warehouse.line,
                          'Kdvorani': 20,
                          'Netbirimfiyat': 100,
                          'Indirimtutar': 0,
                          'Kdvharictutar': 200,
                          'Kdvtoplam': 40
                        };
                        data = {
                          ...warehouse.documents[0],
                          'Cari': {
                            'Id': 1,
                            'Kod': 'CR.001',
                            'Ad': 'Marmara Gıda'
                          },
                          'Doviz': {'Id': 1, 'Birim': 'TL'},
                          'Matrah': 200,
                          'Kdvtoplam': 40,
                          'Geneltoplam': 240,
                          'Faturahareket': [line],
                          'Irsaliyehareket': [line],
                          'Siparishareket': [line],
                          'Ambargchareket': [line]
                        };
                      } else if (r.url.path.contains('FilterStokbakiye')) {
                        data = [
                          {
                            'Stokid': 1,
                            'Kod': 'ST.001',
                            'Ad': 'Organik Zeytinyağı',
                            'Olcubr': 'Adet',
                            'ToplamGirismiktar': 10,
                            'ToplamCikismiktar': 2,
                            'ToplamBakiyemiktar': 8
                          }
                        ];
                      } else {
                        data = warehouse.fixture(r.url.path);
                      }
                      return http.Response(jsonEncode({'Data': data}), 200,
                          headers: {
                            'content-type': 'application/json; charset=utf-8'
                          });
                    }));
          } finally {
            FlutterError.onError = previous;
          }
        });
      }
    }
  }
}
