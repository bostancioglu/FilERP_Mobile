import 'dart:convert';
import '../auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../models/entities/helper/istisna_dto.dart';

class IstisnaService {
  Future<List<IstisnaDto>> getAll(String token) async {
    final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/Istisna/AllWithoutAuth'),
        headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) throw Exception(parseApiError(response));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return ((body['Data'] ?? []) as List)
        .map((e) => IstisnaDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
