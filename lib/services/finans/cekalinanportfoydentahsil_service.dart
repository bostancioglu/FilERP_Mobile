import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/cek/cekalinanportfoydentahsil_dto.dart';
import '../../models/entities/finans/cek/cekalinanportfoydentahsil_create_dto.dart';

class CekalinanportfoydentahsilService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<CekalinanportfoydentahsilDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinanportfoydentahsil'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => CekalinanportfoydentahsilDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CekalinanportfoydentahsilDto> getFull(String token, String id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinanportfoydentahsil/CekalinanportfoydentahsilFull/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return CekalinanportfoydentahsilDto.fromJson(body['Data'] as Map<String, dynamic>);
  }

  Future<String> getNewCekalinanportfoydentahsilNo(String token, String seri, int yil) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinanportfoydentahsil/GetNewCekalinanportfoydentahsilNo/$seri/$yil'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body['Data'].toString();
  }

  Future<String> saveSingle(String token, CekalinanportfoydentahsilCreateDto dto) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinanportfoydentahsil/SaveSingle'),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(parseApiError(res));
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body['Data'].toString();
  }

  Future<void> removeWithItems(String token, String id) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinanportfoydentahsil/RemoveWithItems/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }

  Future<void> complete(String token, String id) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinanportfoydentahsil/Complete/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }
}
