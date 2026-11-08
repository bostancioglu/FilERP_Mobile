import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;

import '../../../config/api_config.dart';
import '../../../helpers/response.dart';
import '../../../models/entities/depo/dat_dto.dart';
import '../../../models/entities/depo/depo_dto.dart';

class DatService {
  Map<String, String> _headers(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  Future<List<DatDto>> getList(String token) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/Dat"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? [];
    return list.map((e) => DatDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DatDto> getById(String token, String id) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/Dat/DatFull/$id"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return DatDto.fromJson(body["Data"]);
  }

  Future<String> getNewDatNo(String token, String seri, int belgeYil) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/Dat/GetNewDatNo/$seri/$belgeYil"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"].toString();
  }

  Future<List<DepoDto>> getDepoListBySubeId(String token, int subeId) async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/Depo/AllBySubeidWithoutAuth/$subeId"), headers: _headers(token));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? [];
    return list.map((e) => DepoDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> saveSingle(String token, Map<String, dynamic> dto) async {
    final res = await http.post(Uri.parse("${ApiConfig.baseUrl}/Dat/SaveSingle"), headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body["Data"].toString();
  }

  Future<void> updateSingle(String token, Map<String, dynamic> dto) async {
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/Dat/UpdateSingle"), headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  Future<String?> saveHareket(String token, Map<String, dynamic> dto) async {
    final res = await http.post(Uri.parse("${ApiConfig.baseUrl}/Dathareket/SaveSingle"), headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception(parseApiError(res));
    try { final body = jsonDecode(utf8.decode(res.bodyBytes)); return body["Data"]?.toString(); } catch (_) { return null; }
  }

  Future<void> updateHareket(String token, Map<String, dynamic> dto) async {
    final res = await http.put(Uri.parse("${ApiConfig.baseUrl}/Dathareket/UpdateSingle"), headers: _headers(token), body: jsonEncode(dto));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  Future<void> deleteHareket(String token, String id) async {
    final res = await http.delete(Uri.parse("${ApiConfig.baseUrl}/Dathareket/RemoveSingle/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  Future<void> deleteDat(String token, String id) async {
    final res = await http.delete(Uri.parse("${ApiConfig.baseUrl}/Dat/RemoveWithItems/$id"), headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }

  Future<void> belgeDurumGuncelle(String token, String datId, int yeniDurum) async {
    final endpoint = yeniDurum == 1 ? "Complete" : "BacktoDraft";
    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/Dat/$endpoint/$datId"),
      headers: _headers(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception(parseApiError(res));
  }
}