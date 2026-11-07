import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/tahsilat/tahsilat_dto.dart';
import '../../models/entities/finans/tahsilat/tahsilat_create_dto.dart';
import '../../models/entities/finans/tahsilat/tahsilat_update_dto.dart';

class TahsilatService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<TahsilatDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Tahsilat'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list
        .map((e) => TahsilatDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TahsilatDto>> getAllByBelgeid(
      String token, String belgeid) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Tahsilat/AllByBelgeid/$belgeid'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list
        .map((e) => TahsilatDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> getNewTahsilatNo(String token, String seri, int yil) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Tahsilat/GetNewTahsilatNo/$seri/$yil'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body['Data'].toString();
  }

  Future<void> create(String token, TahsilatCreateDto dto) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Tahsilat'),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(parseApiError(res));
    }
  }

  Future<void> update(String token, TahsilatUpdateDto dto) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/Tahsilat'),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 204)
      throw Exception(parseApiError(res));
  }

  Future<void> delete(String token, String id) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/Tahsilat/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }
}
