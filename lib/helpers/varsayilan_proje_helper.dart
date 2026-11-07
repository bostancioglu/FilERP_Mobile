import 'package:shared_preferences/shared_preferences.dart';

import '../models/entities/proje/proje_dto.dart';
import '../services/proje/proje_service.dart';

/// Belge ve kalemlere atanacak varsayılan proje.
///
/// Öncelik: 1) Ayarlar > "Varsayılan Proje" ile seçilen proje,
///          2) proje listesindeki ilk kayıt.
class VarsayilanProjeHelper {
  const VarsayilanProjeHelper._();

  static const _kSecilen = 'varsayilan_proje_id';
  static const _kIlkCache = 'ilk_proje_id_cache';

  static Future<int?> getSecilenId() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kSecilen);
  }

  static Future<void> setSecilenId(int? id) async {
    final p = await SharedPreferences.getInstance();
    if (id == null) {
      await p.remove(_kSecilen);
    } else {
      await p.setInt(_kSecilen, id);
    }
  }

  /// Zaten yüklenmiş bir proje listesi varsa (sayfalar, kalem formları) bunu kullan.
  static Future<int?> pickFrom(List<ProjeDto> projeler) async {
    final secilen = await getSecilenId();
    if (secilen != null && projeler.any((p) => p.id == secilen)) return secilen;
    for (final p in projeler) {
      if (p.id != null) return p.id;
    }
    return null;
  }

  /// Liste elde yoksa (hızlı barkod akışları) sunucudan çeker.
  /// Çevrimdışıysa son bilinen ilk proje id'sine düşer.
  static Future<int?> getId(String token) async {
    final secilen = await getSecilenId();
    if (secilen != null) return secilen;

    final p = await SharedPreferences.getInstance();
    try {
      final liste = await ProjeService().getProjeList(token);
      for (final pr in liste) {
        if (pr.id != null) {
          await p.setInt(_kIlkCache, pr.id!);
          return pr.id;
        }
      }
    } catch (_) {}
    return p.getInt(_kIlkCache);
  }
}
