import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/senet/senetalinanhareket_dto.dart';
import '../../models/entities/finans/senet/senetalinanhareket_filter_dto.dart';

/// Senetalinanhareket (tekil senet satırı) sorgu servisleri — senet girişi SenetalinanService.saveWithItems
/// üzerinden yapılır, bu servis mevcut senetleri filtrelemek (ör. portföydeki senetler) içindir.
class SenetalinanhareketService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<SenetalinanhareketDto>> filter(String token, SenetalinanhareketFilterDto filter) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Senetalinanhareket/Filter'),
      headers: _h(token),
      body: jsonEncode(filter.toJson()),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => SenetalinanhareketDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}
