import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;

import '../../config/api_config.dart';
import '../../models/entities/firma/sube_dto.dart';

class SubeService {
  Map<String, String> _headers(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  Future<List<SubeDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Sube/AllWithoutAuth"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception("Şube listesi alınamadı (${res.statusCode})");
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? [];
    return list.map((e) => SubeDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}