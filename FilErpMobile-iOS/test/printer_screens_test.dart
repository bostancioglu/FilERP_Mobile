import 'package:FilERP/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/pages/ayarlar/yazici_ayarlar_page.dart';
import 'package:FilERP/pages/ayarlar/yazici_sablon_listesi_page.dart';
import 'package:FilERP/services/yazici/yazici_sablon_service.dart';
import 'report_center_screens_test.dart' as previews;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (call) async {
      if (call.method == 'requestPermissions')
        return {for (final id in call.arguments as List) id: 1};
      return 1;
    });
    messenger.setMockMethodCallHandler(
        const MethodChannel('groons.web.app/print'),
        (call) async => call.method == 'pairedbluetooths'
            ? ['Test Yazıcısı#00:11:22:33:44:55']
            : false);
    for (final e in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final screen in ['printer', 'printer_saved', 'templates']) {
        testWidgets('$screen ${design.name}_${brightness.name}',
            (tester) async {
          SharedPreferences.setMockInitialValues({
            if (screen == 'printer_saved') ...{
              'bt_printer_mac': '00:11:22:33:44:55',
              'bt_printer_name': 'Test Yazıcısı'
            }
          });
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          final previousError = FlutterError.onError;
          FlutterError.onError = (details) {
            if (details.exceptionAsString().contains('overflowed'))
              debugPrint(details.toString());
            previousError?.call(details);
          };
          addTearDown(() => FlutterError.onError = previousError);
          final key = GlobalKey();
          await tester.runAsync(() async {
            await tester.pumpWidget(RepaintBoundary(
                key: key,
                child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.build(brightness, design: design),
                    home: screen == 'templates'
                        ? const YaziciSablonListesiPage()
                        : const YaziciAyarlarPage())));
            await Future<void>.delayed(const Duration(milliseconds: 500));
          });
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await previews.captureReport(
              tester, key, '${screen}_${design.name}_${brightness.name}');
          if (screen == 'templates') {
            await tester.tap(find.byTooltip('Şablon İşlemleri').first);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Sil'));
            await tester.pumpAndSettle();
            expect(find.text('Şablonu Sil'), findsOneWidget);
            await tester.tap(find.text('İptal'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Yeni Şablon'));
            await tester.pumpAndSettle();
            await tester.enterText(
                find.byType(TextField).first, 'Kompakt Etiket');
            for (final type in [
              'Alan',
              'Metin',
              'Barkod',
              'Ayırıcı',
              'Boşluk',
              'Logo'
            ]) {
              await tester.ensureVisible(find.text('Satır Ekle'));
              await tester.tap(find.text('Satır Ekle'));
              await tester.pumpAndSettle();
              await tester.tap(find.text(type).first);
              await tester.pumpAndSettle();
              if (type == 'Metin')
                await tester.enterText(
                    find.byType(TextField).last, 'FilERP Mobile');
              tester.view.physicalSize = const Size(320, 740);
              tester.view.viewInsets = const FakeViewPadding(bottom: 260);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              tester.view.resetViewInsets();
              await tester.pumpAndSettle();
              await tester.ensureVisible(find.text('Ekle'));
              await tester.tap(find.text('Ekle'));
              await tester.pumpAndSettle();
            }
            expect(find.text('6 satır'), findsOneWidget);
            await previews.captureReport(tester, key,
                'template_editor_${design.name}_${brightness.name}');
            await tester.tap(find.text('Kaydet'));
            await tester.pumpAndSettle();
            final saved = (await YaziciSablonService.instance.getSablonlar())
                .where((s) => s.ad == 'Kompakt Etiket')
                .single;
            expect(saved.satirlar.length, 6);
            expect(saved.satirlar[1].staticMetin, 'FilERP Mobile');
          } else {
            await tester.ensureVisible(find.text('58mm'));
            await tester.tap(find.text('58mm'));
            await tester.pumpAndSettle();
            final prefs = await SharedPreferences.getInstance();
            expect(prefs.getInt('yazici_kagit_eni'), 58);
            expect(prefs.getInt('yazici_satir_genisligi'), 32);
            tester.view.physicalSize = const Size(320, 740);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.scrollUntilVisible(find.text('Şablonları Yönet'), 200,
                scrollable: find.byType(Scrollable).first);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        });
      }
    }
  }
}
