import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../models/entities/yonetim/belge_seri_dto.dart';

class BelgeSeriService {
  Future<List<BelgeSeriDto>> getAll(String token,int belgeTuru) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Belgeseri/AllWithoutAuthByBelgeTuru/$belgeTuru"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Belge seri listesi alınamadı (${res.statusCode})");
    }

    final body = jsonDecode(res.body);
    final List list = body["Data"] ?? [];

    return list
        .map((e) => BelgeSeriDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}