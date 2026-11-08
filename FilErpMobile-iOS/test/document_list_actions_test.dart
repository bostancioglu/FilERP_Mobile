import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/services/auth/user_parameters.dart';
import 'package:FilERP/services/ebelge/portal_service.dart';
import 'package:FilERP/widgets/document_list_actions.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'permission_fixtures.dart';

void main() {
  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      for (final draft in [true, false]) {
        for (final automatic in [false, true]) {
          for (final invoice in [false, true]) {
            testWidgets(
                'list menu ${design.name} ${brightness.name} draft=$draft automatic=$automatic invoice=$invoice',
                (tester) async {
              final token = 'header.${base64Url.encode(utf8.encode(jsonEncode({
                    UserParameters.claimName: {
                      'Otomatikefaturagonder': automatic
                    }
                  })))}.signature';
              grantAdministratorFixture(token: token);
              int? changed;
              var requests = 0;
              await http.runWithClient(() async {
                await tester.pumpWidget(MaterialApp(
                    theme: AppTheme.build(brightness, design: design),
                    home: Scaffold(
                        body: DocumentListActions(
                            module: invoice ? 301 : 501,
                            id: 'doc-1',
                            number: 'BLG001',
                            status: draft ? 0 : 1,
                            electronicStatus: 0,
                            document: invoice
                                ? PortalDocument.invoice
                                : PortalDocument.waybill,
                            onStatusChange: (value) async {
                              changed = value;
                            },
                            onRefresh: () async {}))));
                await tester.tap(find.byTooltip('Belge İşlemleri'));
                await tester.pumpAndSettle();
                final statusLabel = draft ? 'Belgeyi Tamamla' : 'Taslağa Çek';
                final sendLabel = automatic
                    ? (invoice ? 'E-Fatura Gönder' : 'E-İrsaliye Gönder')
                    : 'Portala Gönder';
                expect(find.text(sendLabel),
                    draft ? findsNothing : findsOneWidget);
                expect(
                    find.text(automatic
                        ? 'Portala Gönder'
                        : (invoice ? 'E-Fatura Gönder' : 'E-İrsaliye Gönder')),
                    findsNothing);
                await tester.tap(find.text(statusLabel));
                await tester.pumpAndSettle();
                expect(changed, draft ? 1 : 0);
                if (!draft) {
                  await tester.tap(find.byTooltip('Belge İşlemleri'));
                  await tester.pumpAndSettle();
                  await tester.tap(find.text(sendLabel));
                  await tester.pumpAndSettle();
                  expect(find.text('BLG001'), findsOneWidget);
                  await tester.tap(find.text('Vazgeç'));
                  await tester.pumpAndSettle();
                }
                expect(requests, 0,
                    reason: 'Cancellation must never send a document');
                expect(tester.takeException(), isNull);
              },
                  () => MockClient((_) async {
                        requests++;
                        return http.Response('{}', 500);
                      }));
            });
          }
        }
      }
    }
  }
  testWidgets('no permission hides menu; purchase invoices have no send action',
      (tester) async {
    AuthorizationSession.instance.reset();
    Widget page(int module) => MaterialApp(
        home: Scaffold(
            body: DocumentListActions(
                module: module,
                id: '1',
                number: '1',
                status: 1,
                electronicStatus: 0,
                onStatusChange: (_) async {},
                onRefresh: () async {})));
    await tester.pumpWidget(page(301));
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    grantAdministratorFixture();
    await tester.pumpWidget(page(302));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Belge İşlemleri'));
    await tester.pumpAndSettle();
    expect(find.text('Taslağa Çek'), findsOneWidget);
    expect(find.text('Portala Gönder'), findsNothing);
    expect(find.text('E-Fatura Gönder'), findsNothing);
  });
}
