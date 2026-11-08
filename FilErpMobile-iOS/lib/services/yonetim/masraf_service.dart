import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../models/entities/yonetim/masraf_dto.dart';

class MasrafService {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<MasrafDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Masraf/AllWithoutAuth"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? body;
    return list
        .where((e) => e != null)
        .map((e) => MasrafDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MasrafDto?> getById(String token, int id) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Masraf/WithoutAuth/$id"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) return null;
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final data = body is Map && body.containsKey("Data") ? body["Data"] : body;
    if (data == null) return null;
    return MasrafDto.fromJson(data as Map<String, dynamic>);
  }
}