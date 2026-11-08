import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'package:FilERP/widgets/corporate_menu_icon.dart';
import 'package:FilERP/widgets/erp_module_menu.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'report_center_screens_test.dart' as previews;

void main() {
  setUpAll(() async {
    for (final e in {
      'Roboto': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  const labels = [
    'Fatura',
    'İrsaliye',
    'Sipariş',
    'Teklif',
    'Stok',
    'Depo',
    'Cari',
    'Finans',
    'Kasa',
    'Banka',
    'Çek / Senet',
    'Tahsilat',
    'Raporlar',
    'E-Belge',
    'Portal',
    'Ayarlar',
    'Araç Yükle',
    'Yazıcı',
    'Yazıcı Şablonları',
    'Tema Seçimi',
    'Bağlantı',
    'Çevrimdışı Mod',
    'Varsayılan Proje',
    'Barkod',
    'Kuyruk',
    'Güncelleme',
    'Kullanıcı',
    'Çıkış',
    'NFC',
    'DAT',
    'Plasiyer Konumları',
    'Ana Sayfa',
    'Bluetooth',
    'Kağıt Eni',
  ];
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      testWidgets('vehicle loading menu ${design.name} ${brightness.name}',
          (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        var opened = false;
        await tester.pumpWidget(RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.build(brightness, design: design),
              home: Scaffold(
                  body: Center(
                      child:
                          ErpModuleMenu(title: 'Depo', design: design, items: [
                ErpModuleMenuTile(
                    title: 'Araç Yükle',
                    design: design,
                    icon: Icons.local_shipping_rounded,
                    onTap: () => opened = true)
              ]))),
            )));
        await tester.pumpAndSettle();
        final pictures = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
        expect(
            pictures.map((p) => (p.bytesLoader as SvgAssetLoader).assetName),
            contains(
                'assets/icons/corporate/${brightness == Brightness.dark ? 'dark' : 'light'}/arac-yukleme.svg'));
        await previews.captureReport(
            tester, key, 'vehicle_menu_${design.name}_${brightness.name}');
        await tester.tap(find.text('Araç Yükle'));
        expect(opened, isTrue);
        expect(tester.takeException(), isNull);
      });
      for (final colored in [false, true]) {
        testWidgets(
            'corporate icons ${design.name} ${brightness.name} colored=$colored',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            theme: AppTheme.build(brightness, design: design),
            home: Scaffold(
              body: ColoredBox(
                  color: colored ? const Color(0xFF3949AB) : Colors.transparent,
                  child: Wrap(children: [
                    for (final label in labels)
                      Padding(
                          padding: const EdgeInsets.all(8),
                          child: CorporateMenuIcon(label,
                              size: 48, onColoredSurface: colored))
                  ])),
            ),
          ));
          await tester.pumpAndSettle();
          expect(find.byType(CorporateMenuIcon), findsNWidgets(labels.length));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
