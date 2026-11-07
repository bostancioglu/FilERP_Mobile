import 'package:FilERP/theme/theme_controller.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/pages/plasiyer/plasiyer_harita_page.dart';
import 'report_center_screens_test.dart' as previews;

class TestTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII='));
}

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
      for (final state in ['data', 'empty', 'error', 'denied']) {
        testWidgets('locations $state ${design.name}_${brightness.name}',
            (tester) async {
          final previousShadows = debugDisableShadows;
          debugDisableShadows = false;
          addTearDown(() => debugDisableShadows = previousShadows);
          SharedPreferences.setMockInitialValues({'token_final': 'preview'});
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final capture = GlobalKey();
          final requests = <http.Request>[];
          await http.runWithClient(() async {
            await tester.runAsync(() async {
              await tester.pumpWidget(RepaintBoundary(
                  key: capture,
                  child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.build(brightness, design: design),
                      home: PlasiyerHaritaPage(tileProvider: TestTiles()))));
              await Future<void>.delayed(const Duration(milliseconds: 500));
            });
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (state == 'data') {
              expect(find.text('1 Konum'), findsOneWidget);
              await tester.tap(find.byTooltip('Tüm Konumlar'));
              await tester.pumpAndSettle();
              await previews.captureReport(tester, capture,
                  'locations_${design.name}_${brightness.name}');
              await tester.tap(find.text('Kars Temsilcisi').last);
              await tester.pumpAndSettle();
              expect(find.text('Haritada Göster'), findsOneWidget);
              await tester.tap(find.text('Haritada Göster'));
              await tester.pumpAndSettle();
              await tester.scrollUntilVisible(
                  find.text('Erzurum Temsilcisi'), 80,
                  scrollable: find.byType(Scrollable).last);
              await tester.tap(find.text('Erzurum Temsilcisi'));
              await tester.pumpAndSettle();
              expect(find.text('Haritada Göster'), findsNothing);
              Navigator.of(tester.element(find.text('Erzurum Temsilcisi').last))
                  .pop();
              await tester.pumpAndSettle();
              final before = requests.length;
              await tester.tap(find.byTooltip('Yenile'));
              await tester.runAsync(() async {
                await Future<void>.delayed(const Duration(milliseconds: 500));
              });
              await tester.pumpAndSettle();
              expect(requests.length, greaterThan(before));
            } else if (state == 'empty') {
              expect(find.text('Konum bulunamadı'), findsOneWidget);
            } else if (state == 'error') {
              expect(find.text('Tekrar Dene'), findsOneWidget);
            }
            tester.view.physicalSize = const Size(320, 740);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
                requests.every((r) =>
                    r.method == 'GET' &&
                    r.url.path.endsWith('/Plasiyerkonum/Son')),
                isTrue);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
              () => MockClient((r) async {
                    requests.add(r);
                    return http.Response(
                        jsonEncode({
                          'Data': state == 'data'
                              ? [
                                  {
                                    'Plasiyerid': 1,
                                    'PlasiyerAdi': 'Kars Temsilcisi',
                                    'Enlem': 40.6013,
                                    'Boylam': 43.0975,
                                    'Tarih': DateTime.now()
                                        .subtract(const Duration(minutes: 3))
                                        .toIso8601String()
                                  },
                                  {
                                    'Plasiyerid': 2,
                                    'PlasiyerAdi': 'Erzurum Temsilcisi'
                                  }
                                ]
                              : [],
                          'Message': 'Konum verileri alınamadı'
                        }),
                        state == 'error'
                            ? 500
                            : state == 'denied'
                                ? 403
                                : 200,
                        headers: {
                          'content-type': 'application/json; charset=utf-8'
                        });
                  }));
          debugDisableShadows = previousShadows;
        });
      }
    }
  }
}
