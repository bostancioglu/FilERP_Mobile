import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../helpers/response.dart';

enum PortalDocument { invoice, waybill }

/// Yalnızca IHesap portal kuyruğunu günceller; entegratöre belge göndermez.
class PortalService {
  Future<void> send(String token, String id, PortalDocument document) async {
    if (token.isEmpty) throw const YetkiHatasi();
    if (id.isEmpty) throw Exception('Belge bulunamadı.');
    final controller =
        document == PortalDocument.invoice ? 'Fatura' : 'Irsaliye';
    final full =
        document == PortalDocument.invoice ? 'FaturaFull' : 'IrsaliyeFull';
    final statusKey =
        document == PortalDocument.invoice ? 'EFaturadurum' : 'Eirsaliyedurum';
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final response = await http
        .get(
          Uri.parse(
              '${ApiConfig.baseUrl}/$controller/$full/${Uri.encodeComponent(id)}'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) throw Exception(parseApiError(response));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final data = body is Map ? body['Data'] : null;
    if (data is! Map) throw Exception('Belge durumu alınamadı.');
    if (data['Belgedurum'] != 1) {
      throw Exception('Portala göndermeden önce belgeyi tamamlayın.');
    }
    final status = data[statusKey];
    if (status == 1) throw Exception('Belge zaten portala gönderilmiş.');
    if (status != 0) {
      throw Exception(
          'E-belge işlemi görmüş veya durumu bilinmeyen belge portala gönderilemez.');
    }
    // Yazma isteği otomatik tekrarlanmaz. Asıl durum kontrolü sunucudadır.
    final sent = await http
        .post(
          Uri.parse(
              '${ApiConfig.baseUrl}/$controller/portala-gonder/${Uri.encodeComponent(id)}'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (sent.statusCode != 200 && sent.statusCode != 204) {
      throw Exception(parseApiError(sent));
    }
  }
}
