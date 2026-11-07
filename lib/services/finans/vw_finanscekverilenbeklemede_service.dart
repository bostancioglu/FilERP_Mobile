import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/cek/vw_finanscekverilen_dto.dart';

/// Borç Çek — Ödenecek/Bekleyen Çekler Raporu (VW_Finanscekverilenbeklemede)
class VwFinanscekverilenbeklemedeService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<VwFinanscekverilenDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/VW_Finanscekverilenbeklemede'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => VwFinanscekverilenDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}
