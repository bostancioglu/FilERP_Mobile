import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/senet/senetverilenodemehareket_dto.dart';
import '../../models/entities/finans/senet/senetverilenodemehareket_create_dto.dart';

class SenetverilenodemehareketService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<SenetverilenodemehareketDto>> getAllBySenetverilenodemeId(String token, String id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Senetverilenodemehareket/GetAllBySenetverilenodemeId/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => SenetverilenodemehareketDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveSingle(String token, SenetverilenodemehareketCreateDto dto) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Senetverilenodemehareket/SaveSingle'),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(parseApiError(res));
    }
  }

  Future<void> removeSingle(String token, String id) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/Senetverilenodemehareket/RemoveSingle/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }
}
