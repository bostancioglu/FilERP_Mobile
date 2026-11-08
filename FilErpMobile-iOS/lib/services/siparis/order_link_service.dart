import 'dart:convert';
import '../auth/authorized_http.dart' as http;
import '../../config/api_config.dart';
import '../../helpers/response.dart';
import '../../models/entities/siparis/siparis_dto.dart';
import '../../models/entities/siparis/siparishareket_dto.dart';

class OrderLinkContext {
  final int? customerId, currencyId;
  final bool vatIncluded;
  final double rate;
  const OrderLinkContext(
      {required this.customerId,
      required this.currencyId,
      required this.vatIncluded,
      required this.rate});
}

class OrderLinkService {
  Future<dynamic> _get(String token, String path) async {
    final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/SiparisAlis/$path'),
        headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    return (jsonDecode(utf8.decode(res.bodyBytes)) as Map)['Data'];
  }

  Future<List<SiparisDto>> orders(
      String token, OrderLinkContext context) async {
    if (context.customerId == null || context.currencyId == null)
      throw Exception('Cari ve döviz seçiniz.');
    final value = await _get(token,
        'GetBaglantiSiparis/${context.customerId}/${context.currencyId}/${context.vatIncluded}');
    if (value is! List) throw Exception('Bağlantı siparişleri alınamadı.');
    return value
        .map((e) => SiparisDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<SiparishareketDto>> lines(
      String token, String orderId, int stockId) async {
    final value = await _get(token, 'SiparisFullAdjustedWithBaglanti/$orderId');
    if (value is! Map) throw Exception('Bağlantı siparişi alınamadı.');
    final order = SiparisDto.fromJson(Map<String, dynamic>.from(value));
    return order.siparishareket
        .where((k) =>
            k.stokid == stockId &&
            (k.miktar ?? 0) > 0 &&
            (int.tryParse(k.id ?? '') ?? 0) > 0)
        .toList();
  }
}
