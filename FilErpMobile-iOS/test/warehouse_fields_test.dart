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
import 'package:FilERP/helpers/warehouse_line_fields.dart';
import 'package:FilERP/models/entities/depo/dathareket_dto.dart';
import 'package:FilERP/models/entities/depo/ambargchareket_dto.dart';
import 'package:FilERP/models/entities/depo/depo_dto.dart';
import 'package:FilERP/models/entities/proje/proje_dto.dart';
import 'package:FilERP/models/entities/stok/stok_dto.dart';
import 'package:FilERP/services/depo/dat/dat_service.dart';
import 'package:FilERP/services/depo/ambargc/ambargc_service.dart';
import 'package:FilERP/widgets/dat/dat_kalem_form_sheet.dart';
import 'package:FilERP/widgets/ambargc/ambargc_kalem_form_sheet.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';

final product = {
  'Id': 1,
  'Kod': 'ST.001',
  'Ad': 'Test Ürün',
  'Stokozelligesahip': true,
  'Temelolcubrid': 1,
  'Temelolcubr': {'Id': 1, 'Ad': 'Adet'},
  'Stokozellik': [
    {
      'Id': 11,
      'Stokozelliksabitid': 7,
      'Sira': 1,
      'Stokozelliksabit': {'Id': 7, 'Ad': 'Mavi'}
    },
    {
      'Id': 12,
      'Stokozelliksabitid': 8,
      'Sira': 2,
      'Stokozelliksabit': {'Id': 8, 'Ad': 'Kırmızı'}
    },
  ],
};
final datJson = {
  'Id': 'line-id',
  'Datid': 'dat-id',
  'Stokid': 1,
  'Stokozelliksabitid': 7,
  'Stok': product,
  'Olcubrid': 1,
  'Olcubr': {'Id': 1, 'Ad': 'Adet'},
  'Miktar': 2.5,
  'Miktar2': 4.0,
  'Cikacagisubeid': 1,
  'Gidecegisubeid': 2,
  'Cikacagidepoid': 1,
  'Gidecegidepoid': 2,
  'Cikacagidepoadresid': 'adres-a',
  'Gidecegidepoadresid': 'adres-b',
  'Projeid': 1,
  'Aciklama': 'Mevcut',
};
final ambarJson = {
  'Id': 'ambar-line',
  'Ambargcid': 'ambar-id',
  'Stokid': 1,
  'Stokozelliksabitid': 7,
  'Stok': product,
  'Olcubrid': 1,
  'Olcubr': {'Id': 1, 'Ad': 'Adet'},
  'Depoid': 1,
  'Depoadresid': 'adres-a',
  'Projeid': 1,
  'Miktar': 2.5,
  'Miktar2': 4.1256789,
  'Dovizfiyat': 12.3456789,
  'Fiyat': 493.827156,
  'Tutar': 1234.56789,
  'Aciklama': 'Mevcut',
};
http.Response response(dynamic data) =>
    http.Response(jsonEncode({'Data': data}), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(
      {'token_final': 'fixture', 'sube_id': 1}));
  setUpAll(() async {
    for (final e in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  test('linked feature defaults match web and preserve an existing selection',
      () {
    final stock = StokDto.fromJson(product);
    expect(warehouseFeatureId(stock, null), 7);
    expect(warehouseFeatureId(stock, 8), 8);
    expect(warehouseFeatureId(stock, 99), 99);
    stock.Stokozelligesahip = false;
    expect(warehouseFeatureId(stock, 8), null);
  });
  test(
      'DAT and ambar fields survive draft roundtrip, API bodies and explicit clearing',
      () {
    final dat = DathareketDto.fromJson(datJson);
    final map = dat.toWarehouseJson('parent', includeId: true);
    final restored = DathareketDto.fromJson(warehouseDraftJson(map));
    expect(restored.stokozelliksabitid, 7);
    expect(restored.cikacagidepoadresid, 'adres-a');
    expect(restored.gidecegidepoadresid, 'adres-b');
    expect(restored.id, 'line-id');
    expect(restored.miktar2, 4);
    dat.stokozelliksabitid = null;
    expect(dat.toWarehouseJson('parent')['stokozelliksabitid'], null);
    final ambar = AmbargchareketDto.fromJson(ambarJson);
    final restoredAmbar = AmbargchareketDto.fromJson(
        warehouseDraftJson(ambar.toWarehouseJson('parent', includeId: true)));
    expect(restoredAmbar.stokozelliksabitid, 7);
    expect(restoredAmbar.dovizfiyat, 12.3456789);
    expect(restoredAmbar.miktar2, 4.1256789);
    expect(restoredAmbar.depoadresid, 'adres-a');
    expect(restoredAmbar.id, 'ambar-line');
  });
  test(
      'foreign prices use rate once; local prices and currency changes retain value',
      () {
    final line = AmbargchareketDto()
      ..miktar = 2.5
      ..dovizfiyat = 10
      ..fiyat = 400;
    priceWarehouseLine(line, foreign: true, rate: 40);
    expect(line.fiyat, 400);
    expect(line.tutar, 1000);
    repriceWarehouseLines([line], foreign: true, rate: 45);
    expect(line.fiyat, 450);
    expect(line.tutar, 1125);
    repriceWarehouseLines([line], foreign: false, rate: 1);
    expect(line.fiyat, 450);
    expect(line.dovizfiyat, 0);
    line.dovizfiyat = null;
    repriceWarehouseLines([line], foreign: true, rate: 50);
    expect(line.dovizfiyat, 9);
    expect(line.fiyat, 450);
  });
  test(
      'create and update endpoints receive feature, FX price and depot addresses',
      () async {
    final writes = <http.Request>[];
    await http.runWithClient(() async {
      final dat = DathareketDto.fromJson(datJson);
      final ambar = AmbargchareketDto.fromJson(ambarJson);
      await DatService().saveHareket('fixture', dat.toWarehouseJson('dat-id'));
      await DatService().updateHareket(
          'fixture', dat.toWarehouseJson('dat-id', includeId: true));
      await AmbargcService()
          .saveHareket('fixture', ambar.toWarehouseJson('ambar-id'));
      await AmbargcService().updateHareket(
          'fixture', ambar.toWarehouseJson('ambar-id', includeId: true));
    },
        () => MockClient((r) async {
              writes.add(r);
              return r.method == 'POST'
                  ? response('new-id')
                  : http.Response('', 204);
            }));
    expect(writes.map((r) => r.method), ['POST', 'PUT', 'POST', 'PUT']);
    for (final r in writes) {
      final body = jsonDecode(r.body);
      expect(body['stokozelliksabitid'], 7);
      if (r.url.path.contains('Ambargchareket')) {
        expect(body['dovizfiyat'], 12.3456789);
        expect(body['depoadresid'], 'adres-a');
      } else {
        expect(body['cikacagidepoadresid'], 'adres-a');
        expect(body['gidecegidepoadresid'], 'adres-b');
      }
    }
  });
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final kind in ['dat', 'arac', 'ambar']) {
        testWidgets(
            '$kind linked feature and edit preservation ${design.name} ${brightness.name}',
            (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final originalDat = DathareketDto.fromJson(datJson);
          final originalAmbar = AmbargchareketDto.fromJson(ambarJson);
          dynamic result;
          final key = GlobalKey();
          await http.runWithClient(() async {
            await tester.pumpWidget(RepaintBoundary(
                key: key,
                child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.build(brightness, design: design),
                    home: Builder(
                        builder: (context) => Scaffold(
                            body: Center(
                                child: FilledButton(
                                    onPressed: () async {
                                      final depots = [
                                        DepoDto.fromJson({
                                          'Id': 1,
                                          'Ad': 'Merkez',
                                          'Dinamikdepo': true
                                        }),
                                        DepoDto.fromJson({
                                          'Id': 2,
                                          'Ad': 'Araç',
                                          'Dinamikdepo': true
                                        })
                                      ];
                                      final projects = [
                                        ProjeDto.fromJson({
                                          'Id': 1,
                                          'Kod': 'P01',
                                          'Ad': 'Genel'
                                        })
                                      ];
                                      result = kind == 'ambar'
                                          ? await showAmbargcKalemForm(context,
                                              kalem: originalAmbar,
                                              stoklar: [],
                                              projeler: projects,
                                              depolar: depots,
                                              dovizli: true,
                                              kur: 40)
                                          : await showDatKalemForm(context,
                                              kalem: originalDat,
                                              stoklar: [],
                                              projeler: projects,
                                              cikisDepolar: depots,
                                              girisDepolar: depots,
                                              sade: kind == 'arac');
                                    },
                                    child: const Text('Aç'))))))));
            await tester.tap(find.text('Aç'));
            await flush(tester);
            final feature = find.byWidgetPredicate((w) =>
                w is DropdownButtonFormField<int> &&
                w.decoration.labelText == 'Stok Özelliği');
            await tester.ensureVisible(feature);
            await tester.tap(feature);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Kırmızı').last);
            await tester.pumpAndSettle();
            if (kind == 'ambar') {
              final fx = find.byKey(const ValueKey('warehouse-fx-price'));
              await tester.ensureVisible(fx);
              await tester.enterText(fx, '25,5');
              await tester.pumpAndSettle();
            }
            if (design == ErpDesign.modern && brightness == Brightness.dark) {
              await tester.ensureVisible(feature);
              await tester.pumpAndSettle();
              await tester.runAsync(() async {
                final boundary = key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
                final image = await boundary.toImage(pixelRatio: 1);
                final bytes =
                    await image.toByteData(format: ui.ImageByteFormat.png);
                await File('tool/previews/${kind}_fields_dark.png')
                    .writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            await tester.ensureVisible(find.text('Güncelle'));
            await tester.tap(find.text('Güncelle'));
            await flush(tester);
            expect(result, isNotNull);
            expect(originalDat.stokozelliksabitid, 7);
            expect(originalAmbar.stokozelliksabitid, 7);
            if (kind == 'ambar') {
              final saved = result as AmbargchareketDto;
              expect(saved.stokozelliksabitid, 8);
              expect(saved.dovizfiyat, 25.5);
              expect(saved.fiyat, 1020);
              expect(saved.tutar, 2550);
              expect(saved.miktar2, 4.1256789);
              expect(saved.depoadresid, 'adres-a');
              expect(saved.stokozelliksabit?.ad, 'Kırmızı');
            } else {
              final saved = result as DathareketDto;
              expect(saved.stokozelliksabitid, 8);
              expect(saved.cikacagidepoadresid, 'adres-a');
              expect(saved.gidecegidepoadresid, 'adres-b');
              expect(saved.miktar2, 4);
              expect(saved.cikacagisubeid, 1);
              expect(saved.gidecegisubeid, 2);
            }
            // Cancel must discard changes to both the feature and price.
            await tester.tap(find.text('Aç'));
            await flush(tester);
            final reopenedFeature = find.byWidgetPredicate((w) =>
                w is DropdownButtonFormField<int> &&
                w.decoration.labelText == 'Stok Özelliği');
            await tester.ensureVisible(reopenedFeature);
            await tester.tap(reopenedFeature);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Kırmızı').last);
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('İptal'));
            await tester.tap(find.text('İptal'));
            await flush(tester);
            expect(result, isNull);
            expect(originalDat.stokozelliksabitid, 7);
            expect(originalAmbar.stokozelliksabitid, 7);
            expect(originalAmbar.dovizfiyat, 12.3456789);
            expect(tester.takeException(), null);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
              () => MockClient((r) async {
                    expect(r.method, 'GET');
                    if (r.url.path.contains('/Stok/WithoutAuth/'))
                      return response(product);
                    if (r.url.path.contains('/Depoadres/'))
                      return response([
                        {'Id': 'adres-a', 'Kod': 'A', 'Ad': 'Raf A'},
                        {'Id': 'adres-b', 'Kod': 'B', 'Ad': 'Raf B'}
                      ]);
                    return response([]);
                  }));
        });
      }
    }
  }
}

Future<void> flush(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
  await tester.pumpAndSettle();
}
