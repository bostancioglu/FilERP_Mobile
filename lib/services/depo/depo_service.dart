import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;

import '../../config/api_config.dart';
import '../../models/entities/depo/depo_dto.dart';
import '../../models/entities/depo/depoadres_dto.dart';

class DepoService {
  Map<String, String> _headers(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  Future<List<DepoDto>> getDepoList(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Depo/AllWithoutAuth"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception("Depo listesi alınamadı");
    final Map<String, dynamic> decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final List data = decoded["Data"] ?? [];
    return data.map((e) => DepoDto.fromJson(e)).toList();
  }

  /// Tam depo listesi (Plasiyerid / Plasiyerdeposu dahil). Yetki (Tümünü okuma) gerektirir.
  Future<List<DepoDto>> getTamListe(String token) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/Depo"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception("Depo listesi alınamadı (${res.statusCode})");
    final Map<String, dynamic> decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final List data = decoded["Data"] ?? [];
    return data.map((e) => DepoDto.fromJson(e)).toList();
  }

  /// Depo arama (Depo/Search) — yalnızca oturum açmış olmak yeter (Tümünü okuma yetkisi istemez),
  /// plasiyer kısıtı uygulanır ve Plasiyerid / Plasiyerdeposu dahil TAM kayıt döner.
  /// Metin kodla birebir eşleşirse yalnızca o kayıt gelir.
  Future<List<DepoDto>> ara(String token, String text) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Depo/Search?text=${Uri.encodeQueryComponent(text)}"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception("Depo araması yapılamadı (${res.statusCode})");
    final Map<String, dynamic> decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final List data = decoded["Data"] ?? [];
    return data.map((e) => DepoDto.fromJson(e)).toList();
  }

  Future<List<DepoDto>> getAllBySubeId(String token, int subeId) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Depo/AllBySubeidWithoutAuth/$subeId"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception("Depo listesi alınamadı");
    final Map<String, dynamic> decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final List data = decoded["Data"] ?? [];
    return data.map((e) => DepoDto.fromJson(e)).toList();
  }

  /// Tüm depo adresleri — Depoadres/WithoutAuth
  Future<List<DepoadresDto>> getDepoadresAll(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Depoadres/WithoutAuth"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception("Depo adresleri alınamadı");
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final List data = decoded is Map ? (decoded["Data"] ?? decoded["data"] ?? []) : decoded;
    return data.map((e) => DepoadresDto.fromJson(e)).toList();
  }

  /// Depoya göre adresler — Depoadres/AllWithoutAuthByDepoid/{depoid}
  Future<List<DepoadresDto>> getDepoadresByDepoId(String token, int depoId) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Depoadres/AllWithoutAuthByDepoid/$depoId"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception("Depo adresleri alınamadı");
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final List data = decoded is Map ? (decoded["Data"] ?? decoded["data"] ?? []) : decoded;
    return data.map((e) => DepoadresDto.fromJson(e)).toList();
  }
}