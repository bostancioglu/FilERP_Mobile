import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Oturumdaki kullanıcının plasiyer bilgisi.
class KullaniciPlasiyer {
  final bool plasiyermi;
  final int? plasiyerid;
  const KullaniciPlasiyer({this.plasiyermi = false, this.plasiyerid});

  /// Plasiyer kullanıcısı ve plasiyeri tanımlıysa true: belgelerde plasiyer değiştirilemez.
  bool get kilitli => plasiyermi && plasiyerid != null;
}

/// Kullanıcının plasiyer olup olmadığını (ve hangi plasiyer olduğunu) oturum token'ından okur.
/// Sunucu, giriş sırasında kullanıcı parametrelerini token içine claim olarak koyar
/// (ParametrekullanicisirketClaimDto: Plasiyermi, Plasiyerid); web de aynı bilgiyi kullanır.
class KullaniciPlasiyerHelper {
  const KullaniciPlasiyerHelper._();

  static const _claimAdi = 'G129-134F-4323'; // DTMobil.Shared.Constants.Parametrekullanicisirket

  static Future<KullaniciPlasiyer> getir() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final parcalar = token.split('.');
      if (parcalar.length < 2) return const KullaniciPlasiyer();

      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parcalar[1]))));
      if (payload is! Map) return const KullaniciPlasiyer();

      var claim = payload[_claimAdi];
      if (claim is String) claim = jsonDecode(claim);
      if (claim is! Map) return const KullaniciPlasiyer();

      return KullaniciPlasiyer(
        plasiyermi: claim['Plasiyermi'] == true,
        plasiyerid: claim['Plasiyerid'] is int ? claim['Plasiyerid'] as int : null,
      );
    } catch (_) {
      return const KullaniciPlasiyer();
    }
  }
}
