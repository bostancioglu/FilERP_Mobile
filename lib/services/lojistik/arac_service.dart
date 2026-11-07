import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../models/entities/lojistik/arac_dto.dart';

class AracService {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<AracDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Arac/AllWithoutAuth"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception("Araç listesi alınamadı (${res.statusCode})");
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? body;
    return list
        .where((e) => e != null)
        .map((e) => AracDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Seçilince detayını çek — Lojistikcari navigation dahil
  Future<AracDto?> getByIdWithoutAuth(int id, String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Arac/WithoutAuth/$id"),
      headers: _headers(token),
    );
    debugPrint(">>> AracGetById status: ${res.statusCode}");
    if (res.statusCode != 200) return null;
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final data = body["Data"] ?? body;
    if (data == null) return null;
    return AracDto.fromJson(data as Map<String, dynamic>);
  }
}