import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;

import '../../config/api_config.dart';
import '../../models/entities/proje/proje_dto.dart';

class ProjeService {
  Future<List<ProjeDto>> getProjeList(String token) async {
    final url = "${ApiConfig.baseUrl}/Proje/AllWithoutAuth";

    final res = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Proje listesi alınamadı");
    }

    final body = jsonDecode(res.body);

    final List list = body["Data"] ?? [];

    // Web'deki ProjeSelector ile aynı: sadece Tür = 3 ("Proje") listelenir;
    // Ana (1) ve Grup (2) türleri seçim listelerinde gösterilmez.
    // (AllWithoutAuth ucu Tip alanını göndermediği için süzme Tur'a göre yapılır.)
    return list
        .map((e) => ProjeDto.fromJson(e as Map<String, dynamic>))
        .where((p) => p.tur == 3)
        .toList();
  }
}
