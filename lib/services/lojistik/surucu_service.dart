import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../models/entities/lojistik/surucu_dto.dart';

class SurucuService {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<SurucuDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Surucu/AllWithoutAuth"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception("Sürücü listesi alınamadı (${res.statusCode})");
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? body;
    return list
        .where((e) => e != null)
        .map((e) => SurucuDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}