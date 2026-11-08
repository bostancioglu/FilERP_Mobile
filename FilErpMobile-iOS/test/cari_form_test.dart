import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:FilERP/pages/cari/cari_ekle_page.dart';
import 'package:FilERP/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final entry in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });
  for (final brightness in Brightness.values) {
    testWidgets('Cari form: $brightness layout, tabs, validation and keyboard',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      var writes = 0;
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(brightness),
          initialRoute: '/cari',
          routes: {
            '/': (_) => const Scaffold(),
            '/cari': (_) => const CariEklePage()
          },
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Yeni Cari'), findsOneWidget);
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
                '../tool/previews/cari_form_${brightness.name}.png'));
        // Empty required fields must prevent any write request.
        await tester.tap(find.text('Cari kartını oluştur'));
        await tester.pumpAndSettle();
        expect(find.text('Zorunlu alan'), findsWidgets);
        expect(writes, 0);
        final code = find.byType(TextFormField).first;
        await tester.enterText(code, 'CR.0001');
        await tester.enterText(
            find.byType(TextFormField).at(1), 'Örnek Ticaret Ltd. Şti.');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        tester.testTextInput.hide();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.tap(find.text('Adres'));
        await tester.pumpAndSettle();
        expect(find.text('Konum'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
                '../tool/previews/cari_address_${brightness.name}.png'));
        await tester.tap(find.text('Genel'));
        await tester.pumpAndSettle();
        expect(find.text('CR.0001'), findsOneWidget);
        // Narrow phone layout.
        tester.view.physicalSize = const Size(320, 740);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
          () => MockClient((request) async {
                if (request.method != 'GET') writes++;
                final path = request.url.path;
                final data = path.contains('/Ulke/')
                    ? [
                        {'Id': 1, 'Ad': 'Türkiye'}
                      ]
                    : path.contains('/Il/')
                        ? [
                            {'Id': 34, 'Ad': 'İstanbul', 'Ulkeid': 1}
                          ]
                        : path.contains('/Ilce/')
                            ? [
                                {'Id': 1, 'Ad': 'Kadıköy', 'Ilid': 34}
                              ]
                            : path.endsWith('/Doviz')
                                ? [
                                    {
                                      'Id': 1,
                                      'Ad': 'Türk Lirası',
                                      'Birim': 'TRY'
                                    }
                                  ]
                                : [
                                    {
                                      'Id': 1,
                                      'Adsoyad': 'Örnek Temsilci',
                                      'Kod': 'P01'
                                    }
                                  ];
                return http.Response(jsonEncode({'Data': data}), 200, headers: {
                  'content-type': 'application/json; charset=utf-8'
                });
              }));
    });
  }
}
