import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/cek/cekverilenodeme_dto.dart';
import '../../models/entities/finans/cek/cekverilenodeme_create_dto.dart';

class CekverilenodemeService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<CekverilenodemeDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekverilenodeme'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => CekverilenodemeDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CekverilenodemeDto> getFull(String token, String id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekverilenodeme/CekverilenodemeFull/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return CekverilenodemeDto.fromJson(body['Data'] as Map<String, dynamic>);
  }

  Future<String> getNewCekverilenodemeNo(String token, String seri, int yil) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekverilenodeme/GetNewCekverilenodemeNo/$seri/$yil'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body['Data'].toString();
  }

  Future<String> saveSingle(String token, CekverilenodemeCreateDto dto) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Cekverilenodeme/SaveSingle'),
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
      Uri.parse('${ApiConfig.baseUrl}/Cekverilenodeme/RemoveWithItems/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }

  Future<void> complete(String token, String id) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/Cekverilenodeme/Complete/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }
}
