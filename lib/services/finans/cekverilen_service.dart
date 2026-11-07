import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/cek/cekverilen_dto.dart';
import '../../models/entities/finans/cek/cekverilen_create_dto.dart';

class CekverilenService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<CekverilenDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekverilen'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => CekverilenDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CekverilenDto> getFull(String token, String id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekverilen/CekverilenFull/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return CekverilenDto.fromJson(body['Data'] as Map<String, dynamic>);
  }

  Future<String> getNewCekverilenNo(String token, String seri, int yil) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekverilen/GetNewCekverilenNo/$seri/$yil'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body['Data'].toString();
  }

  Future<String> saveWithItems(String token, CekverilenCreateDto dto) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Cekverilen/SaveWithItems'),
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
      Uri.parse('${ApiConfig.baseUrl}/Cekverilen/RemoveWithItems/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }

  Future<void> complete(String token, String id) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/Cekverilen/Complete/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }
}
