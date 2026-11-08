/// Hassas ayar ekranları için her gün değişen, hesaplamalı erişim kodu.
///
/// Formül: Gün² + (Ay × 31) + (Yıl mod 100) — kareli terim sayesinde günden
/// güne artış miktarı da değişir (doğrusal +1 gibi kolay tahmin edilmez).
/// Örnek: 16.08.2026 → 16² + 8×31 + 26 = 256 + 248 + 26 = 530
///        17.08.2026 → 17² + 8×31 + 26 = 289 + 248 + 26 = 563  (fark: 33)
///        18.08.2026 → 18² + 8×31 + 26 = 324 + 248 + 26 = 598  (fark: 35)
class GunlukKodHelper {
  const GunlukKodHelper._();

  static int hesapla([DateTime? tarih]) {
    final t = tarih ?? DateTime.now();
    final kod = (t.day * t.day) + (t.month * 31) + (t.year % 100);
    return kod;
  }

  static bool dogrula(String girilen, [DateTime? tarih]) {
    final girilenInt = int.tryParse(girilen.trim());
    if (girilenInt == null) return false;
    return girilenInt == hesapla(tarih);
  }
}
