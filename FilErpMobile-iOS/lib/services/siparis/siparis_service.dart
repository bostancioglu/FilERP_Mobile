import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../models/entities/siparis/siparis_dto.dart';

class SiparisService {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ─── SATIŞ SİPARİŞ ──────────────────────────────────────

  Future<List<SiparisDto>> getSatisList(String token) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/Siparis"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? [];
    return list.where((e) => e != null).map((e) => SiparisDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SiparisDto> getSatisById(String token, String id) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/Siparis/SiparisFull/$id"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final data = body is Map && body.containsKey("Data") ? body["Data"] : body;
    return SiparisDto.fromJson(data as Map<String, dynamic>);
  }

  Future<String> getNewSatisNo(String token, String seri, int yil) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/Siparis/GetNewSiparisNo/$seri/$yil"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString() ?? '';
  }

  Future<String> saveSatisSingle(String token, Map<String, dynamic> dto) async {
    final res = await http.post(Uri.parse("${ApiConfig.baseUrl}/Siparis/SaveSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString() ?? '';
  }

  Future<void> updateSatisSingle(String token, Map<String, dynamic> dto) async {
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/Siparis/UpdateSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  Future<void> deleteSatis(String token, String id) async {
    final res = await http.delete(Uri.parse("${ApiConfig.baseUrl}/Siparis/RemoveWithItems/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  Future<void> satisBelgeDurumGuncelle(String token, String id, int yeniDurum) async {
    final endpoint = yeniDurum == 1 ? "Complete" : "BacktoDraft";
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/Siparis/$endpoint/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  Future<String?> saveSatisHareket(String token, Map<String, dynamic> dto) async {
    final res = await http.post(Uri.parse("${ApiConfig.baseUrl}/Siparishareket/SaveSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString();
  }

  Future<void> updateSatisHareket(String token, Map<String, dynamic> dto) async {
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/Siparishareket/UpdateSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  Future<void> deleteSatisHareket(String token, String id) async {
    final res = await http.delete(Uri.parse("${ApiConfig.baseUrl}/Siparishareket/RemoveSingle/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  // ─── ALIŞ SİPARİŞ ───────────────────────────────────────

  Future<List<SiparisDto>> getAlisList(String token) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/SiparisAlis"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? [];
    return list.where((e) => e != null).map((e) => SiparisDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SiparisDto> getAlisById(String token, String id) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/SiparisAlis/SiparisFull/$id"), headers: _headers(token));
    debugPrint(">>> getAlisById status: ${res.statusCode}");
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final bodyStr = utf8.decode(res.bodyBytes);
    debugPrint(">>> getAlisById body[:500]: ${bodyStr.substring(0, bodyStr.length > 500 ? 500 : bodyStr.length)}");
    final body = jsonDecode(bodyStr);
    final data = body is Map && body.containsKey("Data") ? body["Data"] : body;
    debugPrint(">>> getAlisById data type: ${data.runtimeType}");
    if (data == null) throw Exception("Sipariş verisi boş geldi");
    try {
      return SiparisDto.fromJson(data as Map<String, dynamic>);
    } catch (e, st) {
      debugPrint(">>> SiparisDto.fromJson HATA: $e");
      debugPrint(">>> Stack: $st");
      rethrow;
    }
  }

  Future<String> getNewAlisNo(String token, String seri, int yil) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/SiparisAlis/GetNewSiparisNo/$seri/$yil"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString() ?? '';
  }

  Future<String> saveAlisSingle(String token, Map<String, dynamic> dto) async {
    final res = await http.post(Uri.parse("${ApiConfig.baseUrl}/SiparisAlis/SaveSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString() ?? '';
  }

  Future<void> updateAlisSingle(String token, Map<String, dynamic> dto) async {
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/SiparisAlis/UpdateSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  Future<void> deleteAlis(String token, String id) async {
    final res = await http.delete(Uri.parse("${ApiConfig.baseUrl}/SiparisAlis/RemoveWithItems/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  Future<void> alisBelgeDurumGuncelle(String token, String id, int yeniDurum) async {
    final endpoint = yeniDurum == 1 ? "Complete" : "BacktoDraft";
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/SiparisAlis/$endpoint/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  Future<String?> saveAlisHareket(String token, Map<String, dynamic> dto) async {
    final res = await http.post(Uri.parse("${ApiConfig.baseUrl}/SiparishareketAlis/SaveSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString();
  }

  Future<void> updateAlisHareket(String token, Map<String, dynamic> dto) async {
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/SiparishareketAlis/UpdateSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  Future<void> deleteAlisHareket(String token, String id) async {
    final res = await http.delete(Uri.parse("${ApiConfig.baseUrl}/SiparishareketAlis/RemoveSingle/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }
}