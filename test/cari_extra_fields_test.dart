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
import 'package:FilERP/models/entities/cari/cari_dto.dart';
import 'package:FilERP/models/entities/cari/cari_dto_full.dart';
import 'package:FilERP/models/entities/cari/cari_extra_fields.dart';
import 'package:FilERP/widgets/cari/cari_extra_sections.dart';
import 'package:FilERP/services/muhasebe/hesapplani_service.dart';
import 'package:FilERP/pages/cari/cari_ekle_page.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';

final customer = {
  'Id': 7,
  'Kod': 'CR.TEST',
  'Ad': 'Test Ticaret',
  'Vergino': '1234567890',
  'Vergidairesi': 'Test',
  'Ulkeid': 1,
  'Ilid': 34,
  'Ilceid': 1,
  'Dovizid': 1,
  'Plasiyerid': 1,
  'Firmatipi': 1,
  'Kartturu': 1,
  'Efaturatip': 1,
  'Carikategoriid': 42,
  'Kilit': 3,
  'Hesaptipi': 1,
  'Sirketortak': false,
  'Vadegunu': 30,
  'Iskontoorani': 1.5,
  for (final key in cariExtraTextFields.keys) key: 'Web $key',
  for (final key in cariExtraBoolFields.keys) key: true,
  'Bankaid': 1,
  'Bankasubeid': 11,
  'Baglicariid': 8,
  'Komisyoncucariid': 9,
  'Hesapplaniid': 101,
  'Kurfarkigelirhesapplaniid': 102,
  'Kurfarkigiderhesapplaniid': 103,
  'Banka': {'Id': 1, 'Kod': '01', 'Ad': 'Test Bankası A'},
  'Bankasube': {'Id': 11, 'Ad': 'Eski Şube'},
  'Hesapplani': {'Id': 101, 'Kod': '120.01', 'Ad': 'Cari Hesabı'},
  'Baglicari': {'Id': 8, 'Kod': 'CR.008', 'Ad': 'Bağlı Test'},
};

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
  test(
      'full customer -> edit DTO -> JSON preserves all audited fields and existing settings',
      () {
    final full = CariDtoFull.fromJson(customer);
    final edit = full.toEditDto();
    final json = edit.toJson(includeId: true);
    for (final key in [
      ...cariExtraTextFields.keys,
      ...cariExtraIdFields.keys,
      ...cariExtraBoolFields.keys
    ]) {
      expect(json[key], customer[key], reason: key);
    }
    for (final key in [
      'Id',
      'Vadegunu',
      'Iskontoorani',
      'Carikategoriid',
      'Kilit',
      'Hesaptipi',
      'Sirketortak'
    ]) expect(json[key], customer[key], reason: key);
    expect(edit.selectionLabels['Bankaid'], '01 · Test Bankası A');
    expect(CariDto.fromJson(json).Kurumsalemail, customer['Kurumsalemail']);
    expect(full.toJson()['Ortakkod'], customer['Ortakkod']);
  });
  test(
      'clearing fields is explicit; changing a bank clears the old branch without mutating the source',
      () {
    final source = CariDtoFull.fromJson(customer).toEditDto();
    final controller = CariExtraController()..load(source);
    controller.select('Bankaid', 2, 'Yeni Banka');
    expect(controller.id('Bankasubeid'), isNull);
    expect(controller.labels.containsKey('Bankasubeid'), isFalse);
    controller.text['Efaturaalias']!.clear();
    controller.select('Baglicariid', null, null);
    controller.setFlag('Riskkontroluvar', false);
    expect(controller.toJson(), containsPair('Efaturaalias', null));
    expect(controller.toJson(), containsPair('Baglicariid', null));
    expect(controller.toJson(), containsPair('Riskkontroluvar', false));
    expect(source.Bankasubeid, 11);
    expect(source.Efaturaalias, 'Web Efaturaalias');
    controller.dispose();
  });
  test(
      'account selection uses authenticated lookup and only offers muavin accounts',
      () async {
    await http.runWithClient(() async {
      final rows = await HesapplaniService().getForSelection('fixture');
      expect(rows.map((e) => e.id), [101]);
    },
        () => MockClient((request) async {
              expect(request.url.path, '/api/Hesapplani/AllWithoutAuth');
              expect(request.method, 'GET');
              return response([
                {'Id': 100, 'Kod': '120', 'Ad': 'Ana Hesap', 'Tur': 3},
                {'Id': 101, 'Kod': '120.01', 'Ad': 'Muavin Hesap', 'Tur': 5}
              ]);
            }));
  });
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final edit in [false, true]) {
        testWidgets(
            '${design.name} ${brightness.name} ${edit ? 'edit' : 'create'} customer optional fields and exact payload',
            (tester) async {
          SharedPreferences.setMockInitialValues({'token_final': 'fixture'});
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          final writes = <http.Request>[];
          final capture = GlobalKey();
          await http.runWithClient(() async {
            await tester.runAsync(() async {
              await tester.pumpWidget(RepaintBoundary(
                  key: capture,
                  child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.build(brightness, design: design),
                      initialRoute: '/edit',
                      routes: {
                        '/': (_) => const Scaffold(body: Text('Liste')),
                        '/edit': (_) => CariEklePage(
                            editCari: edit
                                ? CariDtoFull.fromJson(customer).toEditDto()
                                : null),
                      })));
              await Future<void>.delayed(const Duration(milliseconds: 100));
            });
            await tester.pumpAndSettle();
            if (!edit) {
              await tester.enterText(field('Cari kodu *'), 'CR.YENI');
              await tester.enterText(
                  field('Cari Ünvan *'), 'Yeni Test Ticaret');
              await tester.enterText(field('Vergi No'), '1234567890');
              await tester.enterText(field('Vergi Dairesi'), 'Test');
            }
            await tab(tester, 'Muhasebe');
            await expand(tester, 'Banka Bilgileri');
            await openPicker(tester, 'Bankaid');
            await tester.tap(find.text('02 · Test Bankası B').last);
            await settleAsync(tester);
            expect(find.text('Eski Şube'), findsNothing);
            await openPicker(tester, 'Bankasubeid');
            expect(find.textContaining('Başka Banka Şubesi'), findsNothing);
            await tester.tap(find.text('22 · Yeni Şube').last);
            await settleAsync(tester);
            await enter(
                tester, 'cari-extra-Iban', 'tr00 0000 0000 0000 0000 0000 00');
            await enter(tester, 'cari-extra-Hesapno', 'HSP-001');
            if (design == ErpDesign.modern && !edit)
              await preview(tester, capture, 'cari_bank_${brightness.name}');
            await expand(tester, 'E-Belge Bilgileri');
            await enter(tester, 'cari-extra-Efaturaalias',
                edit ? '' : 'urn:mail:test@example.test');
            if (!edit) {
              await toggle(tester, 'Efaturamukkellefi');
              await expand(tester, 'Muhasebe Hesapları');
              await openPicker(tester, 'Hesapplaniid');
              expect(find.textContaining('Ana Hesap'), findsNothing);
              await tester.tap(find.text('120.01 · Muavin Hesap').last);
              await settleAsync(tester);
              await tab(tester, 'Ek');
              await expand(tester, 'Risk ve Cari İlişkileri');
              await toggle(tester, 'Riskkontroluvar');
              await enter(tester, 'cari-extra-Kosulkodu', 'KOS-01');
              await openPicker(tester, 'Baglicariid');
              await tester.tap(find.text('CR.008 · Bağlı Test').last);
              await settleAsync(tester);
              await tab(tester, 'İletişim');
              await expand(tester, 'Yetkili Bilgileri');
              await enter(tester, 'cari-extra-Yetkiliad', 'Test Yetkilisi');
              await tab(tester, 'Rapor');
              await expand(tester, 'Ortak Kodlar');
              await toggle(tester, 'Ortakkoduvar');
              await enter(tester, 'cari-extra-Ortakkod', 'ORT-001');
            }
            await tester.runAsync(() async {
              await tester.tap(find.text(
                  edit ? 'Değişiklikleri kaydet' : 'Cari kartını oluştur'));
              await Future<void>.delayed(const Duration(milliseconds: 2600));
            });
            await tester.pumpAndSettle();
            expect(writes.length, 1);
            expect(writes.single.method, edit ? 'PUT' : 'POST');
            expect(writes.single.url.path, '/api/Cari');
            final payload = jsonDecode(writes.single.body) as Map;
            expect(payload['Bankaid'], 2);
            expect(payload['Bankasubeid'], 22);
            expect(payload['Hesapno'], 'HSP-001');
            expect(payload['Iban'], 'TR000000000000000000000000');
            expect(payload['Efaturaalias'],
                edit ? null : 'urn:mail:test@example.test');
            expect(payload['Hesapplaniid'], 101);
            expect(payload['Baglicariid'], 8);
            expect(payload['Riskkontroluvar'], true);
            expect(payload['Ortakkoduvar'], true);
            if (edit) {
              expect(payload['Id'], 7);
              expect(payload['Carikategoriid'], 42);
              expect(payload['Kilit'], 3);
              expect(payload['Hesaptipi'], 1);
              expect(payload['Sirketortak'], false);
              expect(payload['Komisyoncucariid'], 9);
              expect(payload['Kurfarkigelirhesapplaniid'], 102);
              expect(payload['Kurumsalemail'], 'Web Kurumsalemail');
              expect(payload['Eirsaliyealias'], 'Web Eirsaliyealias');
              expect(payload['Iskontoorani'], 1.5);
            } else {
              expect(payload.containsKey('Id'), false);
              expect(payload['Yetkiliad'], 'Test Yetkilisi');
              expect(payload['Kosulkodu'], 'KOS-01');
              expect(payload['Ortakkod'], 'ORT-001');
            }
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
                    if (path.contains('/Ulke/'))
                      return response([
                        {'Id': 1, 'Ad': 'Türkiye'}
                      ]);
                    if (path.contains('/Il/'))
                      return response([
                        {'Id': 34, 'Ad': 'İstanbul', 'Ulkeid': 1}
                      ]);
                    if (path.contains('/Ilce/'))
                      return response([
                        {'Id': 1, 'Ad': 'Kadıköy', 'Ilid': 34}
                      ]);
                    if (path.endsWith('/Doviz'))
                      return response([
                        {'Id': 1, 'Birim': 'TRY', 'Ad': 'Türk Lirası'}
                      ]);
                    if (path.endsWith('/Banka'))
                      return response([
                        {'Id': 1, 'Kod': '01', 'Ad': 'Test Bankası A'},
                        {'Id': 2, 'Kod': '02', 'Ad': 'Test Bankası B'}
                      ]);
                    if (path.contains('/Bankasube/GetByBankaId/2'))
                      return response([
                        {
                          'Id': 22,
                          'Kod': '22',
                          'Ad': 'Yeni Şube',
                          'Bankaid': 2
                        },
                        {'Id': 99, 'Ad': 'Başka Banka Şubesi', 'Bankaid': 1}
                      ]);
                    if (path.contains('/Hesapplani/AllWithoutAuth'))
                      return response([
                        {'Id': 100, 'Kod': '120', 'Ad': 'Ana Hesap', 'Tur': 3},
                        {
                          'Id': 101,
                          'Kod': '120.01',
                          'Ad': 'Muavin Hesap',
                          'Tur': 5
                        }
                      ]);
                    if (path.contains('/Cari/AllWithoutAuth'))
                      return response([
                        {'Id': 7, 'Kod': 'CR.TEST', 'Ad': 'Test Ticaret'},
                        {'Id': 8, 'Kod': 'CR.008', 'Ad': 'Bağlı Test'}
                      ]);
                    return response([
                      {'Id': 1, 'Kod': 'P01', 'Adsoyad': 'Test Temsilcisi'}
                    ]);
                  }));
        });
      }
    }
  }
}

Finder field(String label) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label);
Future<void> settleAsync(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
  await tester.pumpAndSettle();
}

Future<void> tab(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> expand(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openPicker(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey('cari-extra-$key'));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(finder);
    await Future<void>.delayed(const Duration(milliseconds: 60));
  });
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, value);
  tester.testTextInput.hide();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> toggle(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey('cari-extra-$key'));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

http.Response response(Object? value) =>
    http.Response(jsonEncode({'Data': value}), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
Future<void> preview(WidgetTester tester, GlobalKey key, String name) async {
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
