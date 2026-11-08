import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../models/entities/stok/stok_kategori_dto.dart';

class StokKategoriService {
  Future<List<StokkategoriDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Stokkategori/AllWithoutAuth"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Stok kategorileri alınamadı");
    }

    final body = jsonDecode(res.body);
    final List list = body["Data"] ?? [];

    return list
        .map((e) => StokkategoriDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
