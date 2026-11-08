import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:FilERP/helpers/response.dart';
import 'package:FilERP/models/entities/teklif/teklif_dto.dart';
import 'package:FilERP/models/entities/teklif/teklifhareket_dto.dart';
import 'package:FilERP/models/entities/teklif/teklif_codec.dart';
import 'package:FilERP/services/teklif/teklif_service.dart';

void main() {
  for (final sales in [true, false]) {
    test(
        '${sales ? 'sales' : 'purchase'} quote API contract and numeric line IDs',
        () async {
      final requests = <http.Request>[];
      final service = TeklifService(sales: sales);
      final line = TeklifhareketDto()
        ..id = 7
        ..stokid = 1
        ..miktar = 2
        ..fiyat = 100
        ..olcubrid = 1
        ..acikkapali = false;
      final quote = TeklifDto()
        ..id = 'quote-1'
        ..belgeseri = 'TKL'
        ..belgeyil = 2026
        ..belgeno = '000000001'
        ..gecerliliktarihi = DateTime(2026, 11, 30)
        ..teklifhareket = [line];
      await http.runWithClient(() async {
        expect(await service.create('token', quote), 'new-quote');
        await service.updateHeader('token', quote);
        line.teklifid = 'quote-1';
        await service.saveLine('token', line);
        final newLine = TeklifhareketDto()
          ..teklifid = 'quote-1'
          ..stokid = 2;
        await service.saveLine('token', newLine);
        expect(newLine.id, 42);
        await service.removeLine('token', 7);
        await service.changeStatus('token', 'quote-1', true);
        await service.changeStatus('token', 'quote-1', false);
        await service.remove('token', 'quote-1');
      },
          () => MockClient((request) async {
                requests.add(request);
                final data = request.url.path.endsWith('/SaveWithItems')
                    ? 'new-quote'
                    : request.url.path.endsWith('/SaveSingle')
                        ? 42
                        : null;
                return http.Response(jsonEncode({'Data': data}), 200);
              }));
      final controller = sales ? 'Teklif' : 'TeklifAlis';
      final movement = sales ? 'Teklifhareket' : 'TeklifhareketAlis';
      expect(requests.map((r) => '${r.method} ${r.url.path}').toList(), [
        'POST /api/$controller/SaveWithItems',
        'PUT /api/$controller/UpdateSingle',
        'PUT /api/$movement/UpdateSingle',
        'POST /api/$movement/SaveSingle',
        'DELETE /api/$movement/RemoveSingle/7',
        'PUT /api/$controller/Complete/quote-1',
        'PUT /api/$controller/BacktoDraft/quote-1',
        'DELETE /api/$controller/RemoveWithItems/quote-1',
      ]);
      final body = jsonDecode(requests[0].body) as Map;
      expect(body.containsKey('Id'), isFalse);
      expect(body['Gecerliliktarihi'], '2026-11-30T00:00:00.000');
      expect((body['Teklifhareket'] as List).single.containsKey('Id'), isFalse);
      expect(jsonDecode(requests[2].body)['Id'], isA<int>());
      expect(jsonDecode(requests[2].body)['Acikkapali'], isFalse);
      expect(
          requests.every((r) => r.headers['authorization'] == 'Bearer token'),
          isTrue);
    });
  }

  test('shared line editor preserves numeric identity and discount values', () {
    final original = TeklifhareketDto()
      ..id = 19
      ..stokid = 4
      ..miktar = 3
      ..fiyat = 200
      ..iskontoorani1 = 10
      ..iskontotutari1 = 60
      ..iskontotutar = 60
      ..kdvorani = 20
      ..tevkifatorani = .5;
    original
      ..teslimtarihi = DateTime(2026, 12, 1)
      ..talephareketid = 31
      ..acikkapali = false;
    final editor = teklifKalemToEditor(original)..teslimtarihi = null;
    final result = teklifKalemFromEditor(editor, original: original);
    expect(result.id, 19);
    expect(result.teslimtarihi, DateTime(2026, 12, 1));
    expect(result.talephareketid, 31);
    expect(result.acikkapali, isFalse);
    expect(result.iskontoorani1, 10);
    expect(result.iskontotutar, 60);
    expect(result.tevkifatorani, .5);
  });

  test('missing document number fails instead of using a null string',
      () async {
    await http.runWithClient(() async {
      await expectLater(
          const TeklifService(sales: true).nextNumber('token', 'TKL', 2026),
          throwsException);
    }, () => MockClient((_) async => http.Response('{"Data":null}', 200)));
  });

  test('authorization failure remains a permission error', () async {
    await http.runWithClient(() async {
      await expectLater(const TeklifService(sales: true).getAll('token'),
          throwsA(isA<YetkiHatasi>()));
    }, () => MockClient((_) async => http.Response('{}', 403)));
  });
}
