import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FilERP/widgets/document_filter_button.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';

void main() {
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 1.8]) {
        testWidgets(
            'compact filters ${design.name} ${brightness.name} scale=$scale apply cancel and reset',
            (tester) async {
          tester.view.physicalSize = const Size(320, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var selected = const DocumentFilterSelection();
          var applications = 0;
          await tester.pumpWidget(MaterialApp(
              theme: AppTheme.build(brightness, design: design),
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!),
              home: StatefulBuilder(
                  builder: (context, update) => Scaffold(
                      body: SafeArea(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextField(
                                  decoration: InputDecoration(
                                      hintText: 'Fatura / Cari',
                                      suffixIcon: DocumentFilterButton(
                                          status: selected.status,
                                          electronic: selected.electronic,
                                          showElectronic: true,
                                          onApply: (value) => update(() {
                                                selected = value;
                                                applications++;
                                              }))))))))));
          await tester.pumpAndSettle();
          expect(find.byType(ChoiceChip), findsNothing);
          expect(tester.getSize(find.byType(TextField)).height, lessThan(110));
          await tester.tap(find.byTooltip('Filtreler'));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('filter-status-0')));
          await tester
              .ensureVisible(find.byKey(const ValueKey('filter-electronic-1')));
          await tester.tap(find.byKey(const ValueKey('filter-electronic-1')));
          await tester.pumpAndSettle();
          expect(applications, 0);
          await tester.tap(find.byTooltip('Filtreleri kapat'));
          await tester.pumpAndSettle();
          expect(applications, 0);
          await tester.tap(find.byTooltip('Filtreler'));
          await tester.pumpAndSettle();
          expect(
              tester
                  .widget<ChoiceChip>(
                      find.byKey(const ValueKey('filter-status-all')))
                  .selected,
              isTrue);
          await tester.tap(find.byKey(const ValueKey('filter-status-0')));
          await tester
              .ensureVisible(find.byKey(const ValueKey('filter-electronic-1')));
          await tester.tap(find.byKey(const ValueKey('filter-electronic-1')));
          await tester.tap(find.widgetWithText(FilledButton, 'Uygula'));
          await tester.pumpAndSettle();
          expect((selected.status, selected.electronic), (0, 1));
          expect(applications, 1);
          expect(find.text('2'), findsOneWidget);
          expect(find.byType(ChoiceChip), findsNothing);
          await tester.tap(find.byTooltip('Filtreler'));
          await tester.pumpAndSettle();
          expect(
              tester
                  .widget<ChoiceChip>(
                      find.byKey(const ValueKey('filter-status-0')))
                  .selected,
              isTrue);
          await tester.tap(find.widgetWithText(OutlinedButton, 'Sıfırla'));
          await tester.pumpAndSettle();
          expect(applications, 1);
          await tester.tap(find.widgetWithText(FilledButton, 'Uygula'));
          await tester.pumpAndSettle();
          expect((selected.status, selected.electronic), (null, null));
          expect(applications, 2);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  testWidgets('status-only lists have no electronic options', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DocumentFilterButton(status: null, onApply: (_) {}))));
    await tester.tap(find.byTooltip('Filtreler'));
    await tester.pumpAndSettle();
    expect(find.text('Gönderim Durumu'), findsNothing);
    expect(find.text('Portal'), findsNothing);
    expect(find.text('Taslak'), findsOneWidget);
  });
}
