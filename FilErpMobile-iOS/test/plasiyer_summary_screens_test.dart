import 'package:FilERP/theme/theme_controller.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/services/cache/list_cache_service.dart';
import 'package:FilERP/pages/rapor/plasiyer/plasiyer_ozeti_page.dart';
import 'report_center_screens_test.dart' as previews;

void main() {
  late Directory cache;
  setUpAll(() async {
    cache = await Directory.systemTemp.createTemp('plasiyer_summary_');
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
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final locked in [true, false]) {
        testWidgets(
            'plasiyer ${locked ? 'locked' : 'manager'} ${design.name}_${brightness.name}',
            (tester) async {
          final claim = base64Url.encode(utf8.encode(jsonEncode({
            'G129-134F-4323':
                jsonEncode({'Plasiyermi': locked, 'Plasiyerid': 1})
          })));
          SharedPreferences.setMockInitialValues(
              {'token_final': 'x.$claim.x', 'sube_id': 1});
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          final key = GlobalKey();
          final requests = <http.Request>[];
          await http.runWithClient(() async {
            await tester.runAsync(() async {
              await tester.pumpWidget(RepaintBoundary(
                  key: key,
                  child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.build(brightness, design: design),
                      home: const PlasiyerOzetiPage())));
              await Future<void>.delayed(const Duration(milliseconds: 1800));
            });
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (locked) {
              expect(find.text('Genel Özet'), findsOneWidget);
              expect(find.text('Güncel Satış'), findsOneWidget);
              final amountTexts = find.byWidgetPredicate(
                  (w) => w is Text && (w.data?.endsWith(' ₺') ?? false));
              final positions = amountTexts
                  .evaluate()
                  .map((e) => tester.getTopRight(find.byWidget(e.widget)).dx)
                  .toList();
              expect(positions.length, 10);
              for (final x in positions) {
                expect(x, closeTo(positions.first, .5));
              }
              await previews.captureReport(tester, key,
                  'plasiyer_summary_${design.name}_${brightness.name}');
              await tester.tap(find.byTooltip('Dışa Aktar'));
              await tester.pumpAndSettle();
              expect(find.text("PDF'e Aktar"), findsOneWidget);
              expect(find.text('Yazdır'), findsOneWidget);
              Navigator.of(tester.element(find.text('Yazdır'))).pop();
              await tester.pumpAndSettle();
              await tester.tap(find.text('Toplam Tahsilat'));
              await tester.pumpAndSettle();
              expect(find.byType(DraggableScrollableSheet), findsOneWidget);
              await previews.captureReport(tester, key,
                  'plasiyer_collections_${design.name}_${brightness.name}');
              Navigator.of(
                      tester.element(find.byType(DraggableScrollableSheet)))
                  .pop();
              await tester.pumpAndSettle();
              await tester.tap(find.byTooltip('Filtreler'));
              await tester.pumpAndSettle();
              expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
            }
            expect(find.text('Filtreler'), findsOneWidget);
            await previews.captureReport(tester, key,
                'plasiyer_filters_${locked}_${design.name}_${brightness.name}');
            tester.view.physicalSize = const Size(320, 740);
            tester.view.viewInsets = const FakeViewPadding(bottom: 300);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            tester.view.resetViewInsets();
            Navigator.of(tester.element(find.text('Filtreler'))).pop();
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (locked) {
              await tester.scrollUntilVisible(find.text('Stok Durumu'), 250,
                  scrollable: find.byType(Scrollable).first);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
            expect(
                requests.where((r) =>
                    r.method != 'GET' &&
                    !(r.method == 'POST' && r.url.path.contains('/VW_'))),
                isEmpty);
            await tester.pump(const Duration(seconds: 2));
            await tester.runAsync(() async {
              await Future<void>.delayed(const Duration(milliseconds: 800));
            });
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
              () => MockClient((r) async {
                    requests.add(r);
                    final now = DateTime.now();
                    final date = DateTime(now.year, now.month, now.day, 12)
                        .toIso8601String();
                    final path = r.url.path;
                    Object data = [];
                    if (path.contains('/Plasiyer/'))
                      data = [
                        {'Id': 1, 'Kod': 'P01', 'Adsoyad': 'Kars Temsilcisi'}
                      ];
                    else if (path.contains('/Depo'))
                      data = [
                        {
                          'Id': 1,
                          'Kod': 'D01',
                          'Ad': 'Araç Deposu',
                          'Plasiyerdeposu': true,
                          'Plasiyerid': 1
                        }
                      ];
                    else if (path.endsWith('/Fatura'))
                      data = [
                        {
                          'Id': 'invoice1',
                          'Tarih': date,
                          'Plasiyerid': 1,
                          'Belgedurum': 1,
                          'Geneltoplam': 2400,
                          'Belgeserino': 'SF2026000000001',
                          'Cariid': 1
                        }
                      ];
                    else if (path.contains('/Tahsilat'))
                      data = [
                        {
                          'Id': 'collection1',
                          'Tarih': date,
                          'Plasiyerid': 1,
                          'Tahsilattutari': 1500,
                          'Tip': 1,
                          'Islembelgeid': 'invoice1',
                          'Belgeserino': 'TH2026000000001',
                          'Cariid': 1
                        }
                      ];
                    else if (path.contains('VW_Finanskasahareket'))
                      data = [
                        {
                          'Kasaid': 1,
                          'Kasakod': 'K01',
                          'Kasaisim': 'Merkez Kasa',
                          'Giriscikis': 1,
                          'Tutar': 1500,
                          'Belgeturu': 72
                        }
                      ];
                    else if (path.endsWith('/Cari'))
                      data = [
                        {'Id': 1, 'Kod': 'CR.001', 'Ad': 'Marmara Gıda'}
                      ];
                    else if (path.contains('/Doviz'))
                      data = [
                        {'Id': 1, 'Ad': 'Türk Lirası', 'Birim': 'TL'}
                      ];
                    return http.Response(jsonEncode({'Data': data}), 200,
                        headers: {
                          'content-type': 'application/json; charset=utf-8'
                        });
                  }));
        });
      }
    }
  }
}
