import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/cek/cekalinancirohareket_dto.dart';
import '../../models/entities/finans/cek/cekalinancirohareket_create_dto.dart';

class CekalinancirohareketService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<CekalinancirohareketDto>> getAllByCekalinanciroId(String token, String cekalinanciroId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinancirohareket/GetAllByCekalinanciroId/$cekalinanciroId'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => CekalinancirohareketDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveSingle(String token, CekalinancirohareketCreateDto dto) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinancirohareket/SaveSingle'),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(parseApiError(res));
    }
  }

  Future<void> removeSingle(String token, String id) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinancirohareket/RemoveSingle/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }
}
