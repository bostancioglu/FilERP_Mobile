import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;

import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../models/entities/fatura/resolve/alis_fatura_resolve_result.dart';

class AlisFaturaResolveService {
  /// Fatura görselini/PDF'ini backend'e yükler; backend AI ile okuyup
  /// cari/stok/döviz eşleştirmesini kendi tarafında dener, sonucu döner.
  Future<AlisFaturaResolveResult> resolveFromImage(
    String token,
    List<int> bytes,
    String dosyaAdi,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/FaturaAlis/ResolveFromImage');
    http.checkRequest('POST', uri, headers: {'Authorization': 'Bearer $token'});
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('UploadFile', bytes,
          filename: dosyaAdi));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) throw Exception(parseApiError(res));

    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final data = (body is Map && body['Data'] != null)
        ? body['Data']
        : (body is Map && body['data'] != null ? body['data'] : body);
    return AlisFaturaResolveResult.fromJson(data as Map<String, dynamic>);
  }

  /// "Senkronize Et" — kullanıcı eksik cari/stok/proje/ölçü birimi kaydını
  /// başka bir ekrandan oluşturduktan sonra, aynı sonucu backend'e geri
  /// gönderip eşleştirmeyi (Eksikler/KaydaHazir) yeniden hesaplatır.
  Future<AlisFaturaResolveResult> resolve(
      String token, Map<String, dynamic> mevcutSonuc) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/FaturaAlis/Resolve'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(mevcutSonuc),
    );

    if (res.statusCode != 200) throw Exception(parseApiError(res));

    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final data = (body is Map && body['Data'] != null)
        ? body['Data']
        : (body is Map && body['data'] != null ? body['data'] : body);
    return AlisFaturaResolveResult.fromJson(data as Map<String, dynamic>);
  }
}
