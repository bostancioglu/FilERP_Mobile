import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/widgets/mobile_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await font.load();
    await icons.load();
  });
  for (final brightness in Brightness.values) {
    testWidgets('Dashboard works at narrow width in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opened = false;
      final module = DashboardModule('Fatura', 'Satış ve alış belgeleri',
          Icons.receipt_outlined, () => opened = true);
      await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(brightness),
          home: Scaffold(
            body: MobileDashboard(
                userName: 'Kars',
                company: 'Örnek Şirket',
                branch: 'Merkez',
                sales: [module],
                inventory: [
                  DashboardModule(
                      'Stok', 'Ürünler', Icons.inventory_2_outlined, () {})
                ],
                finance: [
                  DashboardModule(
                      'Cari', 'Müşteriler', Icons.people_outline, () {})
                ],
                onReports: () {}),
          )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ÇALIŞMA ALANINIZ'), findsNothing);
      expect(find.text('Merhaba, Kars'), findsNothing);
      expect(find.text('Günlük işlerinize devam edin'), findsNothing);
      expect(find.text('Satış ve alış belgeleri'), findsOneWidget);
      await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
              '../tool/previews/dashboard_${brightness.name}.png'));
      await tester.tap(find.text('Fatura').first);
      expect(opened, isTrue);
      await tester.tap(find.byKey(const ValueKey('quick-access-edit')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Cari'));
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Raporlar'));
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('dashboard_quick_access_v1_Kars'),
          ['Fatura', 'Stok', 'Raporlar']);
      expect(find.text('Cari'), findsOneWidget);
      expect(find.text('Raporlar'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('quick-access-edit')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Stok'));
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(prefs.getStringList('dashboard_quick_access_v1_Kars'),
          ['Fatura', 'Stok', 'Raporlar']);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(find.text('Cari'), findsOneWidget);
      expect(find.text('Raporlar'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Rapor Merkezi'), findsOneWidget);
    });
    testWidgets('Quick access scrolls horizontally in $brightness',
        (tester) async {
      final titles = List.generate(10, (i) => 'Kart ${i + 1}');
      SharedPreferences.setMockInitialValues(
          {'dashboard_quick_access_v1_Kars': titles});
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opened = false;
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.build(brightness),
          home: Scaffold(
              body: MobileDashboard(
            userName: 'Kars',
            company: '',
            branch: '',
            sales: [
              for (final title in titles)
                DashboardModule(title, '', Icons.receipt_outlined,
                    () => opened = title == 'Kart 10',
                    requiredModules: const [301])
            ],
            inventory: const [],
            finance: const [],
            onReports: () {},
          ))));
      await tester.pumpAndSettle();
      final grid = find.byKey(const ValueKey('quick-access-grid'));
      final gridWidget = tester.widget<GridView>(grid);
      final viewport = tester.getRect(grid);
      Rect card(String title) => tester.getRect(find
          .ancestor(
              of: find.descendant(of: grid, matching: find.text(title)),
              matching: find.byType(InkWell))
          .first);
      expect(card('Kart 1').top, card('Kart 2').top);
      expect(card('Kart 2').top, card('Kart 3').top);
      expect(card('Kart 2').left, greaterThan(card('Kart 1').left));
      expect(card('Kart 3').left, greaterThan(card('Kart 2').left));
      expect(card('Kart 4').top, greaterThan(card('Kart 1').bottom));
      expect(card('Kart 4').left, card('Kart 1').left);
      final sixthCard = tester.getRect(find
          .ancestor(
              of: find.descendant(of: grid, matching: find.text('Kart 6')),
              matching: find.byType(InkWell))
          .first);
      expect(sixthCard.right, lessThanOrEqualTo(viewport.right + .01));
      expect(sixthCard.left, greaterThan(viewport.left));
      expect(
          (gridWidget.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount,
          2);
      await tester.drag(grid, const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(gridWidget.controller!.offset, greaterThan(0));
      await tester
          .tap(find.descendant(of: grid, matching: find.text('Kart 10')));
      expect(opened, true);
      expect(tester.takeException(), isNull);
    });
  }
}
