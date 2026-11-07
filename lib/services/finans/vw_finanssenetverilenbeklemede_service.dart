import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/senet/vw_finanssenetverilen_dto.dart';

/// Borç Senet — Ödenecek/Bekleyen Senetler Raporu (VW_Finanssenetverilenbeklemede)
class VwFinanssenetverilenbeklemedeService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<VwFinanssenetverilenDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/VW_Finanssenetverilenbeklemede'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => VwFinanssenetverilenDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}
