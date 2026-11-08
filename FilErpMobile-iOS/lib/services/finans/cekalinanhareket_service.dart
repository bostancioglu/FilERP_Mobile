import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/cek/cekalinanhareket_dto.dart';
import '../../models/entities/finans/cek/cekalinanhareket_filter_dto.dart';

/// Cekalinanhareket (tekil çek satırı) sorgu servisleri — çek girişi CekalinanService.saveWithItems
/// üzerinden yapılır, bu servis mevcut çekleri filtrelemek (ör. portföydeki çekler) içindir.
class CekalinanhareketService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<CekalinanhareketDto>> filter(String token, CekalinanhareketFilterDto filter) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Cekalinanhareket/Filter'),
      headers: _h(token),
      body: jsonEncode(filter.toJson()),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => CekalinanhareketDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}
