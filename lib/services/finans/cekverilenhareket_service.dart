import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/cek/cekverilenhareket_dto.dart';
import '../../models/entities/finans/cek/cekverilenhareket_filter_dto.dart';

/// Cekverilenhareket (tekil borç çeki) sorgu servisi — çek girişi CekverilenService.saveWithItems
/// üzerinden yapılır, bu servis mevcut çekleri filtrelemek (ör. ödeme/iade için ciro'lu çekler) içindir.
class CekverilenhareketService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<String> getNewCekverilenhareketNo(String token, String seri, int yil) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Cekverilenhareket/GetNewCekverilenhareketNo/$seri/$yil'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    return body['Data'].toString();
  }

  Future<List<CekverilenhareketDto>> filter(String token, CekverilenhareketFilterDto filter) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Cekverilenhareket/Filter'),
      headers: _h(token),
      body: jsonEncode(filter.toJson()),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => CekverilenhareketDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}
