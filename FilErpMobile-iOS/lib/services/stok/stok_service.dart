import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/stok/stok_list_dto.dart';
import '../../models/entities/stok/stok_dto.dart';
import '../cache/list_cache_service.dart';

class StokService {
  static const _cacheKey = 'stok_list';

  // =============================
  //  STOK LİSTESİ
  // =============================
  Future<List<StokListDto>> getStokList(String token) async {
    final url = "${ApiConfig.baseUrl}/Stok/AllWithoutAuth";

    http.Response res;
    try {
      res = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
    } catch (e) {
      if (e is YetkiHatasi) rethrow;
      // Ağ hatası — sunucudan cevap alınamadı, önbellek varsa ondan besle
      final cached = ListCacheService.instance.read(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached
            .map((e) => StokListDto.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }

    // Sunucudan cevap geldi (401/403/500 dahil) — önbellekle maskelenmemeli
    if (res.statusCode != 200) throw Exception(parseApiError(res));

    final body = jsonDecode(res.body);
    final List list = body["Data"] ?? [];

    await ListCacheService.instance.save(_cacheKey, list);

    return list
        .map((e) => StokListDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  // =============================
//  STOK DETAY (FULL)
// =============================
Future<StokDto> getStokFullById(String token, int stokId) async {
  final url = "${ApiConfig.baseUrl}/Stok/StokFull/$stokId";

  final res = await http.get(
    Uri.parse(url),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  if (res.statusCode != 200) {
    throw Exception(parseApiError(res));
  }

  final body = jsonDecode(res.body);

  if (body["Data"] == null) {
    throw Exception("Stok detayı yok");
  }

  return StokDto.fromJson(body["Data"]);
}
    // =============================
  //  STOK DETAY (WithoutAuth) - Stokolcubr dahil
  // =============================
  Future<StokDto> getStokById(String token, int stokId) async {
    final url = "${ApiConfig.baseUrl}/Stok/WithoutAuth/$stokId";
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(res.body);
    if (body["Data"] == null) throw Exception("Stok bulunamadı");
    return StokDto.fromJson(body["Data"]);
  }

  // ================= CREATE =================
Future<void> addStok(String token, Map<String, dynamic> json) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/Stok");

    final res = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(json),
    );

    if (res.statusCode >= 400) {  throw Exception(parseApiError(res)); }

}
    // ================= UPDATE =================
  Future<void> updateStok(String token, Map<String, dynamic> json) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/Stok");

    final res = await http.put(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(json),
    );

    if (res.statusCode != 200  && res.statusCode != 204)  throw Exception(parseApiError(res));
  }
    // ================= DELETE =================
  Future<void> deleteStok(String token, int stokId) async {
    final res = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/Stok/$stokId"),
      headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200  && res.statusCode != 204) {
      throw Exception(parseApiError(res));

    }
  }

}
