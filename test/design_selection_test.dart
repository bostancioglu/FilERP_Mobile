import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'package:FilERP/pages/ayarlar/tema_secim_page.dart';
import 'package:FilERP/pages/ana_sayfa_yeni_tasarim_page.dart';
import 'package:FilERP/services/cache/list_cache_service.dart';
import 'package:FilERP/services/offline/offline_service.dart';
import 'report_center_screens_test.dart' as previews;

void main() {
  late Directory cache;
  setUpAll(() async {
    cache = await Directory.systemTemp.createTemp('design_selection_');
    Hive.init(cache.path);
    SharedPreferences.setMockInitialValues({});
    await ListCacheService.instance.init();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (call) async => call.method == 'check' ? ['none'] : null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
        (_) async => null);
    await OfflineService.instance.init();
    for (final e in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  tearDownAll(() async {
    OfflineService.instance.dispose();
    await Hive.close();
    await cache.delete(recursive: true);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({'token_final': 'preview'});
    await ThemeController.load();
  });
  testWidgets('Design and brightness are selected, restored and reversible',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: boundary,
        child: AnimatedBuilder(
            animation: Listenable.merge([designNotifier, themeNotifier]),
            builder: (_, __) => MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.build(Brightness.light,
                      design: designNotifier.value),
                  darkTheme: AppTheme.build(Brightness.dark,
                      design: designNotifier.value),
                  themeMode: themeNotifier.value,
                  home: const TemaSecimPage(),
                ))));
    await tester.tap(find.byKey(const ValueKey('design-modern')));
    await tester.pumpAndSettle();
    expect(designNotifier.value, ErpDesign.modern);
    await tester.ensureVisible(find.text('Koyu'));
    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();
    expect(themeNotifier.value, ThemeMode.dark);
    await previews.captureReport(tester, boundary, 'design_selection_dark');
    designNotifier.value = ErpDesign.classic;
    themeNotifier.value = ThemeMode.light;
    await ThemeController.load();
    expect(designNotifier.value, ErpDesign.modern);
    expect(themeNotifier.value, ThemeMode.dark);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('design-classic')));
    await tester.tap(find.byKey(const ValueKey('design-classic')));
    await tester.pumpAndSettle();
    expect(designNotifier.value, ErpDesign.classic);
    expect(tester.takeException(), isNull);
  });
  for (final brightness in Brightness.values) {
    testWidgets(
        'Modern quick access edits persists and scrolls ${brightness.name}',
        (tester) async {
      final selected = [
        'Fatura',
        'Stok',
        'Cari',
        'Teklif',
        'İrsaliye',
        'Sipariş',
        'Ambar G/Ç'
      ];
      SharedPreferences.setMockInitialValues(
          {'modern_quick_access_v1_demo': selected});
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      var opened = '';
      final app = RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(brightness, design: ErpDesign.modern),
            home: AnaSayfaYeniTasarimPage(
                kullanici: 'demo',
                firma: 'Örnek Şirket',
                sube: 'Merkez',
                aksiyonlar: {
                  for (final title in [
                    ...selected,
                    'Finans',
                    'Depo',
                    'Raporlama'
                  ])
                    title: () => opened = title
                }),
          ));
      await http.runWithClient(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(app);
          await Future<void>.delayed(const Duration(milliseconds: 1200));
        });
        await tester.pumpAndSettle();
        final quick = find.byKey(const ValueKey('modern-quick-list'));
        final fatura =
            find.descendant(of: quick, matching: find.text('Fatura'));
        final stok =
            find.descendant(of: quick, matching: find.text('Stok\nSorgu'));
        expect(
            (tester.getTopLeft(fatura).dy - tester.getTopLeft(stok).dy).abs(),
            lessThan(1));
        await previews.captureReport(
            tester, boundary, 'modern_quick_access_${brightness.name}');
        await tester.drag(quick, const Offset(-1000, 0));
        await tester.pumpAndSettle();
        await tester
            .tap(find.descendant(of: quick, matching: find.text('Ambar\nG/Ç')));
        await tester.pumpAndSettle();
        expect(opened, 'Ambar G/Ç');
        await tester.tap(find.byKey(const ValueKey('modern-quick-edit')));
        await tester.pumpAndSettle();
        for (final label in ['Stok', 'Finans']) {
          final tile = find.widgetWithText(CheckboxListTile, label);
          await tester.ensureVisible(tile);
          await tester.tap(tile);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Kaydet'));
        await tester.pumpAndSettle();
        final prefs = await SharedPreferences.getInstance();
        final saved = prefs.getStringList('modern_quick_access_v1_demo')!;
        expect(saved, contains('Finans'));
        expect(saved, isNot(contains('Stok')));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          await tester.pumpWidget(app);
          await Future<void>.delayed(const Duration(milliseconds: 1200));
        });
        await tester.pumpAndSettle();
        expect(find.descendant(of: quick, matching: find.text('Stok\nSorgu')),
            findsNothing);
        await tester.drag(quick, const Offset(-1000, 0));
        await tester.pumpAndSettle();
        expect(find.descendant(of: quick, matching: find.text('Finans')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
          () => MockClient((_) async => http.Response('{"Data":[]}', 200,
              headers: {'content-type': 'application/json; charset=utf-8'})));
    });

    testWidgets('Modern home and filtered module actions ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      var opened = '';
      await http.runWithClient(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.build(brightness, design: ErpDesign.modern),
                home: AnaSayfaYeniTasarimPage(
                    kullanici: 'demo',
                    firma: 'FilERP Ticaret',
                    sube: 'Kars',
                    aksiyonlar: {
                      for (final title in [
                        'Fatura',
                        'Teklif',
                        'Sipariş',
                        'Ayarlar'
                      ])
                        title: () => opened = title
                    }),
              )));
          for (var frame = 0; frame < 10; frame++) {
            await tester.pump();
            await Future<void>.delayed(const Duration(milliseconds: 250));
          }
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await previews.captureReport(
            tester, boundary, 'design_modern_home_${brightness.name}');
        for (final title in ['Fatura', 'Teklif', 'Sipariş']) {
          await tester.enterText(find.byType(TextField), title);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text(title).last);
          await tester.tap(find.text(title).last);
          await tester.pumpAndSettle();
          expect(opened, title);
        }
        await tester.tap(find.text('Ayarlar'));
        await tester.pumpAndSettle();
        expect(opened, 'Ayarlar');
      },
          () => MockClient((request) async => http.Response('{"Data":[]}', 200,
              headers: {'content-type': 'application/json'})));
    });
  }
}
