import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../models/entities/helper/banka_master_dto.dart';

class BankaMasterService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<BankaMasterDto>> getBankalar(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Banka'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception('Banka listesi alınamadı');
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => BankaMasterDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BankasubeMasterDto>> getSubeler(String token, {int? bankaid}) async {
    final path = bankaid != null
        ? '${ApiConfig.baseUrl}/Bankasube/GetByBankaId/$bankaid'
        : '${ApiConfig.baseUrl}/Bankasube';
    final res = await http.get(Uri.parse(path), headers: _h(token));
    if (res.statusCode != 200) throw Exception('Şube listesi alınamadı');
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => BankasubeMasterDto.fromJson(e as Map<String, dynamic>)).toList();
  }
}
