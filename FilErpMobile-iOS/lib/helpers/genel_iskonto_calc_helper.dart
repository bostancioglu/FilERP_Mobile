import '../models/entities/fatura/fatura_create_dto.dart';

class GenelIskontoCalcHelper {
  static void recalc(FaturaCreateDto f) {
    final araToplam = f.aratoplam ?? 0;

    double iskontoTutar = 0;

    // 1 Oran varsa
    if ((f.geneliskontooran ?? 0) > 0) {
      iskontoTutar = araToplam * ((f.geneliskontooran ?? 0) / 100);
    }

    // 2 Tutar varsa (oranı ezer)
    if ((f.geneliskontotutar ?? 0) > 0) {
      iskontoTutar = f.geneliskontotutar!;
    }

    f.geneliskontotutar = iskontoTutar;
    f.aratoplam2 = araToplam - iskontoTutar;
  }
}
