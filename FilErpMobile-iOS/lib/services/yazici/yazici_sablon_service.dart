import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/yazici/yazici_sablon.dart';

class YaziciSablonService {
  YaziciSablonService._();
  static final YaziciSablonService instance = YaziciSablonService._();

  static const _kSablonlar  = 'yazici_sablonlar_v1';
  static const _kKagitEni   = 'yazici_kagit_eni';
  static const _kSatirGen   = 'yazici_satir_genisligi';
  static const _kLogoPath   = 'yazici_logo_path';

  // ── Yazıcı Logosu ─────────────────────────────────────────────────────────

  Future<String?> getCustomLogoPath() async {
    final p = await SharedPreferences.getInstance();
    final path = p.getString(_kLogoPath);
    if (path == null) return null;
    if (!await File(path).exists()) {
      await p.remove(_kLogoPath); // dosya silinmişse temizle
      return null;
    }
    return path;
  }

  /// Seçilen dosyayı app dokümanlar klasörüne kopyalar ve path'i kaydeder.
  Future<String> saveCustomLogo(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/yazici_logo_custom.png');
    await File(sourcePath).copy(dest.path);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLogoPath, dest.path);
    return dest.path;
  }

  Future<void> clearCustomLogo() async {
    final p = await SharedPreferences.getInstance();
    final path = p.getString(_kLogoPath);
    await p.remove(_kLogoPath);
    if (path != null) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
  }

  // ── Kağıt eni ─────────────────────────────────────────────────────────────

  Future<int> getKagitEni() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kKagitEni) ?? 80;
  }

  Future<void> setKagitEni(int mm) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kKagitEni, mm);
    // Kağıt eni değişince satır genişliğini varsayılana sıfırla
    await p.setInt(_kSatirGen, mm >= 80 ? 48 : 32);
  }

  // ── Satır genişliği (karakter sayısı) ─────────────────────────────────────
  // 58mm → varsayılan 32, 80mm → varsayılan 48

  Future<int> getSatirGenisligi() async {
    final p   = await SharedPreferences.getInstance();
    final eni = p.getInt(_kKagitEni) ?? 80;
    return p.getInt(_kSatirGen) ?? (eni >= 80 ? 48 : 32);
  }

  Future<void> setSatirGenisligi(int genislik) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kSatirGen, genislik.clamp(20, 64));
  }

  // ── Şablonlar ─────────────────────────────────────────────────────────────

  Future<List<YaziciSablon>> getSablonlar() async {
    final p = await SharedPreferences.getInstance();
    final json = p.getString(_kSablonlar);
    if (json == null || json.isEmpty) return YaziciSablon.fabrika();
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => YaziciSablon.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return YaziciSablon.fabrika();
    }
  }

  Future<void> saveSablonlar(List<YaziciSablon> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _kSablonlar, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<YaziciSablon?> getSablon(String id) async {
    final list = await getSablonlar();
    try {
      return list.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addOrUpdate(YaziciSablon sablon) async {
    final list = await getSablonlar();
    final idx = list.indexWhere((s) => s.id == sablon.id);
    if (idx >= 0) {
      list[idx] = sablon;
    } else {
      list.add(sablon);
    }
    await saveSablonlar(list);
  }

  Future<void> delete(String id) async {
    final list = await getSablonlar();
    list.removeWhere((s) => s.id == id && !s.varsayilanMi);
    await saveSablonlar(list);
  }

  /// Fabrika şablonlarını sıfırla (tüm kullanıcı şablonları silinir)
  Future<void> sifirla() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kSablonlar);
  }
}
