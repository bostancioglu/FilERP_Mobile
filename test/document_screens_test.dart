import 'list_filter_helpers.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'package:FilERP/services/cache/list_cache_service.dart';
import 'package:FilERP/pages/cari/cari_list_page.dart';
import 'package:FilERP/pages/stok/stok_list_page.dart';
import 'package:FilERP/pages/fatura/Satisfaturasi/satisfatura_list.dart';
import 'package:FilERP/pages/fatura/Alisfaturasi/alisfatura_list.dart';
import 'package:FilERP/pages/irsaliye/irsaliye_list_page.dart';
import 'package:FilERP/pages/irsaliye/Alis/alisirsaliye_list.dart';
import 'package:FilERP/pages/fatura/Satisfaturasi/fatura_ekle_page.dart';
import 'package:FilERP/pages/fatura/Alisfaturasi/alisfatura_ekle_page.dart';
import 'package:FilERP/pages/irsaliye/irsaliye_ekle_page.dart';
import 'package:FilERP/pages/irsaliye/Alis/alisirsaliye_ekle_page.dart';

final _customers = [
  {
    'Id': 1,
    'Kod': 'CR.0001',
    'Ad': 'Marmara Gıda ve Ticaret Ltd. Şti.',
    'Vergino': '1234567890',
    'Vergidairesi': 'Kadıköy',
    'Vadegunu': 30
  },
  {
    'Id': 2,
    'Kod': 'CR.0002',
    'Ad': 'Kuzey Market',
    'Vergino': '9876543210',
    'Vadegunu': 15
  },
];
final _products = [
  {
    'Id': 1,
    'Kod': 'ST.0001',
    'Ad': 'Organik Zeytinyağı 1 L',
    'Barkodlar': '869000000001',
    'TemelolcubrKod': 'ADET'
  },
  {
    'Id': 2,
    'Kod': 'ST.0002',
    'Ad': 'Filtre Kahve 250 g',
    'Barkodlar': '869000000002',
    'TemelolcubrKod': 'PAKET'
  },
];
final _documents = [
  {
    'Id': 'document-1',
    'Belgeserino': 'SF2026000000001',
    'Tarih': '2026-10-28',
    'Belgedurum': 1,
    'Geneltoplam': 24580.75,
    'Dovizid': 1,
    'Cari': _customers[0],
    'EFaturadurum': 3,
    'Eirsaliyedurum': 3,
    'Aciklama': 'Ekim ayı ürün teslimatı'
  },
  {
    'Id': 'document-2',
    'Belgeserino': 'SF2026000000002',
    'Tarih': '2026-10-27',
    'Belgedurum': 0,
    'Geneltoplam': 8700.0,
    'Dovizid': 1,
    'Cari': _customers[1]
  },
  {
    'Id': 'document-3',
    'Belgeserino': 'SF2026000000003',
    'Tarih': '2026-10-26',
    'Belgedurum': 1,
    'Geneltoplam': 1260.50,
    'Dovizid': 1,
    'Cari': {'Id': 3, 'Kod': 'CR.0003', 'Ad': 'Ege Şarküteri'},
    'EFaturadurum': 3
  },
  {
    'Id': 'document-4',
    'Belgeserino': 'SF2026000000004',
    'Tarih': '2026-10-25',
    'Belgedurum': 0,
    'Geneltoplam': 3940.0,
    'Dovizid': 1,
    'Cari': {'Id': 4, 'Kod': 'CR.0004', 'Ad': 'Ada Toptan Gıda'}
  },
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  setUpAll(() async {
    cache = await Directory.systemTemp.createTemp('filerp_ui_test_');
    Hive.init(cache.path);
    await ListCacheService.instance.init();
    for (final entry in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });
  tearDownAll(() async {
    await Hive.close();
    await cache.delete(recursive: true);
  });
  final screens = <String, Widget Function()>{
    'cari_list': () => const CariListPage(),
    'stok_list': () => const StokListPage(),
    'satis_fatura_list': () => const SatisFaturaListPage(),
    'alis_fatura_list': () => const AlisFaturaList(),
    'satis_irsaliye_list': () => const IrsaliyeListPage(),
    'alis_irsaliye_list': () => const AlisIrsaliyeList(),
    'satis_fatura_entry': () => const FaturaEklePage(),
    'alis_fatura_entry': () => const AlisFaturaEklePage(),
    'satis_irsaliye_entry': () => const IrsaliyeEklePage(),
    'alis_irsaliye_entry': () => const AlisIrsaliyeEklePage(),
  };
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final entry in screens.entries) {
        testWidgets(
            '${design.name}_${entry.key} ${brightness.name}: layout and interactions',
            (tester) async {
          final previousShadows = debugDisableShadows;
          debugDisableShadows = false;
          addTearDown(() => debugDisableShadows = previousShadows);
          final previousErrorHandler = FlutterError.onError;
          FlutterError.onError = (details) {
            if (details.exceptionAsString().contains('overflowed'))
              debugPrint(details.toString());
            previousErrorHandler?.call(details);
          };
          addTearDown(() => FlutterError.onError = previousErrorHandler);
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
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
                        '/screen': (_) => entry.value()
                      },
                    )));
                await Future<void>.delayed(const Duration(milliseconds: 200));
              });
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(find.byType(CircularProgressIndicator), findsNothing);
              await _capture(tester, capture,
                  '${design.name}_${entry.key}_${brightness.name}');
              if (entry.key.endsWith('irsaliye_entry')) {
                final phase = find.byWidgetPredicate((widget) =>
                    widget is DropdownButton<int> &&
                    widget.items!.any((item) =>
                        item.child is Text &&
                        (item.child as Text).data == 'Kara Yolu (3)'));
                expect(phase, findsOneWidget);
                await tester.ensureVisible(phase);
                await tester.tap(phase);
                await tester.pumpAndSettle();
                await tester.tap(find.text('Kara Yolu (3)').last);
                await tester.pumpAndSettle();
                expect(tester.widget<DropdownButton<int>>(phase).value, 3);
                await _capture(tester, capture,
                    '${design.name}_${entry.key}_tasima_${brightness.name}');
              }
              if (design == ErpDesign.modern &&
                  entry.key.endsWith('fatura_entry')) {
                await tester.tap(find.text('Cari Seç').first);
                await tester.pumpAndSettle();
                await tester.tap(find.textContaining('Marmara Gıda').last);
                await tester.pumpAndSettle();
                expect(find.text('Marmara Gıda ve Ticaret Ltd. Şti.'),
                    findsOneWidget);
                await _capture(tester, capture,
                    '${design.name}_${entry.key}_${brightness.name}');
              }
              if (design == ErpDesign.modern &&
                  (entry.key.endsWith('fatura_list') ||
                      entry.key.endsWith('irsaliye_list'))) {
                await applyListFilters(tester,
                    electronic: 3, electronicVisible: true);
                expect(find.textContaining('Kuzey Market'), findsNothing);
                expect(find.textContaining('Marmara Gıda'), findsWidgets);
                await applyListFilters(tester,
                    electronic: -2, electronicVisible: true);
                expect(find.textContaining('Marmara Gıda'), findsNothing);
                expect(find.textContaining('Kuzey Market'), findsWidgets);
                await _capture(tester, capture,
                    '${design.name}_${entry.key}_erp_${brightness.name}');
                await applyListFilters(tester,
                    electronic: null, electronicVisible: true);
              }
              if (entry.key.endsWith('fatura_list')) {
                await tester.tap(find.byTooltip('Belge İşlemleri').first);
                await tester.pumpAndSettle();
                expect(find.text('Taslağa Çek'), findsOneWidget);
                await _capture(tester, capture,
                    '${design.name}_${entry.key}_menu_${brightness.name}');
                await tester.tap(find.text('Taslağa Çek'));
                await tester.pumpAndSettle();
                expect(find.textContaining('taslak durumuna alınacak'),
                    findsOneWidget);
                await tester.tap(find.text('Vazgeç'));
                await tester.pumpAndSettle();
                expect(writes, 0);
              }
              if (entry.key.endsWith('_list')) {
                final field = find.byType(TextField).first;
                await tester.enterText(
                    field, entry.key == 'stok_list' ? '869000000002' : 'Kuzey');
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                expect(
                    find.textContaining(entry.key == 'stok_list'
                        ? 'Filtre Kahve'
                        : 'Kuzey Market'),
                    findsWidgets);
                expect(
                    find.textContaining(entry.key == 'stok_list'
                        ? 'Organik Zeytinyağı'
                        : 'Marmara Gıda'),
                    findsNothing);
                await tester.enterText(field, 'bulunmayan_kayıt');
                await tester.pumpAndSettle();
                expect(
                    find.textContaining(entry.key == 'stok_list'
                        ? 'Filtre Kahve'
                        : 'Kuzey Market'),
                    findsNothing);
                await tester.enterText(field, '');
                tester.testTextInput.hide();
                FocusManager.instance.primaryFocus?.unfocus();
                await tester.pumpAndSettle();
                if (entry.key.contains('fatura') ||
                    entry.key.contains('irsaliye')) {
                  await applyListFilters(tester, status: 0);
                  await tester.pumpAndSettle();
                  expect(find.textContaining('Marmara Gıda'), findsNothing);
                  expect(find.textContaining('Kuzey Market'), findsWidgets);
                }
              } else {
                // Visit all existing tabs, including the extra delivery carrier form.
                for (final label in [
                  'Kalemler',
                  'Özet',
                  if (entry.key.endsWith('irsaliye_entry')) 'Taşıyıcı',
                  'Üst Bilgiler'
                ]) {
                  await tester.tap(find.text(label).first);
                  await tester.pumpAndSettle();
                  expect(tester.takeException(), isNull, reason: '$label tab');
                  if (label == 'Üst Bilgiler')
                    _expectDateSurfaces(tester, brightness, design);
                  if (label == 'Özet')
                    await _capture(tester, capture,
                        '${design.name}_${entry.key}_summary_${brightness.name}');
                }
                tester.view.viewInsets = const FakeViewPadding(bottom: 300);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                tester.view.resetViewInsets();
              }
              tester.view.physicalSize = const Size(320, 740);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              if (entry.key.endsWith('_entry')) {
                await tester.tap(find.text('Özet').first);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
              }
              expect(writes, 0,
                  reason:
                      'Preview interactions must not save or change documents');
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pumpAndSettle();
            },
                () => MockClient((request) async {
                      if (request.method != 'GET') writes++;
                      final p = request.url.path;
                      Object data = [];
                      if (p.endsWith('/Cari')) data = _customers;
                      if (p.contains('/Cari/CariFull/'))
                        data = _customers.first;
                      if (p.contains('/Stok/AllWithoutAuth')) data = _products;
                      if (p.endsWith('/Fatura') ||
                          p.endsWith('/FaturaAlis') ||
                          p.endsWith('/Irsaliye') ||
                          p.endsWith('/IrsaliyeAlis')) data = _documents;
                      if (p.endsWith('/Doviz'))
                        data = [
                          {'Id': 1, 'Ad': 'Türk Lirası', 'Birim': 'TRY'}
                        ];
                      if (p.contains('GetNew')) data = '000000001';
                      return http.Response(jsonEncode({'Data': data}), 200,
                          headers: {
                            'content-type': 'application/json; charset=utf-8'
                          });
                    }));
          } finally {
            debugDisableShadows = previousShadows;
          }
        });
      }
    }
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final target = File('tool/previews/$name.png');
    await target.parent.create(recursive: true);
    await target.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void _expectDateSurfaces(
    WidgetTester tester, Brightness brightness, ErpDesign design) {
  final icons = find.byIcon(Icons.calendar_today_outlined);
  expect(icons, findsWidgets,
      reason: 'Document headers must expose date fields');
  for (final element in icons.evaluate()) {
    final decoration = tester
        .widget<Container>(find
            .ancestor(
              of: find.byElementPredicate(
                  (candidate) => identical(candidate, element)),
              matching: find.byWidgetPredicate((widget) =>
                  widget is Container &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration as BoxDecoration).color != null),
            )
            .first)
        .decoration as BoxDecoration;
    final scheme = Theme.of(element).colorScheme;
    final expected = brightness == Brightness.dark || design == ErpDesign.modern
        ? scheme.surfaceContainerLow
        : Colors.white;
    expect(decoration.color, expected,
        reason: 'Date fields must follow the current theme');
  }
}
