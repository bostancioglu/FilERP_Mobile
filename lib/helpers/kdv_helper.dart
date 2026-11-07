class KdvHelper {
  /// DB: 0.2 veya 20 → UI: %20
  static String yuzdeText(num? oran) {
    if (oran == null) return "-";
    final yuzde = oran <= 1.0 && oran > 0 ? oran * 100 : oran;
    return "%${yuzde.toStringAsFixed(0)}";
  }
}