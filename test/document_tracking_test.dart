import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/config/api_config.dart';
import 'package:FilERP/models/entities/stok/document_tracking.dart';
import 'package:FilERP/services/stok/document_tracking_service.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/document_tracking_sheet.dart';
import 'package:FilERP/theme/app_theme.dart';
import 'package:FilERP/theme/theme_controller.dart';
import 'permission_fixtures.dart';

const id = '11111111-1111-1111-1111-111111111111';
TrackingLine line(TrackingDocument doc,
        {double quantity = 4, String? direction}) =>
    TrackingLine(
        document: doc,
        documentId: id,
        lineId: '12',
        stockId: 7,
        warehouseId: 8,
        addressId: '22222222-2222-2222-2222-222222222222',
        featureId: 9,
        direction: direction,
        quantity: quantity,
        multiplier: 2);
http.Response data(Object? value) =>
    http.Response(jsonEncode({'Data': value}), 200,
        headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final doc in TrackingDocument.values) {
    test('${doc.name}: exact tracking routes, unit quantities and expiry',
        () async {
      grantAdministratorFixture(token: 'fixture');
      final requests = <http.Request>[];
      final service = DocumentTrackingService();
      final target = line(doc);
      final date = DateTime(2027, 1, 2);
      final choice = TrackingChoice(
          id: 5, partyId: 3, label: 'SER-5', balance: 5, expiry: date);
      await http.runWithClient(() async {
        final choices = await service.choices('fixture', target, 1);
        expect(choices.mode, 2);
        await service.add('fixture', target,
            choice: choice, serial: true, quantity: 1, expiry: date);
        await service.remove('fixture', target,
            TrackingDetail(id: id, quantity: 1, status: 1, serialId: 5));
      },
          () => MockClient((request) async {
                requests.add(request);
                if (request.method != 'GET') return http.Response('', 204);
                if (request.url.path.contains('Full'))
                  return data({'Belgedurum': 0});
                if (request.url.path.contains('SecimFilter'))
                  return data({'TakipModu': 2, 'Partiler': [], 'Seriler': []});
                return data([]);
              }));
      final query = requests.first.url.queryParameters;
      expect(query['yon'], doc.incoming ? '1' : '2');
      expect(query['subeid'], '1');
      expect(query['stokid'], '7');
      expect(query['depoid'], '8');
      expect(query['stokozelliksabitid'], '9');
      expect(query['bakiyesiolmayanlarigetir'], '${doc.incoming}');
      final write = requests.singleWhere((r) => r.method == 'PUT');
      expect(write.url.path, '/api/Stoktakipdetay/${doc.saveRoute}/StokTakip');
      final payload = jsonDecode(write.body);
      expect(payload['Belgeid'], id);
      expect(payload['Belgehareketid'], 12);
      expect(payload['Detaylar'].single['Partiid'], 3);
      expect(payload['Detaylar'].single['Seriid'], 5);
      expect(payload['Detaylar'].single['Miktar'], 1);
      expect(payload['Detaylar'].single['Sonkullanmatarihi'],
          date.toIso8601String());
      final remove = requests.singleWhere((r) => r.method == 'DELETE');
      expect(remove.url.path, '/api/Stoktakipdetay/StokTakip/${doc.type}/$id');
      expect(jsonDecode(remove.body), [id]);
    });
  }

  for (final failure in [
    'completed',
    'unknown-status',
    'duplicate',
    'over-quantity',
    'insufficient-balance',
    'permission',
    'unsaved'
  ]) {
    test('tracking blocks $failure without a mutation request', () async {
      grantAdministratorFixture(token: 'fixture');
      if (failure == 'permission') {
        AuthorizationSession.instance.activate([
          {'Subeid': 1, 'Modulaltid': 301, 'TumunuOkuma': true}
        ],
            branch: 1,
            company: 1,
            environment: ApiConfig.serverType.name,
            token: 'fixture');
      }
      var writes = 0;
      await http.runWithClient(() async {
        final target = failure == 'unsaved'
            ? const TrackingLine(
                document: TrackingDocument.salesInvoice,
                documentId: null,
                lineId: null,
                stockId: 7,
                quantity: 1,
                multiplier: 1)
            : line(TrackingDocument.salesInvoice,
                quantity: failure == 'over-quantity' ? .5 : 4);
        await expectLater(
            DocumentTrackingService().add('fixture', target,
                choice: TrackingChoice(
                    id: 5,
                    partyId: 3,
                    label: 'SER-5',
                    balance: failure == 'insufficient-balance' ? 0 : 5),
                serial: true,
                quantity: 1),
            throwsA(isA<Exception>()));
        expect(writes, 0);
      },
          () => MockClient((request) async {
                if (request.method != 'GET') {
                  writes++;
                  return http.Response('', 204);
                }
                if (request.url.path.contains('Full'))
                  return data(failure == 'unknown-status'
                      ? {}
                      : {'Belgedurum': failure == 'completed' ? 1 : 0});
                return data(failure == 'duplicate'
                    ? [
                        {
                          'Id': id,
                          'Seriid': 5,
                          'Partiid': 3,
                          'Miktar': 1,
                          'Kayitdurumu': 1
                        }
                      ]
                    : []);
              }));
    });
  }

  test('movement direction overrides document default for returns', () {
    expect(
        line(TrackingDocument.salesInvoice, direction: 'G').incoming, isTrue);
    expect(line(TrackingDocument.purchaseWaybill, direction: 'C').incoming,
        isFalse);
  });

  for (final design in ErpDesign.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
          '${design.name} ${brightness.name}: party selection and completed readonly state',
          (tester) async {
        SharedPreferences.setMockInitialValues(
            {'token_final': 'fixture', 'sube_id': 1});
        grantAdministratorFixture(token: 'fixture');
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final writes = <http.Request>[];
        var completed = false;
        var added = false;
        await http.runWithClient(() async {
          await tester.pumpWidget(MaterialApp(
              theme: AppTheme.build(brightness, design: design),
              home: Scaffold(
                  body: DocumentTrackingButton(
                      line: line(TrackingDocument.purchaseWaybill), mode: 1))));
          await tester.runAsync(() async {
            await tester.tap(find.text('Parti Takibi'));
            await Future<void>.delayed(const Duration(milliseconds: 80));
          });
          await tester.pumpAndSettle();
          await tester.tap(find.text('Parti Seç'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('PARTI-3').last);
          await tester.pumpAndSettle();
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 30)));
          await tester.pumpAndSettle();
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'The form must scroll above the keyboard');
          tester.view.viewInsets = const FakeViewPadding();
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            await tester.tap(find.text('Ekle'));
            await Future<void>.delayed(const Duration(milliseconds: 80));
          });
          await tester.pumpAndSettle();
          expect(writes.length, 1);
          expect(
              jsonDecode(writes.single.body)['Detaylar'].single['Miktar'], 4);
          expect(find.byTooltip('Takibi kaldır'), findsOneWidget);
          await tester.tap(find.byTooltip('Kapat'));
          await tester.pumpAndSettle();
          completed = true;
          await tester.runAsync(() async {
            await tester.tap(find.text('Parti Takibi'));
            await Future<void>.delayed(const Duration(milliseconds: 80));
          });
          await tester.pumpAndSettle();
          expect(find.text('Ekle'), findsNothing);
          expect(find.byTooltip('Takibi kaldır'), findsNothing);
          expect(writes.length, 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
            () => MockClient((request) async {
                  if (request.method != 'GET') {
                    writes.add(request);
                    added = true;
                    return http.Response('', 204);
                  }
                  if (request.url.path.contains('Full'))
                    return data({'Belgedurum': completed ? 1 : 0});
                  if (request.url.path.contains('SecimFilter'))
                    return data({
                      'TakipModu': 1,
                      'Seriler': [],
                      'Partiler': [
                        {'Id': 3, 'Kod': 'PARTI-3'}
                      ]
                    });
                  return data(added
                      ? [
                          {
                            'Id': id,
                            'Partiid': 3,
                            'Miktar': 4,
                            'Kayitdurumu': completed ? 2 : 1
                          }
                        ]
                      : []);
                }));
      });
    }
  }
}
