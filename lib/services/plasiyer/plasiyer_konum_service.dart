import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;

import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../models/entities/plasiyer/plasiyer_konum_dto.dart';

/// Plasiyer canlı konum takibi.
///
/// Backend'de henüz karşılığı yok — bu servis, backend ekibine iletilecek
/// olan aşağıdaki sözleşmeye göre yazıldı:
///
///   POST /Plasiyerkonum
///     Body: { "Plasiyerid": int, "Enlem": double, "Boylam": double }
///     (Tarih sunucu tarafında set edilir)
///
///   GET /Plasiyerkonum/Son
///     Response: { "Data": [ { "Plasiyerid", "PlasiyerAdi", "Enlem", "Boylam", "Tarih" }, ... ] }
///     (Her plasiyerin en son bilinen konumu, tek kayıt/plasiyer)
class PlasiyerKonumService {
  Future<void> gonderKonum(
    String token, {
    required int plasiyerid,
    required double enlem,
    required double boylam,
  }) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/Plasiyerkonum"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "Plasiyerid": plasiyerid,
        "Enlem": enlem,
        "Boylam": boylam,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }

  Future<List<PlasiyerKonumDto>> getSonKonumlar(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Plasiyerkonum/Son"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) throw Exception(parseApiError(res));

    final body = jsonDecode(res.body);
    final List list = body["Data"] ?? [];
    return list
        .map((e) => PlasiyerKonumDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
