/// Belge türü sabitleri — C# BelgeTuru enum'una birebir karşılık gelir.
class BelgeTuruCouples {
  const BelgeTuruCouples._();

  // ─── Fatura ────────────────────────────────────────────
  static const int satisFaturasi               = 1;
  static const int alisFaturasi                = 2;
  // ─── İrsaliye ──────────────────────────────────────────
  static const int satisIrsaliyesi             = 3;
  static const int alisIrsaliyesi              = 4;
  // ─── Sipariş ───────────────────────────────────────────
  static const int satisSiparis                = 5;
  static const int alisSiparis                 = 6;
  // ─── Üretim ────────────────────────────────────────────
  static const int uretim                      = 7;
  // ─── Transfer ──────────────────────────────────────────
  static const int depolarArasiTransfer        = 8;
  static const int subelerArasiTransfer        = 9;
  // ─── Ambar ─────────────────────────────────────────────
  static const int ambarCikisFisi              = 10;
  static const int ambarGirisFisi              = 11;
  // ─── Diğer ─────────────────────────────────────────────
  static const int giderPusulasi               = 12;
  static const int stoklarArasiVirman          = 13;
  static const int stokDevir                   = 14;
  static const int stokSayim                   = 15;
  static const int mustahsil                   = 16;
  // ─── Teklif / Talep ────────────────────────────────────
  static const int satisTeklif                 = 17;
  static const int alisTeklif                  = 18;
  static const int satisTalep                  = 19;
  static const int alisTalep                   = 20;
  // ─── Kasa / Banka ──────────────────────────────────────
  static const int kasaHareket                 = 21;
  static const int bankaHareket                = 22;
  // ─── Çek Müşteri ───────────────────────────────────────
  static const int cekBordroMusteri            = 23;
  static const int cekMusteri                  = 24;
  static const int cekBordroMusteriCiro        = 25;
  static const int cekMusteriCiro              = 26;
  static const int cekBordroMusteriTahsil      = 27;
  static const int cekMusteriTahsil            = 28;
  static const int cekBordroMusteriProtesto    = 29;
  static const int cekMusteriProtesto          = 30;
  static const int cekBordroMusteriIade        = 31;
  static const int cekMusteriIade              = 32;
  static const int cekBordroMusteriPortfoy     = 33;
  static const int cekMusteriPortfoy           = 34;
  // ─── Bağlantı / Karşılaştırma ──────────────────────────
  static const int alisBaglantiSiparis         = 35;
  static const int satisBaglantiSiparis        = 36;
  static const int teklifKarsilastirma         = 37;
  // ─── Üretim Yönetim ────────────────────────────────────
  static const int uretimPlanlama              = 38;
  static const int uretimEmri                  = 39;
  // ─── Lojistik ──────────────────────────────────────────
  static const int palet                       = 40;
  static const int sevkEmri                    = 41;
  static const int malToplama                  = 42;
  // ─── Çek Borç ──────────────────────────────────────────
  static const int cekBordroBorc               = 43;
  static const int cekBorc                     = 44;
  static const int cekBordroBorcOdeme          = 45;
  static const int cekBorcOdeme                = 46;
  static const int cekBordroBorcIade           = 47;
  static const int cekBorcIade                 = 48;
  // ─── Senet Müşteri ─────────────────────────────────────
  static const int senetBordroMusteri          = 49;
  static const int senetMusteri                = 50;
  static const int senetBordroMusteriCiro      = 51;
  static const int senetMusteriCiro            = 52;
  static const int senetBordroMusteriTahsil    = 53;
  static const int senetMusteriTahsil          = 54;
  static const int senetBordroMusteriProtesto  = 55;
  static const int senetMusteriProtesto        = 56;
  static const int senetBordroMusteriIade      = 57;
  static const int senetMusteriIade            = 58;
  static const int senetBordroMusteriPortfoy   = 59;
  static const int senetMusteriPortfoy         = 60;
  // ─── Senet Borç ────────────────────────────────────────
  static const int senetBordroBorc             = 61;
  static const int senetBorc                   = 62;
  static const int senetBordroBorcOdeme        = 63;
  static const int senetBorcOdeme              = 64;
  static const int senetBordroBorcIade         = 65;
  static const int senetBorcIade               = 66;
  // ─── Finans / Muhasebe ─────────────────────────────────
  static const int yuklemePlani                = 67;
  static const int yevmiyeFisi                 = 68;
  static const int proformaFatura              = 69;
  static const int cariDevir                   = 70;
  static const int giderFisi                   = 71;
  static const int tahsilat                    = 72;
  static const int odeme                       = 73;
  static const int finansPlanlama              = 74;
  // ─── Özel Sebze (101-106) ──────────────────────────────
  static const int sebzeBosTransfer            = 101;
  static const int sebzeDoluTransfer           = 102;
  static const int sebzeUretim                 = 103;
  static const int sebzeElekIslem              = 104;
  static const int sebzeKapBosaltma            = 105;
  static const int sebzeKapDevir               = 106;
  // ─── Proje Yönetim (121+) ──────────────────────────────
  static const int projeYonetimIsEmri          = 121;

  // ─── Ad listesi ────────────────────────────────────────
  static const List<_BelgeTuruCouple> _list = [
    _BelgeTuruCouple(1,   "Satış Faturası"),
    _BelgeTuruCouple(2,   "Alış Faturası"),
    _BelgeTuruCouple(3,   "Satış İrsaliyesi"),
    _BelgeTuruCouple(4,   "Alış İrsaliyesi"),
    _BelgeTuruCouple(5,   "Satış Sipariş"),
    _BelgeTuruCouple(6,   "Alış Sipariş"),
    _BelgeTuruCouple(7,   "Üretim"),
    _BelgeTuruCouple(8,   "Dep. Ara. Tra."),
    _BelgeTuruCouple(9,   "Şub. Ara. Tra."),
    _BelgeTuruCouple(10,  "Ambar Çıkış Fişi"),
    _BelgeTuruCouple(11,  "Ambar Giriş Fişi"),
    _BelgeTuruCouple(12,  "Gider Pusulası"),
    _BelgeTuruCouple(13,  "Stoklar Arası Virman"),
    _BelgeTuruCouple(14,  "Stok Devir"),
    _BelgeTuruCouple(15,  "Stok Sayım"),
    _BelgeTuruCouple(16,  "Müstahsil"),
    _BelgeTuruCouple(17,  "Satış Teklif"),
    _BelgeTuruCouple(18,  "Alış Teklif"),
    _BelgeTuruCouple(19,  "Satış Talep"),
    _BelgeTuruCouple(20,  "Alış Talep"),
    _BelgeTuruCouple(21,  "Kasa Hareket"),
    _BelgeTuruCouple(22,  "Banka Hareket"),
    _BelgeTuruCouple(35,  "Alış Bağlantı Sipariş"),
    _BelgeTuruCouple(36,  "Satış Bağlantı Sipariş"),
    _BelgeTuruCouple(37,  "Teklif Karşılaştırma"),
    _BelgeTuruCouple(38,  "Üretim Planlama"),
    _BelgeTuruCouple(39,  "Üretim Emri"),
    _BelgeTuruCouple(40,  "Palet"),
    _BelgeTuruCouple(41,  "Sevk Emri"),
    _BelgeTuruCouple(42,  "Mal Toplama"),
    _BelgeTuruCouple(67,  "Yükleme Planı"),
    _BelgeTuruCouple(68,  "Yevmiye Fişi"),
    _BelgeTuruCouple(69,  "Proforma Fatura"),
    _BelgeTuruCouple(70,  "Cari Devir"),
    _BelgeTuruCouple(71,  "Gider Fişi"),
    _BelgeTuruCouple(72,  "Tahsilat"),
    _BelgeTuruCouple(73,  "Ödeme"),
    _BelgeTuruCouple(74,  "Finans Planlama"),
    _BelgeTuruCouple(101, "Sebze Boş Kap Transfer"),
    _BelgeTuruCouple(102, "Sebze Dolu Kap Transfer"),
    _BelgeTuruCouple(103, "Sebze Üretim"),
    _BelgeTuruCouple(104, "Sebze Elek İşlem"),
    _BelgeTuruCouple(105, "Sebze Kap Boşaltma"),
    _BelgeTuruCouple(106, "Sebze Kap Devir"),
    _BelgeTuruCouple(121, "İş Emri"),
  ];

  static String adById(int? id) =>
      _list.where((e) => e.tur == id).firstOrNull?.ad ?? '-';

  static List<_BelgeTuruCouple> get tumListesi => _list;
}

class _BelgeTuruCouple {
  final int    tur;
  final String ad;
  const _BelgeTuruCouple(this.tur, this.ad);
}