import '../models/entities/depo/depo_dto.dart';
import '../services/depo/depo_service.dart';
import 'varsayilan_depo_helper.dart';

/// Bir plasiyerin kendi (araç) deposunu bulur.
///
/// Sırayla:
///  1) Tam depo listesi (`GET /Depo`, "Tümünü okuma" yetkisi ister): Plasiyerdeposu işaretli ve plasiyeri bu kişi olan depo.
///  2) Yetki yoksa `Depo/Search` ile (yalnızca oturum yeter): kullanıcının görebildiği depoların kodları tek tek aranıp
///     Plasiyerid / Plasiyerdeposu alanlı tam kayıt okunur. Sonuç oturum boyunca önbelleğe alınır.
///  3) Yine bulunamazsa ve çağıran plasiyer kullanıcının kendisiyse ([kilitli]):
///     Ayarlar > Varsayılan Depo seçimi araç deposu olarak kullanılır.
/// Bulunamazsa null döner (çağıran eski varsayılana düşer).
class PlasiyerDepoHelper {
  const PlasiyerDepoHelper._();

  static List<DepoDto>? _tamListe; // oturum boyunca önbellek (yalnızca başarılı yanıt)
  static bool _tamListeYasak = false; // yetki yok → tekrar tekrar denenmesin
  static final Map<int, int?> _aramaOnbellek = {}; // plasiyerId → depoId (Depo/Search sonucu)

  static Future<int?> getId(
    String token,
    int? plasiyerId, {
    bool kilitli = false,
    List<DepoDto>? mevcutDepolar,
  }) async {
    var tamAlindi = false;
    if (plasiyerId != null && !_tamListeYasak) {
      try {
        final tam = _tamListe ??= await DepoService().getTamListe(token);
        tamAlindi = true;
        final bulunan = tam
            .where((d) => d.plasiyerdeposu == true && d.plasiyerid == plasiyerId)
            .firstOrNull
            ?.id;
        if (bulunan != null) return bulunan;
      } catch (_) {
        _tamListeYasak = true;
      }
    }
    if (plasiyerId != null && !tamAlindi) {
      final bulunan = await _aramaIle(token, plasiyerId);
      if (bulunan != null) return bulunan;
    }
    if (kilitli) {
      final varsayilan = await VarsayilanDepoHelper.getSecilenId();
      if (varsayilan != null && (mevcutDepolar == null || mevcutDepolar.any((d) => d.id == varsayilan))) {
        return varsayilan;
      }
    }
    return null;
  }

  /// Görünen depoların kodlarını `Depo/Search` ile (birebir kod eşleşmesi tam kaydı döndürür) arayıp
  /// plasiyerin deposunu bulur. Hata olursa null döner ve önbelleğe yazılmaz.
  static Future<int?> _aramaIle(String token, int plasiyerId) async {
    if (_aramaOnbellek.containsKey(plasiyerId)) return _aramaOnbellek[plasiyerId];
    try {
      final svc = DepoService();
      final liste = await svc.getDepoList(token); // plasiyer kısıtlı: kendi deposu + plasiyer deposu olmayanlar
      final kodlar = liste.map((d) => (d.kod ?? '').trim()).where((k) => k.isNotEmpty).toSet().toList();
      int? bulunan;
      for (var i = 0; i < kodlar.length && bulunan == null; i += 6) {
        final dilim = kodlar.sublist(i, i + 6 > kodlar.length ? kodlar.length : i + 6);
        final sonuc = await Future.wait(dilim.map((k) => svc.ara(token, k).catchError((_) => <DepoDto>[])));
        for (final r in sonuc) {
          final d = r.where((x) => x.plasiyerdeposu == true && x.plasiyerid == plasiyerId).firstOrNull;
          if (d?.id != null) {
            bulunan = d!.id;
            break;
          }
        }
      }
      _aramaOnbellek[plasiyerId] = bulunan;
      return bulunan;
    } catch (_) {
      return null;
    }
  }
}
