import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../models/entities/teklif/teklif_dto.dart';
import '../../models/entities/teklif/teklifhareket_dto.dart';
import '../../models/entities/teklif/teklif_codec.dart';

class TeklifService {
  final bool sales;
  const TeklifService({required this.sales});
  String get controller => sales ? 'Teklif' : 'TeklifAlis';
  String get lineController => sales ? 'Teklifhareket' : 'TeklifhareketAlis';

  Future<dynamic> _request(String token, String method, String path,
      [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/$path');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    final response = switch (method) {
      'POST' => await http.post(uri, headers: headers, body: jsonEncode(body)),
      'PUT' => await http.put(uri, headers: headers, body: jsonEncode(body)),
      'DELETE' => await http.delete(uri, headers: headers),
      _ => await http.get(uri, headers: headers),
    };
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(parseApiError(response));
    }
    if (response.bodyBytes.isEmpty) return null;
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return decoded is Map && decoded.containsKey('Data')
        ? decoded['Data']
        : decoded;
  }

  Future<List<TeklifDto>> getAll(String token) async {
    final data = await _request(token, 'GET', controller) as List? ?? [];
    return data
        .map((e) => TeklifDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TeklifDto> getFull(String token, String id) async =>
      TeklifDto.fromJson(
          await _request(token, 'GET', '$controller/TeklifFull/$id')
              as Map<String, dynamic>);

  Future<String> nextNumber(String token, String series, int year) async {
    final value = await _request(
        token, 'GET', '$controller/GetNewTeklifNo/$series/$year');
    if (value == null || value.toString().trim().isEmpty) {
      throw Exception('Teklif numarası alınamadı.');
    }
    return value.toString();
  }

  Map<String, dynamic> createBody(TeklifDto quote) => teklifJson(quote)
    ..remove('Id')
    ..['Teklifhareket'] = (quote.teklifhareket ?? [])
        .map((line) => teklifKalemJson(line)..remove('Id'))
        .toList();

  Future<String> create(String token, TeklifDto quote) async {
    final data = await _request(
        token, 'POST', '$controller/SaveWithItems', createBody(quote));
    final id = data is Map ? data['Id'] : data;
    if (id == null || id.toString().isEmpty) {
      throw Exception('Teklif numarası alınamadı.');
    }
    return id.toString();
  }

  Future<void> updateHeader(String token, TeklifDto quote) async {
    await _request(token, 'PUT', '$controller/UpdateSingle', teklifJson(quote));
  }

  Future<void> saveLine(String token, TeklifhareketDto line) async {
    if (line.id != null) {
      await _request(
          token, 'PUT', '$lineController/UpdateSingle', teklifKalemJson(line));
    } else {
      final data = await _request(token, 'POST', '$lineController/SaveSingle',
          teklifKalemJson(line)..remove('Id'));
      line.id = int.tryParse((data is Map ? data['Id'] : data).toString());
      if (line.id == null) throw Exception('Teklif kalemi numarası alınamadı.');
    }
  }

  Future<void> removeLine(String token, int id) async {
    await _request(token, 'DELETE', '$lineController/RemoveSingle/$id');
  }

  Future<void> remove(String token, String id) async {
    await _request(token, 'DELETE', '$controller/RemoveWithItems/$id');
  }

  Future<void> changeStatus(String token, String id, bool complete) async {
    await _request(token, 'PUT',
        '$controller/${complete ? 'Complete' : 'BacktoDraft'}/$id');
  }
}
