import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/helpers/ui_feedback.dart';
import 'package:FilERP/helpers/response.dart';
import 'package:FilERP/widgets/yetki_hatasi_widget.dart';
import 'package:FilERP/widgets/fatura/fatura_genel_iskonto_sheet.dart';
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
  for (final brightness in Brightness.values) {
    testWidgets('Shared feedback and discount ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late BuildContext context;
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.build(brightness),
              home: Builder(builder: (ctx) {
                context = ctx;
                return const Scaffold(
                    body: Center(child: Text('FilERP Mobile')));
              }))));
      final cancelled = UiFeedback.confirm(context,
          title: 'Belge Silinsin mi?',
          message: 'Seçili belge silinecek.',
          destructive: true);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(await cancelled, false);
      final confirmed = UiFeedback.confirm(context,
          title: 'Belge Silinsin mi?',
          message: 'Seçili belge silinecek.',
          destructive: true);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Evet'));
      await tester.pumpAndSettle();
      expect(await confirmed, true);
      var retries = 0;
      final denied = UiFeedback.showException(context, const YetkiHatasi(),
          onYenile: () => retries++);
      await tester.pumpAndSettle();
      expect(find.text('Yetkisiz İşlem'), findsOneWidget);
      await tester.tap(find.text('Tekrar Dene'));
      await tester.pumpAndSettle();
      await denied;
      expect(retries, 1);
      final loading = UiFeedback.showLoading(context, text: 'Yükleniyor');
      await tester.pump();
      expect(find.text('Yükleniyor'), findsOneWidget);
      UiFeedback.hideLoading(loading);
      await tester.pump();
      expect(find.text('Yükleniyor'), findsNothing);
      final discount = showFaturaGenelIskontoSheet(context, araToplam: 1000);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '10');
      await tester.pumpAndSettle();
      expect(find.text('100.00'), findsOneWidget);
      await previews.captureReport(
          tester, boundary, 'followup_discount_${brightness.name}');
      await tester.tap(find.text('Uygula'));
      await tester.pumpAndSettle();
      final result = await discount;
      expect(result?.oran, 10);
      expect(result?.tutar, 100);
      expect(tester.takeException(), isNull);
    });
    testWidgets('Permission retry ${brightness.name}', (tester) async {
      var retries = 0;
      await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(brightness),
          home: Scaffold(body: YetkiHatasiWidget(onYenile: () => retries++))));
      await tester.tap(find.text('Tekrar Dene'));
      expect(retries, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
