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
import 'package:FilERP/pages/finans/cek/cekalinanciro_ekle_page.dart';
import 'package:FilERP/pages/finans/cek/cekalinanciro_liste_page.dart';
import 'package:FilERP/pages/finans/cek/cekalinaniade_ekle_page.dart';
import 'package:FilERP/pages/finans/cek/cekalinaniade_liste_page.dart';
import 'package:FilERP/pages/finans/cek/cekalinanportfoydentahsil_ekle_page.dart';
import 'package:FilERP/pages/finans/cek/cekalinanportfoydentahsil_liste_page.dart';
import 'package:FilERP/pages/finans/cek/cekalinanprotesto_ekle_page.dart';
import 'package:FilERP/pages/finans/cek/cekalinanprotesto_liste_page.dart';
import 'package:FilERP/pages/finans/cek/cekalinantahsil_ekle_page.dart';
import 'package:FilERP/pages/finans/cek/cekalinantahsil_liste_page.dart';
import 'package:FilERP/pages/finans/cek/cekalinan_ekle_page.dart';
import 'package:FilERP/pages/finans/cek/cekalinan_liste_page.dart';
import 'package:FilERP/pages/finans/senet/senetalinanciro_ekle_page.dart';
import 'package:FilERP/pages/finans/senet/senetalinanciro_liste_page.dart';
import 'package:FilERP/pages/finans/senet/senetalinaniade_ekle_page.dart';
import 'package:FilERP/pages/finans/senet/senetalinaniade_liste_page.dart';
import 'package:FilERP/pages/finans/senet/senetalinanportfoydentahsil_ekle_page.dart';
import 'package:FilERP/pages/finans/senet/senetalinanportfoydentahsil_liste_page.dart';
import 'package:FilERP/pages/finans/senet/senetalinanprotesto_ekle_page.dart';
import 'package:FilERP/pages/finans/senet/senetalinanprotesto_liste_page.dart';
import 'package:FilERP/pages/finans/senet/senetalinantahsil_ekle_page.dart';
import 'package:FilERP/pages/finans/senet/senetalinantahsil_liste_page.dart';
import 'package:FilERP/pages/finans/senet/senetalinan_ekle_page.dart';
import 'package:FilERP/pages/finans/senet/senetalinan_liste_page.dart';
import 'package:FilERP/pages/finans/borc/cekverileniade_ekle_page.dart';
import 'package:FilERP/pages/finans/borc/cekverileniade_liste_page.dart';
import 'package:FilERP/pages/finans/borc/cekverilenodeme_ekle_page.dart';
import 'package:FilERP/pages/finans/borc/cekverilenodeme_liste_page.dart';
import 'package:FilERP/pages/finans/borc/cekverilen_ekle_page.dart';
import 'package:FilERP/pages/finans/borc/cekverilen_liste_page.dart';
import 'package:FilERP/pages/finans/borc/senetverileniade_ekle_page.dart';
import 'package:FilERP/pages/finans/borc/senetverileniade_liste_page.dart';
import 'package:FilERP/pages/finans/borc/senetverilenodeme_ekle_page.dart';
import 'package:FilERP/pages/finans/borc/senetverilenodeme_liste_page.dart';
import 'package:FilERP/pages/finans/borc/senetverilen_ekle_page.dart';
import 'package:FilERP/pages/finans/borc/senetverilen_liste_page.dart';

final currencies = [
  {'Id': 1, 'Ad': 'Türk Lirası', 'Birim': 'TL'},
  {'Id': 2, 'Ad': 'Amerikan Doları', 'Birim': 'USD'}
];
final cash = [
  {'Id': 1, 'Kod': 'KS.001', 'Ad': 'Merkez Kasa', 'Dovizid': 1},
  {'Id': 2, 'Kod': 'KS.002', 'Ad': 'Döviz Kasası', 'Dovizid': 2}
];
final banks = [
  {
    'Id': 1,
    'Kod': 'BN.001',
    'Ad': 'Ticari TL Hesabı',
    'Dovizid': 1,
    'Doviz': currencies[0],
    'Banka': {'Id': 1, 'Ad': 'Örnek Banka'},
    'Hesaptipi': 1
  },
  {
    'Id': 2,
    'Kod': 'BN.002',
    'Ad': 'İhracat USD Hesabı',
    'Dovizid': 2,
    'Doviz': currencies[1],
    'Banka': {'Id': 1, 'Ad': 'Örnek Banka'},
    'Hesaptipi': 1
  }
];
final customers = [
  {'Id': 1, 'Kod': 'CR.001', 'Ad': 'Marmara Gıda Ltd. Şti.'},
  {'Id': 2, 'Kod': 'CR.002', 'Ad': 'Kuzey Market'}
];
final movements = [
  {
    'Id': 'move-1',
    'Kasaid': 1,
    'Bankahesapid': 1,
    'Dovizid': 1,
    'Tarih': '2026-10-28',
    'Giriscikis': 1,
    'Islemtipi': 1,
    'Islemcariid': 1,
    'Tutar': 12500.0,
    'Doviztutar': 0.0,
    'Belgeserino': 'KS2026000000001',
    'Belgeseri': 'KS',
    'Belgeno': '000000001',
    'Belgeyil': 2026,
    'Islemcari': customers[0],
    'Doviz': currencies[0],
    'Kasa': cash[0],
    'Projeid': 1,
    'Plasiyerid': 1
  },
  {
    'Id': 'move-2',
    'Kasaid': 1,
    'Bankahesapid': 1,
    'Dovizid': 2,
    'Tarih': '2026-10-27',
    'Giriscikis': 2,
    'Islemtipi': 1,
    'Islemcariid': 2,
    'Tutar': 1690.0,
    'Doviztutar': 50.0,
    'Kur': 33.8,
    'Belgeserino': 'KS2026000000002',
    'Belgeseri': 'KS',
    'Belgeno': '000000002',
    'Belgeyil': 2026,
    'Islemcari': customers[1],
    'Doviz': currencies[1],
    'Kasa': cash[0],
    'Projeid': 1,
    'Plasiyerid': 1
  },
];
final collections = [
  {
    'Id': 'collection-1',
    'Cariid': 1,
    'Cari': customers[0],
    'Kasaid': 1,
    'Kasa': cash[0],
    'Dovizid': 1,
    'Doviz': currencies[0],
    'Tarih': '2026-10-28',
    'Tip': 1,
    'Tahsilattutari': 12500.0,
    'Belgeserino': 'TH2026000000001',
    'Belgeseri': 'TH',
    'Belgeno': '000000001',
    'Belgeyil': 2026,
    'Plasiyerid': 1,
    'Projeid': 1
  },
  {
    'Id': 'collection-2',
    'Cariid': 2,
    'Cari': customers[1],
    'Bankahesapid': 2,
    'Bankahesap': banks[1],
    'Dovizid': 2,
    'Doviz': currencies[1],
    'Tarih': '2026-10-27',
    'Tip': 2,
    'Tahsilattutari': 3380.0,
    'Doviztutar': 100.0,
    'Kur': 33.8,
    'Belgeserino': 'TH2026000000002',
    'Belgeseri': 'TH',
    'Belgeno': '000000002',
    'Belgeyil': 2026,
    'Plasiyerid': 1,
    'Projeid': 1
  },
];
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  setUpAll(() async {
    cache = await Directory.systemTemp.createTemp('filerp_finance_');
    Hive.init(cache.path);
    await ListCacheService.instance.init();
    for (final e in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries)
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
  });
  tearDownAll(() async {
    await Hive.close();
    await cache.delete(recursive: true);
  });
  final screens = <String, Widget Function()>{
    'cekalinanciro_ekle_page': () => const CekalinanciroEklePage(),
    'cekalinanciro_liste_page': () => const CekalinanciroListePage(),
    'cekalinaniade_ekle_page': () => const CekalinaniadeEklePage(),
    'cekalinaniade_liste_page': () => const CekalinaniadeListePage(),
    'cekalinanportfoydentahsil_ekle_page': () =>
        const CekalinanportfoydentahsilEklePage(),
    'cekalinanportfoydentahsil_liste_page': () =>
        const CekalinanportfoydentahsilListePage(),
    'cekalinanprotesto_ekle_page': () => const CekalinanprotestoEklePage(),
    'cekalinanprotesto_liste_page': () => const CekalinanprotestoListePage(),
    'cekalinantahsil_ekle_page': () => const CekalinantahsilEklePage(),
    'cekalinantahsil_liste_page': () => const CekalinantahsilListePage(),
    'cekalinan_ekle_page': () => const CekalinanEklePage(),
    'cekalinan_liste_page': () => const CekalinanListePage(),
    'senetalinanciro_ekle_page': () => const SenetalinanciroEklePage(),
    'senetalinanciro_liste_page': () => const SenetalinanciroListePage(),
    'senetalinaniade_ekle_page': () => const SenetalinaniadeEklePage(),
    'senetalinaniade_liste_page': () => const SenetalinaniadeListePage(),
    'senetalinanportfoydentahsil_ekle_page': () =>
        const SenetalinanportfoydentahsilEklePage(),
    'senetalinanportfoydentahsil_liste_page': () =>
        const SenetalinanportfoydentahsilListePage(),
    'senetalinanprotesto_ekle_page': () => const SenetalinanprotestoEklePage(),
    'senetalinanprotesto_liste_page': () =>
        const SenetalinanprotestoListePage(),
    'senetalinantahsil_ekle_page': () => const SenetalinantahsilEklePage(),
    'senetalinantahsil_liste_page': () => const SenetalinantahsilListePage(),
    'senetalinan_ekle_page': () => const SenetalinanEklePage(),
    'senetalinan_liste_page': () => const SenetalinanListePage(),
    'cekverileniade_ekle_page': () => const CekverileniadeEklePage(),
    'cekverileniade_liste_page': () => const CekverileniadeListePage(),
    'cekverilenodeme_ekle_page': () => const CekverilenodemeEklePage(),
    'cekverilenodeme_liste_page': () => const CekverilenodemeListePage(),
    'cekverilen_ekle_page': () => const CekverilenEklePage(),
    'cekverilen_liste_page': () => const CekverilenListePage(),
    'senetverileniade_ekle_page': () => const SenetverileniadeEklePage(),
    'senetverileniade_liste_page': () => const SenetverileniadeListePage(),
    'senetverilenodeme_ekle_page': () => const SenetverilenodemeEklePage(),
    'senetverilenodeme_liste_page': () => const SenetverilenodemeListePage(),
    'senetverilen_ekle_page': () => const SenetverilenEklePage(),
    'senetverilen_liste_page': () => const SenetverilenListePage(),
  };
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final screen in screens.entries) {
        testWidgets('${screen.key} ${design.name}_${brightness.name}',
            (tester) async {
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          final previousShadows = debugDisableShadows;
          debugDisableShadows = false;
          final oldError = FlutterError.onError;
          FlutterError.onError = (d) {
            if (d.exceptionAsString().contains('overflowed'))
              debugPrint(d.toString());
            oldError?.call(d);
          };
          final capture = GlobalKey();
          var writes = 0;
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
                await Future<void>.delayed(const Duration(milliseconds: 200));
              });
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(find.byType(CircularProgressIndicator), findsNothing);
              await captureScreen(tester, capture,
                  '${screen.key}_${design.name}_${brightness.name}');
              final isForm = screen.key.endsWith('_ekle_page');
              if (!isForm) {
                expect(find.textContaining('24.580,75'), findsWidgets);
                await tester.tap(find.byTooltip('İşlemler').first);
                await tester.pumpAndSettle();
                await tester.tap(find.text('Sil').last);
                await tester.pumpAndSettle();
                await tester.tap(find.text('Vazgeç'));
                await tester.pumpAndSettle();
                await tester.enterText(
                    find.byType(TextField).first, 'bulunmayan');
                await tester.pumpAndSettle();
                expect(find.textContaining('0 sonuç'), findsOneWidget);
                await tester.enterText(find.byType(TextField).first, '');
                tester.testTextInput.hide();
                FocusManager.instance.primaryFocus?.unfocus();
              }
              final coreForm = RegExp(
                      r'^(cekalinan|senetalinan|cekverilen|senetverilen)_ekle_page$')
                  .hasMatch(screen.key);
              if (coreForm) {
                // Required customer still blocks advancing before a selection.
                await tester.tap(find.text('Sonraki').first);
                await tester.pumpAndSettle();
                expect(find.text('Lütfen cari seçiniz.'), findsOneWidget);
                await tester.pump(const Duration(seconds: 4));
                await tester.pumpAndSettle();
                await tester.tap(find
                    .ancestor(
                        of: find.text('Cari seçiniz').first,
                        matching: find.byWidgetPredicate((w) => w.runtimeType
                            .toString()
                            .startsWith('DropdownSearch<')))
                    .first);
                await tester.pumpAndSettle();
                await tester.tap(find.textContaining('Marmara Gıda').last);
                await tester.runAsync(() async {
                  await Future<void>.delayed(const Duration(milliseconds: 100));
                });
                await tester.pumpAndSettle();
                await tester.tap(find.text('Sonraki').first);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                await captureScreen(tester, capture,
                    '${screen.key}_transaction_${design.name}_${brightness.name}');
                await tester.tap(find.text('Sonraki').first);
                await tester.pumpAndSettle();
                expect(find.text('Tutar *'), findsWidgets);
                await tester.enterText(
                    find.byWidgetPredicate((w) =>
                        w is TextField && w.decoration?.hintText == 'Tutar'),
                    '24580,75');
                tester.testTextInput.hide();
                FocusManager.instance.primaryFocus?.unfocus();
                await tester.tap(find.text('Sonraki').first);
                await tester.pumpAndSettle();
                expect(find.text('Açıklama'), findsWidgets);
                await captureScreen(tester, capture,
                    '${screen.key}_detail_${design.name}_${brightness.name}');
                await tester.tap(find
                    .text(screen.key.startsWith('cek')
                        ? 'Çek Ekle'
                        : 'Senet Ekle')
                    .first);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                await tester.pump(const Duration(seconds: 4));
                await tester.pumpAndSettle();
                await captureScreen(tester, capture,
                    '${screen.key}_items_${design.name}_${brightness.name}');
              }
              tester.view.physicalSize = const Size(320, 740);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              if (isForm) {
                tester.view.viewInsets = const FakeViewPadding(bottom: 300);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                tester.view.resetViewInsets();
              }
              expect(writes, 0,
                  reason:
                      'Preview must not create, update or delete financial records');
              await tester.pump(const Duration(seconds: 5));
              await tester.pumpAndSettle();
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pumpAndSettle();
            },
                () => MockClient((request) async {
                      final p = request.url.path;
                      if (request.method != 'GET' &&
                          p != '/api/VW_Carihareket/Filter') writes++;
                      Object data = [];
                      if (p.contains('/Bankahesap')) data = banks;
                      final route = p.split('/').last;
                      if (RegExp(r'^(Cek|Senet)(alinan|verilen)')
                          .hasMatch(route)) {
                        final core = route.startsWith('Cek')
                            ? (route.startsWith('Cekalinan')
                                ? 'Cekalinan'
                                : 'Cekverilen')
                            : (route.startsWith('Senetalinan')
                                ? 'Senetalinan'
                                : 'Senetverilen');
                        data = List.generate(
                            2,
                            (i) => {
                                  'Id': 'bordro-$i',
                                  'Cariid': i + 1,
                                  'Cari': customers[i],
                                  'Bankahesapid': 1,
                                  'Bankahesap': banks[0],
                                  'Belgeserino': 'CB202600000000${i + 1}',
                                  'Tarih': '2026-10-29',
                                  'Belgedurum': i,
                                  'Ciroturu': 1,
                                  '${route}hareket': [
                                    if (route == core)
                                      {
                                        'Id': 'item-$i',
                                        'Tutar': 24580.75,
                                        'Dovizid': 1,
                                        'Doviz': currencies[0],
                                        'Vadetarihi': '2026-11-29'
                                      }
                                    else
                                      {
                                        'Id': 'item-$i',
                                        '${core}hareket': {
                                          'Id': 'original-$i',
                                          'Tutar': 24580.75,
                                          'Dovizid': 1,
                                          'Doviz': currencies[0],
                                          'Vadetarihi': '2026-11-29'
                                        }
                                      }
                                  ]
                                });
                      }
                      if (p.endsWith('/Doviz')) data = currencies;
                      if (p.endsWith('/Cari')) data = customers;
                      if (p.contains('/Proje'))
                        data = [
                          {'Id': 1, 'Kod': 'P01', 'Ad': 'Genel', 'Tur': 3}
                        ];
                      if (p.contains('/Plasiyer'))
                        data = [
                          {
                            'Id': 1,
                            'Kod': 'PL.001',
                            'Adsoyad': 'Örnek Temsilci'
                          }
                        ];
                      if (p.contains('/Belgeseri'))
                        data = [
                          {'Id': 1, 'Seri': 'FN', 'Ebelgetip': 0}
                        ];
                      if (p.contains('/Kur/'))
                        data = {'Dovizsatis': 33.8, 'Dovizalis': 33.8};
                      if (p.contains('GetNew')) data = '000000001';
                      return http.Response(jsonEncode({'Data': data}), 200,
                          headers: {
                            'content-type': 'application/json; charset=utf-8'
                          });
                    }));
          } finally {
            debugDisableShadows = previousShadows;
            FlutterError.onError = oldError;
          }
        });
      }
    }
  }
}

Future<void> captureScreen(
    WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final target = File('tool/previews/negotiable_$name.png');
    await target.parent.create(recursive: true);
    await target.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}
