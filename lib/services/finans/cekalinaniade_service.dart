import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/cek/cekalinaniade_dto.dart';
import '../../models/entities/finans/cek/cekalinaniade_create_dto.dart';

class CekalinaniadeService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<CekalinaniadeDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinaniade'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => CekalinaniadeDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CekalinaniadeDto> getFull(String token, String id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinaniade/CekalinaniadeFull/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return CekalinaniadeDto.fromJson(body['Data'] as Map<String, dynamic>);
  }

  Future<String> getNewCekalinaniadeNo(String token, String seri, int yil) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinaniade/GetNewCekalinaniadeNo/$seri/$yil'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body['Data'].toString();
  }

  Future<String> saveSingle(String token, CekalinaniadeCreateDto dto) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinaniade/SaveSingle'),
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
      Uri.parse('${ApiConfig.baseUrl}/Cekalinaniade/RemoveWithItems/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }

  Future<void> complete(String token, String id) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinaniade/Complete/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }
}
