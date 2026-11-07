/// Fatura satır ve toplam hesaplamalarını merkezi olarak yöneten helper.
///
/// Hesaplama sırası:
///   1. Ara Toplam  = Miktar × Birim Fiyat
///   2. Matrah      = Ara Toplam - Satır İskontosu
///   3. KDV Tutarı  = Matrah × KDV Oranı   (KDV Hariç ise)
///      veya Matrah = Genel Toplam / (1 + KDV Oranı)  (KDV Dahil ise)
///   4. Tevkifat    = KDV Tutarı × Tevkifat Oranı
///   5. Net Toplam  = Matrah + (KDV Tutarı - Tevkifat)
class FaturaHesapHelper {
  // ─── Kalem Hesabı ────────────────────────────────────
  static KalemHesapSonuc hesaplaKalem({
    required double miktar,
    required double fiyat,
    required double iskontoTutar,
    required double kdvOrani,       // 0-100 arası (örn: 20.0)
    required double tevkifatOrani,  // 0-1 arası  (örn: 0.5)
    required bool kdvDahil,
    double malFazlasiAdet = 0,   
  }) {
    final double ara      = miktar * fiyat;
    final double netTutar = ara - iskontoTutar;
    final double oran     = kdvOrani / 100;

    double matrah;
    double kdvTutar;
    double genelToplam;

    if (kdvDahil) {
      genelToplam = netTutar;
      matrah      = oran > 0 ? genelToplam / (1 + oran) : genelToplam;
      kdvTutar    = genelToplam - matrah;
    } else {
      matrah      = netTutar;
      kdvTutar    = matrah * oran;
      genelToplam = matrah + kdvTutar;
    }

    // Tevkifat: KDV × oran 
    final double tevkifatTutar    = kdvTutar * tevkifatOrani;
    final double saticinaOdenenKdv = kdvTutar - tevkifatTutar;

    if (tevkifatOrani > 0) {
      genelToplam = matrah + saticinaOdenenKdv;
    }

    return KalemHesapSonuc(
      bruttutar      : matrah,
      kdvtutar       : kdvTutar,
      tevkifattutar  : tevkifatOrani > 0 ? tevkifatTutar : null,
      tevkifatmatrahi: tevkifatOrani > 0 ? kdvTutar : null,
      tutar          : genelToplam,
    );
  }

  // ─── Fatura Toplam Hesabı ─────────────────────────────
  /// Kalem listesinden fatura toplamlarını hesaplar.
  /// Genel iskonto varsa matrah ve KDV'ye oransal uygulanır.
  static FaturaTotalSonuc hesaplaFaturaToplam({
    required List<KalemTutar> kalemler,
    double? genelIskontoOrani,    // % olarak (örn: 10.0)
    double? genelIskontoTutar,
  }) {
    double matrahToplam = 0;
    double kdvToplam    = 0;

    for (final k in kalemler) {
      matrahToplam += k.bruttutar;
      // Net KDV = brüt KDV - tevkifat
      kdvToplam    += k.kdvtutar - (k.tevkifattutar ?? 0);
    }

    // Genel iskonto
    double genIsk = 0;
    if ((genelIskontoTutar ?? 0) > 0) {
      genIsk = genelIskontoTutar!;
    } else if ((genelIskontoOrani ?? 0) > 0) {
      genIsk = matrahToplam * (genelIskontoOrani! / 100);
    }
    if (genIsk > matrahToplam) genIsk = matrahToplam;

    final double matrahNet = matrahToplam - genIsk;

    // Genel iskonto KDV'yi de oransal etkiler
    final double kdvOranEfektif = matrahToplam > 0 ? (kdvToplam / matrahToplam) : 0;
    final double kdvNet         = matrahNet * kdvOranEfektif;

    return FaturaTotalSonuc(
      aratoplam   : matrahNet,
      kdvtoplam   : kdvNet,
      iskontotutar: genIsk,
      geneltoplam : matrahNet + kdvNet,
    );
  }
}

// ─── Sonuç Modelleri ─────────────────────────────────────

class KalemHesapSonuc {
  final double  bruttutar;
  final double  kdvtutar;
  final double? tevkifattutar;
  final double? tevkifatmatrahi;
  final double  tutar;

  const KalemHesapSonuc({
    required this.bruttutar,
    required this.kdvtutar,
    required this.tutar,
    this.tevkifattutar,
    this.tevkifatmatrahi,
  });
}

class KalemTutar {
  final double  bruttutar;
  final double  kdvtutar;
  final double? tevkifattutar;

  const KalemTutar({
    required this.bruttutar,
    required this.kdvtutar,
    this.tevkifattutar,
  });
}

class FaturaTotalSonuc {
  final double aratoplam;
  final double kdvtoplam;
  final double iskontotutar;
  final double geneltoplam;

  const FaturaTotalSonuc({
    required this.aratoplam,
    required this.kdvtoplam,
    required this.iskontotutar,
    required this.geneltoplam,
  });
}