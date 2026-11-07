import 'package:FilERP/theme/theme_controller.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/pages/cari/cari_detay_page.dart';
import 'package:FilERP/pages/stok/stok_detay_page.dart';
import 'package:FilERP/pages/stok/stok_ekle_page.dart';
import 'package:FilERP/models/entities/stok/stok_dto.dart';

final _customer = {
  'Id': 1,
  'Kod': 'CR.0001',
  'Ad': 'Marmara Gıda ve Ticaret Ltd. Şti.',
  'Vergino': '1234567890',
  'Vergidairesi': 'Kadıköy',
  'Kurumsaltel': '0216 555 12 34',
  'Yetkilimobil': '0532 555 12 34',
  'Adres': 'Örnek Mahallesi, Bahar Sokak No: 18 Kadıköy / İstanbul',
  'Vadegunu': 30,
  'Iskontoorani': 5,
  'Firmatipi': 1,
  'Kartturu': 1
};
final _unit = {'Id': 1, 'Ad': 'Adet', 'Kod': 'ADET'};
final _stock = {
  'Id': 1,
  'Kod': 'ST.0001',
  'Ad': 'Organik Sızma Zeytinyağı 1 L',
  'Yabanciad': 'Organic Olive Oil',
  'Kdvalis': 0.1,
  'Kdvsatis': 0.1,
  'Temelolcubrid': 1,
  'Kartturu': 1,
  'Stokturu': 1,
  'Takipsekli': 1,
  'Grupkodu': 'GIDA',
  'Stokkategoriid': 1,
  'Stokkategori': {'Id': 1, 'Ad': 'Gıda'},
  'Stokolcubr': [
    {
      'Id': 1,
      'Olcubrid': 1,
      'Pay': 1,
      'Payda': 1,
      'Carpim': 1,
      'Sira': 1,
      'Olcubr': _unit
    }
  ],
  'Stokbarkod': [
    {'Id': 'barkod-1', 'Barkod': '869000000001', 'Olcubrid': 1, 'Olcubr': _unit}
  ],
  'Stokfiyat': [
    {
      'Id': 1,
      'Alisfiyat': 285.50,
      'Satisfiyat': 349.90,
      'Dovizid': 1,
      'Doviz': {'Id': 1, 'Birim': 'TRY', 'Ad': 'Türk Lirası'}
    }
  ]
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
      for (final name in [
        'cari_detail',
        'stok_detail',
        'stok_create',
        'stok_edit'
      ]) {
        testWidgets(
            '$name ${design.name}_${brightness.name}: layout and interactions',
            (tester) async {
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          final capture = GlobalKey();
          var writes = 0;
          final previousShadows = debugDisableShadows;
          debugDisableShadows = false;
          try {
            await http.runWithClient(() async {
              final screen = name == 'cari_detail'
                  ? const CariDetayPage(cariId: 1)
                  : name == 'stok_detail'
                      ? const StokDetayPage(stokId: 1)
                      : StokEklePage(
                          editStok: name == 'stok_edit'
                              ? StokDto.fromJson(_stock)
                              : null);
              await tester.pumpWidget(RepaintBoundary(
                  key: capture,
                  child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.build(brightness, design: design),
                      initialRoute: '/screen',
                      routes: {
                        '/': (_) => const Scaffold(),
                        '/screen': (_) => screen
                      })));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(find.byType(CircularProgressIndicator), findsNothing);
              await _capture(
                  tester, capture, '${name}_${design.name}_${brightness.name}');
              if (name.endsWith('detail')) {
                await tester.drag(
                    find.byType(CustomScrollView), const Offset(0, -500));
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                if (name == 'stok_detail') {
                  await tester.tap(find.byTooltip('Stok işlemleri'));
                  await tester.pumpAndSettle();
                  expect(find.text('Stoğu Düzenle'), findsOneWidget);
                  expect(find.text('Barkod Yazdır'), findsOneWidget);
                  expect(find.textContaining('Sil'), findsWidgets);
                  await tester.tap(find.text('Stoğu Sil'));
                  await tester.pumpAndSettle();
                  await tester.tap(find.text('Vazgeç'));
                  await tester.pumpAndSettle();
                }
                await tester.tap(find.byTooltip('Düzenle').first);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                expect(
                    find.text(name == 'cari_detail'
                        ? 'Cari Güncelle'
                        : 'Stok Güncelle'),
                    findsOneWidget);
                await tester.pageBack();
                await tester.pumpAndSettle();
              } else {
                if (name == 'stok_create') {
                  await tester.tap(find.text('Stok kartını oluştur'));
                  await tester.pumpAndSettle();
                  expect(find.text('Zorunlu alan'), findsWidgets);
                  await tester.enterText(
                      find.byType(TextFormField).first, 'ST.0002');
                  await tester.enterText(
                      find.byType(TextFormField).at(1), 'Filtre Kahve 250 g');
                } else {
                  expect(
                      tester
                          .widget<TextFormField>(
                              find.byType(TextFormField).first)
                          .enabled,
                      isFalse);
                }
                tester.testTextInput.hide();
                FocusManager.instance.primaryFocus?.unfocus();
                for (final label in ['Açıklama', 'Rapor', 'Vergi', 'Genel']) {
                  await tester.ensureVisible(find.text(label).first);
                  await tester.tap(find.text(label).first);
                  await tester.pumpAndSettle();
                  expect(tester.takeException(), isNull);
                }
                expect(find.text(name == 'stok_create' ? 'ST.0002' : 'ST.0001'),
                    findsOneWidget);
                tester.view.viewInsets = const FakeViewPadding(bottom: 300);
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                tester.view.resetViewInsets();
              }
              tester.view.physicalSize = const Size(320, 740);
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              if (name.endsWith('detail')) {
                await tester.drag(
                    find.byType(CustomScrollView), const Offset(0, 1000));
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
              }
              expect(writes, 0,
                  reason: 'UI preview must not write data or print');
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pumpAndSettle();
            },
                () => MockClient((request) async {
                      if (request.method != 'GET') writes++;
                      final path = request.url.path;
                      final Object data = path.contains('/Cari/CariFull/')
                          ? _customer
                          : path.contains('/Stok/StokFull/')
                              ? _stock
                              : path.contains('/Olcubr/')
                                  ? [_unit]
                                  : path.contains('/Stokkategori/')
                                      ? [
                                          {'Id': 1, 'Ad': 'Gıda'}
                                        ]
                                      : [];
                      return http.Response(jsonEncode({'Data': data}), 200,
                          headers: {
                            'content-type': 'application/json; charset=utf-8'
                          });
                    }));
          } finally {
            debugDisableShadows = previousShadows;
          }
        });
      }
    }
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final previous = debugDisableShadows;
    try {
      debugDisableShadows = false;
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final target = File('tool/previews/$name.png');
      await target.parent.create(recursive: true);
      await target.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    } finally {
      debugDisableShadows = previous;
    }
  });
}
