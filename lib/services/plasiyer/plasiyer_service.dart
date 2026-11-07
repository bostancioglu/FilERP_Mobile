import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;

import '../../config/api_config.dart';
import '../../models/entities/plasiyer/plasiyer_dto.dart';

class PlasiyerService {
  Future<List<PlasiyerDto>> getPlasiyerler(String token) async {
    final url = "${ApiConfig.baseUrl}/Plasiyer/AllWithoutAuth";

    final res = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Plasiyer listesi alınamadı (${res.statusCode})");
    }

    final body = jsonDecode(res.body);

    final List list = body["Data"] ?? [];

    return list
        .map((e) => PlasiyerDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
