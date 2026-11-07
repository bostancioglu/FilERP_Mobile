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
import 'package:FilERP/pages/teklif/teklif_list_page.dart';
import 'package:FilERP/pages/teklif/teklif_entry_page.dart';

final customers = [
  {'Id': 1, 'Kod': 'CR.001', 'Ad': 'Marmara Gıda Ltd. Şti.'},
  {'Id': 2, 'Kod': 'CR.002', 'Ad': 'Kuzey Market'}
];
final product = {
  'Id': 1,
  'Kod': 'ST.001',
  'Ad': 'Organik Zeytinyağı 1 L',
  'Kdvorani': 20.0,
  'Olcubrid': 1
};
final line = {
  'Id': 1,
  'Stokid': 1,
  'Stok': product,
  'Olcubrid': 1,
  'Olcubr': {'Id': 1, 'Kod': 'AD', 'Ad': 'Adet'},
  'Miktar': 2.0,
  'Fiyat': 100.0,
  'Kdvorani': 20.0,
  'Bruttutar': 200.0,
  'Kdvtutar': 40.0,
  'Tutar': 240.0,
  'Songeneltoplam': 240.0,
  'Depoid': 1,
  'Projeid': 1
};
final orders = List.generate(
    2,
    (i) => {
          'Id': 'quote-${i + 1}',
          'Cariid': i + 1,
          'Cari': customers[i],
          'Belgeserino': 'TKL202600000000${i + 1}',
          'Belgeseri': 'TKL',
          'Belgeyil': 2026,
          'Belgeno': '00000000${i + 1}',
          'Tarih': '2026-10-29',
          'Fiilitarih': '2026-10-29',
          'Belgedurum': i,
          'Dovizid': 1,
          'Kur': 1.0,
          'Oncelik': i + 1,
          'Kdvdahil': false,
          'Geneltoplam': 240.0,
          'Teklifhareket': [line]
        });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  setUpAll(() async {
    cache = await Directory.systemTemp.createTemp('filerp_quote_');
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
    'sales_list': () => const TeklifListPage(sales: true),
    'purchase_list': () => const TeklifListPage(sales: false),
    'sales_create': () => const TeklifEntryPage(sales: true),
    'purchase_create': () => const TeklifEntryPage(sales: false),
    'sales_edit': () => const TeklifEntryPage(sales: true, quoteId: 'quote-1'),
    'purchase_edit': () =>
        const TeklifEntryPage(sales: false, quoteId: 'quote-1'),
    'sales_view': () => const TeklifEntryPage(sales: true, quoteId: 'quote-2'),
    'purchase_view': () =>
        const TeklifEntryPage(sales: false, quoteId: 'quote-2'),
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
                expect(find.byType(ErpDocumentCard), findsNWidgets(2));
                await tester.tap(find.byTooltip('Belge İşlemleri').first);
                await tester.pumpAndSettle();
                expect(find.text('Düzenle'), findsOneWidget);
                await tester.tap(find.text('Sil'));
                await tester.pumpAndSettle();
                expect(find.text('Teklifi Sil'), findsOneWidget);
                await tester.tap(find.text('Vazgeç'));
                await tester.pumpAndSettle();
                await tester.enterText(find.byType(TextField).first, 'Kuzey');
                await tester.pumpAndSettle();
                expect(find.byType(ErpDocumentCard), findsOneWidget);
                await tester.enterText(find.byType(TextField).first, '');
                tester.testTextInput.hide();
                FocusManager.instance.primaryFocus?.unfocus();
                await applyListFilters(tester, status: 0);
                await tester.pumpAndSettle();
                expect(find.byType(ErpDocumentCard), findsOneWidget);
                expect(find.text('Marmara Gıda Ltd. Şti.'), findsOneWidget);
              } else {
                for (final tab in ['Kalemler', 'Özet', 'Belge']) {
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
                  expect(find.text('Kalem Detayı'), findsOneWidget);
                  await captureReport(tester, capture,
                      '${screen.key}_line_${design.name}_${brightness.name}');
                  await tester.ensureVisible(find.text('İskonto'));
                  await tester.tap(find.text('İskonto'));
                  await tester.pumpAndSettle();
                  expect(find.text('İskontolar (Satır)'), findsOneWidget);
                  await captureReport(tester, capture,
                      '${screen.key}_discount_${design.name}_${brightness.name}');
                  tester.view.physicalSize = const Size(320, 740);
                  tester.view.viewInsets = const FakeViewPadding(bottom: 300);
                  await tester.pumpAndSettle();
                  expect(tester.takeException(), isNull);
                  tester.view.resetViewInsets();
                  Navigator.of(tester.element(find.text('İskontolar (Satır)')))
                      .pop();
                  await tester.pumpAndSettle();

                  tester.view.physicalSize = const Size(320, 740);
                  await tester.pumpAndSettle();
                  expect(tester.takeException(), isNull);
                  await tester.tap(find.byTooltip('Kapat'));
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
              if (screen.key.endsWith('_view'))
                expect(find.text('Kaydet'), findsNothing);
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
    final file = File('tool/previews/quote_$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Object fixture(String path) {
  if (path.endsWith('/Teklif') || path.endsWith('/TeklifAlis')) return orders;
  if (path.contains('/TeklifFull/'))
    return orders[path.endsWith('quote-2') ? 1 : 0];
  if (path.contains('GetNew')) return '000000001';
  if (path.contains('/Belgeseri/'))
    return [
      {'Id': 1, 'Seri': 'TKL'}
    ];
  if (path.contains('/Cari/Cariadres/')) return [];
  if (path.endsWith('/Cari')) return customers;
  if (path.contains('/Stok/AllWithoutAuth')) return [product];
  if (RegExp(r'/Stok/(Full/)?1$').hasMatch(path)) return product;
  if (path.contains('/Proje'))
    return [
      {'Id': 1, 'Kod': 'P01', 'Ad': 'Genel', 'Tur': 3}
    ];
  if (path.contains('/Plasiyer'))
    return [
      {'Id': 1, 'Kod': 'PL.01', 'Adsoyad': 'Örnek Temsilci'}
    ];
  if (path.contains('/Depo/'))
    return [
      {'Id': 1, 'Kod': 'D01', 'Ad': 'Merkez Depo'}
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
