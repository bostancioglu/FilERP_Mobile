import '../models/entities/fatura/fatura_hareket_create_dto.dart';

class IskontoCalcHelper {
  static void recalc(FaturaHareketCreateDto k) {
    double kalan = k.bruttutar ?? 0;

    double toplamIskonto = 0;

    void uygula(double? oran, int index) {
      if (oran == null || oran <= 0) return;

      final isk = kalan * (oran / 100);
      toplamIskonto += isk;
      kalan -= isk;

      switch (index) {
        case 1:
          k.iskontotutari1 = isk;
          break;
        case 2:
          k.iskontotutari2 = isk;
          break;
        case 3:
          k.iskontotutari3 = isk;
          break;
        case 4:
          k.iskontotutari4 = isk;
          break;
        case 5:
          k.iskontotutari5 = isk;
          break;
      }
    }

    // SIRAYLA
    uygula(k.iskontoorani1, 1);
    uygula(k.iskontoorani2, 2);
    uygula(k.iskontoorani3, 3);
    uygula(k.iskontoorani4, 4);
    uygula(k.iskontoorani5, 5);

    k.iskontotutar = toplamIskonto;
    k.aratoplamiskontolu = kalan;
  }
}
