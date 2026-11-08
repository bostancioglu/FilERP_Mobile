import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../models/entities/olcubirimi/olcubr_dto.dart';

class OlcubrService {
  Future<List<OlcubrDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Olcubr/AllWithoutAuth"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (res.statusCode != 200) throw Exception("Ölçü birimleri alınamadı");
    final body = jsonDecode(res.body);
    final List list = body["Data"] ?? [];
    return list.map((e) => OlcubrDto.fromJson(e)).toList();
  }

  Future<List<OlcubrDto>> getByStokId(String token, int stokId) async {
    final url = "${ApiConfig.baseUrl}/Stok/WithoutAuth/$stokId";
    print("=== OLCUBR REQUEST === $url");
    final res = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    print("=== OLCUBR RESPONSE === status: ${res.statusCode}, body: ${res.body}");
    if (res.statusCode != 200) throw Exception("Stok ölçü birimleri alınamadı");
    final body = jsonDecode(res.body);
    final List list = body["Data"] ?? [];
    return list.map((e) => OlcubrDto.fromJson(e)).toList();
  }
}