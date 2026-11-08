import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'package:FilERP/widgets/erp_page_style.dart';
import 'package:FilERP/widgets/erp_ui.dart';

void main() {
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      testWidgets('Shared page style ${design.name} ${brightness.name}',
          (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var refreshed = 0, opened = 0, deleted = 0, menuOpened = 0;
        late TabController tabs;
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.build(brightness, design: design),
            home: DefaultTabController(
                length: 3,
                child: Builder(builder: (context) {
                  tabs = DefaultTabController.of(context);
                  return Scaffold(
                      appBar: ErpPageAppBar(
                        context: context,
                        title: const Text('Belge',
                            style: TextStyle(color: Color(0xFF17243B))),
                        actions: [
                          IconButton(
                              tooltip: 'Yenile',
                              onPressed: () => refreshed++,
                              icon: const Icon(Icons.refresh,
                                  color: Colors.black))
                        ],
                        bottom: PreferredSize(
                            preferredSize: const Size.fromHeight(40),
                            child: ColoredBox(
                                color: Colors.white,
                                child: ErpAdaptiveTabs(
                                    context: context,
                                    tabBar: const TabBar(tabs: [
                                      Tab(text: 'Belge'),
                                      Tab(text: 'Kalemler'),
                                      Tab(text: 'Özet')
                                    ])))),
                      ),
                      body: ListView(children: [
                        ErpDocumentCard(
                            number: 'SP0001',
                            date: '01.11.2026',
                            customer: 'Örnek Cari',
                            customerCode: 'CR.001',
                            amount: '240,00 TL',
                            status: 'Taslak',
                            statusColor: Colors.orange,
                            icon: Icons.receipt_outlined,
                            onTap: () {},
                            onMenu: () => menuOpened++),
                        ErpFormSection(
                            title: 'Bilgiler',
                            icon: Icons.receipt_outlined,
                            children: const [Text('Değer')]),
                        ErpRecordCard(
                            title: 'Uzun Müşteri ve Tedarikçi Ünvanı',
                            code: 'CR.001',
                            icon: Icons.business_outlined,
                            details: const ['Kars', 'Merkez'],
                            onTap: () => opened++),
                        ErpFinanceCard(
                            title: 'Kasa Hareketi',
                            metadata: const ['01.11.2026', 'Giriş'],
                            icon: Icons.payments_outlined,
                            amount: '123.456,78 TL',
                            secondaryAmount: '2.345,67 USD',
                            onDelete: () => deleted++),
                      ]));
                }))));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Yenile'));
        expect(refreshed, 1);
        await tester.tap(find.byTooltip('Belge işlemleri'));
        expect(menuOpened, 1);
        await tester.tap(find.text('Kalemler'));
        await tester.pumpAndSettle();
        expect(tabs.index, 1);
        tabs.animateTo(2);
        await tester.pumpAndSettle();
        expect(tabs.index, 2);
        await tester
            .ensureVisible(find.text('Uzun Müşteri ve Tedarikçi Ünvanı'));
        await tester.tap(find.text('Uzun Müşteri ve Tedarikçi Ünvanı'));
        expect(opened, 1);
        await tester.ensureVisible(find.byTooltip('İşlemler'));
        await tester.tap(find.byTooltip('İşlemler'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sil'));
        await tester.pumpAndSettle();
        expect(deleted, 1);
        expect(find.text('123.456,78 TL'), findsOneWidget);
        expect(find.text('2.345,67 USD'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final brightness in Brightness.values) {
    testWidgets(
        'Many Modern tabs stay readable and follow selection ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late TabController controller;
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.build(brightness, design: ErpDesign.modern),
          home: DefaultTabController(
              length: 6,
              child: Builder(builder: (context) {
                controller = DefaultTabController.of(context);
                return Scaffold(
                    appBar: ErpPageAppBar(
                        context: context,
                        title: const Text('Cari'),
                        bottom: ErpAdaptiveTabs(
                            context: context,
                            tabBar: TabBar(isScrollable: true, tabs: [
                              for (var i = 0; i < 6; i++)
                                Tab(text: 'Sekme ${i + 1}')
                            ]))),
                    body: TabBarView(children: [
                      for (var i = 0; i < 6; i++)
                        Center(child: Text('İçerik $i'))
                    ]));
              }))));
      await tester.pumpAndSettle();
      controller.animateTo(5);
      await tester.pumpAndSettle();
      expect(
          tester.getRect(find.text('Sekme 6')).right, lessThanOrEqualTo(320));
      expect(find.text('İçerik 5'), findsOneWidget);
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(700, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sekme 1'));
      await tester.pumpAndSettle();
      expect(controller.index, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
