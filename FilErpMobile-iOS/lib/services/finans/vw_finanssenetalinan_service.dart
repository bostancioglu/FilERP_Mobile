import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/senet/vw_finanssenetalinan_dto.dart';

/// Müşteri Senet raporları — her biri ayrı bir backend view/controller'a karşılık gelir
/// (VW_Finanssenetalinan, ...ciro, ...portfoy, ...tahsil, ...teminat, ...protesto),
/// hepsi aynı DTO yapısını paylaşır.
class VwFinanssenetalinanService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<VwFinanssenetalinanDto>> _get(String token, String path) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/$path'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => VwFinanssenetalinanDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Genel Senet Listesi (Müşteri)
  Future<List<VwFinanssenetalinanDto>> getGenel(String token) => _get(token, 'VW_Finanssenetalinan');

  /// Verilene Göre Senet Listesi (Ciro)
  Future<List<VwFinanssenetalinanDto>> getVerilenegore(String token) => _get(token, 'VW_Finanssenetalinanciro');

  /// Portföydeki Senetler
  Future<List<VwFinanssenetalinanDto>> getPortfoy(String token) => _get(token, 'VW_Finanssenetalinanportfoy');

  /// Tahsildeki Senetler
  Future<List<VwFinanssenetalinanDto>> getTahsil(String token) => _get(token, 'VW_Finanssenetalinantahsil');

  /// Teminattaki Senetler
  Future<List<VwFinanssenetalinanDto>> getTeminat(String token) => _get(token, 'VW_Finanssenetalinanteminat');

  /// Karşılıksız Senetler (Protesto)
  Future<List<VwFinanssenetalinanDto>> getKarsiliksiz(String token) => _get(token, 'VW_Finanssenetalinanprotesto');
}
