import 'package:shared_preferences/shared_preferences.dart';

/// Ayarlar > "Varsayılan Kasa" ile seçilen kasa.
/// Plasiyer kasası sunucudan otomatik bulunamadığında (yetki yok) yedek olarak kullanılır.
class VarsayilanKasaHelper {
  const VarsayilanKasaHelper._();

  static const _kSecilen = 'varsayilan_kasa_id';

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
}
