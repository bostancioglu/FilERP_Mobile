import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/senet/senetverilenhareket_dto.dart';
import '../../models/entities/finans/senet/senetverilenhareket_filter_dto.dart';

/// Senetverilenhareket (tekil borç senedi) sorgu servisi — senet girişi SenetverilenService.saveWithItems
/// üzerinden yapılır, bu servis mevcut senetleri filtrelemek (ör. ödeme/iade için ciro'lu senetler) içindir.
class SenetverilenhareketService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<String> getNewSenetverilenhareketNo(String token, String seri, int yil) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Senetverilenhareket/GetNewSenetverilenhareketNo/$seri/$yil'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body['Data'].toString();
  }

  Future<List<SenetverilenhareketDto>> filter(String token, SenetverilenhareketFilterDto filter) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Senetverilenhareket/Filter'),
      headers: _h(token),
      body: jsonEncode(filter.toJson()),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => SenetverilenhareketDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}
