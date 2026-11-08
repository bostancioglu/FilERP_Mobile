import '../auth/authorization_session.dart';
import 'dart:async';
import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../helpers/response.dart';
import 'portal_service.dart';

class EBelgeUncertain implements Exception {
  @override
  String toString() =>
      'Gönderim sonucu doğrulanamadı. Tekrar göndermeden önce belgeyi e-belge portalından kontrol edin.';
}

class EBelgeService {
  static final Set<String> _inFlight = {};

  /// Tam ERP belgesini dönüştürmeden gönderir. Şirket sırları diske/loga yazılmaz.
  Future<void> send({
    required String token,
    required String id,
    required int companyId,
    required PortalDocument document,
  }) async {
    if (token.isEmpty) throw const YetkiHatasi();
    if (id.isEmpty || companyId <= 0)
      throw Exception('Belge veya şirket bilgisi eksik.');
    final revision = AuthorizationSession.instance.revision;
    final erpUrl = ApiConfig.baseUrl;
    final eUrl = ApiConfig.eBelgeBaseUrl;
    final invoice = document == PortalDocument.invoice;
    final controller = invoice ? 'Fatura' : 'Irsaliye';
    final stateKey = invoice ? 'EFaturadurum' : 'Eirsaliyedurum';
    final key = 'ebelge_send:$eUrl:$companyId:$controller:$id';
    if (!_inFlight.add(key)) throw Exception('Belge gönderimi devam ediyor.');
    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      final data = await _getData(
          '$erpUrl/$controller/${controller}Full/${Uri.encodeComponent(id)}',
          headers);
      if (data is! Map<String, dynamic> ||
          data['Id']?.toString().toLowerCase() != id.toLowerCase()) {
        throw Exception('Belge bilgisi alınamadı.');
      }
      if (data['Sirketid'] != companyId)
        throw Exception('Belge seçili şirkete ait değil.');
      if (data['Belgeturu'] != (invoice ? 1 : 3))
        throw Exception('Yalnızca satış belgeleri gönderilebilir.');
      if (data['Belgedurum'] != 1)
        throw Exception('Göndermeden önce belgeyi tamamlayın.');
      if (data[stateKey] != 0 && data[stateKey] != 1) {
        throw Exception(
            'E-belge işlemi görmüş veya durumu bilinmeyen belge tekrar gönderilemez.');
      }
      // ERP durumu henüz güncellenmemiş olsa bile e-belge kaydını kontrol et.
      for (final type in invoice ? [1, 3] : [2]) {
        final existing = await _getData(
            '$eUrl/EDocument/getby-belgeid/${Uri.encodeComponent(id)}/$type',
            headers);
        if (existing != null)
          throw Exception(
              'Belgenin e-belge kaydı mevcut. Tekrar gönderilemez.');
      }
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(key)) throw EBelgeUncertain();
      // Sirket/Sirket/{id} şirket düzenleme içindir ve sırları çözer.
      // E-belge API'si şifreli değerleri bekler; Full belgesindeki Sirket
      // nesnesi hem bunları hem şirketin adres bilgilerini aynen taşır.
      final company = data['Sirket'];
      if (company is! Map<String, dynamic> || company['Id'] != companyId) {
        throw Exception('Şirket bilgisi alınamadı.');
      }
      final integrator = company['Efaturaentegrator'];
      if (integrator == null || integrator == 0)
        throw Exception('Şirketin e-belge entegratörü tanımlı değil.');
      final user = company['Efaturaentegratorkullaniciadi']?.toString() ?? '';
      final password = company['Efaturaentegratorsifre']?.toString() ?? '';
      if (user.isEmpty || password.isEmpty)
        throw Exception('Şirketin entegratör bilgileri eksik.');
      headers.addAll({
        'entegrator': integrator.toString(),
        'entegratorUserName': user,
        'entegratorPassword': password,
        'entegratorClientId': company['Entegratorclientid']?.toString() ?? '',
        'entegratorClientSecret':
            company['Entegratorclientsecret']?.toString() ?? '',
      });
      data['Sirket'] = company;
      final rows = data[invoice ? 'Faturahareket' : 'Irsaliyehareket'];
      if (data['Cari'] is! Map ||
          data['Doviz'] is! Map ||
          rows is! List ||
          rows.isEmpty ||
          rows.any((row) =>
              row is! Map ||
              row['Stok'] is! Map ||
              row['Stok']['Temelolcubr'] is! Map)) {
        throw Exception('Belgenin cari, döviz veya ürün bilgileri eksik.');
      }
      // İşlem sırasında ortam değiştirilmişse farklı ortama belge gönderme.
      if (revision != AuthorizationSession.instance.revision || ApiConfig.baseUrl != erpUrl || ApiConfig.eBelgeBaseUrl != eUrl) {
        throw Exception('Ortam değişti. Belgeyi yeniden açın.');
      }
      // Yanıt kaybolursa uygulama yeniden açılsa bile otomatik tekrar gönderilmez.
      if (!await prefs.setString(key, 'pending'))
        throw Exception('Gönderim durumu kaydedilemedi.');
      final payload = jsonEncode(data);
      http.Response response;
      try {
        response = await http
            .post(
              Uri.parse(
                  '$eUrl/${invoice ? 'EFatura/send-invoice' : 'EIrsaliye/send-waybill'}'),
              headers: headers,
              body: payload,
            )
            .timeout(const Duration(seconds: 90));
      } catch (_) {
        throw EBelgeUncertain();
      }
      // 401/403 isteği gönderim işlemine ulaşmadan reddeder.
      if (response.statusCode == 401 || response.statusCode == 403) {
        await prefs.remove(key);
        throw const YetkiHatasi();
      }
      // Sunucu belgeyi gönderip ERP'ye yazarken hata vermiş olabilir.
      if (response.statusCode != 200) throw EBelgeUncertain();
      dynamic result;
      try {
        result = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        throw EBelgeUncertain();
      }
      if (result is! Map ||
          result['Data'] is! Map ||
          (result['Errors'] is List && (result['Errors'] as List).isNotEmpty)) {
        throw EBelgeUncertain();
      }
      final sent = result['Data'] as Map;
      if (sent['Succeed'] == false) {
        await prefs.remove(key);
        throw Exception(
            sent['Message']?.toString() ?? 'E-belge gönderilemedi.');
      }
      if (sent['Succeed'] != true) throw EBelgeUncertain();
      await prefs.setString(key, 'sent');
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<dynamic> _getData(String url, Map<String, String> headers) async {
    final response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) throw Exception(parseApiError(response));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map ||
        !body.containsKey('Data') ||
        (body['Errors'] is List && (body['Errors'] as List).isNotEmpty)) {
      throw Exception('E-belge bilgisi alınamadı.');
    }
    return body['Data'];
  }
}
