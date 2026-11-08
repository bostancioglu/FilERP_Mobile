import '../models/entities/fatura/fatura_hareket_create_dto.dart';

class KdvCalcHelper {
  static void recalcKalem(
    FaturaHareketCreateDto k, {
    required bool kdvDahil,
  }) {
    final oran = (k.kdvorani ?? 0) / 100;
    final miktar = k.miktar ?? 0;
    final fiyat = k.fiyat ?? 0;

    double netFiyat;

    if (kdvDahil && oran > 0) {
      netFiyat = fiyat / (1 + oran);
    } else {
      netFiyat = fiyat;
    }

    final brut = netFiyat * miktar;
    final kdv = brut * oran;

    k.bruttutar = brut;
    k.kdvtutar = kdv;
    k.tutar = brut + kdv;
  }
}
