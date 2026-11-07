import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/cari/cari_dto_full.dart';
import '../../models/entities/cari/cariadres_dto.dart';
import '../../models/entities/cari/cari_dto_lite.dart';
import '../../models/entities/cari/cari_dto.dart';
import '../cache/list_cache_service.dart';

class CariService {
  static const _cacheKey = 'cari_list';

  // =============================
  //  CARİ LİSTESİ LİTE
  // =============================
  Future<List<CariDtoLite>> getCariler(String token) async {
    final url = "${ApiConfig.baseUrl}/Cari";
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
      // Ağ hatası (internet yok, timeout vb.) — sunucudan cevap alınamadı,
      // önbellek varsa ondan besle
      final cached = ListCacheService.instance.read(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached
            .map((e) => CariDtoLite.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }

    // Sunucudan cevap geldi (401/403/500 dahil) — bu gerçek bir hata,
    // önbellekle maskelenmemeli (örn. yetki hatası kullanıcıya gösterilmeli)
    if (res.statusCode != 200) throw Exception(parseApiError(res));

    final body = jsonDecode(utf8.decode(res.bodyBytes));

    // API -> { Data: [...] }
    final List list = body["Data"] ?? [];

    await ListCacheService.instance.save(_cacheKey, list);

    return list
        .map((e) => CariDtoLite.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // =============================
  //  CARİ LİSTESİ TAM
  // =============================
  Future<List<CariDto>> getCariList(String token) async {
    final url = "${ApiConfig.baseUrl}/Cari/AllWithoutAuth";
    final res = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) throw Exception(parseApiError(res));

    final body = jsonDecode(utf8.decode(res.bodyBytes));

    // API -> { Data: [...] }
    final List list = body["Data"] ?? [];

    return list
        .map((e) => CariDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // =============================
  //  CARİ DETAY (FULL)
  // =============================
  Future<CariDtoFull> getCariFullById(String token, int cariId) async {
    final url = "${ApiConfig.baseUrl}/Cari/CariFull/$cariId";

    final res = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) throw Exception(parseApiError(res));

    final body = jsonDecode(utf8.decode(res.bodyBytes));

    if (body["Data"] == null) {
      throw Exception("Cari detay boş döndü");
    }

    return CariDtoFull.fromJson(body["Data"]);
  }

  // =============================
  //  CARİ EKLE
  // =============================
  Future<void> addCari(
    String token,
    Map<String, dynamic> json,
  ) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/Cari"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(json),
    );

    if (res.statusCode >= 400) {
      throw Exception(parseApiError(res));
    }
  }

  // =============================
  //  CARİ SİL
  // =============================
  Future<void> deleteCari(String token, int cariId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/Cari/$cariId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }

  // =============================
  //  CARİ UPDATE
  // =============================
  Future<void> updateCari(
    String token,
    Map<String, dynamic> json,
  ) async {
    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/Cari"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(json),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }

  // =============================
  //  CARİ ADRES LİSTESİ
  // =============================
  Future<List<CariadresDto>> getCariAdres(String token, int cariId) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Cari/Cariadres/$cariId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? [];
    return list
        .map((e) => CariadresDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
