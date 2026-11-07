import 'list_filter_helpers.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:FilERP/services/cache/list_cache_service.dart';
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
import 'package:FilERP/widgets/erp_ui.dart';
import 'package:FilERP/pages/depo/ambargc/ambargc_list.dart';
import 'package:FilERP/pages/depo/ambargc/ambargc_ekle_page.dart';
import 'package:FilERP/pages/depo/dat/dat_list_page.dart';
import 'package:FilERP/pages/depo/dat/dat_ekle_page.dart';
import 'package:FilERP/widgets/erp_transfer_card.dart';
import 'package:FilERP/services/offline/offline_service.dart';

final product = {
  'Id': 1,
  'Kod': 'ST.001',
  'Ad': 'Organik Zeytinyağı 1 L',
  'Olcubrid': 1
};
final warehouses = [
  {
    'Id': 1,
    'Kod': 'D01',
    'Ad': 'Merkez Depo',
    'Subeid': 1,
    'Dinamikdepo': true
  },
  {'Id': 2, 'Kod': 'D02', 'Ad': 'Sevkiyat Deposu', 'Subeid': 2},
];
final branches = [
  {'Id': 1, 'Kod': 'MRK', 'Ad': 'Merkez Şube'},
  {'Id': 2, 'Kod': 'KRS', 'Ad': 'Kars Şubesi'}
];
final line = {
  'Id': 'line-1',
  'Stokid': 1,
  'Stok': product,
  'Olcubrid': 1,
  'Olcubr': {'Id': 1, 'Kod': 'AD', 'Ad': 'Adet'},
  'Miktar': 2.0,
  'Fiyat': 100.0,
  'Tutar': 200.0,
  'Depoid': 1,
  'Projeid': 1,
  'Cikacagidepoid': 1,
  'Gidecegidepoid': 2,
  'Cikacagidepo': warehouses[0],
  'Gidecegidepo': warehouses[1]
};
final documents = List.generate(
    2,
    (i) => {
          'Id': 'doc-${i + 1}',
          'Subeid': 1,
          'Sube': branches[0],
          'Gidecegisubeid': 2,
          'Gidecegisube': branches[1],
          'Belgeserino': 'DPO202600000000${i + 1}',
          'Belgeseri': 'DPO',
          'Belgeyil': 2026,
          'Belgeno': '00000000${i + 1}',
          'Tarih': '2026-10-29',
          'Teslimtarihi': '2026-10-30',
          'Belgedurum': i,
          'Dovizid': 1,
          'Kur': 1.0,
          'Giriscikis': i + 1,
          'Islemyeri': 3,
          'Masrafid': 1,
          'Projeid': 1,
          'Plasiyerid': 1,
          'Geneltoplam': 200.0,
          'Dathareket': [line],
          'Ambargchareket': [line],
        });
final queued = OfflineQueueItem(
    localId: 'preview-transfer',
    type: 'dat_full',
    createdAt: DateTime(2026, 10, 29),
    payload: {
      'dat': {
        'subeid': 1,
        'gidecegisubeid': 2,
        'belgeseri': 'DPO',
        'belgeyil': 2026,
        'belgeno': '000000003',
        'tarih': '2026-10-29',
        'teslimtarihi': '2026-10-30',
        'projeid': 1,
        'plasiyerid': 1
      },
      'kalemler': [
        {
          'stokid': 1,
          'olcubrid': 1,
          'projeid': 1,
          'cikacagidepoid': 1,
          'gidecegidepoid': 2,
          'miktar': 3.0
        }
      ],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  setUpAll(() async {
    cache = await Directory.systemTemp.createTemp('filerp_quote_');
    Hive.init(cache.path);
    await ListCacheService.instance.init();
    SharedPreferences.setMockInitialValues({'offline_mode': false});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (call) async => call.method == 'check' ? ['wifi'] : null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        (_) async => null);
    final box = await Hive.openBox<String>('offline_queue');
    await box.put(queued.localId, jsonEncode(queued.toJson()));
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
    'warehouse_list': () => const AmbargcList(),
    'transfer_list': () => const DatListPage(),
    'vehicle_list': () => const DatListPage(aracYukleme: true),
    'warehouse_create': () => const AmbargcEklePage(),
    'transfer_create': () => const DatEklePage(),
    'warehouse_edit': () => const AmbargcEklePage(ambargcId: 'doc-1'),
    'transfer_edit': () => const DatEklePage(datId: 'doc-1'),
    'transfer_offline_edit': () => DatEklePage(queueItem: queued),
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
                      initialRoute: '/report',
                      routes: {
                        '/': (_) => const Scaffold(),
                        '/report': (_) => screen.value()
                      },
                    )));
                await Future<void>.delayed(const Duration(milliseconds: 200));
              });
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(find.text('Yeniden Dene'), findsNothing);
              await captureReport(tester, capture,
                  '${screen.key}_${design.name}_${brightness.name}');
              final isList = screen.key.endsWith('_list');
              if (isList) {
                if (screen.key == 'warehouse_list') {
                  expect(find.byType(ErpDocumentCard), findsNWidgets(2));
                  await tester.tap(find.byTooltip('Belge işlemleri').first);
                  await tester.pumpAndSettle();
                  expect(find.text('Düzenle'), findsOneWidget);
                  Navigator.of(tester.element(find.text('Düzenle'))).pop();
                  await tester.pumpAndSettle();
                } else {
                  expect(find.byType(ErpTransferCard), findsNWidgets(3));
                  expect(find.text('Gönderim Bekliyor'), findsOneWidget);
                  await tester.tap(find.byTooltip('Transfer işlemleri').first);
                  await tester.pumpAndSettle();
                  expect(find.text('Şimdi Gönder'), findsOneWidget);
                  Navigator.of(tester.element(find.text('Şimdi Gönder'))).pop();
                  await tester.pumpAndSettle();
                }
                await tester.enterText(
                    find.byType(TextField).first, '000000001');
                await tester.pumpAndSettle();
                await tester.enterText(find.byType(TextField).first, '');
                tester.testTextInput.hide();
                FocusManager.instance.primaryFocus?.unfocus();
                await applyListFilters(tester, status: 0);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
              } else {
                for (final tab in [
                  'Kalemler',
                  if (screen.key.startsWith('warehouse')) 'Özet',
                  'Belge'
                ]) {
                  await tester.tap(find.text(tab).first);
                  await tester.pumpAndSettle();
                  expect(tester.takeException(), isNull);
                  await captureReport(
                      tester,
                      capture,
                      '${screen.key}_${tab == 'Özet' ? 'summary' : tab == 'Kalemler' ? 'items' : 'header'}_${design.name}_${brightness.name}');
                }
                if (screen.key.endsWith('_edit')) {
                  await tester.tap(find.text('Kalemler').first);
                  await tester.pumpAndSettle();
                  expect(find.byType(ErpFinanceCard), findsOneWidget);
                  await tester.tap(find.byType(ErpFinanceCard).first);
                  await tester.runAsync(() async {
                    await Future<void>.delayed(
                        const Duration(milliseconds: 150));
                  });
                  await tester.pumpAndSettle();
                  expect(tester.takeException(), isNull);
                  await captureReport(tester, capture,
                      '${screen.key}_line_${design.name}_${brightness.name}');
                  tester.view.physicalSize = const Size(320, 740);
                  tester.view.viewInsets = const FakeViewPadding(bottom: 300);
                  await tester.pumpAndSettle();
                  expect(tester.takeException(), isNull);
                  tester.view.resetViewInsets();
                  await tester.tap(find.byTooltip('Kapat').last);
                  await tester.pumpAndSettle();
                }
                tester.view.viewInsets = const FakeViewPadding(bottom: 300);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                tester.view.resetViewInsets();
              }
              tester.view.physicalSize = const Size(320, 740);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(writes, 0);
              await tester.pump(const Duration(seconds: 5));
              await tester.pumpAndSettle();
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pumpAndSettle();
            },
                () => MockClient((request) async {
                      if (request.method != 'GET') writes++;
                      return http.Response(
                          jsonEncode({'Data': fixture(request.url.path)}), 200,
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
    final file = File('tool/previews/warehouse_$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Object fixture(String path) {
  if (path.endsWith('/Ambargc') || path.endsWith('/Dat')) return documents;
  if (path.contains('/AmbargcFull/') || path.contains('/DatFull/'))
    return documents[0];
  if (path.contains('GetNew')) return '000000001';
  if (path.contains('/Belgeseri/'))
    return [
      {'Id': 1, 'Seri': 'DPO'}
    ];
  if (path.contains('/Sube')) return branches;
  if (path.contains('/Depoadres/'))
    return [
      {
        'Id': 'address-1',
        'Depoid': 1,
        'Kod': 'A01',
        'Ad': 'Raf A',
        'Bolum': 'Sevkiyat'
      }
    ];
  if (path.contains('/Depo/')) return warehouses;
  if (path.contains('/Stok/AllWithoutAuth')) return [product];
  if (RegExp(r'/Stok/(Full/)?1$').hasMatch(path))
    return {
      ...product,
      'Temelolcubr': {'Id': 1, 'Kod': 'AD', 'Ad': 'Adet'}
    };
  if (path.contains('/Proje'))
    return [
      {'Id': 1, 'Kod': 'P01', 'Ad': 'Genel', 'Tur': 3}
    ];
  if (path.contains('/Plasiyer'))
    return [
      {'Id': 1, 'Kod': 'PL01', 'Adsoyad': 'Örnek Temsilci'}
    ];
  if (path.contains('/Masraf'))
    return [
      {'Id': 1, 'Kod': 'M01', 'Ad': 'Merkez Masraf'}
    ];
  if (path.contains('/Doviz'))
    return [
      {'Id': 1, 'Ad': 'Türk Lirası', 'Birim': 'TL'}
    ];
  if (path.contains('/Olcubr'))
    return [
      {'Id': 1, 'Kod': 'AD', 'Ad': 'Adet'}
    ];
  return [];
}
