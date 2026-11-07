import 'package:FilERP/widgets/erp_page_style.dart';
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
import 'package:FilERP/pages/finans/kasa/kasa_islem_list_page.dart';
import 'package:FilERP/pages/finans/kasa/kasa_tanim_list_page.dart';
import 'package:FilERP/pages/finans/kasa/kasa_tanim_ekle_page.dart';
import 'package:FilERP/pages/finans/kasa/kasahareket_liste_page.dart';
import 'package:FilERP/pages/finans/kasa/kasahareket_ekle_page.dart';
import 'package:FilERP/pages/finans/banka/banka_islem_list_page.dart';
import 'package:FilERP/pages/finans/banka/banka_tanim_list_page.dart';
import 'package:FilERP/pages/finans/banka/banka_tanim_ekle_page.dart';
import 'package:FilERP/pages/finans/banka/bankahareket_liste_page.dart';
import 'package:FilERP/pages/finans/banka/bankahareket_ekle_page.dart';
import 'package:FilERP/pages/finans/tahsilat/tahsilat_liste_page.dart';
import 'package:FilERP/pages/finans/tahsilat/tahsilat_ekle_page.dart';
import 'package:FilERP/models/entities/finans/kasa_islem/kasa_dto.dart';
import 'package:FilERP/models/entities/finans/kasa_islem/kasahareket_dto.dart';
import 'package:FilERP/models/entities/finans/banka/bankahesap_dto.dart';
import 'package:FilERP/models/entities/finans/banka/bankahareket_dto.dart';
import 'package:FilERP/models/entities/finans/tahsilat/tahsilat_dto.dart';

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
const source = TahsilatKaynakBelge(
    belgeId: 'invoice-1',
    belgeturu: 1,
    toplamTutar: 24580.75,
    cariid: 1,
    dovizid: 1,
    projeid: 1,
    plasiyerid: 1,
    belgeserino: 'SF2026000000001');

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
    'cash_accounts': () => const KasaIslemListPage(),
    'bank_accounts': () => const BankaIslemListPage(),
    'cash_definitions': () => const KasaTanimListPage(),
    'bank_definitions': () => const BankaTanimListPage(),
    'cash_movements': () => const KasahareketListePage(
        kasaId: 1, kasaAdi: 'Merkez Kasa', kasaKodu: 'KS.001'),
    'bank_movements': () =>
        BankahareketListePage(bankahesap: BankahesapDto.fromJson(banks[0])),
    'collections': () => const TahsilatListePage(),
    'cash_create': () => const KasaTanimEklePage(),
    'bank_create': () => const BankaTanimEklePage(),
    'cash_movement_create': () => const KasahareketEklePage(),
    'bank_movement_create': () =>
        BankahareketEklePage(bankahesap: BankahesapDto.fromJson(banks[0])),
    'collection_create': () => const TahsilatEklePage(),
    'cash_edit': () => KasaTanimEklePage(editKasa: KasaDto.fromJson(cash[1])),
    'bank_edit': () =>
        BankaTanimEklePage(editBanka: BankahesapDto.fromJson(banks[1])),
    'cash_movement_edit': () =>
        KasahareketEklePage(editHareket: KasahareketDto.fromJson(movements[1])),
    'bank_movement_edit': () => BankahareketEklePage(
        bankahesap: BankahesapDto.fromJson(banks[1]),
        editHareket: BankahareketDto.fromJson(movements[1])),
    'collection_edit': () =>
        TahsilatEklePage(editTahsilat: TahsilatDto.fromJson(collections[1])),
    'invoice_collections': () => const TahsilatListePage(kaynakBelge: source),
    'invoice_collection_create': () =>
        const TahsilatEklePage(kaynakBelge: source),
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
              final isForm = screen.key.endsWith('_create') ||
                  screen.key.endsWith('_edit');
              if (!isForm) {
                if (screen.key.endsWith('_accounts')) {
                  expect(find.textContaining('12.500,00 ₺'), findsWidgets);
                  expect(find.textContaining('USD'), findsWidgets);
                }
                final menu = find.byTooltip('İşlemler');
                if (menu.evaluate().isNotEmpty) {
                  await tester.tap(menu.first);
                  await tester.pumpAndSettle();
                  await tester.tap(find.text('Sil').last);
                  await tester.pumpAndSettle();
                  expect(find.text('Vazgeç'), findsOneWidget);
                  await tester.tap(find.text('Vazgeç'));
                  await tester.pumpAndSettle();
                }
                if (find.byType(TextField).evaluate().isNotEmpty) {
                  final field = find.byType(TextField).first;
                  final query = screen.key.startsWith('cash_')
                      ? 'Döviz'
                      : screen.key.startsWith('bank_')
                          ? 'USD'
                          : 'Kuzey';
                  await tester.enterText(field, query);
                  await tester.pumpAndSettle();
                  expect(tester.takeException(), isNull);
                  await tester.enterText(field, 'bulunmayan_kayıt');
                  await tester.pumpAndSettle();
                  expect(find.textContaining('sonuç'), findsWidgets);
                  await tester.enterText(field, '');
                  tester.testTextInput.hide();
                  FocusManager.instance.primaryFocus?.unfocus();
                  await tester.pumpAndSettle();
                }
              } else {
                // Existing cash/collection step validation still controls navigation.
                if ((find.byType(TabBar).evaluate().isNotEmpty ||
                    find.byType(ErpAdaptiveTabs).evaluate().isNotEmpty)) {
                  for (final label in [
                    'İşlem',
                    if (screen.key.endsWith('_edit')) 'Detay',
                    'Belge'
                  ]) {
                    await tester.tap(find.text(label).first);
                    await tester.pumpAndSettle();
                    expect(tester.takeException(), isNull);
                    if (label == 'İşlem')
                      await captureScreen(tester, capture,
                          '${screen.key}_transaction_${design.name}_${brightness.name}');
                  }
                }
                tester.view.viewInsets = const FakeViewPadding(bottom: 300);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                tester.view.resetViewInsets();
              }
              tester.view.physicalSize = const Size(320, 740);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              if (isForm &&
                  (find.byType(TabBar).evaluate().isNotEmpty ||
                      find.byType(ErpAdaptiveTabs).evaluate().isNotEmpty)) {
                await tester.tap(find.text('İşlem').first);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
              }
              expect(writes, 0,
                  reason:
                      'Preview must not create, update or delete financial records');
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pumpAndSettle();
            },
                () => MockClient((request) async {
                      final p = request.url.path;
                      if (request.method != 'GET' &&
                          p != '/api/VW_Carihareket/Filter') writes++;
                      Object data = [];
                      if (p.contains('/Kasa') && !p.contains('/Kasahareket'))
                        data = cash;
                      if (p.contains('/Bankahesap')) data = banks;
                      if (p.contains('/VW_Finanskasatoplam'))
                        data = [
                          {
                            'Id': 1,
                            'Kasaid': 1,
                            'Kasakod': 'KS.001',
                            'Kasaisim': 'Merkez Kasa',
                            'Bakiyetutar': 12500.0,
                            'Dovizbirim': 'TL'
                          },
                          {
                            'Id': 2,
                            'Kasaid': 2,
                            'Kasakod': 'KS.002',
                            'Kasaisim': 'Döviz Kasası',
                            'Bakiyetutar': -1690.0,
                            'Dovizbakiyetutar': -50.0,
                            'Dovizbirim': 'USD'
                          }
                        ];
                      if (p.contains('/VW_Finansbankatoplam'))
                        data = [
                          {'Id': 1, 'Bankahesapid': 1, 'Bakiyetutar': 12500.0},
                          {
                            'Id': 2,
                            'Bankahesapid': 2,
                            'Bakiyetutar': -1690.0,
                            'Dovizbakiyetutar': -50.0
                          }
                        ];
                      if (p.contains('/Kasahareket/GetBy') ||
                          p.contains('/Bankahareket/GetBy')) data = movements;
                      if (p.contains('/Tahsilat') && !p.contains('GetNew'))
                        data = collections;
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
    final target = File('tool/previews/finance_$name.png');
    await target.parent.create(recursive: true);
    await target.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}
