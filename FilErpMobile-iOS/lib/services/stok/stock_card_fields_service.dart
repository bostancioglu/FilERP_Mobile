import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../widgets/erp_record_fields.dart';
import '../auth/authorization_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

const stockRowFields = <String, List<RecordField>>{
  'Stokolcubr': [
    RecordField('Olcubrid', 'Ölçü Birimi', RecordFieldType.lookup,
        lookup: 'unit', required: true),
    RecordField('Pay', 'Pay', RecordFieldType.number,
        required: true, minimum: .000001),
    RecordField('Payda', 'Payda', RecordFieldType.number,
        required: true, minimum: .000001),
    RecordField('Sira', 'Sıra', RecordFieldType.integer, minimum: 1)
  ],
  'Stokfiyat': [
    RecordField('Dovizid', 'Döviz', RecordFieldType.lookup,
        lookup: 'currency', required: true),
    RecordField('Alisfiyat', 'Alış Fiyatı', RecordFieldType.number, minimum: 0),
    RecordField('Satisfiyat', 'Satış Fiyatı', RecordFieldType.number,
        minimum: 0),
    RecordField('Karyuzde', 'Kâr Yüzdesi', RecordFieldType.number),
    RecordField('Maliyet', 'Maliyet', RecordFieldType.number, minimum: 0),
    RecordField('Aciklama', 'Açıklama', RecordFieldType.text),
    RecordField('Sira', 'Sıra', RecordFieldType.integer, minimum: 1)
  ],
  'Stokbarkod': [
    RecordField('Barkod', 'Barkod', RecordFieldType.text, required: true),
    RecordField('Olcubrid', 'Ölçü Birimi', RecordFieldType.lookup,
        lookup: 'unit', required: true),
    RecordField('Sira', 'Sıra', RecordFieldType.integer, minimum: 1)
  ],
  'Stokozellik': [
    RecordField('Stokozelliksabitid', 'Stok Özelliği', RecordFieldType.lookup,
        lookup: 'feature', required: true),
    RecordField('Carigrupkodu', 'Cari Grup Kodu', RecordFieldType.text),
    RecordField('Sira', 'Sıra', RecordFieldType.integer, minimum: 1)
  ],
  'Stokalternatif': [
    RecordField('Alternatifstokid', 'Alternatif Stok', RecordFieldType.lookup,
        lookup: 'stock', required: true),
    RecordField('Sira', 'Sıra', RecordFieldType.integer, minimum: 1)
  ],
  'Stoksube': [
    RecordField('Subeid', 'Şube', RecordFieldType.lookup,
        lookup: 'branch', required: true)
  ],
};

class StockRowsController extends ChangeNotifier {
  final Map<String, List<Map<String, dynamic>>> rows = {};
  final Map<String, Map<String, Map<String, dynamic>>> original = {};
  StockRowsController(Map<String, dynamic> source) {
    for (final key in stockRowFields.keys) {
      rows[key] = ((jsonDecode(jsonEncode(source[key] ?? []))) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      original[key] = {
        for (final row in rows[key]!)
          if (row['Id'] != null)
            row['Id'].toString(): payload(key, row, includeId: true)
      };
    }
  }
  Map<String, dynamic> payload(String kind, Map<String, dynamic> row,
          {bool includeId = false, int? stockId}) =>
      {
        if (includeId && row['Id'] != null) 'Id': row['Id'],
        if (stockId != null) 'Stokid': stockId,
        for (final f in stockRowFields[kind]!) f.key: row[f.key],
        if (kind == 'Stokolcubr')
          'Carpim': ((row['Pay'] as num?)?.toDouble() ?? 0) /
              ((row['Payda'] as num?)?.toDouble() ?? 1),
      };
  Map<String, dynamic> createBody() => {
        for (final key in rows.keys)
          key: rows[key]!.map((e) => payload(key, e)).toList()
      };
  bool get dirty {
    for (final kind in rows.keys) {
      if (rows[kind]!.length != original[kind]!.length) return true;
      for (final row in rows[kind]!) {
        if (row['Id'] == null ||
            jsonEncode(payload(kind, row, includeId: true)) !=
                jsonEncode(original[kind]![row['Id'].toString()])) return true;
      }
    }
    return false;
  }

  void put(String kind, Map<String, dynamic> row, [int? index]) {
    if (index == null) {
      rows[kind]!.add(row);
    } else {
      rows[kind]![index] = row;
    }
    notifyListeners();
  }

  void remove(String kind, int index) {
    rows[kind]!.removeAt(index);
    notifyListeners();
  }
}

class StockCardFieldsService {
  final int? stockId;
  const StockCardFieldsService({this.stockId});
  Future<dynamic> _request(String method, String route,
      [Map<String, dynamic>? body]) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    final uri = Uri.parse('${ApiConfig.baseUrl}/$route');
    final response = switch (method) {
      'POST' => await http.post(uri, headers: headers, body: jsonEncode(body)),
      'PUT' => await http.put(uri, headers: headers, body: jsonEncode(body)),
      'DELETE' => await http.delete(uri, headers: headers),
      _ => await http.get(uri, headers: headers)
    };
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw Exception(parseApiError(response));
    if (response.bodyBytes.isEmpty) return null;
    return (jsonDecode(utf8.decode(response.bodyBytes)) as Map)['Data'];
  }

  Future<List<RecordChoice>> choices(String type) async {
    final branch = AuthorizationSession.instance.branchId ??
        (await SharedPreferences.getInstance()).getInt('sube_id') ??
        0;
    final route = switch (type) {
      'unit' => 'Olcubr/AllWithoutAuth',
      'currency' => 'Doviz',
      'stock' => 'Stok/AllWithoutAuth',
      'feature' => 'Stokozelliksabit',
      'branch' => 'Sube/AllWithoutAuth',
      'account' => 'Hesapplani/AllWithoutAuth',
      'depot' => 'Depo/AllBySubeidWithoutAuth/$branch',
      'exemption' => 'Istisna/AllWithoutAuth',
      _ => throw ArgumentError(type)
    };
    final data = await _request('GET', route);
    if (data is! List) throw Exception('Seçim listesi alınamadı.');
    return data
        .where((e) =>
            (type != 'account' || e['Tur'] == 5) &&
            (type != 'stock' || e['Id'] != stockId))
        .map((e) => RecordChoice(
            e['Id'] as int,
            [e['Kod'], e['Ad'] ?? e['Aciklama'] ?? e['Birim']]
                .whereType<String>()
                .where((v) => v.isNotEmpty)
                .join(' · ')))
        .toList();
  }

  Future<void> sync(StockRowsController controller) async {
    if (stockId == null) throw StateError('Stock ID required');
    AuthorizationSession.instance.require(101, Access.update);
    for (final kind in controller.rows.keys) {
      final original = controller.original[kind]!;
      final current = controller.rows[kind]!;
      final deleted = original.keys
          .where((id) => !current.any((row) => row['Id']?.toString() == id))
          .toList();
      for (final id in deleted) {
        await _request('DELETE', 'Stok/$kind/$id');
        original.remove(id);
      }
      for (final row in current) {
        final id = row['Id'];
        final payload = controller.payload(kind, row, includeId: id != null);
        if (id != null &&
            jsonEncode(payload) == jsonEncode(original[id.toString()]))
          continue;
        final data = await _request(id == null ? 'POST' : 'PUT', 'Stok/$kind',
            {...payload, 'Stokid': stockId});
        if (id == null) {
          final savedId = data is Map ? data['Id'] : data;
          if (savedId == null)
            throw Exception(
                'Satır kaydedildi ancak kayıt numarası alınamadı. Kartı yeniden açın.');
          row['Id'] = savedId;
        }
        original[row['Id'].toString()] =
            controller.payload(kind, row, includeId: true);
      }
    }
  }
}
