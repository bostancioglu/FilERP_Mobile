/// Genel amaçlı fiş satırı: raporlar kendi içeriğini [FisSatir] listesi olarak üretir;
/// aynı liste hem ekran önizlemesinde ([FisSatir.onizleme]) hem yazıcıda
/// (BluetoothPrintService.buildSatirlarFisi) kullanılır, böylece ikisi birebir aynı olur.
class FisSatir {
  final String metin;
  final bool kalin;
  final bool ortali;

  /// Çift boy (başlık) — yalnızca yazıcıda büyür, önizlemede düz metin olarak görünür.
  final bool buyuk;

  const FisSatir(this.metin, {this.kalin = false, this.ortali = false, this.buyuk = false});

  /// Ekran önizlemesi için düz metin satırları (ortalı satırlar boşlukla ortalanır).
  static List<String> onizleme(List<FisSatir> satirlar, int genislik) => [
        for (final s in satirlar)
          s.ortali && s.metin.length < genislik ? '${' ' * ((genislik - s.metin.length) ~/ 2)}${s.metin}' : s.metin,
      ];
}

/// Satır genişliğine (kağıt eni) göre fiş satırı üretim yardımcıları.
class FisBicim {
  final int genislik;
  const FisBicim(this.genislik);

  String cizgi(String ch) => ch * genislik;

  /// Satıra sığmayan metni keser.
  String kes(String s) => s.length > genislik ? s.substring(0, genislik) : s;

  /// Sol metin + sağa yaslı değer. Sığmazsa sol metin kısaltılır.
  String satir(String sol, String sag) {
    final azami = genislik - sag.length - 1;
    final l = sol.length > azami ? sol.substring(0, azami < 1 ? 1 : azami) : sol;
    final bosluk = genislik - l.length - sag.length;
    return l + (' ' * (bosluk > 1 ? bosluk : 1)) + sag;
  }
}
