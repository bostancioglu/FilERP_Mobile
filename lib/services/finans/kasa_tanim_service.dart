import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';
import '../../models/entities/finans/kasa_islem/kasa_dto.dart';
import '../../models/entities/finans/kasa_islem/kasa_create_dto.dart';

class KasaTanimService {
  Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<KasaDto>> getAll(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Kasa'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list
        .map((e) => KasaDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Kasa seçimi için liste. Yetki (TumunuOkuma) istemez ve oturumdaki kullanıcı
  /// plasiyer ise yalnızca ona tanımlı kasaları döndürür (web KasaSelector ile aynı uç nokta).
  Future<List<KasaDto>> getAllWithoutAuth(String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/Kasa/AllWithoutAuth'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list
        .map((e) => KasaDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Kasa arama (Kasa/Search) — yalnızca oturum açmış olmak yeter (Tümünü okuma yetkisi istemez),
  /// plasiyer kısıtı uygulanır ve Plasiyerid / Plasiyerkasasi dahil TAM kayıt döner.
  /// Metin kodla birebir eşleşirse yalnızca o kayıt gelir.
  Future<List<KasaDto>> ara(String token, String text) async {
    final res = await http.get(
      Uri.parse(
          '${ApiConfig.baseUrl}/Kasa/Search?text=${Uri.encodeQueryComponent(text)}'),
      headers: _h(token),
    );
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = body['Data'] ?? [];
    return list
        .map((e) => KasaDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(String token, KasaCreateDto dto) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/Kasa'),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(parseApiError(res));
    }
  }

  Future<void> update(String token, KasaCreateDto dto) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/Kasa'),
      headers: _h(token),
      body: jsonEncode(dto.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 204)
      throw Exception(parseApiError(res));
  }

  Future<void> delete(String token, int id) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/Kasa/$id'),
      headers: _h(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(parseApiError(res));
    }
  }
}
