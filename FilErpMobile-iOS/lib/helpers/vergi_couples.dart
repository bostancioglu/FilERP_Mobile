/// Vergi / Tevkifat oranları için sabit liste ve yardımcı metodlar
class VergiCouples {
  // ─── Tevkifat Oranları ───────────────────────────────
  static const List<TevkifatCouple> tevkifatOranlari = [
    TevkifatCouple(0.0,  "0"),
    TevkifatCouple(0.1,  "1/10"),
    TevkifatCouple(0.2,  "2/10"),
    TevkifatCouple(0.3,  "3/10"),
    TevkifatCouple(0.4,  "4/10"),
    TevkifatCouple(0.5,  "5/10"),
    TevkifatCouple(0.6,  "6/10"),
    TevkifatCouple(0.7,  "7/10"),
    TevkifatCouple(0.8,  "8/10"),
    TevkifatCouple(0.9,  "9/10"),
    TevkifatCouple(1.0,  "10/10"),
  ];

  /// Ondalık oran → "x/10" string (örn. 0.3 → "3/10")
  static String adByOran(double? oran) {
    if (oran == null) return "0";
    final found = tevkifatOranlari.where((e) => (e.oran - oran).abs() < 0.001);
    return found.isEmpty ? "0" : found.first.ad;
  }

  /// "x/10" string → ondalık oran (örn. "3/10" → 0.3)
  static double oranByAd(String? ad) {
    if (ad == null) return 0;
    final found = tevkifatOranlari.where((e) => e.ad == ad);
    return found.isEmpty ? 0 : found.first.oran;
  }
}

class TevkifatCouple {
  final double oran;
  final String ad;
  const TevkifatCouple(this.oran, this.ad);
}