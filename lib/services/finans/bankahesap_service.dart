import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/banka/bankahesap_dto.dart';
import '../../models/entities/finans/banka/bankahesap_create_dto.dart';
import '../../models/entities/finans/banka/vw_finansbankahesaptoplam_dto.dart';

class BankahesapService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<BankahesapDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Bankahesap'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list
        .map((e) => BankahesapDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<VwFinansbankahesaptoplamDto>> getBankahesapToplam(
      String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/VW_Finansbankatoplam'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list
        .map((e) =>
            VwFinansbankahesaptoplamDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BankahesapDto>> getAllWithoutAuth(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Bankahesap/AllWithoutAuth'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list
        .map((e) => BankahesapDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(String token, BankahesapCreateDto dto) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Bankahesap'),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(parseApiError(res));
    }
  }

  Future<void> update(String token, BankahesapCreateDto dto) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/Bankahesap'),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 204)
      throw Exception(parseApiError(res));
  }

  Future<void> delete(String token, int id) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/Bankahesap/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }
}
