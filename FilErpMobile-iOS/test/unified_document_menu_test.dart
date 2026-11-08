import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/config/api_config.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/services/ebelge/portal_service.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'package:FilERP/widgets/document_list_actions.dart';
import 'package:FilERP/pages/fatura/Satisfaturasi/satisfatura_list.dart';
import 'package:FilERP/pages/fatura/Alisfaturasi/alisfatura_list.dart';
import 'package:FilERP/pages/siparis/Satis/satissiparis_list.dart';
import 'package:FilERP/pages/siparis/Alis/alissiparis_list.dart';
import 'package:FilERP/pages/teklif/teklif_list_page.dart';
import 'permission_fixtures.dart';

void main() {
  for (final design in ErpDesign.values) {
    for (final module in [301, 302, 501, 502, 401, 402, 601, 602]) {
      for (final status in [0, 1]) {
        testWidgets(
            'same edit status delete menu ${design.name} module=$module status=$status',
            (tester) async {
          grantAdministratorFixture();
          var edited = 0, deleted = 0;
          await tester.pumpWidget(MaterialApp(
              theme: AppTheme.build(Brightness.light, design: design),
              home: Scaffold(
                  body: DocumentListActions(
                      module: module,
                      id: 'doc-1',
                      number: 'TEST001',
                      status: status,
                      electronicStatus: 0,
                      // Even an erroneous document argument must not expose sending for
                      // purchases, orders or quotes.
                      document: module == 501
                          ? PortalDocument.waybill
                          : PortalDocument.invoice,
                      onStatusChange: (_) async {},
                      onRefresh: () async {},
                      onEdit: () async {
                        edited++;
                      },
                      onDelete: () async {
                        deleted++;
                      }))));
          await tester.tap(find.byTooltip('Belge İşlemleri'));
          await tester.pumpAndSettle();
          final draft = status == 0;
          expect(find.text('Düzenle'), draft ? findsOneWidget : findsNothing);
          expect(find.text('Sil'), draft ? findsOneWidget : findsNothing);
          final stateLabel = draft ? 'Belgeyi Tamamla' : 'Taslağa Çek';
          expect(find.text(stateLabel), findsOneWidget);
          expect(
              find.text('Portala Gönder'),
              status == 1 && [301, 501].contains(module)
                  ? findsOneWidget
                  : findsNothing);
          if (draft) {
            expect(tester.getTopLeft(find.text('Düzenle')).dy,
                lessThan(tester.getTopLeft(find.text(stateLabel)).dy));
            expect(tester.getTopLeft(find.text(stateLabel)).dy,
                lessThan(tester.getTopLeft(find.text('Sil')).dy));
            await tester.tap(find.text('Düzenle'));
            await tester.pumpAndSettle();
            expect(edited, 1);
            await tester.tap(find.byTooltip('Belge İşlemleri'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Sil'));
            await tester.pumpAndSettle();
            expect(deleted, 1);
          } else {
            // An old popup callback must also refuse mutation after completion.
            final popup = tester.widget<PopupMenuButton<String>>(
                find.byType(PopupMenuButton<String>).first);
            popup.onSelected!('edit');
            popup.onSelected!('delete');
            await tester.pumpAndSettle();
            expect(edited, 0);
            expect(deleted, 0);
            Navigator.of(tester.element(find.text(stateLabel))).pop();
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  testWidgets('edit and delete respect their individual permissions',
      (tester) async {
    final session = AuthorizationSession.instance;
    void activate(bool update, bool delete) => session.activate([
          {
            'Subeid': 1,
            'Modulaltid': 601,
            'TumunuOkuma': true,
            'Guncelleme': update,
            'Silme': delete
          }
        ], branch: 1, company: 1, environment: ApiConfig.serverType.name);
    var edited = 0, deleted = 0;
    Widget page() => MaterialApp(
        home: Scaffold(
            body: DocumentListActions(
                module: 601,
                id: '1',
                number: '1',
                status: 0,
                electronicStatus: 0,
                onStatusChange: (_) async {},
                onRefresh: () async {},
                onEdit: () async {
                  edited++;
                },
                onDelete: () async {
                  deleted++;
                })));
    activate(false, false);
    await tester.pumpWidget(page());
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    activate(true, false);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Belge İşlemleri'));
    await tester.pumpAndSettle();
    expect(find.text('Sil'), findsNothing);
    expect(find.text('Belgeyi Tamamla'), findsNothing);
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    expect(edited, 1);
    activate(false, true);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Belge İşlemleri'));
    await tester.pumpAndSettle();
    expect(find.text('Düzenle'), findsNothing);
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(deleted, 1);
  });
  final pages = <String, Widget Function()>{
    'Fatura': () => const SatisFaturaListPage(),
    'FaturaAlis': () => const AlisFaturaList(),
    'Siparis': () => const SatisSiparisList(),
    'SiparisAlis': () => const AlisSiparisList(),
    'Teklif': () => const TeklifListPage(sales: true),
    'TeklifAlis': () => const TeklifListPage(sales: false),
  };
  for (final entry in pages.entries) {
    testWidgets(
        '${entry.key} list delete confirms then calls the document endpoint',
        (tester) async {
      SharedPreferences.setMockInitialValues({'token_final': 'fake-token'});
      grantAdministratorFixture();
      final writes = <http.Request>[];
      var removed = false;
      await http.runWithClient(() async {
        await tester.runAsync(() async {
          await tester.pumpWidget(MaterialApp(
              theme: AppTheme.build(Brightness.light), home: entry.value()));
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Belge İşlemleri').first);
        await tester.pumpAndSettle();
        expect(find.text('Düzenle'), findsOneWidget);
        await tester.tap(find.text('Sil'));
        await tester.pumpAndSettle();
        expect(writes, isEmpty);
        await tester.tap(find.widgetWithText(OutlinedButton, 'Vazgeç'));
        await tester.pumpAndSettle();
        expect(writes, isEmpty);
        await tester.tap(find.byTooltip('Belge İşlemleri').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sil'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Sil'));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(writes.map((r) => '${r.method} ${r.url.path}'),
            ['DELETE /api/${entry.key}/RemoveWithItems/doc-1']);
        expect(removed, isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
          () => MockClient((request) async {
                if (request.method != 'GET') {
                  writes.add(request);
                  removed = true;
                  return http.Response('{}', 200);
                }
                return http.Response(
                    jsonEncode({
                      'Data': removed
                          ? []
                          : [
                              {
                                'Id': 'doc-1',
                                'Belgeserino': 'TEST001',
                                'Belgedurum': 0,
                                'Tarih': '2026-11-05',
                                'Geneltoplam': 100,
                                'Cari': {
                                  'Id': 1,
                                  'Kod': 'CR001',
                                  'Ad': 'Test Cari'
                                }
                              }
                            ]
                    }),
                    200,
                    headers: {
                      'content-type': 'application/json; charset=utf-8'
                    });
              }));
    });
  }
}
