import 'package:FilERP/theme/theme_controller.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/services/cache/list_cache_service.dart';
import 'package:FilERP/models/entities/cari/cari_dto_lite.dart';
import 'package:FilERP/models/entities/stok/stok_list_dto.dart';
import 'package:FilERP/models/entities/helper/doviz_dto.dart';
import 'package:FilERP/pages/rapor/rapor_merkezi_page.dart';
import 'package:FilERP/pages/rapor/rapor_tanimlari.dart';
import 'package:FilERP/pages/rapor/ortak/rapor_sayfasi.dart';
import 'package:FilERP/pages/rapor/ortak/rapor_modelleri.dart';
import 'package:FilERP/pages/rapor/stok/stokhareket_raporu.dart';
import 'package:FilERP/pages/rapor/cari/carihareket_raporu.dart';

final customers = [
  {'Id': 1, 'Kod': 'CR.001', 'Ad': 'Marmara Gıda Ltd. Şti.'},
  {'Id': 2, 'Kod': 'CR.002', 'Ad': 'Kuzey Market'},
];
final products = [
  {'Id': 1, 'Kod': 'ST.001', 'Ad': 'Organik Zeytinyağı 1 L'},
  {'Id': 2, 'Kod': 'ST.002', 'Ad': 'Filtre Kahve 250 g'},
];
final stockMovements = [
  {
    'Id': 1,
    'Stokid': 1,
    'Kod': 'ST.001',
    'Ad': 'Organik Zeytinyağı 1 L',
    'Tarih': '2026-10-29',
    'Belgeno': 'AG2026000000001',
    'Belge': 'Ambar Girişi',
    'Gckod': 'G',
    'Girismiktar': 10.0,
    'Cikismiktar': 0.0,
    'Giristutar': 2000.0,
    'Cikistutar': 0.0,
    'Fiyat': 200.0,
    'Olcubr': 'Adet'
  },
  {
    'Id': 2,
    'Stokid': 1,
    'Kod': 'ST.001',
    'Ad': 'Organik Zeytinyağı 1 L',
    'Tarih': '2026-10-29',
    'Belgeno': 'AC2026000000001',
    'Belge': 'Ambar Çıkışı',
    'Gckod': 'Ç',
    'Girismiktar': 0.0,
    'Cikismiktar': 2.0,
    'Giristutar': 0.0,
    'Cikistutar': 500.0,
    'Fiyat': 250.0,
    'Olcubr': 'Adet'
  },
];
final customerMovements = [
  {
    'Id': 'row-1',
    'cariid': 1,
    'carikod': 'CR.001',
    'cariisim': 'Marmara Gıda Ltd. Şti.',
    'Tarih': '2026-10-29',
    'vadetarih': '2026-11-29',
    'Belgeno': 'SF2026000000001',
    'Aciklama': 'Satış faturası',
    'Borctutar': 2000.0,
    'Alacaktutar': 0.0,
    'Borcbakiye': 2000.0,
    'Alacakbakiye': 0.0,
    'Dovizbirim': 'USD',
    'Kur': 20.0,
    'Dovizborctutar': 100.0,
    'Dovizalacaktutar': 0.0,
    'Dovizborcbakiye': 100.0,
    'Dovizalacakbakiye': 0.0
  },
  {
    'Id': 'row-2',
    'cariid': 2,
    'carikod': 'CR.002',
    'cariisim': 'Kuzey Market',
    'Tarih': '2026-10-29',
    'Belgeno': 'TH2026000000001',
    'Aciklama': 'Tahsilat',
    'Borctutar': 0.0,
    'Alacaktutar': 500.0,
    'Borcbakiye': 0.0,
    'Alacakbakiye': 500.0,
    'Dovizbirim': 'TL'
  },
];
final balances = [
  {
    'Cariid': 1,
    'Carikod': 'CR.001',
    'Cariisim': 'Marmara Gıda Ltd. Şti.',
    'Borc': 2000.0,
    'Alacak': 500.0,
    'Borcdoviz': 100.0,
    'Alacakdoviz': 25.0
  },
  {
    'Cariid': 2,
    'Carikod': 'CR.002',
    'Cariisim': 'Kuzey Market',
    'Borc': 0.0,
    'Alacak': 500.0,
    'Borcdoviz': 0.0,
    'Alacakdoviz': 25.0
  },
];
final stockBalances = [
  {
    'Stokid': 1,
    'Kod': 'ST.001',
    'Ad': 'Organik Zeytinyağı 1 L',
    'Depoid': 1,
    'Depokodu': 'D01',
    'Depoadi': 'Merkez Depo',
    'Bakiye': 150.0,
    'Olcubr': 'Adet'
  },
  {
    'Stokid': 2,
    'Kod': 'ST.002',
    'Ad': 'Filtre Kahve 250 g',
    'Depoid': 1,
    'Depokodu': 'D01',
    'Depoadi': 'Merkez Depo',
    'Bakiye': 30.0,
    'Olcubr': 'Adet'
  },
  {
    'Stokid': 3,
    'Kod': 'ST.003',
    'Ad': 'Sıfır Bakiye',
    'Depoid': 1,
    'Depokodu': 'D01',
    'Depoadi': 'Merkez Depo',
    'Bakiye': 0.0,
    'Olcubr': 'Adet'
  },
];
DovizDto usd() =>
    DovizDto.fromJson({'Id': 2, 'Ad': 'Amerikan Doları', 'Birim': 'USD'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  setUpAll(() async {
    cache = await Directory.systemTemp.createTemp('filerp_report_center_');
    Hive.init(cache.path);
    await ListCacheService.instance.init();
    for (final e in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  tearDownAll(() async {
    await Hive.close();
    await cache.delete(recursive: true);
  });
  final screens = <String, Widget Function()>{
    'center': () => const RaporMerkeziPage(),
    'stock_movement': () => const StokHareketRaporu(),
    'stock_movement_selected': () => StokHareketRaporu(
        baslangicStok:
            StokListDto(Id: 1, Kod: 'ST.001', Ad: 'Organik Zeytinyağı 1 L')),
    'customer_movement': () => const CariHareketRaporu(),
    'customer_movement_selected': () => CariHareketRaporu(
        baslangicCari:
            CariDtoLite(Id: 1, Kod: 'CR.001', Ad: 'Marmara Gıda Ltd. Şti.')),
    'stock_balance': () => RaporSayfasi(tanim: stokBakiyeTanim),
    'customer_balance_period': () => RaporSayfasi(tanim: cariBorcAlacakTanim),
    'customer_balance_current': () => RaporSayfasi(
        tanim: cariBorcAlacakTanim,
        baslangicFiltre: RaporFiltre()..anahtar = true),
    'customer_balance_usd': () => RaporSayfasi(
        tanim: cariBorcAlacakTanim,
        baslangicFiltre: RaporFiltre()
          ..doviz = usd()
          ..anahtar = true),
    'customer_balance_usd_period': () => RaporSayfasi(
        tanim: cariBorcAlacakTanim,
        baslangicFiltre: RaporFiltre()
          ..doviz = usd()
          ..tarih1 = DateTime(2026, 10, 1)
          ..tarih2 = DateTime(2026, 10, 29)
          ..anahtar = true),
  };
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final screen in screens.entries) {
        testWidgets('${screen.key} ${design.name}_${brightness.name}',
            (tester) async {
          SharedPreferences.setMockInitialValues(
              {'token_final': 'preview', 'sube_id': 1});
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          final shadows = debugDisableShadows;
          debugDisableShadows = false;
          final oldError = FlutterError.onError;
          FlutterError.onError = (d) {
            if (d.exceptionAsString().contains('overflowed'))
              debugPrint(d.toString());
            oldError?.call(d);
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
                        routes: {
                          '/': (_) => const Scaffold(),
                          '/screen': (_) => screen.value()
                        })));
                await Future<void>.delayed(const Duration(milliseconds: 1600));
              });
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              if (screen.key == 'stock_movement' ||
                  screen.key == 'customer_movement') {
                await tester.tap(find.text('Sorgula').last);
                await tester.pumpAndSettle();
              }
              expect(tester.takeException(), isNull);
              await captureReport(tester, capture,
                  '${screen.key}_${design.name}_${brightness.name}');
              if (screen.key == 'center') {
                expect(find.text('Rapor Merkezi'), findsOneWidget);
                expect(find.text('Cari hareketleri, borç / alacak / bakiye'),
                    findsNothing);
                await tester.enterText(find.byType(TextField), 'stok');
                await tester.pumpAndSettle();
                expect(find.text('Stok Hareket'), findsOneWidget);
                expect(find.text('Stok Bakiye'), findsOneWidget);
                await tester.enterText(find.byType(TextField), '12');
                await tester.pumpAndSettle();
                expect(find.text('Stok Bakiye'), findsOneWidget);
                await tester.enterText(find.byType(TextField), 'bulunmayan');
                await tester.pumpAndSettle();
                expect(find.text('Eşleşen rapor bulunamadı'), findsOneWidget);
              } else {
                await tester.tap(find.byTooltip('Dışa Aktar'));
                await tester.pumpAndSettle();
                expect(find.text("Excel'e Aktar"), findsOneWidget);
                expect(find.text("PDF'e Aktar"), findsOneWidget);
                Navigator.of(tester.element(find.text("Excel'e Aktar"))).pop();
                await tester.pumpAndSettle();
                if (screen.key.contains('movement')) {
                  final stock = screen.key.startsWith('stock');
                  await tester.tap(find.text(stock ? 'Giriş' : 'Borç').first);
                  await tester.pumpAndSettle();
                  expect(
                      find.text(stock ? 'AC2026000000001' : 'TH2026000000001'),
                      findsNothing);
                  await tester.tap(find.byTooltip('Filtreyi Temizle'));
                  await tester.pumpAndSettle();
                  expect(
                      find.text(stock ? 'AC2026000000001' : 'TH2026000000001'),
                      findsOneWidget);
                } else {
                  await tester.enterText(find.byType(TextField).first,
                      screen.key == 'stock_balance' ? 'Kahve' : 'Kuzey');
                  await tester.pumpAndSettle();
                  expect(
                      find.textContaining('Organik Zeytinyağı'), findsNothing);
                  await tester.enterText(find.byType(TextField).first, '');
                  tester.testTextInput.hide();
                  FocusManager.instance.primaryFocus?.unfocus();
                }
                await tester.tap(find.byTooltip('Filtreler').first);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                await captureReport(tester, capture,
                    '${screen.key}_filters_${design.name}_${brightness.name}');
                tester.view.physicalSize = const Size(320, 740);
                tester.view.viewInsets = const FakeViewPadding(bottom: 300);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                tester.view.resetViewInsets();
                Navigator.of(tester.element(find.text('Filtreler').last)).pop();
                await tester.pumpAndSettle();
              }
              tester.view.physicalSize = const Size(320, 740);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(
                  requests.where((r) =>
                      r.method != 'GET' &&
                      !(r.method == 'POST' &&
                          r.url.path.startsWith('/api/VW_'))),
                  isEmpty,
                  reason: 'Reports must not write business records');
              await tester.pump(const Duration(seconds: 2));
              await tester.runAsync(() async {
                await Future<void>.delayed(const Duration(milliseconds: 800));
              });
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pumpAndSettle();
            },
                () => MockClient((request) async {
                      requests.add(request);
                      return http.Response(
                          jsonEncode({'Data': fixture(request.url.path)}), 200,
                          headers: {
                            'content-type': 'application/json; charset=utf-8'
                          });
                    }));
          } finally {
            debugDisableShadows = shadows;
            FlutterError.onError = oldError;
          }
        });
      }
    }
  }
}

Object fixture(String path) {
  if (path.contains('/VW_Stokhareket/Filter')) return stockMovements;
  if (path.contains('/VW_Carihareket/Filter')) return customerMovements;
  if (path.contains('/VW_Stokbakiyesubedepo/Query')) return stockBalances;
  if (path.contains('/VW_Cariborcalacak')) return balances;
  if (path.endsWith('/Cari')) return customers;
  if (path.contains('/Stok/AllWithoutAuth')) return products;
  if (path.contains('/Proje'))
    return [
      {'Id': 1, 'Kod': 'P01', 'Ad': 'Genel', 'Tur': 3}
    ];
  if (path.contains('/Depo'))
    return [
      {'Id': 1, 'Kod': 'D01', 'Ad': 'Merkez Depo'}
    ];
  if (path.contains('/Doviz'))
    return [
      {'Id': 1, 'Ad': 'Türk Lirası', 'Birim': 'TL'},
      {'Id': 2, 'Ad': 'Amerikan Doları', 'Birim': 'USD'}
    ];
  return [];
}

Future<void> captureReport(
    WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final target = File('tool/previews/reports_$name.png');
    await target.parent.create(recursive: true);
    await target.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
