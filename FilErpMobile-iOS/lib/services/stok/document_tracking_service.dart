import 'dart:convert';
import '../auth/authorized_http.dart' as http;
import '../auth/authorization_session.dart';
import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../models/entities/stok/document_tracking.dart';

class DocumentTrackingService {
  Map<String, String> _headers(String token) =>
      {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  dynamic _data(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw Exception(parseApiError(response));
    if (response.bodyBytes.isEmpty) return null;
    return (jsonDecode(utf8.decode(response.bodyBytes)) as Map)['Data'];
  }

  void _requireSaved(TrackingLine line) {
    if (!line.saved || line.stockId == null)
      throw Exception('Önce belgeyi ve kalemi kaydedin.');
  }

  Future<bool> isDraft(String token, TrackingLine line) async {
    _requireSaved(line);
    AuthorizationSession.instance.require(line.document.module, Access.read);
    final data = _data(await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/${line.document.controller}/${line.document.fullRoute}/${line.documentId}'),
        headers: _headers(token)));
    // Missing status must never allow mutations.
    return data is Map && data['Belgedurum'] == 0;
  }

  Future<TrackingSelection> choices(
      String token, TrackingLine line, int branchId) async {
    _requireSaved(line);
    AuthorizationSession.instance.require(line.document.module, Access.read);
    final uri = Uri.parse('${ApiConfig.baseUrl}/Stoktakipdetay/SecimFilter')
        .replace(queryParameters: {
      'yon': line.incoming ? '1' : '2',
      'stokid': '${line.stockId}',
      'subeid': '$branchId',
      if (line.warehouseId != null) 'depoid': '${line.warehouseId}',
      if (line.addressId != null) 'depoadresid': line.addressId!,
      if (line.featureId != null) 'stokozelliksabitid': '${line.featureId}',
      'bakiyesiolmayanlarigetir': '${line.incoming}',
    });
    final data = _data(await http.get(uri, headers: _headers(token)));
    if (data is! Map) throw Exception('Seri/parti seçim bilgisi alınamadı.');
    return TrackingSelection.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<TrackingDetail>> details(String token, TrackingLine line) async {
    _requireSaved(line);
    AuthorizationSession.instance.require(line.document.module, Access.read);
    final data = _data(await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/Stoktakipdetay/StokTakip/${line.document.type}/${line.documentId}/${line.lineId}'),
        headers: _headers(token)));
    if (data is! List) throw Exception('Seri/parti kayıtları alınamadı.');
    return data
        .map((e) => TrackingDetail.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _requireEditable(String token, TrackingLine line) async {
    AuthorizationSession.instance.require(line.document.module, Access.update);
    if (!await isDraft(token, line))
      throw Exception('Önce belgeyi taslağa çekmelisiniz.');
  }

  Future<void> add(String token, TrackingLine line,
      {required TrackingChoice choice,
      required bool serial,
      required double quantity,
      DateTime? expiry}) async {
    _requireSaved(line);
    if (quantity <= 0 || (serial && quantity != 1))
      throw Exception('Geçerli bir miktar girin.');
    if (line.multiplier <= 0)
      throw Exception('Kalemin ölçü birimi bilgisi geçersiz.');
    await _requireEditable(token, line);
    // Reload immediately before mutation so duplicate/quantity checks use saved rows.
    final existing = await details(token, line);
    if (existing.any((r) => r.status != 1))
      throw Exception('Önce belgeyi taslağa çekmelisiniz.');
    if (serial && existing.any((r) => r.serialId == choice.id))
      throw Exception('Bu seri zaten seçilmiş.');
    if (existing.fold<double>(0, (s, r) => s + r.quantity) + quantity >
        line.quantity + .000001) {
      throw Exception('Seçim miktarı kalem miktarını aşamaz.');
    }
    if (!line.incoming && choice.balance < quantity / line.multiplier)
      throw Exception('Yeterli bakiye bulunmuyor.');
    _data(await http.put(
        Uri.parse(
            '${ApiConfig.baseUrl}/Stoktakipdetay/${line.document.saveRoute}/StokTakip'),
        headers: _headers(token),
        body: jsonEncode({
          'Belgeid': line.documentId,
          'Belgehareketid': int.parse(line.lineId!),
          'Detaylar': [
            {
              'Partiid': choice.partyId,
              'Seriid': serial ? choice.id : null,
              'Miktar': quantity,
              'Sonkullanmatarihi':
                  (line.incoming ? expiry : choice.expiry)?.toIso8601String(),
            }
          ]
        })));
  }

  Future<void> remove(
      String token, TrackingLine line, TrackingDetail detail) async {
    _requireSaved(line);
    if (detail.status != 1)
      throw Exception('Önce belgeyi taslağa çekmelisiniz.');
    await _requireEditable(token, line);
    _data(await http.delete(
        Uri.parse(
            '${ApiConfig.baseUrl}/Stoktakipdetay/StokTakip/${line.document.type}/${line.documentId}'),
        headers: _headers(token),
        body: jsonEncode([detail.id])));
  }
}
