import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> applyListFilters(WidgetTester tester,
    {int? status, int? electronic, bool electronicVisible = false}) async {
  await tester.tap(find.byTooltip('Filtreler'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('filter-status-${status ?? 'all'}')));
  if (electronicVisible) {
    await tester
        .tap(find.byKey(ValueKey('filter-electronic-${electronic ?? 'all'}')));
  }
  await tester.ensureVisible(find.widgetWithText(FilledButton, 'Uygula'));
  await tester.tap(find.widgetWithText(FilledButton, 'Uygula'));
  await tester.pumpAndSettle();
}
