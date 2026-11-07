import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FilERP/helpers/electronic_document_filter.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'package:FilERP/widgets/document_action_ui.dart';
import 'package:FilERP/widgets/invoice_modern_ui.dart';
import 'report_center_screens_test.dart' as previews;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final e in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  test('ERP excludes only portal and electronic documents', () {
    for (final state in <int?>[null, 0, 1, 2, 3, 4, 5]) {
      expect(ElectronicDocumentFilter.matches(state, null), isTrue);
      expect(ElectronicDocumentFilter.matches(state, -2),
          state != 1 && state != 3);
      expect(ElectronicDocumentFilter.matches(state, 1), state == 1);
      expect(ElectronicDocumentFilter.matches(state, 3), state == 3);
    }
  });
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final portal in [true, false]) {
        testWidgets(
            '${design.name} ${brightness.name} ${portal ? 'portal' : 'send'} confirmation',
            (tester) async {
          tester.view.physicalSize = const Size(390, 780);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final key = GlobalKey();
          bool? choice;
          await tester.pumpWidget(RepaintBoundary(
              key: key,
              child: MaterialApp(
                theme: AppTheme.build(brightness, design: design),
                debugShowCheckedModeBanner: false,
                home: Builder(
                    builder: (context) => Scaffold(
                        body: TextButton(
                            onPressed: () async => choice =
                                await DocumentSendDialog.show(context,
                                    title: portal
                                        ? 'Portala Gönder'
                                        : 'E-Fatura Gönder · TEST',
                                    documentNumber: 'SF2026000000123',
                                    portal: portal),
                            child: const Text('Aç')))),
              )));
          await tester.tap(find.text('Aç'));
          await tester.pumpAndSettle();
          await previews.captureReport(tester, key,
              'document_${portal ? 'portal' : 'send'}_${design.name}_${brightness.name}');
          tester.view.physicalSize = const Size(320, 640);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Vazgeç'));
          await tester.pumpAndSettle();
          expect(choice, false);
          await tester.tap(find.text('Aç'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(
              FilledButton, portal ? 'Portala Gönder' : 'Oluştur ve Gönder'));
          await tester.pumpAndSettle();
          expect(choice, true);
        });
      }
      testWidgets('${design.name} ${brightness.name} completed invoice actions',
          (tester) async {
        tester.view.physicalSize = const Size(390, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        String? choice;
        await tester.pumpWidget(RepaintBoundary(
            key: key,
            child: MaterialApp(
              theme: AppTheme.build(brightness, design: design),
              debugShowCheckedModeBanner: false,
              home: Builder(
                  builder: (context) => Scaffold(
                      body: TextButton(
                          onPressed: () async => choice =
                              await InvoiceCompletedDialog.show(context),
                          child: const Text('Aç')))),
            )));
        for (final item in {
          'Tahsilat Yap': 'tahsilat',
          'Yazdır': 'yazdir',
          'Kapat': 'kapat'
        }.entries) {
          await tester.tap(find.text('Aç'));
          await tester.pumpAndSettle();
          if (item.value == 'tahsilat') {
            await previews.captureReport(tester, key,
                'document_completed_${design.name}_${brightness.name}');
            tester.view.physicalSize = const Size(320, 640);
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(item.key));
          await tester.pumpAndSettle();
          expect(choice, item.value);
        }
      });
    }
  }
  testWidgets('electronic filter shows icons and returns ERP choice',
      (tester) async {
    int? electronic;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: InvoiceFilters(
      status: null,
      electronic: null,
      onStatus: (_) {},
      onElectronic: (value) => electronic = value,
    ))));
    await tester.tap(find.byTooltip('Filtreler'));
    await tester.pumpAndSettle();
    final erp = find.widgetWithText(ChoiceChip, 'ERP');
    expect(
        find.descendant(
            of: erp, matching: find.byIcon(Icons.inventory_2_outlined)),
        findsOneWidget);
    await tester.tap(erp);
    await tester.pumpAndSettle();
    expect(electronic, isNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Uygula'));
    await tester.pumpAndSettle();
    expect(electronic, ElectronicDocumentFilter.erp);
  });
}
