import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/cek/cekalinaniadehareket_dto.dart';
import '../../models/entities/finans/cek/cekalinaniadehareket_create_dto.dart';

class CekalinaniadehareketService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<CekalinaniadehareketDto>> getAllByCekalinaniadeId(String token, String cekalinaniadeId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinaniadehareket/GetAllByCekalinaniadeId/$cekalinaniadeId'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => CekalinaniadehareketDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveSingle(String token, CekalinaniadehareketCreateDto dto) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinaniadehareket/SaveSingle'),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(parseApiError(res));
    }
  }

  Future<void> removeSingle(String token, String id) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinaniadehareket/RemoveSingle/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }
}
