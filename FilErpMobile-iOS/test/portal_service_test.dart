import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:FilERP/helpers/response.dart';
import 'package:FilERP/services/fatura/fatura_service.dart';
import 'package:FilERP/services/irsaliye/irsaliye_service.dart';

void main() {
  for (final invoice in [true, false]) {
    final controller = invoice ? 'Fatura' : 'Irsaliye';
    final statusKey = invoice ? 'EFaturadurum' : 'Eirsaliyedurum';
    Future<void> send([String token = 'test-token']) => invoice
        ? FaturaService().portalaGonder(token, 'document-1')
        : IrsaliyeService().portalaGonder(token, 'document-1');

    for (final successCode in [200, 204]) {
      test(
          '$controller checks fresh status then sends to portal ($successCode)',
          () async {
        final requests = <http.Request>[];
        await http.runWithClient(
            send,
            () => MockClient((request) async {
                  requests.add(request);
                  if (request.method == 'GET') {
                    return http.Response(
                        jsonEncode({
                          'Data': {'Belgedurum': 1, statusKey: 0}
                        }),
                        200);
                  }
                  return http.Response('', successCode);
                }));
        expect(requests.map((r) => '${r.method} ${r.url.path}'), [
          'GET /api/$controller/${controller}Full/document-1',
          'POST /api/$controller/portala-gonder/document-1',
        ]);
        expect(
            requests.every(
                (r) => r.headers['authorization'] == 'Bearer test-token'),
            isTrue);
        expect(requests.last.body, isEmpty);
      });
    }

    for (final state in [
      {'Belgedurum': 0, statusKey: 0},
      {'Belgedurum': 1, statusKey: 1},
      {'Belgedurum': 1, statusKey: 2},
      {'Belgedurum': 1, statusKey: 3},
      {'Belgedurum': 1, statusKey: 4},
      {'Belgedurum': 1, statusKey: 5},
      {'Belgedurum': 1},
    ]) {
      test('$controller refuses ineligible document $state without POST',
          () async {
        final requests = <http.Request>[];
        await http.runWithClient(() async {
          await expectLater(send(), throwsException);
        },
            () => MockClient((request) async {
                  requests.add(request);
                  return http.Response(jsonEncode({'Data': state}), 200);
                }));
        expect(requests.single.method, 'GET');
      });
    }

    test('$controller preserves authorization failure', () async {
      await http.runWithClient(() async {
        await expectLater(send(), throwsA(isA<YetkiHatasi>()));
      }, () => MockClient((request) async => http.Response('', 403)));
      await expectLater(send(''), throwsA(isA<YetkiHatasi>()));
    });

    test('$controller does not retry a failed POST', () async {
      var posts = 0;
      await http.runWithClient(() async {
        await expectLater(send(),
            throwsA(predicate((e) => e.toString().contains('Sunucu hatası'))));
      },
          () => MockClient((request) async {
                if (request.method == 'GET') {
                  return http.Response(
                      jsonEncode({
                        'Data': {'Belgedurum': 1, statusKey: 0}
                      }),
                      200);
                }
                posts++;
                return http.Response(
                    jsonEncode({
                      'Errors': ['Sunucu hatası']
                    }),
                    500,
                    headers: {
                      'content-type': 'application/json; charset=utf-8'
                    });
              }));
      expect(posts, 1);
    });
  }
}
