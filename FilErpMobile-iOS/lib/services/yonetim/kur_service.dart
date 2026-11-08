import 'dart:convert';

import 'package:FilERP/services/auth/authorized_http.dart' as http;

import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../models/entities/yonetim/kur_dto.dart';

class KurService {
  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<KurDto?> getByDovizIdAndDate(
    String token,
    int dovizId,
    DateTime tarih,
  ) async {
    final tarihValue = '${tarih.month}-${tarih.day}-${tarih.year}';
    final res = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/Kur/GetByDovizIdAndDate/$dovizId/$tarihValue',
      ),
      headers: _headers(token),
    );

    if (res.statusCode != 200) {
      throw Exception(parseApiError(res));
    }

    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final data = body is Map && body.containsKey('Data') ? body['Data'] : body;
    if (data == null) {
      return null;
    }
    return KurDto.fromJson(data as Map<String, dynamic>);
  }
}
