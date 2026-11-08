import 'package:shared_preferences/shared_preferences.dart';

import '../models/entities/depo/depo_dto.dart';
import '../services/depo/depo_service.dart';

/// Kalemlere atanacak varsayılan depo.
///
/// Öncelik: 1) Ayarlar > "Varsayılan Depo" ile seçilen depo,
///          2) depo listesindeki ilk kayıt.
/// Hızlı/direkt barkod akışları kalem formunu atladığı için depoyu buradan alır.
class VarsayilanDepoHelper {
  const VarsayilanDepoHelper._();

  static const _kSecilen = 'varsayilan_depo_id';
  static const _kIlkCache = 'ilk_depo_id_cache';

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

  /// Zaten yüklenmiş bir depo listesi varsa (kalem formları) bunu kullan.
  static Future<int?> pickFrom(List<DepoDto> depolar) async {
    final secilen = await getSecilenId();
    if (secilen != null && depolar.any((d) => d.id == secilen)) return secilen;
    for (final d in depolar) {
      if (d.id != null) return d.id;
    }
    return null;
  }

  /// Liste elde yoksa (hızlı barkod akışları) sunucudan çeker.
  /// Çevrimdışıysa son bilinen ilk depo id'sine düşer.
  static Future<int?> getId(String token) async {
    final secilen = await getSecilenId();
    if (secilen != null) return secilen;

    final p = await SharedPreferences.getInstance();
    try {
      final liste = await DepoService().getDepoList(token);
      for (final d in liste) {
        if (d.id != null) {
          await p.setInt(_kIlkCache, d.id!);
          return d.id;
        }
      }
    } catch (_) {}
    return p.getInt(_kIlkCache);
  }
}
