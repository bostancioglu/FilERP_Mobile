import 'package:shared_preferences/shared_preferences.dart';

import '../models/entities/plasiyer/plasiyer_dto.dart';
import '../services/cari/cari_service.dart';

/// Cari kartında tanımlı plasiyeri döndürür.
/// Belgelerde cari seçilince plasiyer otomatik o carinin plasiyeri olsun diye
/// kullanılır. Cari liste DTO'su (CariDtoLite) plasiyer taşımadığı için cari
/// kartı ayrıca çekilir; sonuçlar oturum boyunca bellekte tutulur.
class CariPlasiyerHelper {
  const CariPlasiyerHelper._();

  static final Map<int, int?> _cache = {};

  /// Cari kartında plasiyer tanımlıysa onun id'sini, yoksa (veya alınamazsa) null döner.
  static Future<int?> getPlasiyerId(int? cariId) async {
    if (cariId == null) return null;
    if (_cache.containsKey(cariId)) return _cache[cariId];
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final full = await CariService().getCariFullById(token, cariId);
      _cache[cariId] = full.Plasiyerid;
      return full.Plasiyerid;
    } catch (_) {
      return null;
    }
  }

  /// Cari kartında plasiyer varsa o, yoksa [plasiyerler] listesindeki İLK kayıt.
  /// (Liste boşsa null.) Cari seçilince plasiyer alanını doldurmak için kullanılır.
  static Future<int?> getPlasiyerIdOrFirst(
      int? cariId, List<PlasiyerDto> plasiyerler) async {
    final pid = await getPlasiyerId(cariId);
    if (pid != null) return pid;
    for (final p in plasiyerler) {
      if (p.Id != null) return p.Id;
    }
    return null;
  }

  /// Cari kartı güncellendiyse eski değer kalmasın.
  static void temizle() => _cache.clear();
}
