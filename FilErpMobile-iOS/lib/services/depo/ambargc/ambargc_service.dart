import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../../config/api_config.dart';
import '../../../helpers/response.dart';
import '../../../models/entities/depo/ambargc_dto.dart';

class AmbargcService {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ─── LİSTELE ────────────────────────────────────────────

  Future<List<AmbargcDto>> getList(String token) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/Ambargc"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? [];
    return list
        .where((e) => e != null)
        .map((e) => AmbargcDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── DETAY ──────────────────────────────────────────────

  Future<AmbargcDto> getById(String token, String id) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/Ambargc/AmbargcFull/$id"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final data = body is Map && body.containsKey("Data") ? body["Data"] : body;
    if (data == null) throw Exception("Ambar G/Ç verisi boş geldi");
    return AmbargcDto.fromJson(data as Map<String, dynamic>);
  }

  // ─── YENİ NO ────────────────────────────────────────────

  Future<String> getNewNo(String token, String seri, int yil) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/Ambargc/GetNewAmbargcNo/$seri/$yil"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString() ?? '';
  }

  // ─── KAYDET ─────────────────────────────────────────────

  Future<String> saveSingle(String token, Map<String, dynamic> dto) async {
    final res = await http.post(Uri.parse("${ApiConfig.baseUrl}/Ambargc/SaveSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString() ?? '';
  }

  // ─── GÜNCELLE ───────────────────────────────────────────

  Future<void> updateSingle(String token, Map<String, dynamic> dto) async {
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/Ambargc/UpdateSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  // ─── SİL ────────────────────────────────────────────────

  Future<void> removeWithItems(String token, String id) async {
    final res = await http.delete(Uri.parse("${ApiConfig.baseUrl}/Ambargc/RemoveWithItems/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  // ─── BELGE DURUM ────────────────────────────────────────

  Future<void> belgeDurumGuncelle(String token, String id, int yeniDurum) async {
    final endpoint = yeniDurum == 1 ? "Complete" : "BacktoDraft";
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/Ambargc/$endpoint/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  // ─── HAREKET KAYDET ─────────────────────────────────────

  Future<String?> saveHareket(String token, Map<String, dynamic> dto) async {
    final res = await http.post(Uri.parse("${ApiConfig.baseUrl}/Ambargchareket/SaveSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString();
  }

  // ─── HAREKET GÜNCELLE ───────────────────────────────────

  Future<void> updateHareket(String token, Map<String, dynamic> dto) async {
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/Ambargchareket/UpdateSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  // ─── HAREKET SİL ────────────────────────────────────────

  Future<void> deleteHareket(String token, String id) async {
    final res = await http.delete(Uri.parse("${ApiConfig.baseUrl}/Ambargchareket/RemoveSingle/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }
}