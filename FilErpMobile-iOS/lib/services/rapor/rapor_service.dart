import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../models/entities/rapor/stok/view_stokhareket.dart';
import '../../models/entities/rapor/stok/stokbakiye_dto.dart';
import '../../models/entities/rapor/cari/view_carihareket.dart';

class RaporService {
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<ViewStokhareket>> getStokHareket(String token, {
    DateTime? tarih1, DateTime? tarih2,
    int? stokid, int? cariid, int? projeid, int? depoid,
  }) async {
    final filter = {
      if (tarih1  != null) "Tarih1":  tarih1.toIso8601String(),
      if (tarih2  != null) "Tarih2":  tarih2.toIso8601String(),
      if (stokid  != null) "Stokid":  stokid,
      if (cariid  != null) "Cariid":  cariid,
      if (projeid != null) "Projeid": projeid,
      if (depoid  != null) "Depoid":  depoid,
    };
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/VW_Stokhareket/Filter"),
      headers: _headers(token), body: jsonEncode(filter));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? body;
    return list.where((e) => e != null)
        .map((e) => ViewStokhareket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Malzeme bazında toplam giriş/çıkış/kalan — VW_Stokhareket/FilterStokbakiye
  Future<List<StokbakiyeDto>> getStokBakiye(String token, {
    DateTime? tarih1, DateTime? tarih2, int? depoid, int? stokid,
  }) async {
    final filter = {
      if (tarih1 != null) "Tarih1": tarih1.toIso8601String(),
      if (tarih2 != null) "Tarih2": tarih2.toIso8601String(),
      if (depoid != null) "Depoid": depoid,
      if (stokid != null) "Stokid": stokid,
    };
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/VW_Stokhareket/FilterStokbakiye"),
      headers: _headers(token), body: jsonEncode(filter));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? body;
    return list.where((e) => e != null)
        .map((e) => StokbakiyeDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ViewCarihareket>> getCariHareket(String token, {
    DateTime? tarih1, DateTime? tarih2, int? cariid, int? projeid, int? dovizid,
  }) async {
    final filter = {
      if (tarih1  != null) "Tarih1":  tarih1.toIso8601String(),
      if (tarih2  != null) "Tarih2":  tarih2.toIso8601String(),
      if (cariid  != null) "Cariid":  cariid,
      if (projeid != null) "Projeid": projeid,
      if (dovizid != null) "Dovizid": dovizid,
    };
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/VW_Carihareket/Filter"),
      headers: _headers(token), body: jsonEncode(filter));
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body["Data"] ?? body;
    return list.where((e) => e != null)
        .map((e) => ViewCarihareket.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}