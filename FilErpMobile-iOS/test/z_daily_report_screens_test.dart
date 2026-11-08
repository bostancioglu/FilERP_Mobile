import 'package:FilERP/theme/theme_controller.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/pages/rapor/kasa/z_raporu.dart';
import 'package:FilERP/pages/rapor/genel/gunluk_ozet_page.dart';
import 'report_center_screens_test.dart' as previews;

void main() {
  setUpAll(() async {
    for (final e in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final z in [true, false]) {
        testWidgets(
            '${z ? 'z_report' : 'daily_summary'} ${design.name}_${brightness.name}',
            (tester) async {
          SharedPreferences.setMockInitialValues({'token_final': 'preview'});
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final key = GlobalKey();
          final requests = <http.Request>[];
          await http.runWithClient(() async {
            await tester.runAsync(() async {
              await tester.pumpWidget(RepaintBoundary(
                  key: key,
                  child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.build(brightness, design: design),
                      home: z ? const ZRaporuPage() : const GunlukOzetPage())));
              await Future<void>.delayed(const Duration(milliseconds: 500));
            });
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (z) {
              await tester.tap(find.text('Sorgula'));
              await tester.pumpAndSettle();
              expect(find.byTooltip('Yazdır'), findsOneWidget);
              expect(find.text('2.400,00 ₺'), findsOneWidget);
              expect(find.text('500,00 ₺'), findsOneWidget);
              await tester.tap(find.byType(Switch));
              await tester.pumpAndSettle();
              expect(find.text('Marmara Gıda'), findsOneWidget);
              expect(find.text('Eski İşlem'), findsNothing);
            }
            await previews.captureReport(tester, key,
                '${z ? 'z_report' : 'daily_summary'}_${design.name}_${brightness.name}');
            if (!z) {
              for (final title in [
                'Kasa',
                'Satış Faturası',
                'Satış İrsaliyesi',
                'Satış Siparişi',
                'Depolar Arası Transfer'
              ]) {
                final f = find.text(title);
                expect(f, findsOneWidget);
                await tester.ensureVisible(f);
                await tester.tap(f);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                if (find
                    .byType(DraggableScrollableSheet)
                    .evaluate()
                    .isNotEmpty) {
                  if (title == 'Kasa')
                    await previews.captureReport(tester, key,
                        'daily_cash_details_${design.name}_${brightness.name}');
                  tester.view.physicalSize = const Size(320, 740);
                  await tester.pumpAndSettle();
                  expect(tester.takeException(), isNull);
                  Navigator.of(
                          tester.element(find.byType(DraggableScrollableSheet)))
                      .pop();
                  await tester.pumpAndSettle();
                }
              }
            }
            tester.view.physicalSize = const Size(320, 740);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(requests.every((r) => r.method == 'GET'), isTrue);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
              () => MockClient((r) async {
                    requests.add(r);
                    final now = DateTime.now();
                    final date = DateTime(now.year, now.month, now.day, 12)
                        .toIso8601String();
                    Object data = [];
                    final path = r.url.path;
                    if (path.contains('/Kasa/'))
                      data = [
                        {'Id': 1, 'Kod': 'K01', 'Ad': 'Merkez Kasa'}
                      ];
                    else if (path.contains('/Kasahareket/'))
                      data = [
                        {
                          'Id': 'a',
                          'Tarih': date,
                          'Giriscikis': 1,
                          'Tutar': 2400,
                          'Islemtipi': 1,
                          'Islemcari': {'Ad': 'Marmara Gıda'},
                          'Aciklama': 'Fatura tahsilatı'
                        },
                        {
                          'Id': 'b',
                          'Tarih': date,
                          'Giriscikis': 2,
                          'Tutar': 500,
                          'Aciklama': 'Tedarikçi ödemesi'
                        },
                        {
                          'Id': 'c',
                          'Tarih': '2000-01-01',
                          'Giriscikis': 1,
                          'Tutar': 99999,
                          'Aciklama': 'Eski İşlem'
                        }
                      ];
                    else if (path.endsWith('/Fatura') ||
                        path.endsWith('/Irsaliye') ||
                        path.endsWith('/Siparis') ||
                        path.endsWith('/Dat'))
                      data = [
                        {
                          'Id': 'doc1',
                          'Tarih': date,
                          'Belgedurum': 1,
                          'Belgeserino': 'SF2026000000001',
                          'Geneltoplam': 2400
                        },
                        {
                          'Id': 'draft',
                          'Tarih': date,
                          'Belgedurum': 0,
                          'Geneltoplam': 99999
                        }
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
