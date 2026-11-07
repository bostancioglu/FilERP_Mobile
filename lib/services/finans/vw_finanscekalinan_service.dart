import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/cek/vw_finanscekalinan_dto.dart';

/// Müşteri Çek raporları — her biri ayrı bir backend view/controller'a karşılık gelir
/// (VW_Finanscekalinan, ...ciro, ...portfoy, ...tahsil, ...teminat, ...protesto),
/// hepsi aynı DTO yapısını paylaşır.
class VwFinanscekalinanService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<VwFinanscekalinanDto>> _get(String token, String path) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/$path'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list.map((e) => VwFinanscekalinanDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Genel Çek Listesi (Müşteri)
  Future<List<VwFinanscekalinanDto>> getGenel(String token) => _get(token, 'VW_Finanscekalinan');

  /// Verilene Göre Çek Listesi (Ciro)
  Future<List<VwFinanscekalinanDto>> getVerilenegore(String token) => _get(token, 'VW_Finanscekalinanciro');

  /// Portföydeki Çekler
  Future<List<VwFinanscekalinanDto>> getPortfoy(String token) => _get(token, 'VW_Finanscekalinanportfoy');

  /// Tahsildeki Çekler
  Future<List<VwFinanscekalinanDto>> getTahsil(String token) => _get(token, 'VW_Finanscekalinantahsil');

  /// Teminattaki Çekler
  Future<List<VwFinanscekalinanDto>> getTeminat(String token) => _get(token, 'VW_Finanscekalinanteminat');

  /// Karşılıksız Çekler (Protesto)
  Future<List<VwFinanscekalinanDto>> getKarsiliksiz(String token) => _get(token, 'VW_Finanscekalinanprotesto');
}
