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
import 'package:hive_flutter/hive_flutter.dart';
import 'package:FilERP/services/cache/list_cache_service.dart';
import 'package:FilERP/widgets/finance_extra_fields.dart';
import 'package:FilERP/models/entities/finans/kasa_islem/kasa_dto.dart';
import 'package:FilERP/models/entities/finans/kasa_islem/kasahareket_dto.dart';
import 'package:FilERP/models/entities/finans/banka/bankahesap_dto.dart';
import 'package:FilERP/models/entities/finans/banka/bankahareket_dto.dart';
import 'package:FilERP/pages/finans/kasa/kasa_tanim_ekle_page.dart';
import 'package:FilERP/pages/finans/kasa/kasahareket_ekle_page.dart';
import 'package:FilERP/pages/finans/banka/banka_tanim_ekle_page.dart';
import 'package:FilERP/pages/finans/banka/bankahareket_ekle_page.dart';
import 'package:FilERP/pages/finans/tahsilat/tahsilat_ekle_page.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';

final cash = {
  'Id': 1,
  'Kod': 'KS.001',
  'Ad': 'Merkez',
  'Dovizid': 1,
  'Plasiyerkasasi': true,
  'Plasiyerid': 1
};
final bank = {
  'Id': 1,
  'Kod': 'BN.001',
  'Ad': 'Ticari Hesap',
  'Dovizid': 1,
  'Bankaid': 1,
  'Bankasubeid': 1,
  'Hesaptipi': 1,
  'Faizhesapplaniid': 101,
  'Kkdfhesapplaniid': 102,
  'Cezahesapplaniid': 103
};
final movement = <String, dynamic>{
  'Id': 'move-id',
  'Kasaid': 1,
  'Bankahesapid': 1,
  'Giriscikis': 2,
  'Islemtipi': 8,
  'Islemmasrafid': 1,
  'Islemmasraf': {'Id': 1, 'Kod': 'MS.001', 'Ad': 'İşletme Gideri'},
  'Dovizid': 2,
  'Doviz': {'Id': 2, 'Birim': 'USD'},
  'Kur': 40.123456,
  'Doviztutar': 100.0,
  'Tutar': 4012.3456,
  'Tarih': '2026-11-06',
  'Evraktarih': '2026-11-06',
  'Valortarihi': '2026-11-06',
  'Doviztarih': '2026-11-06',
  'Projeid': 1,
  'Plasiyerid': 1,
  'Belgeseri': 'FN',
  'Belgeyil': 2026,
  'Belgeno': '00000001',
  'Masraf': 3.125678,
  for (final p in bankChargePairs.entries) ...{
    p.key: 12.345678,
    p.value: 0.307657
  },
};
http.Response data(dynamic value) =>
    http.Response(jsonEncode({'Data': value}), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});
http.Response lookups(http.Request r) {
  final p = r.url.path;
  if (p.contains('GetNew')) return data('00000002');
  if (p.contains('/Kur/')) return data({'Dovizsatis': 40.123456});
  if (p.endsWith('/Doviz'))
    return data([
      {'Id': 1, 'Birim': 'TRY', 'Ad': 'Türk Lirası'},
      {'Id': 2, 'Birim': 'USD', 'Ad': 'Dolar'}
    ]);
  if (p.contains('/Bankahesap')) return data([bank]);
  if (p.contains('/Kasa') && !p.contains('Kasahareket')) return data([cash]);
  if (p.contains('/Banka'))
    return data([
      {'Id': 1, 'Ad': 'Örnek Banka', 'Bankaid': 1}
    ]);
  if (p.contains('/Masraf'))
    return data([
      {'Id': 1, 'Kod': 'MS.001', 'Ad': 'İşletme Gideri'},
      {'Id': 2, 'Kod': 'MS.002', 'Ad': 'Kira'}
    ]);
  if (p.contains('/Hesapplani'))
    return data([
      {'Id': 100, 'Kod': '780', 'Ad': 'Ana Hesap', 'Tur': 3},
      for (final id in [101, 102, 103])
        {'Id': id, 'Kod': '780.$id', 'Ad': 'Muavin $id', 'Tur': 5}
    ]);
  if (p.contains('/Plasiyer'))
    return data([
      {'Id': 1, 'Kod': 'PL01', 'Adsoyad': 'Test Temsilcisi'}
    ]);
  if (p.contains('/Proje'))
    return data([
      {'Id': 1, 'Kod': 'PR01', 'Ad': 'Genel', 'Tur': 3}
    ]);
  if (p.contains('/Belgeseri'))
    return data([
      {'Id': 1, 'Seri': 'FN', 'Ebelgetip': 0}
    ]);
  if (p.contains('/Cari'))
    return data([
      {'Id': 1, 'Kod': 'CR01', 'Ad': 'Test Cari'}
    ]);
  return data([]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  setUp(() => SharedPreferences.setMockInitialValues(
      {'token_final': 'fixture', 'sube_id': 1}));
  setUpAll(() async {
    cache = await Directory.systemTemp.createTemp('filerp_finance_fields_');
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
  test('bank charges convert FX to TL and preserve independent saved precision',
      () {
    final c = BankChargesController(initial: movement);
    c.currency(true, 40.123456, reprice: false);
    expect(c.amount('Faiz', outgoing: true), 12.345678);
    c.text['Faizdoviz']!.text = '2,5';
    expect(c.amount('Faiz', outgoing: true), 100.30864);
    c.currency(true, 50);
    expect(c.amount('Faiz', outgoing: true), 125);
    expect(c.amount('Faiz', outgoing: false), 0);
    c.currency(false, 0);
    expect(c.amount('Faizdoviz', outgoing: true, fx: true), 0);
    expect(c.amount('Faiz', outgoing: true), 125);
    c.dispose();
  });
  test('new account lookups return only leaf accounts', () async {
    await http.runWithClient(() async {
      expect((await financeFieldChoices('account')).map((e) => e.id),
          [101, 102, 103]);
    }, () => MockClient((r) async => lookups(r)));
  });
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final kind in ['cash', 'bank', 'cash-move', 'bank-move']) {
        testWidgets(
            '$kind field edits and exact update payload ${design.name} ${brightness.name}',
            (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final writes = <http.Request>[];
          final capture = GlobalKey();
          final page = switch (kind) {
            'cash' => KasaTanimEklePage(editKasa: KasaDto.fromJson(cash)),
            'bank' =>
              BankaTanimEklePage(editBanka: BankahesapDto.fromJson(bank)),
            'cash-move' => KasahareketEklePage(
                editHareket:
                    KasahareketDto.fromJson({...movement, 'Islemtipi': 7})),
            _ => BankahareketEklePage(
                editHareket: BankahareketDto.fromJson(movement))
          };
          await http.runWithClient(() async {
            await tester.runAsync(() async {
              await tester.pumpWidget(RepaintBoundary(
                  key: capture,
                  child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.build(brightness, design: design),
                      initialRoute: '/edit',
                      routes: {
                        '/': (_) => const Scaffold(),
                        '/edit': (_) => page
                      })));
              await Future<void>.delayed(const Duration(milliseconds: 100));
            });
            await flush(tester);
            if (kind == 'cash') {
              final flag =
                  find.byKey(const ValueKey('cash-owner-Plasiyerkasasi'));
              await tester.ensureVisible(flag);
              await tester.tap(flag);
              await tester.pumpAndSettle();
            } else if (kind == 'bank') {
              await choose(tester, 'bank-account-Faizhesapplaniid',
                  '780.102 · Muavin 102');
              final clear = find.byTooltip('KKDF Hesabı temizle');
              await visible(tester, clear);
              await tester.tap(clear);
              await tester.pumpAndSettle();
            } else if (kind == 'bank-move') {
              await choose(tester, 'movement-Islemmasrafid', 'MS.002 · Kira');
              await visible(tester, find.text('Faiz ve Masraflar'));
              await tester.tap(find.text('Faiz ve Masraflar'));
              await tester.pumpAndSettle();
              final fx = find.byKey(const ValueKey('bank-charge-Faizdoviz'));
              await visible(tester, fx);
              await tester.enterText(fx, '2,5');
              await tester.pumpAndSettle();
            } else {
              await tester.tap(find.text('İşlem').first);
              await tester.pumpAndSettle();
              await choose(tester, 'movement-Islemmasrafid', 'MS.002 · Kira');
            }
            if (design == ErpDesign.modern && brightness == Brightness.dark) {
              await tester.runAsync(() async {
                final boundary = capture.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
                final image = await boundary.toImage(pixelRatio: 1);
                final bytes =
                    await image.toByteData(format: ui.ImageByteFormat.png);
                await File('tool/previews/finance_${kind}_fields_dark.png')
                    .writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            if (kind == 'cash-move') {
              await tester.tap(find.text('Detay').first);
              await tester.pumpAndSettle();
            }
            final save = find.text('Güncelle');
            await tester.ensureVisible(save.first);
            await tester.runAsync(() async {
              await tester.tap(save.first);
              await Future<void>.delayed(const Duration(milliseconds: 2700));
            });
            await tester.pumpAndSettle();
            expect(writes.length, 1);
            expect(find.byWidget(page), findsNothing);
            expect(writes.single.method, 'PUT');
            final body = jsonDecode(writes.single.body);
            if (kind == 'cash') {
              expect(body['Plasiyerkasasi'], false);
              expect(body['Plasiyerid'], null);
            }
            if (kind == 'bank') {
              expect(body['Faizhesapplaniid'], 102);
              expect(body['Kkdfhesapplaniid'], null);
              expect(body['Cezahesapplaniid'], 103);
            }
            if (kind.endsWith('move')) {
              expect(body['Islemmasrafid'], 2);
              expect(body['Projeid'], 1);
              expect(body['Plasiyerid'], 1);
            }
            if (kind == 'bank-move') {
              expect(body['Faiz'], 100.30864);
              expect(body['Faizdoviz'], 2.5);
              expect(body['Kkdf'], 12.345678);
              expect(body['Cezadoviz'], 0.307657);
              expect(body['Kur'], 40.123456);
            }
            if (kind == 'cash-move') {
              expect(body['Masraf'], 3.125678);
            }
            expect(tester.takeException(), null);
            await tester.pump(const Duration(seconds: 6));
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
              () => MockClient((r) async {
                    if (r.method != 'GET' && !r.url.path.contains('/VW_')) {
                      writes.add(r);
                      return http.Response('', 204);
                    }
                    return lookups(r);
                  }));
        });
      }
    }
  }
  testWidgets('new salesperson cash requires an owner and sends the selection',
      (tester) async {
    final writes = <http.Request>[];
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.build(Brightness.light),
          initialRoute: '/new',
          routes: {
            '/': (_) => const Scaffold(),
            '/new': (_) => const KasaTanimEklePage()
          }));
      await flush(tester);
      await tester.enterText(
          find.byWidgetPredicate((w) =>
              w is TextField && w.decoration?.labelText == 'Kasa Kodu *'),
          'KS.NEW');
      await tester.enterText(
          find.byWidgetPredicate(
              (w) => w is TextField && w.decoration?.labelText == 'Kasa Adı *'),
          'Plasiyer Kasası');
      await tester.tap(find.byKey(const ValueKey('cash-owner-Plasiyerkasasi')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kasa Oluştur'));
      await tester.pumpAndSettle();
      expect(writes, isEmpty);
      await choose(tester, 'cash-owner-Plasiyerid', 'Test Temsilcisi');
      await tester.runAsync(() async {
        await tester.tap(find.text('Kasa Oluştur'));
        await Future<void>.delayed(const Duration(milliseconds: 2700));
      });
      await tester.pumpAndSettle();
      expect(writes.length, 1);
      expect(writes.single.method, 'POST');
      final body = jsonDecode(writes.single.body);
      expect(body['Plasiyerkasasi'], true);
      expect(body['Plasiyerid'], 1);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
        () => MockClient((r) async {
              if (r.method != 'GET') {
                writes.add(r);
                return data(1);
              }
              return lookups(r);
            }));
  });
  testWidgets('new collection keeps bank type disabled per user instruction',
      (tester) async {
    await http.runWithClient(() async {
      await tester.runAsync(() async {
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.build(Brightness.light),
            home: const TahsilatEklePage()));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await flush(tester);
      final types = find.byWidgetPredicate((w) =>
          w is DropdownButton<int> &&
          w.items!.map((e) => e.value).toList().toString() == '[1, 3]');
      expect(types, findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }, () => MockClient((r) async => lookups(r)));
  });
}

Future<void> flush(WidgetTester tester) async {
  await tester.pump();
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, String key, String label) async {
  final field = find.byKey(ValueKey(key));
  await visible(tester, field);
  await tester.tap(field);
  await flush(tester);
  await tester.tap(find.text(label).last);
  await flush(tester);
}

Future<void> visible(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 3; i++) {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }
}
