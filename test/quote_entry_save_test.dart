import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/pages/teklif/teklif_entry_page.dart';
import 'package:FilERP/services/cache/list_cache_service.dart';
import 'quote_screens_test.dart' as data;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cache;
  setUpAll(() async {
    cache = await Directory.systemTemp.createTemp('filerp_quote_save_');
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

  for (final sales in [true, false]) {
    testWidgets(
        '${sales ? 'sales' : 'purchase'} quote create with a line and save',
        (tester) async {
      SharedPreferences.setMockInitialValues(
          {'token_final': 'preview', 'sube_id': 1});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final writes = <http.Request>[];
      await http.runWithClient(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(MaterialApp(
              theme: AppTheme.build(Brightness.light),
              initialRoute: '/new',
              routes: {
                '/': (_) => const Scaffold(body: Text('Teklif Listesi')),
                '/new': (_) => TeklifEntryPage(sales: sales),
              }));
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();
        expect(find.text('Yeniden Dene'), findsNothing);
        // Missing customer must prevent writes.
        await tester.tap(find.text('Kalemler').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kaydet'));
        await tester.pumpAndSettle();
        expect(find.text('Lütfen cari seçiniz.'), findsOneWidget);
        expect(writes, isEmpty);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Belge').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cari').first);
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('CR.001').last);
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kalem ekle'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Stok'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('ST.001').last);
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        final fields = find.descendant(
            of: find.byType(Dialog).last, matching: find.byType(TextField));
        await tester.enterText(fields.at(0), '2');
        await tester.enterText(fields.at(1), '100');
        tester.testTextInput.hide();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.ensureVisible(find.text('Ekle').last);
        await tester.tap(find.text('Ekle').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Özet').first);
        await tester.pumpAndSettle();
        expect(find.text('240,00 ₺'), findsWidgets);
        if (sales) {
          await tester.tap(find.byTooltip('Kaydetme seçenekleri'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Kaydet ve Tamamla'));
        } else {
          await tester.tap(find.text('Kaydet'));
        }
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 150));
        });
        await tester.pumpAndSettle();
        expect(find.text('Teklif Listesi'), findsOneWidget);
        expect(
            writes.first.url.path,
            sales
                ? '/api/Teklif/SaveWithItems'
                : '/api/TeklifAlis/SaveWithItems');
        final body = jsonDecode(writes.first.body) as Map;
        expect(body['Cariid'], 1);
        expect(body['Geneltoplam'], 240);
        expect(body['Gecerliliktarihi'], isNotNull);
        expect(body['Tahsilattarihi'], isNotNull);
        expect(body['Vadetarihi'], isNotNull);
        final line = (body['Teklifhareket'] as List).single as Map;
        expect(line['Miktar'], 2);
        expect(line['Fiyat'], 100);
        expect(line['Olcubrid'], 1);
        expect(line.containsKey('Id'), isFalse);
        expect(writes.length, sales ? 2 : 1);
        if (sales)
          expect(writes.last.url.path, '/api/Teklif/Complete/quote-created');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
          () => MockClient((request) async {
                Object? result;
                if (request.method != 'GET') {
                  writes.add(request);
                  result = request.url.path.endsWith('SaveWithItems')
                      ? 'quote-created'
                      : null;
                } else {
                  result = data.fixture(request.url.path);
                  if (RegExp(r'/Stok/1$').hasMatch(request.url.path)) {
                    result = {
                      ...data.product,
                      'Kdvsatis': 20,
                      'Temelolcubr': {'Id': 1, 'Ad': 'Adet', 'Kod': 'AD'}
                    };
                  }
                }
                return http.Response(jsonEncode({'Data': result}), 200,
                    headers: {
                      'content-type': 'application/json; charset=utf-8'
                    });
              }));
    });
  }
}
