import '../models/entities/finans/kasa_islem/kasa_dto.dart';
import '../services/finans/kasa_tanim_service.dart';
import 'varsayilan_kasa_helper.dart';

/// Bir plasiyerin kendi kasasını bulur ("plasiyer kasası").
///
/// Sırayla:
///  1) Kasa kartında "Plasiyer kasası" işaretli ve plasiyeri bu kişi olan kasa
///     (kasa listesi bu alanları taşıyorsa; ya da tam kasa listesi — `GET /Kasa`, yetki ister — okunabiliyorsa).
///  2) Yetki yoksa `Kasa/Search` ile (yalnızca oturum yeter): kullanıcının görebildiği kasaların kodları tek tek
///     aranıp Plasiyerid / Plasiyerkasasi alanlı tam kayıt okunur. Sonuç oturum boyunca önbelleğe alınır.
///  3) Plasiyerin görebildiği tek bir kasa varsa o kasa.
///  4) Plasiyer kullanıcının kendisiyse: Ayarlar > Varsayılan Kasa.
/// Bulunamazsa null döner (çağıran eski varsayılana düşer).
class PlasiyerKasaHelper {
  const PlasiyerKasaHelper._();

  static final Map<int, int?> _aramaOnbellek = {}; // plasiyerId → kasaId (Kasa/Search sonucu)

  static Future<KasaDto?> getir(
    String token,
    int? plasiyerId, {
    List<KasaDto>? mevcutKasalar,
    bool kilitli = false,
  }) async {
    List<KasaDto> kasalar = mevcutKasalar ?? const [];
    if (kasalar.isEmpty) {
      try {
        kasalar = await KasaTanimService().getAllWithoutAuth(token);
      } catch (_) {}
    }

    if (plasiyerId != null) {
      // 1a) Liste plasiyer bilgisini taşıyorsa
      final dogrudan = kasalar.where((k) => k.Plasiyerkasasi == true && k.Plasiyerid == plasiyerId).firstOrNull;
      if (dogrudan != null) return dogrudan;

      // 1b) Tam liste (yetki gerektirir)
      var tamAlindi = false;
      try {
        final tam = await KasaTanimService().getAll(token);
        tamAlindi = true;
        final bulunan = tam.where((k) => k.Plasiyerkasasi == true && k.Plasiyerid == plasiyerId).firstOrNull;
        if (bulunan != null) {
          return kasalar.where((k) => k.Id == bulunan.Id).firstOrNull ?? bulunan;
        }
      } catch (_) {}

      // 2) Yetki yoksa Kasa/Search ile
      if (!tamAlindi) {
        final id = await _aramaIle(token, plasiyerId, kasalar);
        if (id != null) {
          final k = kasalar.where((x) => x.Id == id).firstOrNull;
          if (k != null) return k;
        }
      }
    }

    // 3) Tek kasa
    if (kasalar.length == 1) return kasalar.first;

    // 4) Yedek: Ayarlar > Varsayılan Kasa
    if (kilitli) {
      final varsayilan = await VarsayilanKasaHelper.getSecilenId();
      if (varsayilan != null) return kasalar.where((k) => k.Id == varsayilan).firstOrNull;
    }
    return null;
  }

  /// Görünen kasaların kodlarını `Kasa/Search` ile (birebir kod eşleşmesi tam kaydı döndürür) arayıp
  /// plasiyerin kasasını bulur. Hata olursa null döner ve önbelleğe yazılmaz.
  static Future<int?> _aramaIle(String token, int plasiyerId, List<KasaDto> kasalar) async {
    if (_aramaOnbellek.containsKey(plasiyerId)) return _aramaOnbellek[plasiyerId];
    try {
      final svc = KasaTanimService();
      final kodlar = kasalar.map((k) => (k.Kod ?? '').trim()).where((k) => k.isNotEmpty).toSet().toList();
      int? bulunan;
      for (var i = 0; i < kodlar.length && bulunan == null; i += 6) {
        final dilim = kodlar.sublist(i, i + 6 > kodlar.length ? kodlar.length : i + 6);
        final sonuc = await Future.wait(dilim.map((k) => svc.ara(token, k).catchError((_) => <KasaDto>[])));
        for (final r in sonuc) {
          final k = r.where((x) => x.Plasiyerkasasi == true && x.Plasiyerid == plasiyerId).firstOrNull;
          if (k?.Id != null) {
            bulunan = k!.Id;
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
