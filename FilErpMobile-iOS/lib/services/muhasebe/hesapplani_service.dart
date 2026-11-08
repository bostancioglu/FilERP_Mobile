import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../models/entities/muhasebe/hesapplani_dto.dart';

class HesapplaniService {
  Future<List<HesapplaniDto>> getForSelection(String token) async {
    final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/Hesapplani/AllWithoutAuth'),
        headers: _h(token));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return ((body['Data'] ?? []) as List)
        .map((e) => HesapplaniDto.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.tur == 5)
        .toList();
  }

  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<HesapplaniDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Hesapplani'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list
        .map((e) => HesapplaniDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
