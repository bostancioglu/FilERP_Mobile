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
import 'package:FilERP/pages/irsaliye/irsaliye_ekle_page.dart';
import 'package:FilERP/pages/irsaliye/Alis/alisirsaliye_ekle_page.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'package:FilERP/services/cache/list_cache_service.dart';

const documentId = '11111111-1111-1111-1111-111111111111';
const customer = {'Id': 1, 'Ad': 'Test Müşterisi', 'Kod': 'CR.001'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  setUpAll(() async {
    cache = await Directory.systemTemp.createTemp('filerp_waybill_fields_');
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
  for (final sales in [true, false]) {
    testWidgets(
        '${sales ? 'sales' : 'purchase'} waybill: edit, discount, notes, carrier and exact payload',
        (tester) async {
      SharedPreferences.setMockInitialValues(
          {'token_final': 'fixture', 'sube_id': 1});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final writes = <http.Request>[];
      final capture = GlobalKey();
      await http.runWithClient(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(RepaintBoundary(
              key: capture,
              child: MaterialApp(
                  theme:
                      AppTheme.build(Brightness.dark, design: ErpDesign.modern),
                  initialRoute: '/edit',
                  routes: {
                    '/': (_) => const Scaffold(body: Text('Liste')),
                    '/edit': (_) => sales
                        ? const IrsaliyeEklePage(irsaliyeId: documentId)
                        : const AlisIrsaliyeEklePage(irsaliyeId: documentId),
                  })));
          await Future<void>.delayed(const Duration(milliseconds: 150));
        });
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kalemler'));
        await tester.pumpAndSettle();
        expect(find.text('Parti Takibi'), findsOneWidget);
        await tester.runAsync(() async {
          await tester.tap(find.text('Parti Takibi'));
          await Future<void>.delayed(const Duration(milliseconds: 80));
        });
        await tester.pumpAndSettle();
        expect(find.text('Parti Seç'), findsOneWidget);
        await _capture(tester, capture,
            '${sales ? 'sales' : 'purchase'}_waybill_tracking_fields');
        await tester.tap(find.byTooltip('Kapat'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Üst Bilgiler'));
        await tester.pumpAndSettle();
        expect(find.text('Ek Açıklamalar (2)'), findsOneWidget);
        await tester.ensureVisible(find.text('Ek Açıklamalar (2)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ek Açıklamalar (2)'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byWidgetPredicate((w) =>
                w is TextField && w.decoration?.labelText == 'Açıklama 1'),
            'Mobil not');
        await tester.tap(find.text('Uygula'));
        await tester.pumpAndSettle();
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Taşıyıcı'));
        await tester.pumpAndSettle();
        expect(find.textContaining('34 TEST 01'), findsWidgets);
        expect(find.text('Teslim A. Kantar Miktar'), findsOneWidget);
        await _capture(tester, capture,
            '${sales ? 'sales' : 'purchase'}_waybill_carrier_fields');
        await tester.tap(find.text('Özet'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(OutlinedButton, 'Genel İskonto'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byWidgetPredicate((w) =>
                w is TextField &&
                w.decoration?.labelText == 'İskonto Oranı (%)'),
            '20');
        await tester.tap(find.text('Uygula'));
        await tester.pumpAndSettle();
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pumpAndSettle();
        await _capture(tester, capture,
            '${sales ? 'sales' : 'purchase'}_waybill_discount_fields');
        await tester.tap(find.text('Kaydet').last);
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await tester.tap(find.text('Taslak Kaydet'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(writes.length, 1);
        final request = writes.single;
        expect(request.method, 'PUT');
        expect(request.url.path,
            '/api/${sales ? 'Irsaliye' : 'IrsaliyeAlis'}/UpdateSingle');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['aciklama1'], 'Mobil not');
        expect(payload['aciklama20'], 'Web not 20');
        expect(payload['geneliskontooran'], 20);
        expect(payload['geneliskontotutar'], 200);
        expect(payload['dovizgeneliskontotutar'], 200);
        expect(payload['geneltoplam'], 960);
        expect(payload['aracid'], 7);
        expect(payload['surucuid'], 8);
        expect(payload['lojistikcariid'], 1);
        expect(payload['kapadet'], 12);
        expect(payload['tedarikcikantarmiktar'], 100);
        expect(payload['teslimalinankantarmiktar'], 99);
        expect(payload.containsKey('kayittarihi'), isFalse);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
          () => MockClient((request) async {
                final path = request.url.path;
                if (request.method != 'GET') {
                  writes.add(request);
                  return http.Response('', 204);
                }
                Object data = [];
                if (path.endsWith('/Cari')) data = [customer];
                if (path.contains('IrsaliyeFull'))
                  data = {
                    'Id': documentId,
                    'Cariid': 1,
                    'Cari': customer,
                    'Belgedurum': 0,
                    'Belgeseri': 'TEST',
                    'Belgeyil': 2026,
                    'Belgeno': '1',
                    'Kdvdahil': false,
                    'Tarih': '2026-11-06',
                    'Fiilitarih': '2026-11-06',
                    'Belgetipi': 1,
                    'Dovizid': 1,
                    'Kur': 1,
                    'Geneliskontooran': 10,
                    'Geneliskontotutar': 100,
                    'Aciklama1': 'Web not 1',
                    'Aciklama20': 'Web not 20',
                    'Aracid': 7,
                    'Surucuid': 8,
                    'Lojistikcariid': 1,
                    'Kapadet': 12,
                    'Tedarikcikantarmiktar': 100,
                    'Teslimalinankantarmiktar': 99,
                    'Irsaliyehareket': [
                      {
                        'Id': 21,
                        'Stokid': 1,
                        'Stok': {
                          'Id': 1,
                          'Ad': 'Ürün',
                          'Kod': 'ST.001',
                          'Partiseritakipmodu': 1
                        },
                        'Olcubrcarpim': 1,
                        'Miktar': 10,
                        'Fiyat': 100,
                        'Bruttutar': 1000,
                        'Kdvorani': 20,
                        'Kdvtutar': 200,
                        'Tutar': 1200,
                        'Olcubr2id': 7,
                        'IstisnaId': 9,
                        'Stokadiaciklama': 'Web ürün',
                        'Doviziskontotutari6': 3.5
                      }
                    ]
                  };
                if (path.endsWith('/Doviz'))
                  data = [
                    {'Id': 1, 'Ad': 'Türk Lirası', 'Birim': 'TRY'}
                  ];
                if (path.contains('/Arac/'))
                  data = [
                    {
                      'Id': 7,
                      'Plaka': '34 TEST 01',
                      'Tip': 'Kamyon',
                      'Lojistikcariid': 1
                    }
                  ];
                if (path.contains('/Surucu/'))
                  data = [
                    {'Id': 8, 'Adsoyad': 'Test Sürücüsü'}
                  ];
                if (path.contains('/Stoktakipdetay/SecimFilter')) {
                  data = {
                    'TakipModu': 1,
                    'Partiler': [
                      {'Id': 1, 'Kod': 'PARTI-01'}
                    ],
                    'Seriler': []
                  };
                }
                return http.Response(jsonEncode({'Data': data}), 200, headers: {
                  'content-type': 'application/json; charset=utf-8'
                });
              }));
    });
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('tool/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}
