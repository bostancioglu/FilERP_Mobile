import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FilERP/widgets/erp_module_menu.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
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
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final large in [false, true]) {
        testWidgets(
            'Module menus ${design.name} ${brightness.name} large=$large',
            (tester) async {
          tester.view.physicalSize = const Size(320, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final boundary = GlobalKey();
          late BuildContext root;
          var opened = false;
          await tester.pumpWidget(RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.build(brightness, design: design),
                home: Builder(builder: (ctx) {
                  root = ctx;
                  return const Scaffold(body: Center(child: Text('Ana Sayfa')));
                }),
              )));
          showDialog<void>(
              context: root,
              builder: (ctx) => MediaQuery(
                    data: MediaQuery.of(ctx).copyWith(
                        textScaler: TextScaler.linear(large ? 1.6 : 1)),
                    child: ErpModuleMenu(
                        title: 'Faturalar',
                        design: design,
                        items: [
                          for (final sales in [true, false])
                            ErpModuleMenuTile(
                              title: sales ? 'Satış Faturası' : 'Alış Faturası',
                              asset:
                                  'assets/icons/new/${sales ? 'satis' : 'alis'}_faturasi.png',
                              design: design,
                              onTap: () {
                                opened = true;
                                Navigator.pop(ctx);
                              },
                            ),
                        ]),
                  ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (!large)
            await previews.captureReport(
                tester, boundary, 'menu_${design.name}_${brightness.name}');
          await tester.tap(find.text('Alış Faturası'));
          await tester.pumpAndSettle();
          expect(opened, true);
          expect(find.text('Faturalar'), findsNothing);
          showDialog<void>(
              context: root,
              builder: (ctx) =>
                  ErpModuleMenu(title: 'Finans', design: design, items: [
                    for (var i = 0; i < 14; i++)
                      ErpModuleMenuTile(
                          title: 'Uzun Rapor Başlığı ${i + 1}',
                          requiredModules: const [1001],
                          icon: Icons.insights_outlined,
                          design: design,
                          onTap: () => showDialog<void>(
                              context: ctx,
                              builder: (childCtx) => ErpModuleMenu(
                                      title: 'Alt Menü',
                                      design: design,
                                      items: [
                                        ErpModuleMenuTile(
                                            title: 'Listeyi Aç',
                                            requiredModules: const [1001],
                                            icon: Icons.list,
                                            design: design,
                                            onTap: () {
                                              Navigator.of(childCtx).popUntil(
                                                  (route) => route.isFirst);
                                              Navigator.of(root).push(
                                                  MaterialPageRoute<void>(
                                                      builder: (_) =>
                                                          const Scaffold(
                                                              body: Text(
                                                                  'Belge Listesi'))));
                                            }),
                                      ]))),
                  ]));
          await tester.pumpAndSettle();
          tester.view.physicalSize = const Size(740, 320);
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
              find.text('Uzun Rapor Başlığı 14'), 250,
              scrollable: find.byType(Scrollable));
          await tester.tap(find.text('Uzun Rapor Başlığı 14'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Menüyü Kapat').last);
          await tester.pumpAndSettle();
          expect(find.text('Finans'), findsOneWidget);
          await tester.tap(find.text('Uzun Rapor Başlığı 14'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Listeyi Aç'));
          await tester.pumpAndSettle();
          expect(find.text('Belge Listesi'), findsOneWidget);
          Navigator.pop(root);
          await tester.pumpAndSettle();
          expect(find.text('Finans'), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
