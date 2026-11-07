import 'fatura_hesap_helper.dart';
import '../models/entities/irsaliye/irsaliye_dto.dart';
import '../models/entities/irsaliye/irsaliyehareket_dto.dart';

class IrsaliyeHesapHelper {
  static double rate(IrsaliyeDto document) =>
      (document.dovizid ?? 1) == 1 || (document.kur ?? 0) <= 0
          ? 1
          : document.kur!;

  /// Line prices and all accounting totals are in TL. Foreign amounts are
  /// converted only at the UI/API boundary.
  static FaturaTotalSonuc recalculate(
      IrsaliyeDto document, List<IrsaliyehareketDto> rows) {
    final percentage = document.geneliskontooran;
    final result = FaturaHesapHelper.hesaplaFaturaToplam(
        kalemler: rows
            .map((r) => KalemTutar(
                bruttutar: r.bruttutar ?? 0,
                kdvtutar: r.kdvtutar ?? 0,
                tevkifattutar: r.tevkifattutar))
            .toList(),
        genelIskontoOrani: percentage,
        genelIskontoTutar:
            (percentage ?? 0) > 0 ? null : document.geneliskontotutar);
    document.aratoplam = result.aratoplam;
    document.kdvtoplam = result.kdvtoplam;
    document.geneltoplam = result.geneltoplam;
    document.geneliskontotutar = result.iskontotutar;
    document.dovizgeneliskontotutar = result.iskontotutar / rate(document);
    return result;
  }
}
