import 'dart:async';
import 'dart:convert';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../helpers/response.dart';

/// Backend view satırı. Alan adları harf büyüklüğüne duyarsız okunur
/// (view'larda `carikod` gibi küçük, `Borctutar` gibi büyük harfli adlar karışık geliyor).
class RaporKayit {
  final Map<String, dynamic> _m;

  RaporKayit(Map<String, dynamic> m)
      : _m = {for (final e in m.entries) e.key.toLowerCase(): e.value};

  dynamic ham(String alan) => _m[alan.toLowerCase()];

  String s(String alan, [String varsayilan = '']) {
    final v = ham(alan);
    return v == null ? varsayilan : v.toString();
  }

  double d(String alan) {
    final v = ham(alan);
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? 0;
  }

  int? i(String alan) {
    final v = ham(alan);
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}');
  }

  DateTime? t(String alan) {
    final v = ham(alan);
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

/// Rapor view'larına (VW_*) istek atan ortak servis.
class RaporApi {
  const RaporApi._();

  static Future<Map<String, String>> _basliklar() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  static List<RaporKayit> _coz(http.Response res) {
    if (res.statusCode != 200) throw Exception(parseApiError(res));
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final List list = (body is Map ? body['Data'] : body) ?? [];
    return list.whereType<Map>().map((e) => RaporKayit(Map<String, dynamic>.from(e))).toList();
  }

  /// `POST <yol>` — filtre gövdesi (Tarih1, Tarih2, Cariid, Stokid, Depoid, Dovizid, Belgeno ...).
  /// Sunucu aynı kullanıcının aynı uca 0,5 sn içinde ikinci POST'unu "İşlem Tekrarı Engellendi" (429) diye reddeder
  /// (gövdeye bakmaz). Bu yüzden aynı uca giden istekler sıraya dizilir ve aralarında boşluk bırakılır.
  static final Map<String, Future<void>> _sira = {};

  static Future<List<RaporKayit>> post(String yol, Map<String, dynamic> filtre) async {
    final onceki = _sira[yol] ?? Future<void>.value();
    final bu = Completer<void>();
    _sira[yol] = bu.future;
    try {
      await onceki;
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/$yol'),
        headers: await _basliklar(),
        body: jsonEncode(filtre),
      );
      return _coz(res);
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 650), bu.complete);
    }
  }

  static Future<List<RaporKayit>> get(String yol) async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/$yol'), headers: await _basliklar());
    return _coz(res);
  }

  /// Filtre gövdesi: boş (null) alanlar gönderilmez; tarihler gün başı/sonu olarak normalleştirilir.
  static Map<String, dynamic> filtre({
    DateTime? tarih1,
    DateTime? tarih2,
    int? cariid,
    int? stokid,
    int? depoid,
    int? dovizid,
    int? projeid,
    int? plasiyerid,
    String? belgeno,
  }) =>
      {
        if (tarih1 != null) 'Tarih1': DateTime(tarih1.year, tarih1.month, tarih1.day).toIso8601String(),
        if (tarih2 != null) 'Tarih2': DateTime(tarih2.year, tarih2.month, tarih2.day, 23, 59, 59).toIso8601String(),
        if (cariid != null) 'Cariid': cariid,
        if (stokid != null) 'Stokid': stokid,
        if (depoid != null) 'Depoid': depoid,
        if (dovizid != null) 'Dovizid': dovizid,
        if (projeid != null) 'Projeid': projeid,
        if (plasiyerid != null) 'Plasiyerid': plasiyerid,
        if (belgeno != null && belgeno.isNotEmpty) 'Belgeno': belgeno,
      };
}
