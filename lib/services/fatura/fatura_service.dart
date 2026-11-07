import '../ebelge/portal_service.dart';
import 'dart:convert';
/*import 'package:flutter/foundation.dart';*/
import 'package:FilERP/services/auth/authorized_http.dart' as http;

import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../models/entities/fatura/fatura_list_dto.dart';
import '../../models/entities/fatura/fatura_dto.dart';
import '../../models/entities/fatura/fatura_create_dto.dart';
import '../../models/entities/fatura/fatura_update_dto.dart';
import '../../models/entities/fatura/faturahareket_dto.dart';

class FaturaService {

  Map<String, String> _headers(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  // =================================================
  //  SATIŞ FATURASI - LİSTE
  // =================================================
  Future<List<FaturaListDto>> getSatisFaturaList(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Fatura"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(res.body);
    final List list = body["Data"] ?? [];
    return list.map((e) => FaturaListDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  // =================================================
  //  SATIŞ FATURASI - DETAY (FULL)
  // =================================================
  Future<FaturaDto> getFaturaDetay(String token, String faturaId) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Fatura/FaturaFull/$faturaId"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(res.body);
    if (body["Data"] == null) throw Exception("Fatura detayı bulunamadı");
    return FaturaDto.fromJson(body["Data"]);
  }

  // =================================================
  //  YENİ FATURA NO - GET
  // =================================================
  Future<String> getNewFaturaNo(String token, String seri, int belgeyili) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Fatura/GetNewFaturaNo/$seri/$belgeyili"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(res.body);
    return body["Data"] as String;
  }

  // =================================================
  //  1 - FATURA ÜST BİLGİ KAYDET → Fatura/SaveSingle
  //  Dönen Data = yeni faturaId (Guid/String)
  // =================================================
  Future<String> saveSingle(String token, FaturaCreateDto dto) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/Fatura/SaveSingle"),
      headers: _headers(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(parseApiError(res));
    final body = jsonDecode(res.body);
    return body["Data"]?.toString() ?? "";
  }

  // =================================================
  //  2 - FATURA SATIR KAYDET → Faturahareket/SaveSingle
  //  faturaid, dto içinde dolu olmalı
  // =================================================
  Future<String?> saveRowSingle(String token, FaturahareketDto dto) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/Faturahareket/SaveSingle"),
      headers: _headers(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("[${res.statusCode}] ${parseApiError(res)}\n\nHam Yanıt: ${res.body}");
    }
    try {
      final body = jsonDecode(res.body);
      final data = body["Data"];
      if (data != null) return data.toString();
    } catch (_) {}
    return null;
  }

  // =================================================
  //  3 - FATURA ÜST BİLGİ GÜNCELLE → Fatura/UpdateSingle
  // =================================================
  Future<void> updateSingle(String token, FaturaUpdateDto dto) async {
    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/Fatura/UpdateSingle"),
      headers: _headers(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  // =================================================
  //  4+5 - FATURA SATIR GÜNCELLE → Faturahareket/UpdateRowSingle
  //        YENİ SATIR EKLE   → Faturahareket/SaveSingle
  //  Kalem id dolu ise güncelle, null ise yeni kayıt
  // =================================================
  Future<void> saveOrUpdateRow(String token, FaturahareketDto dto) async {
    if (dto.id != null) {
      final body = jsonEncode(dto.toJson());
      final res = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/Faturahareket/UpdateSingle"),
        headers: _headers(token),
        body: body,
      );
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception("[${res.statusCode}] ${utf8.decode(res.bodyBytes)}");
      }
    } else {
      final savedId = await saveRowSingle(token, dto);
      if (savedId != null) dto.id = savedId;
    }
  }

  // =================================================
  //  FATURA SİL
  // =================================================
  Future<void> deleteFatura(String token, String faturaId) async {
    final res = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/Fatura/RemoveWithItems/$faturaId"),
      headers: _headers(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  // =================================================
  //  KALEM SİL → Faturahareket/RemoveSingle/{kalemId}
  // =================================================
  Future<void> removeKalem(String token, String kalemId) async {
    final res = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/Faturahareket/RemoveSingle/$kalemId"),
      headers: _headers(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  // =================================================
  //  BELGE DURUM GÜNCELLE  (0=Taslak, 1=Tamamlandı)
  // =================================================
  Future<void> belgeDurumGuncelle(String token, String faturaId, int yeniDurum) async {
    final endpoint = yeniDurum == 0 ? "BacktoDraft" : "Complete";
    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/Fatura/$endpoint/$faturaId"),
      headers: _headers(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  // =================================================
  //  PORTALA GÖNDER
  // =================================================
  Future<void> portalaGonder(String token, String faturaId) =>
      PortalService().send(token, faturaId, PortalDocument.invoice);

  // =================================================
  //  ALIŞ FATURASI - LİSTE
  // =================================================
  Future<List<FaturaListDto>> getAlisFaturaList(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/FaturaAlis"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(res.body);
    final List list = body["Data"] ?? [];
    return list.map((e) => FaturaListDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  // =================================================
  //  ALIŞ FATURASI - DETAY (FULL)
  // =================================================
  Future<FaturaDto> getAlisFaturaDetay(String token, String faturaId) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/FaturaAlis/FaturaFull/$faturaId"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(res.body);
    if (body["Data"] == null) throw Exception("Fatura detayı bulunamadı");
    return FaturaDto.fromJson(body["Data"]);
  }

  // =================================================
  //  ALIŞ FATURASI - YENİ NO
  // =================================================
  Future<String> getNewAlisFaturaNo(String token, String seri, int belgeyili) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/FaturaAlis/GetNewFaturaNo/$seri/$belgeyili"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(res.body);
    return body["Data"] as String;
  }

  // =================================================
  //  ALIŞ FATURASI - KAYDET
  // =================================================
  Future<String> saveAlisSingle(String token, FaturaCreateDto dto) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/FaturaAlis/SaveSingle"),
      headers: _headers(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(parseApiError(res));
    final body = jsonDecode(res.body);
    return body["Data"]?.toString() ?? "";
  }

  // =================================================
  //  ALIŞ FATURASI - GÜNCELLE
  // =================================================
  Future<void> updateAlisSingle(String token, FaturaUpdateDto dto) async {
    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/FaturaAlis/UpdateSingle"),
      headers: _headers(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  // =================================================
  //  ALIŞ FATURASI - SİL
  // =================================================
  Future<void> deleteAlisFatura(String token, String faturaId) async {
    final res = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/FaturaAlis/RemoveWithItems/$faturaId"),
      headers: _headers(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  // =================================================
  //  ALIŞ FATURASI - BELGE DURUM
  // =================================================
  Future<void> alisBelgeDurumGuncelle(String token, String faturaId, int yeniDurum) async {
    final endpoint = yeniDurum == 0 ? "BacktoDraft" : "Complete";
    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/FaturaAlis/$endpoint/$faturaId"),
      headers: _headers(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  // =================================================
  //  ALIŞ FATURASI - KALEM KAYDET
  // =================================================
  Future<String?> saveAlisRowSingle(String token, FaturahareketDto dto) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/FaturahareketAlis/SaveSingle"),
      headers: _headers(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("[${res.statusCode}] ${parseApiError(res)}\n\nHam Yanıt: ${res.body}");
    }
    try {
      final body = jsonDecode(res.body);
      final data = body["Data"];
      if (data != null) return data.toString();
    } catch (_) {}
    return null;
  }

  // =================================================
  //  ALIŞ FATURASI - KALEM GÜNCELLE / YENİ
  // =================================================
  Future<void> saveOrUpdateAlisRow(String token, FaturahareketDto dto) async {
    if (dto.id != null) {
      final res = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/FaturahareketAlis/UpdateSingle"),
        headers: _headers(token),
        body: jsonEncode(dto.toJson()),
      );
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception("[${res.statusCode}] ${utf8.decode(res.bodyBytes)}");
      }
    } else {
      final savedId = await saveAlisRowSingle(token, dto);
      if (savedId != null) dto.id = savedId;
    }
  }

  // =================================================
  //  ALIŞ FATURASI - KALEM SİL
  // =================================================
  Future<void> removeAlisKalem(String token, String kalemId) async {
    final res = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/FaturahareketAlis/RemoveSingle/$kalemId"),
      headers: _headers(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }
}