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
import 'package:FilERP/helpers/stock_field_schema.dart';
import 'package:FilERP/models/entities/stok/stok_dto.dart';
import 'package:FilERP/pages/stok/stok_ekle_page.dart';
import 'package:FilERP/services/stok/stock_card_fields_service.dart';
import 'package:FilERP/widgets/erp_record_fields.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';

final stock = <String, dynamic>{
  'Id': 42,
  'Kod': 'ST.042',
  'Ad': 'Test Stok',
  'Temelolcubrid': 1,
  'Stokkategoriid': 1,
  'Kartturu': 1,
  'Stokturu': 1,
  'Takipsekli': 1,
  'Kdvalis': 20.5,
  'Sirketortak': false,
  'Stokozelligesahip': true,
  'Stokozellikcariden': true,
  'Partiseritakipmodu': 2,
  'Indirimyapilamaz': true,
  'Promosyonyapilamaz': true,
  'Iadeedilemez': true,
  'Tartilir': true,
  'Gtipkodu': '123456',
  'Istisnaid': 6,
  'Otvalis': 2.125678,
  'Otvsatis': 3.5,
  'Yurticialishesapplaniid': 120,
  'Yurticialishesapplani': {'Id': 120, 'Kod': '153.01', 'Ad': 'Ticari Mal'},
  'Uretimtarihi': '2026-11-01T00:00:00',
  'Recetesivar': true,
  'Stokolcubr': [
    {
      'Id': 11,
      'Olcubrid': 2,
      'Pay': 12.0,
      'Payda': 1.0,
      'Carpim': 12.0,
      'Sira': 1,
      'Olcubr': {'Id': 2, 'Ad': 'Koli'}
    }
  ],
  'Stokfiyat': [
    {
      'Id': 12,
      'Dovizid': 1,
      'Sira': 1,
      'Alisfiyat': 125.678901,
      'Satisfiyat': 180.0,
      'Doviz': {'Id': 1, 'Ad': 'Türk Lirası', 'Birim': 'TRY'}
    }
  ],
  'Stokbarkod': [
    {'Id': 'barcode-id', 'Barkod': '123456789', 'Olcubrid': 1, 'Sira': 1}
  ],
  'Stokozellik': [
    {
      'Id': 13,
      'Stokozelliksabitid': 8,
      'Carigrupkodu': 'A',
      'Sira': 1,
      'Stokozelliksabit': {'Id': 8, 'Ad': 'Renk'}
    }
  ],
  'Stokalternatif': [
    {'Id': 14, 'Alternatifstokid': 43, 'Sira': 1}
  ],
  'Stoksube': [
    {'Id': 'branch-id', 'Subeid': 1}
  ],
};
http.Response data(dynamic value) =>
    http.Response(jsonEncode({'Data': value}), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
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
  setUp(() => SharedPreferences.setMockInitialValues(
      {'token_final': 'fixture', 'sube_id': 1}));
  test(
      'full stock survives model, form controller and JSON without rounding or flag loss',
      () {
    final dto = StokDto.fromJson(stock);
    final json = dto.toJson();
    final c = RecordFieldsController(stockExtraFields, initial: json);
    final body = {...dto.toSaveJson(includeId: true), ...c.toJson()};
    for (final key in [
      'Gtipkodu',
      'Istisnaid',
      'Otvalis',
      'Otvsatis',
      'Sirketortak',
      'Partiseritakipmodu',
      'Stokozelligesahip',
      'Stokozellikcariden',
      'Yurticialishesapplaniid',
      'Indirimyapilamaz'
    ]) {
      expect(body[key], stock[key], reason: key);
    }
    expect(c.labels['Yurticialishesapplaniid'], '153.01 · Ticari Mal');
    expect(dto.extraCollections['Recetesivar'], true);
    expect(json['Stokozellik'][0]['Stokozelliksabitid'], 8);
    final rows = StockRowsController(json);
    expect(rows.dirty, false);
    expect(rows.createBody()['Stokfiyat'][0]['Alisfiyat'], 125.678901);
    c.choose('Istisnaid', null, null);
    c.text['Gtipkodu']!.clear();
    c.setValue('Indirimyapilamaz', false);
    expect(c.toJson()['Istisnaid'], null);
    expect(c.toJson()['Gtipkodu'], null);
    expect(c.toJson()['Indirimyapilamaz'], false);
    c.dispose();
    rows.dispose();
  });
  test('create rows remove IDs and navigation, calculate exact unit multiplier',
      () {
    final c = StockRowsController(stock);
    final body = c.createBody();
    expect(body['Stokolcubr'][0]['Carpim'], 12);
    for (final list in body.values) {
      for (final row in list) {
        expect(row.containsKey('Id'), false);
        expect(row.containsKey('Stokid'), false);
        expect(row.containsKey('_labels'), false);
      }
    }
    c.dispose();
  });
  test(
      'row sync uses separate endpoints and retries only changes not already acknowledged',
      () async {
    final c = StockRowsController(stock);
    c.remove('Stokbarkod', 0);
    c.rows['Stokfiyat']![0]['Satisfiyat'] = 190.0;
    c.put('Stokozellik', {'Stokozelliksabitid': 9, 'Sira': 2});
    final requests = <http.Request>[];
    bool fail = true;
    await http.runWithClient(() async {
      final service = StockCardFieldsService(stockId: 42);
      await expectLater(service.sync(c), throwsException);
      expect(c.dirty, true);
      fail = false;
      await service.sync(c);
      expect(c.dirty, false);
    },
        () => MockClient((r) async {
              requests.add(r);
              if (r.url.path.endsWith('/Stokozellik') && r.method == 'POST') {
                if (fail) return http.Response('{"Message":"Test error"}', 500);
                return data({'Id': 99});
              }
              return http.Response('', 204);
            }));
    expect(requests.where((r) => r.method == 'PUT').length, 1);
    expect(requests.where((r) => r.method == 'DELETE').length, 1);
    expect(requests.first.url.path, endsWith('/Stok/Stokfiyat'));
    expect(jsonDecode(requests.first.body)['Stokid'], 42);
    expect(c.rows['Stokozellik']!.last['Id'], 99);
    c.dispose();
  });
  test(
      'lookup routes match API and restrict account leaves / self alternatives',
      () async {
    final paths = <String>[];
    await http.runWithClient(() async {
      final service = StockCardFieldsService(stockId: 42);
      expect((await service.choices('account')).map((e) => e.id), [2]);
      expect((await service.choices('stock')).map((e) => e.id), [43]);
      await service.choices('depot');
    },
        () => MockClient((r) async {
              paths.add(r.url.path);
              if (r.url.path.contains('Hesapplani'))
                return data([
                  {'Id': 1, 'Tur': 3, 'Ad': 'Ana'},
                  {'Id': 2, 'Tur': 5, 'Ad': 'Muavin'}
                ]);
              if (r.url.path.contains('/Stok/'))
                return data([
                  {'Id': 42, 'Ad': 'Kendisi'},
                  {'Id': 43, 'Ad': 'Alternatif'}
                ]);
              return data([]);
            }));
    expect(paths.last, endsWith('/Depo/AllBySubeidWithoutAuth/1'));
  });
  for (final edit in [false, true]) {
    testWidgets(
        'stock ${edit ? 'update' : 'create'} sends header and correct row contract',
        (tester) async {
      final writes = <http.Request>[];
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.build(Brightness.light),
            initialRoute: '/edit',
            routes: {
              '/': (_) => const Scaffold(body: Text('Liste')),
              '/edit': (_) =>
                  StokEklePage(editStok: edit ? StokDto.fromJson(stock) : null),
            }));
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();
        if (!edit) {
          await tester.enterText(
              find.byWidgetPredicate((w) =>
                  w is TextField && w.decoration?.labelText == 'Stok Kodu *'),
              'ST.NEW');
          await tester.enterText(
              find.byWidgetPredicate((w) =>
                  w is TextField && w.decoration?.labelText == 'Stok Adı *'),
              'Yeni Stok');
        }
        await tester.runAsync(() async {
          await tester.tap(find
              .text(edit ? 'Değişiklikleri kaydet' : 'Stok kartını oluştur'));
          await Future<void>.delayed(const Duration(milliseconds: 2700));
        });
        await tester.pumpAndSettle();
        expect(writes.length, 1);
        final body = jsonDecode(writes.single.body) as Map;
        expect(writes.single.method, edit ? 'PUT' : 'POST');
        if (edit) {
          expect(body['Sirketortak'], false);
          expect(body['Stokozelligesahip'], true);
          expect(body['Recetesivar'], true);
          expect(body['Otvalis'], 2.125678);
          expect(body['Kdvalis'], 20.5);
          expect(body.containsKey('Stokfiyat'), false);
        } else {
          expect(body['Sirketortak'], true);
          for (final key in stockRowFields.keys) {
            expect(body[key], isList);
          }
        }
        expect(tester.takeException(), null);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
          () => MockClient((r) async {
                if (r.method != 'GET') {
                  writes.add(r);
                  return http.Response('', 204);
                }
                return data([
                  {'Id': 1, 'Ad': 'Adet'}
                ]);
              }));
    });
  }
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      testWidgets('stock details and row editor $design $brightness',
          (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await http.runWithClient(() async {
          await tester.pumpWidget(RepaintBoundary(
              key: const ValueKey('preview'),
              child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.build(brightness, design: design),
                  home: StokEklePage(editStok: StokDto.fromJson(stock)))));
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 40)));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Detaylar'));
          await tester.tap(find.text('Detaylar'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Kullanım ve Takip'));
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('stock-extra-Indirimyapilamaz')),
              findsOneWidget);
          await tester.tap(find.text('Kullanım ve Takip'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Fiyatlar (1)'));
          await tester.tap(find.text('Fiyatlar (1)'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Türk Lirası'));
          await tester.tap(find.text('Türk Lirası'));
          await tester.pumpAndSettle();
          final price = find.byKey(const ValueKey('stock-row-Satisfiyat'));
          await tester.enterText(price, '250,75');
          if (design == ErpDesign.modern) {
            tester.testTextInput.hide();
            await tester.pumpAndSettle();
            final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('preview')));
            final image =
                (await tester.runAsync(() => boundary.toImage(pixelRatio: 1)))!;
            final png = await tester.runAsync(
                () => image.toByteData(format: ui.ImageByteFormat.png));
            if (png != null)
              await tester.runAsync(() =>
                  File('tool/previews/stock_details_${brightness.name}.png')
                      .writeAsBytes(png.buffer.asUint8List()));
            image.dispose();
          }
          await tester.ensureVisible(find.text('Uygula'));
          await tester.tap(find.text('Uygula'));
          await tester.pumpAndSettle();
          expect(find.text('Alış: 125.678901 · Satış: 250.75'), findsOneWidget);
          expect(tester.takeException(), null);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
            () => MockClient((r) async => data([
                  {'Id': 1, 'Ad': 'Adet'}
                ])));
      });
    }
  }
}
