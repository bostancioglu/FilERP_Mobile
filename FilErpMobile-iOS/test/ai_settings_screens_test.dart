import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/pages/ayarlar/ai_ayarlar_page.dart';
import 'package:FilERP/helpers/gunluk_kod_helper.dart';
import 'package:FilERP/services/ai/ai_settings_service.dart';
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
    for (final saved in [false, true]) {
      testWidgets('ai settings ${brightness.name} ${saved ? 'saved' : 'empty'}',
          (tester) async {
        const previewKey = 'preview-only-key-1234';
        SharedPreferences.setMockInitialValues(
            {if (saved) 'ai_anthropic_api_key': previewKey});
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final key = GlobalKey();
        final requests = <http.Request>[];
        var responseCode = 200;
        await http.runWithClient(() async {
          await tester.pumpWidget(RepaintBoundary(
              key: key,
              child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.build(brightness),
                  home: const AiAyarlarPage())));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.enterText(find.byType(TextField), 'invalid');
          await tester.tap(find.text('Giriş'));
          await tester.pumpAndSettle();
          expect(find.text('Kod hatalı.'), findsOneWidget);
          expect(find.text('Kaydet'), findsNothing);
          await tester.enterText(
              find.byType(TextField), GunlukKodHelper.hesapla().toString());
          await tester.tap(find.text('Giriş'));
          await tester.pumpAndSettle();
          expect(find.text('Kaydet'), findsOneWidget);
          expect(requests, isEmpty);
          await previews.captureReport(tester, key,
              'ai_settings_${saved ? 'saved' : 'empty'}_${brightness.name}');
          await tester.enterText(find.byType(TextField), previewKey);
          expect(tester.widget<TextField>(find.byType(TextField)).obscureText,
              isTrue);
          await tester.tap(find.byTooltip('Anahtarı Göster'));
          await tester.pumpAndSettle();
          expect(tester.widget<TextField>(find.byType(TextField)).obscureText,
              isFalse);
          await tester.tap(find.byTooltip('Anahtarı Gizle'));
          await tester.tap(find.text('Kaydet'));
          await tester.pumpAndSettle();
          expect(await AiSettingsService.instance.getApiKey(), previewKey);
          expect(
              tester.widget<TextField>(find.byType(TextField)).controller!.text,
              isEmpty);
          await tester.tap(find.text('Bağlantıyı Test Et'));
          await tester.pumpAndSettle();
          expect(find.text('Bağlantı başarılı.'), findsOneWidget);
          expect(requests.single.headers['x-api-key'], previewKey);
          responseCode = 401;
          await tester.tap(find.text('Bağlantıyı Test Et'));
          await tester.pumpAndSettle();
          expect(find.text('Test anahtarı geçersiz.'), findsOneWidget);
          tester.view.physicalSize = const Size(320, 740);
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Anahtar İşlemleri'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Anahtarı Sil'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Vazgeç'));
          await tester.pumpAndSettle();
          expect(await AiSettingsService.instance.getApiKey(), previewKey);
          await tester.tap(find.byTooltip('Anahtar İşlemleri'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Anahtarı Sil'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Sil'));
          await tester.pumpAndSettle();
          expect(await AiSettingsService.instance.getApiKey(), isNull);
          expect(find.text('Bağlantıyı Test Et'), findsNothing);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
            () => MockClient((r) async {
                  requests.add(r);
                  return http.Response(
                      jsonEncode(responseCode == 200
                          ? {'content': []}
                          : {
                              'error': {'message': 'Test anahtarı geçersiz.'}
                            }),
                      responseCode,
                      headers: {
                        'content-type': 'application/json; charset=utf-8'
                      });
                }));
      });
    }
  }
}
