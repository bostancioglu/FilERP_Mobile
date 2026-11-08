import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../models/entities/referans/referans_dto.dart';

class ReferansService {
  Map<String, String> _headers(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  // =================================================
  //  REFERANS LİSTESİ
  // =================================================
  Future<List<ReferansDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/Referans/AllWithoutAuth"),
      headers: _headers(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(res.body);
    final List list = body["Data"] ?? [];
    return list.map((e) => ReferansDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}