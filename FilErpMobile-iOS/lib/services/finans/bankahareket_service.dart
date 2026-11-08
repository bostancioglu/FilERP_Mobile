import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/banka/bankahareket_dto.dart';
import '../../models/entities/finans/banka/bankahareket_create_dto.dart';
import '../../models/entities/finans/banka/bankahareket_update_dto.dart';

class BankahareketService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<BankahareketDto>> getByBankahesapid(
      String token, int bankahesapid) async {
    final res = await http.get(
      Uri.parse(
          '${ApiConfig.baseUrl}/Bankahareket/GetByBankahesapid/$bankahesapid'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list
        .map((e) => BankahareketDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> getNewBelgeNo(String token, String seri, int yil) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Bankahareket/GetNewBelgeNo/$seri/$yil'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body['Data'].toString();
  }

  Future<void> create(String token, BankahareketCreateDto dto) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Bankahareket'),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(parseApiError(res));
    }
  }

  Future<void> update(String token, BankahareketUpdateDto dto) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/Bankahareket'),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 204)
      throw Exception(parseApiError(res));
  }

  Future<void> delete(String token, String id) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/Bankahareket/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }
}
