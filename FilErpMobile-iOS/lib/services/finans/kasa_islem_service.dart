import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/kasa_islem/vw_finanskasatoplam_dto.dart';
import '../../models/entities/finans/kasa_islem/kasa_dto.dart';
import '../../models/entities/finans/kasa_islem/bankahesap_dto.dart';
import '../../models/entities/finans/kasa_islem/kasahareket_create_dto.dart';
import '../../models/entities/finans/kasa_islem/kasahareket_update_dto.dart';
import '../../models/entities/finans/kasa_islem/kasahareket_dto.dart';

class KasaIslemService {
  Map<String, String> _h(String token) => {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

  // ── Kasa Toplam Listesi ────────────────────────────────────────────────────
  Future<List<VwFinanskasatoplamDto>> getKasaToplam(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/VW_Finanskasatoplam"),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? [];
    return list
        .map((e) => VwFinanskasatoplamDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Kasa Listesi ──────────────────────────────────────────────────────────
  Future<List<KasaDto>> getKasalar(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Kasa/AllWithoutAuth"),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? [];
    return list
        .map((e) => KasaDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Banka Hesap Listesi ───────────────────────────────────────────────────
  Future<List<BankahesapDto>> getBankaHesaplar(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Bankahesap/AllWithoutAuth"),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? [];
    return list
        .map((e) => BankahesapDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Kasaya Ait Hareketler ─────────────────────────────────────────────────
  Future<List<KasahareketDto>> getKasahareketByKasaid(
      String token, int kasaid) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Kasahareket/GetByKasaid/$kasaid"),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? [];
    return list
        .map((e) => KasahareketDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Yeni Belge No ─────────────────────────────────────────────────────────
  Future<String> getNewBelgeNo(String token, String seri, int yil) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Kasahareket/GetNewBelgeNo/$seri/$yil"),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"].toString();
  }

  // ── Kasahareket Kaydet (POST) ─────────────────────────────────────────────
  Future<String> saveKasahareket(String token, KasahareketCreateDto dto) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/Kasahareket"),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(parseApiError(res));
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString() ?? "";
  }

  // ── Kasahareket Güncelle (PUT) ────────────────────────────────────────────
  Future<void> updateKasahareket(String token, KasahareketUpdateDto dto) async {
    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/Kasahareket"),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 204)
      throw Exception(parseApiError(res));
  }

  // ── Kasahareket Sil (DELETE) ──────────────────────────────────────────────
  Future<void> deleteKasahareket(String token, String id) async {
    final res = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/Kasahareket/$id"),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }
}
