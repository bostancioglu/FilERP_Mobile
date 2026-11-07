import '../ebelge/portal_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:FilERP/services/auth/authorized_http.dart' as http;

import '../../config/api_config.dart';
import '../../models/entities/irsaliye/irsaliye_dto.dart';

class IrsaliyeService {
  Future<void> portalaGonder(String token, String irsaliyeId) =>
      PortalService().send(token, irsaliyeId, PortalDocument.waybill);

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  String _parseError(http.Response res) {
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      // Errors array varsa birleştir
      final errors = body["Errors"];
      if (errors is List && errors.isNotEmpty) {
        return errors.join(", ");
      }
      return body["Message"]?.toString() ?? body["message"]?.toString() ?? "İşlem sırasında hata oluştu (${res.statusCode})";
    } catch (_) {
      return "İşlem sırasında hata oluştu (${res.statusCode})";
    }
  }

  Future<List<IrsaliyeDto>> getList(String token) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/Irsaliye"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(_parseError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? [];
    return list.map((e) => IrsaliyeDto.fromJson(e)).toList();
  }

  Future<IrsaliyeDto> getById(String token, String id) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/Irsaliye/IrsaliyeFull/$id"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(_parseError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final data = body["Data"] ?? body;
    return IrsaliyeDto.fromJson(data as Map<String, dynamic>);
  }

  Future<String> getNewIrsaliyeNo(String token, String seri, int belgeYil) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/Irsaliye/GetNewIrsaliyeNo/$seri/$belgeYil"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(_parseError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString() ?? '';
  }

  Future<String> saveSingle(String token, Map<String, dynamic> dto) async {
    final res = await http.post(Uri.parse("${ApiConfig.baseUrl}/Irsaliye/SaveSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(_parseError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString() ?? '';
  }

  Future<void> updateSingle(String token, Map<String, dynamic> dto) async {
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/Irsaliye/UpdateSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(_parseError(res));
  }

  Future<void> removeWithItems(String token, String id) async {
    final res = await http.delete(Uri.parse("${ApiConfig.baseUrl}/Irsaliye/RemoveWithItems/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(_parseError(res));
  }

  Future<void> belgeDurumGuncelle(String token, String irsaliyeId, int yeniDurum) async {
    final endpoint = yeniDurum == 1 ? "Complete" : "BacktoDraft";
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/Irsaliye/$endpoint/$irsaliyeId"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(_parseError(res));
  }

  Future<String?> saveHareket(String token, Map<String, dynamic> dto) async {
    final res = await http.post(Uri.parse("${ApiConfig.baseUrl}/Irsaliyehareket/SaveSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(_parseError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString();
  }

  Future<void> updateHareket(String token, Map<String, dynamic> dto) async {
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/Irsaliyehareket/UpdateSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(_parseError(res));
  }

  Future<void> deleteHareket(String token, String id) async {
    final res = await http.delete(Uri.parse("${ApiConfig.baseUrl}/Irsaliyehareket/RemoveSingle/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(_parseError(res));
  }
  // ─── ALIŞ İRSALİYESİ ─────────────────────────────────────

  Future<List<IrsaliyeDto>> getAlisList(String token) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/IrsaliyeAlis"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(_parseError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? [];
    return list.map((e) => IrsaliyeDto.fromJson(e)).toList();
  }

  Future<IrsaliyeDto> getAlisById(String token, String id) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/IrsaliyeAlis/IrsaliyeFull/$id"), headers: _headers(token));
    debugPrint(">>> getAlisById status: ${res.statusCode}");
    debugPrint(">>> getAlisById body: ${utf8.decode(res.bodyBytes).substring(0, res.bodyBytes.length > 300 ? 300 : res.bodyBytes.length)}");
    if (res.statusCode != 200) throw Exception(_parseError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final data = body is Map && body.containsKey("Data") ? body["Data"] : body;
    if (data == null) throw Exception("API boş veri döndürdü");
    return IrsaliyeDto.fromJson(data as Map<String, dynamic>);
  }

  Future<String> saveAlisSingle(String token, Map<String, dynamic> dto) async {
    debugPrint(">>> saveAlisSingle dto: ${jsonEncode(dto)}");
    final res = await http.post(Uri.parse("${ApiConfig.baseUrl}/IrsaliyeAlis/SaveSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    debugPrint(">>> saveAlisSingle status: ${res.statusCode}");
    debugPrint(">>> saveAlisSingle response: ${utf8.decode(res.bodyBytes)}");
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(_parseError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString() ?? '';
  }

  Future<void> updateAlisSingle(String token, Map<String, dynamic> dto) async {
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/IrsaliyeAlis/UpdateSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(_parseError(res));
  }

  Future<void> removeAlisWithItems(String token, String id) async {
    final res = await http.delete(Uri.parse("${ApiConfig.baseUrl}/IrsaliyeAlis/RemoveWithItems/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(_parseError(res));
  }

  Future<void> alisBelgeDurumGuncelle(String token, String irsaliyeId, int yeniDurum) async {
    final endpoint = yeniDurum == 1 ? "Complete" : "BacktoDraft";
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/IrsaliyeAlis/$endpoint/$irsaliyeId"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(_parseError(res));
  }

  Future<String?> saveAlisHareket(String token, Map<String, dynamic> dto) async {
    debugPrint(">>> saveAlisHareket dto: ${jsonEncode(dto)}");
    final res = await http.post(Uri.parse("${ApiConfig.baseUrl}/IrsaliyehareketAlis/SaveSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    debugPrint(">>> saveAlisHareket status: ${res.statusCode}");
    debugPrint(">>> saveAlisHareket response: ${utf8.decode(res.bodyBytes)}");
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(_parseError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"]?.toString();
  }

  Future<void> updateAlisHareket(String token, Map<String, dynamic> dto) async {
    debugPrint(">>> updateAlisHareket dto: ${jsonEncode(dto)}");
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/IrsaliyehareketAlis/UpdateSingle"),
        headers: _headers(token), body: jsonEncode(dto));
    debugPrint(">>> updateAlisHareket status: ${res.statusCode}");
    debugPrint(">>> updateAlisHareket response: ${utf8.decode(res.bodyBytes)}");
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(_parseError(res));
  }

  Future<void> deleteAlisHareket(String token, String id) async {
    final res = await http.delete(Uri.parse("${ApiConfig.baseUrl}/IrsaliyehareketAlis/RemoveSingle/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(_parseError(res));
  }
}