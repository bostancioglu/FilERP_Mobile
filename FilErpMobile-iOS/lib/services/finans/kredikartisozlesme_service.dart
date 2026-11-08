import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/tahsilat/kredikartisozlesme_dto.dart';

class KredikartisozlesmeService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<KredikartisozlesmeDto>> getAllByBankahesapidWithoutAuth(String token, int bankahesapid) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Kredikartisozlesme/AllByBankahesapidWithoutAuth/$bankahesapid'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => KredikartisozlesmeDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}
