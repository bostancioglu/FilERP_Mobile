class ParaBirimiHelper {
  /// Döviz ID -> Sembol
  /// 1 = TL, 2 = USD, 3 = EUR, 4 = GBP
  static String sembolById(int? dovizId) {
    switch (dovizId) {
      case 1:
        return "₺"; // Türk Lirası
      case 2:
        return "\$"; // Amerikan Doları
      case 3:
        return "€"; // Euro
      case 4:
        return "£"; // İngiliz Sterlini
      default:
        return "₺";
    }
  }


  static String adById(int? dovizId) {
    switch (dovizId) {
      case 1:
        return "TL";
      case 2:
        return "USD";
      case 3:
        return "EUR";
      case 4:
        return "GBP";
      default:
        return "TL";
    }
  }
}
