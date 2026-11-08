import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../helpers/response.dart';
import '../../config/api_config.dart';

/// Çek/Senet bordrosunu İhesap web ile aynı sırayla kaydeder:
/// önce bordro (başlık) SaveSingle, sonra her çek/senet `<Prefix>hareket/SaveSingle`
/// (bordro Id'si ile). Bir kalem başarısız olursa bordro tüm kalemleriyle silinir.
/// [prefix]: Cekalinan, Cekverilen, Senetalinan, Senetverilen.
class BordroKayitService {
  static Map<String, String> _h(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<String> kaydet(
    String token,
    String prefix,
    Map<String, dynamic> baslik,
    List<Map<String, dynamic>> hareketler,
  ) async {
    final hareketKey = '${prefix}hareket';
    final fkKey = '${prefix}id';
    final head = Map<String, dynamic>.from(baslik)..remove(hareketKey);

    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/$prefix/SaveSingle'),
      headers: _h(token),
      body: jsonEncode(head),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(parseApiError(res));
    }
    final id = jsonDecode(utf8.decode(res.bodyBytes))['Data'].toString();

    try {
      for (final h in hareketler) {
        final body = Map<String, dynamic>.from(h)..[fkKey[0].toUpperCase() + fkKey.substring(1)] = id;
        final r = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/$hareketKey/SaveSingle'),
          headers: _h(token),
          body: jsonEncode(body),
        );
        if (r.statusCode != 200 && r.statusCode != 201) {
          throw Exception(parseApiError(r));
        }
      }
    } catch (_) {
      try {
        await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/$prefix/RemoveWithItems/$id'),
          headers: _h(token),
        );
      } catch (_) {}
      rethrow;
    }
    return id;
  }
}
