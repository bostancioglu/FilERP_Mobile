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
import 'package:FilERP/models/entities/teklif/teklifhareket_dto.dart';
import 'package:FilERP/models/entities/teklif/teklif_codec.dart';
import 'package:FilERP/models/entities/siparis/siparishareket_dto.dart';
import 'package:FilERP/helpers/order_line_amounts.dart';
import 'package:FilERP/services/siparis/order_link_service.dart';
import 'package:FilERP/services/cache/list_cache_service.dart';
import 'package:FilERP/pages/teklif/teklif_entry_page.dart';
import 'package:FilERP/pages/siparis/Satis/satissiparis_ekle_page.dart';
import 'package:FilERP/pages/siparis/Alis/alissiparis_ekle_page.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'package:FilERP/widgets/siparis/siparis_kalem_form_sheet.dart';
import 'order_screens_test.dart' as orderData;
import 'quote_screens_test.dart' as quoteData;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  setUpAll(() async {
    cache = await Directory.systemTemp.createTemp('filerp_order_quote_fields_');
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

  test(
      'quote editor roundtrip preserves six currency discount tiers and explicit exemption clear',
      () {
    final input = TeklifhareketDto.fromJson({
      'Id': 12,
      'Stokid': 1,
      'IstisnaId': 9,
      'Olcubr2id': 7,
      'Stokadiaciklama': 'Özel ürün',
      for (var i = 1; i <= 6; i++) 'Iskontotutari$i': i * 10,
      for (var i = 1; i <= 6; i++) 'Doviziskontotutari$i': i * .25
    });
    final editor = teklifKalemToEditor(input)..istisnaId = null;
    final output = teklifKalemFromEditor(editor, original: input);
    final json = teklifKalemJson(output);
    expect(input.istisnaId, 9);
    expect(json['IstisnaId'], isNull);
    expect(json['Olcubr2id'], 7);
    expect(json['Stokadiaciklama'], 'Özel ürün');
    for (var i = 1; i <= 6; i++) {
      expect(json['Iskontotutari$i'], i * 10);
      expect(json['Doviziskontotutari$i'], i * .25);
    }
  });

  test(
      'order currency editor converts discounts and extra cost exactly once and keeps link metadata',
      () {
    final source = SiparishareketDto.fromJson({
      'Id': 12,
      'Siparisid': 'order-1',
      'Stokid': 1,
      'Olcubr2id': 7,
      'IstisnaId': 9,
      'Fiyat': 4000,
      'Dovizfiyat': 100,
      'Iskontotutar': 400,
      'Iskontotutari1': 400,
      'Doviziskontotutari1': 10,
      'Ekmaliyet': 200,
      'Dovizekmaliyet': 5,
      'Baglantikullan': true,
      'Baglantisiparishareketid': 99
    });
    final editor = OrderLineAmounts.editor(source, 40, true);
    expect(editor.fiyat, 100);
    expect(editor.iskontotutari1, 10);
    expect(editor.ekmaliyet, 5);
    editor.ekmaliyet = 6;
    OrderLineAmounts.fromEditor(editor, 40, true);
    expect(editor.ekmaliyet, 240);
    expect(editor.iskontotutar, 400);
    expect(editor.iskontotutari1, 400);
    expect(source.ekmaliyet, 200);
    expect(editor.baglantisiparishareketid, 99);
    expect(editor.istisnaId, 9);
    OrderLineAmounts.revalue(editor, 50, 40);
    expect(editor.ekmaliyet, 300);
    expect(editor.iskontotutari1, 500);
    expect(editor.iskontotutar, 500);
    final again = OrderLineAmounts.editor(editor, 50, true);
    expect(again.ekmaliyet, 6);
    expect(again.iskontotutari1, 10);
    OrderLineAmounts.toLocal(editor, 50);
    expect(editor.ekmaliyet, 6);
    expect(editor.iskontotutari1, 10);
    expect(editor.doviziskontotutari1, isNull);
  });

  testWidgets(
      'purchase line editor clears optional fields and selects an actual linked order without mutating its source',
      (tester) async {
    SharedPreferences.setMockInitialValues({'token_final': 'fixture'});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = SiparishareketDto.fromJson({
      ...orderData.line,
      'Id': 12,
      'IstisnaId': 9,
      'Olcubr2id': 7,
      'Stokadiaciklama': 'Web ürün'
    });
    SiparishareketDto? saved;
    final capture = GlobalKey();
    await http.runWithClient(() async {
      await tester.pumpWidget(RepaintBoundary(
          key: capture,
          child: MaterialApp(
              theme: AppTheme.build(Brightness.light, design: ErpDesign.modern),
              home: Scaffold(
                  body: Builder(
                      builder: (context) => FilledButton(
                          onPressed: () async {
                            saved = await showSiparisKalemForm(context,
                                kalem: source,
                                orderFields: true,
                                linkContext: const OrderLinkContext(
                                    customerId: 1,
                                    currencyId: 1,
                                    vatIncluded: false,
                                    rate: 1),
                                stoklar: [],
                                projeler: [],
                                depolar: [],
                                kdvDahil: false);
                          },
                          child: const Text('Aç')))))));
      await tester.runAsync(() async {
        await tester.tap(find.text('Aç'));
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Bağlantı Kullan'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Bağlantı Kullan'));
        await Future<void>.delayed(const Duration(milliseconds: 60));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('BS-001').last);
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Bağlantı ürünü ·').last);
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Vergi ve Ambalaj'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vergi ve Ambalaj'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('İstisna temizle'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('İstisna temizle'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ambalaj Ölçü Birimi temizle'));
      await tester.pumpAndSettle();
      final description = find.byWidgetPredicate((w) =>
          w is TextField && w.decoration?.labelText == 'Stok Adı Açıklama');
      await tester.ensureVisible(description);
      await tester.pumpAndSettle();
      await tester.enterText(description, 'Mobil ürün');
      final cost = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Ek Maliyet');
      await tester.ensureVisible(cost);
      await tester.pumpAndSettle();
      await tester.enterText(cost, '12,50');
      await tester.pumpAndSettle();
      await capturePreview(tester, capture, 'order_purchase_line_new_fields');
      final save = find.text('Güncelle');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(saved?.istisnaId, isNull);
      expect(saved?.olcubr2id, isNull);
      expect(saved?.ekmaliyet, 12.5);
      expect(saved?.stokadiaciklama, 'Mobil ürün');
      expect(saved?.baglantisiparishareketid, 11);
      expect(saved?.baglantikullan, isTrue);
      expect(saved?.fiyat, 125);
      expect(saved?.miktar, 3);
      expect(source.istisnaId, 9);
      expect(source.olcubr2id, 7);
      expect(source.baglantikullan, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
        () => MockClient((request) async {
              final path = request.url.path;
              if (path.contains('GetBaglantiSiparis'))
                return response([
                  {'Id': 'link-1', 'Belgeserino': 'BS-001'}
                ]);
              if (path.contains('SiparisFullAdjustedWithBaglanti'))
                return response({
                  'Siparishareket': [
                    {
                      'Id': 11,
                      'Stokid': 1,
                      'Miktar': 3,
                      'Fiyat': 125,
                      'Olcubrid': 1,
                      'Stok': {'Id': 1, 'Ad': 'Bağlantı ürünü'}
                    }
                  ]
                });
              if (RegExp(r'/Stok/1$').hasMatch(path))
                return response({
                  'Id': 1,
                  'Temelolcubr': {'Id': 1, 'Kod': 'AD', 'Ad': 'Adet'}
                });
              return response([]);
            }));
  });

  test(
      'purchase link queries match web contracts and only return matching available stock lines',
      () async {
    final requests = <http.Request>[];
    await http.runWithClient(() async {
      final service = OrderLinkService();
      final orders = await service.orders(
          'fixture',
          const OrderLinkContext(
              customerId: 1, currencyId: 2, vatIncluded: false, rate: 40));
      expect(orders.single.id, 'link-1');
      final lines = await service.lines('fixture', 'link-1', 1);
      expect(lines.single.id, '11');
    },
        () => MockClient((r) async {
              requests.add(r);
              return response(r.url.path.contains('GetBaglantiSiparis')
                  ? [
                      {'Id': 'link-1', 'Belgeserino': 'BS-001'}
                    ]
                  : {
                      'Siparishareket': [
                        {'Id': 11, 'Stokid': 1, 'Miktar': 2},
                        {'Id': 12, 'Stokid': 2, 'Miktar': 3},
                        {'Id': 13, 'Stokid': 1, 'Miktar': 0}
                      ]
                    });
            }));
    expect(
        requests[0].url.path, '/api/SiparisAlis/GetBaglantiSiparis/1/2/false');
    expect(requests[1].url.path,
        '/api/SiparisAlis/SiparisFullAdjustedWithBaglanti/link-1');
    expect(requests.every((r) => r.method == 'GET'), isTrue);
  });

  for (final quote in [false, true]) {
    for (final sales in [true, false]) {
      testWidgets(
          '${quote ? 'quote' : 'order'} ${sales ? 'sales' : 'purchase'} header fields survive edit and save',
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
                    theme: AppTheme.build(Brightness.dark,
                        design: ErpDesign.modern),
                    initialRoute: '/edit',
                    routes: {
                      '/': (_) => const Scaffold(body: Text('Liste')),
                      '/edit': (_) => quote
                          ? TeklifEntryPage(sales: sales, quoteId: 'quote-1')
                          : sales
                              ? const SatisSiparisEklePage(siparisId: 'order-1')
                              : const AlisSiparisEklePage(siparisId: 'order-1'),
                    })));
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Teslimat ve Diğer Bilgiler'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Teslimat ve Diğer Bilgiler'));
          await tester.pumpAndSettle();
          final reference = find.byWidgetPredicate((w) =>
              w is TextField && w.decoration?.labelText == 'Referans Belge No');
          await tester.ensureVisible(reference);
          await tester.pumpAndSettle();
          await tester.enterText(reference, 'MOB-REF-2');
          final delivery =
              find.byKey(const ValueKey('commercial-Teslimat Tipi'));
          await tester.ensureVisible(delivery);
          await tester.pumpAndSettle();
          await tester.tap(delivery);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Nakliye Alıcı').last);
          await tester.pumpAndSettle();
          final notes = find.text('Ek Açıklamalar (2)');
          await tester.ensureVisible(notes);
          await tester.pumpAndSettle();
          await tester.tap(notes);
          await tester.pumpAndSettle();
          await tester.enterText(
              find.byWidgetPredicate((w) =>
                  w is TextField && w.decoration?.labelText == 'Açıklama 1'),
              'Mobil açıklama');
          await tester.tap(find.text('Uygula'));
          await tester.pumpAndSettle();
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 30)));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Özet').first);
          await tester.pumpAndSettle();
          await tester
              .tap(find.widgetWithText(OutlinedButton, 'Genel İskonto'));
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
          await capturePreview(tester, capture,
              '${quote ? 'quote' : 'order'}_${sales ? 'sales' : 'purchase'}_new_fields');
          await tester.runAsync(() async {
            await tester.tap(find.text('Kaydet').last);
            await Future<void>.delayed(const Duration(milliseconds: 80));
          });
          await tester.pumpAndSettle();
          if (!quote) {
            await tester.runAsync(() async {
              await tester.tap(find.text('Taslak Kaydet'));
              await Future<void>.delayed(const Duration(milliseconds: 80));
            });
            await tester.pumpAndSettle();
          }
          final header = jsonDecode(writes.first.body) as Map;
          Object? value(String name) => header[quote
              ? name
              : '${name[0].toLowerCase()}${name.substring(1)}'.toLowerCase()];
          expect(value('Referansbelgeno'), 'MOB-REF-2');
          expect(value('Teslimattipi'), 2);
          expect(value('Aciklama1'), 'Mobil açıklama');
          expect(value('Aciklama20'), 'Web 20');
          expect(value('Geneliskontooran'), 20);
          expect(value('Geneliskontotutar'), 40);
          expect(value('Geneltoplam'), 192);
          expect(value('Dovizgeneliskontotutar'), 40);
          if (quote && !sales) expect(header['Grupno'], 42);
          if (!quote) {
            expect(header['baglanti'], false);
            expect(writes.length, 2);
          }
          final row = jsonDecode(writes.last.body) as Map;
          expect(row[quote ? 'Olcubr2id' : 'olcubr2id'], 7);
          expect(row[quote ? 'IstisnaId' : 'istisnaId'], 9);
          expect(
              row[quote ? 'Stokadiaciklama' : 'stokadiaciklama'], 'Web ürün');
          expect(tester.takeException(), isNull);
          await tester.pump(const Duration(seconds: 6));
          await tester.pumpAndSettle();
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
            () => MockClient((request) async {
                  if (request.method != 'GET') {
                    writes.add(request);
                    return http.Response('', 204);
                  }
                  final path = request.url.path;
                  if (path.contains('/SiparisFull/') ||
                      path.contains('/TeklifFull/'))
                    return response({
                      ...(quote
                          ? quoteData.orders.first
                          : orderData.orders.first),
                      'Id': quote ? 'quote-1' : 'order-1',
                      'Projeid': 1,
                      'Plasiyerid': 1,
                      'Belgeturu': quote ? (sales ? 17 : 18) : (sales ? 5 : 6),
                      'Belgetipi': 1,
                      'Teslimattipi': 3,
                      'Referansbelgeno': 'WEB-REF',
                      'Grupno': 42,
                      'Aciklama1': 'Web 1',
                      'Aciklama20': 'Web 20',
                      'Geneliskontooran': 10,
                      'Geneliskontotutar': 20,
                      'Baglanti': false,
                      quote ? 'Teklifhareket' : 'Siparishareket': [
                        {
                          ...(quote ? quoteData.line : orderData.line),
                          'Olcubr2id': 7,
                          'IstisnaId': 9,
                          'Stokadiaciklama': 'Web ürün'
                        }
                      ],
                    });
                  return response(quote
                      ? quoteData.fixture(path)
                      : orderData.fixture(path));
                }));
      });
    }
  }
}

http.Response response(Object? value) =>
    http.Response(jsonEncode({'Data': value}), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
Future<void> capturePreview(
    WidgetTester tester, GlobalKey key, String name) async {
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
