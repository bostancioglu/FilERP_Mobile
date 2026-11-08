import 'permission_fixtures.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:FilERP/config/api_config.dart';
import 'package:FilERP/helpers/response.dart';
import 'package:FilERP/services/ebelge/ebelge_service.dart';
import 'package:FilERP/services/ebelge/portal_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => ApiConfig.setServer(ServerType.canli, save: false));

  test('e-document API follows the selected ERP environment', () async {
    await ApiConfig.setServer(ServerType.test, save: false);
    expect(ApiConfig.eBelgeBaseUrl, 'http://31.207.84.254:7197/api');
    expect(ApiConfig.baseUrl, ApiConfig.testUrl);
    await ApiConfig.setServer(ServerType.canli, save: false);
    expect(ApiConfig.eBelgeBaseUrl, 'http://152.89.38.195:7199/api');
    expect(ApiConfig.baseUrl, ApiConfig.canliUrl);
  });

  for (final invoice in [true, false]) {
    final controller = invoice ? 'Fatura' : 'Irsaliye';
    final stateKey = invoice ? 'EFaturadurum' : 'Eirsaliyedurum';
    final rowsKey = invoice ? 'Faturahareket' : 'Irsaliyehareket';
    Map<String, dynamic> document() => {
          'Id': 'document-1',
          'Sirketid': 7,
          'Belgeturu': invoice ? 1 : 3,
          'Belgedurum': 1,
          stateKey: 1,
          'Cari': {'Ad': 'Test Cari'},
          'Doviz': {'Id': 1},
          rowsKey: [
            {
              'Stok': {
                'Temelolcubr': {'Kod': 'AD'}
              }
            }
          ],
          'Aciklama20': 'Preserve full payload',
        };
    final company = {
      'Id': 7,
      'Efaturaentegrator': 1,
      'Efaturaentegratorkullaniciadi': 'fake-user',
      'Efaturaentegratorsifre': 'fake-encrypted-password',
      'Entegratorclientid': 'fake-client',
      'Entegratorclientsecret': 'fake-encrypted-secret',
      'Adres': 'Örnek şirket adresi',
      'Ulke': {'Kod': 'TR'},
    };
    Future<void> send() => EBelgeService().send(
        token: 'fake-token',
        id: 'document-1',
        companyId: 7,
        document: invoice ? PortalDocument.invoice : PortalDocument.waybill);
    http.Response response(Object? data, [int status = 200]) =>
        http.Response(jsonEncode({'Data': data}), status,
            headers: {'content-type': 'application/json; charset=utf-8'});
    MockClient client(
      List<http.Request> requests, {
      Map<String, dynamic>? doc,
      bool existing = false,
      Future<http.Response> Function(http.Request)? post,
      Map<String, dynamic>? companyOverride,
    }) =>
        MockClient((r) async {
          requests.add(r);
          if (r.method == 'POST')
            return post != null ? await post(r) : response({'Succeed': true});
          if (r.url.path.contains('/EDocument/'))
            return response(existing ? {'Id': 'existing'} : null);
          if (r.url.path.contains('/Sirket/')) {
            throw StateError(
                'Şifreyi çözen şirket düzenleme ucu çağrılmamalı.');
          }
          final full = doc ?? document();
          return response({
            ...full,
            if (!full.containsKey('Sirket'))
              'Sirket': companyOverride ?? company,
          });
        });

    for (final environment in ServerType.values) {
      test(
          '$controller forwards full payload and encrypted headers in ${environment.name}',
          () async {
        await ApiConfig.setServer(environment, save: false);
        grantAdministratorFixture();
        final requests = <http.Request>[];
        await http.runWithClient(send, () => client(requests));
        final sent = requests.last;
        expect(sent.method, 'POST');
        expect(sent.url.toString(),
            '${ApiConfig.eBelgeBaseUrl}/${invoice ? 'EFatura/send-invoice' : 'EIrsaliye/send-waybill'}');
        expect(requests.first.url.toString().startsWith(ApiConfig.baseUrl),
            isTrue);
        expect(sent.headers['authorization'], 'Bearer fake-token');
        expect(sent.headers['entegratorpassword'],
            company['Efaturaentegratorsifre']);
        expect(sent.headers['entegratorclientsecret'],
            company['Entegratorclientsecret']);
        final payload = jsonDecode(sent.body);
        expect(payload['Aciklama20'], 'Preserve full payload');
        expect(payload[rowsKey], isNotEmpty);
        expect(payload['Sirket'], company);
        expect(requests.where((r) => r.url.path.contains('/Sirket/')), isEmpty);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getKeys().any((k) => k.contains('fake-')), isFalse);
        expect(prefs.getKeys().map(prefs.get), ['sent']);
      });
    }
    for (final change in [
      {'Belgedurum': 0},
      {stateKey: 3},
      {stateKey: 2},
      {stateKey: null},
      {'Sirketid': 8},
      {'Belgeturu': invoice ? 2 : 4},
      {rowsKey: []},
    ]) {
      test('$controller refuses invalid payload $change without send',
          () async {
        final requests = <http.Request>[];
        await http.runWithClient(() => expectLater(send(), throwsException),
            () => client(requests, doc: {...document(), ...change}));
        expect(requests.where((r) => r.method == 'POST'), isEmpty);
      });
    }
    test('$controller refuses existing e-document while ERP is stale',
        () async {
      final requests = <http.Request>[];
      await http.runWithClient(() => expectLater(send(), throwsException),
          () => client(requests, existing: true));
      expect(requests.where((r) => r.method == 'POST'), isEmpty);
    });
    test('$controller refuses missing company credentials', () async {
      final requests = <http.Request>[];
      await http.runWithClient(
          () => expectLater(send(), throwsException),
          () => client(requests,
              companyOverride: {...company, 'Efaturaentegratorsifre': ''}));
      expect(requests.where((r) => r.method == 'POST'), isEmpty);
    });

    test(
        '$controller never falls back to the decrypting endpoint if company is missing',
        () async {
      final requests = <http.Request>[];
      await http.runWithClient(
        () => expectLater(send(), throwsException),
        () => client(requests, doc: {...document(), 'Sirket': null}),
      );
      expect(requests.where((r) => r.method == 'POST'), isEmpty);
      expect(requests.where((r) => r.url.path.contains('/Sirket/')), isEmpty);
    });
    for (final outcome in ['network', 'server', 'invalid', 'success']) {
      test('$controller prevents repeat after $outcome even with new service',
          () async {
        final requests = <http.Request>[];
        await http.runWithClient(() async {
          if (outcome == 'success') {
            await send();
          } else {
            await expectLater(send(), throwsA(isA<EBelgeUncertain>()));
          }
          await expectLater(send(), throwsA(isA<EBelgeUncertain>()));
        },
            () => client(requests, post: (_) async {
                  if (outcome == 'network')
                    throw http.ClientException('Disconnected');
                  if (outcome == 'server') return response(null, 500);
                  if (outcome == 'invalid')
                    return http.Response('invalid', 200);
                  return response({'Succeed': true});
                }));
        expect(requests.where((r) => r.method == 'POST').length, 1);
      });
    }
    test('$controller handles nested rejection instead of HTTP-only success',
        () async {
      final requests = <http.Request>[];
      await http.runWithClient(
          () => expectLater(
              send(),
              throwsA(
                  predicate((e) => e.toString().contains('Belge reddedildi')))),
          () => client(requests,
              post: (_) async =>
                  response({'Succeed': false, 'Message': 'Belge reddedildi'})));
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    });
    test('$controller handles forbidden without leaving pending marker',
        () async {
      final requests = <http.Request>[];
      await http.runWithClient(
          () => expectLater(send(), throwsA(isA<YetkiHatasi>())),
          () => client(requests, post: (_) async => response(null, 403)));
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    });
    test('$controller blocks overlapping sends', () async {
      final requests = <http.Request>[];
      await http.runWithClient(() async {
        final first = send();
        await expectLater(send(), throwsException);
        await first;
      }, () => client(requests));
      expect(requests.where((r) => r.method == 'POST').length, 1);
    });
  }
}
