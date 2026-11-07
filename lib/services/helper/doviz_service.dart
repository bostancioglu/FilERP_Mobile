import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../models/entities/helper/doviz_dto.dart';

class DovizService {
  Future<List<DovizDto>> getDovizler(String token) async {
    final url = "${ApiConfig.baseUrl}/Doviz";

    final res = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Döviz listesi alınamadı (${res.statusCode})");
    }

    final body = jsonDecode(res.body);
    final List list = body["Data"] ?? [];

    return list
        .map((e) => DovizDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Bugünün kurunu döviz ID'ye göre çek
  Future<double?> getTodayByDovizId(String token, int dovizId) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Kur/GetTodayByDovizId/$dovizId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    final data = body["Data"];
    if (data == null) return null;
    if (data is num) return data.toDouble();
    if (data is Map) {
      return (data["Dovizsatis"] as num?)?.toDouble() ??
             (data["Dovizalis"] as num?)?.toDouble();
    }
    return null;
  }
}