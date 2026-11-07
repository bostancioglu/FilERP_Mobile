class LookupItem {
  final int id;
  final String ad;

  const LookupItem(this.id, this.ad);
}

class LookupHelper {
  // ================== KART TÜRLERİ ==================
  static const List<LookupItem> kartTurleri = [
    LookupItem(1, "Müşteri"),
    LookupItem(2, "Bayi"),
    LookupItem(3, "İhracat"),
    LookupItem(4, "Satıcı"),
    LookupItem(5, "Toptancı"),
    LookupItem(6, "İthalat"),
    LookupItem(7, "Müstahsil"),
    LookupItem(8, "Nakliyeci"),
    LookupItem(9, "Taşeron"),
    LookupItem(10, "Hizmet"),
  ];

  // ================== E-FATURA TİPLERİ ==================
  static const List<LookupItem> efaturaTipleri = [
    LookupItem(1, "Temel"),
    LookupItem(2, "Ticari"),
    LookupItem(3, "Kamu"),
    LookupItem(4, "Yolcu Beraber"),
    LookupItem(5, "İhracat"),
    LookupItem(6, "Özel Fatura"),
    LookupItem(7, "E-Arşiv Fatura"),
    LookupItem(8, "HKS"),
    LookupItem(9, "E-Arşiv Belge"),
    LookupItem(10, "Enerji"),
  ];
  // ================== FATURA BELGE TİPLERİ ==================
static const List<LookupItem> faturaBelgeTipleri = [
  LookupItem(1, "Açık"),
  LookupItem(2, "Kapalı"),
  LookupItem(3, "İade"),
  LookupItem(4, "Zayi İade"),
  LookupItem(5, "İthalat"),
  LookupItem(6, "İhracat"),
  LookupItem(7, "İhracat Kayıtlı"),
  LookupItem(8, "Özel Matrah"),
  LookupItem(9, "SGK"),
  LookupItem(10, "Komisyoncu"),
  LookupItem(11, "HKS Satış"),
  LookupItem(12, "HKS Komisyoncu"),
  LookupItem(13, "Şarj"),
  LookupItem(14, "Şarj Anlık"),
];

  // ================== KDV YÜZDESİ ======================
    static const List<KdvLookup> kdvOranlari = [
    KdvLookup(oran: 0,  katsayi: 0.0,  text: "%0"),
    KdvLookup(oran: 1,  katsayi: 0.01, text: "%1"),
    KdvLookup(oran: 10, katsayi: 0.10, text: "%10"),
    KdvLookup(oran: 20, katsayi: 0.20, text: "%20"),
  ];
}

class KdvLookup {
  final int oran;        // 0, 1, 10, 20
  final double katsayi;  // 0.0, 0.01, 0.10, 0.20
  final String text;     // %0, %1, %10, %20

  const KdvLookup({
    required this.oran,
    required this.katsayi,
    required this.text,
  });
  // ================== BELGE TÜRLERİ ==================
static const List<LookupItem> belgeTurleri = [
  LookupItem(1, "Satış Faturası"),
  LookupItem(2, "Alış Faturası"),
  LookupItem(3, "Satış İrsaliyesi"),
  LookupItem(4, "Alış İrsaliyesi"),
  LookupItem(5, "Satış Sipariş"),
  LookupItem(6, "Alış Sipariş"),
  LookupItem(7, "Üretim"),
  LookupItem(8, "Dep. Ara. Tra."),
  LookupItem(9, "Şub. Ara. Tra."),
  LookupItem(10, "Ambar Çıkış Fişi"),
  LookupItem(11, "Ambar Giriş Fişi"),
  LookupItem(12, "Gider Pusulası"),
  LookupItem(13, "Stoklar Arası Virman"),
  LookupItem(14, "Stok Devir"),
  LookupItem(15, "Stok Sayım"),
  LookupItem(16, "Müstahsil"),
  LookupItem(17, "Satış Teklif"),
  LookupItem(18, "Alış Teklif"),
  LookupItem(19, "Satış Talep"),
  LookupItem(20, "Alış Talep"),
  LookupItem(21, "Kasa Hareket"),
  LookupItem(22, "Banka Hareket"),
  LookupItem(23, "Çek Bordro Müşteri"),
  LookupItem(24, "Çek Müşteri"),
  LookupItem(25, "Çek Bordro Müşteri Ciro"),
  LookupItem(26, "Çek Müşteri Ciro"),
  LookupItem(27, "Çek Bordro Müşteri Tahsil"),
  LookupItem(28, "Çek Müşteri Tahsil"),
  LookupItem(29, "Çek Bordro Müşteri Protesto"),
  LookupItem(30, "Çek Müşteri Protesto"),
  LookupItem(31, "Çek Bordro Müşteri İade"),
  LookupItem(32, "Çek Müşteri İade"),
  LookupItem(33, "Çek Bordro Müşteri Portföyden Tahsil"),
  LookupItem(34, "Çek Portföyden Müşteri Tahsil"),
  LookupItem(35, "Alış Bağlantı Sipariş"),
  LookupItem(36, "Satış Bağlantı Sipariş"),
  LookupItem(37, "Teklif Karşılaştırma"),
  LookupItem(38, "Üretim Planlama"),
  LookupItem(39, "Üretim Emri"),
  LookupItem(40, "Palet"),
  LookupItem(41, "Sevk Emri"),
  LookupItem(42, "Mal Toplama"),
  LookupItem(43, "Çek Bordro Borç"),
  LookupItem(44, "Çek Borç"),
  LookupItem(45, "Çek Bordro Borç Ödeme"),
  LookupItem(46, "Çek Borç Ödeme"),
  LookupItem(47, "Çek Bordro Borç İade"),
  LookupItem(48, "Çek Borç İade"),
  LookupItem(49, "Senet Bordro Müşteri"),
  LookupItem(50, "Senet Müşteri"),
  LookupItem(51, "Senet Bordro Müşteri Ciro"),
  LookupItem(52, "Senet Müşteri Ciro"),
  LookupItem(53, "Senet Bordro Müşteri Tahsil"),
  LookupItem(54, "Senet Müşteri Tahsil"),
  LookupItem(55, "Senet Bordro Müşteri Protesto"),
  LookupItem(56, "Senet Müşteri Protesto"),
  LookupItem(57, "Senet Bordro Müşteri İade"),
  LookupItem(58, "Senet Müşteri İade"),
  LookupItem(59, "Senet Bordro Müşteri Portföyden Tahsil"),
  LookupItem(60, "Senet Portföyden Müşteri Tahsil"),
  LookupItem(61, "Senet Bordro Borç"),
  LookupItem(62, "Senet Borç"),
  LookupItem(63, "Senet Bordro Borç Ödeme"),
  LookupItem(64, "Senet Borç Ödeme"),
  LookupItem(65, "Senet Bordro Borç İade"),
  LookupItem(66, "Senet Borç İade"),
  LookupItem(67, "Yükleme Planı"),
  LookupItem(68, "Yevmiye Fişi"),
  LookupItem(69, "Proforma Fatura"),
  LookupItem(70, "Cari Devir"),
  LookupItem(71, "Gider Fişi"),
  LookupItem(72, "Tahsilat"),
  LookupItem(73, "Ödeme"),
  // ÖZEL - Sebze
  LookupItem(101, "Sebze Boş Kap Transfer"),
  LookupItem(102, "Sebze Dolu Kap Transfer"),
  LookupItem(103, "Sebze Üretim"),
  LookupItem(104, "Sebze Elek İşlem"),
  LookupItem(105, "Sebze Kap Boşaltma"),
  LookupItem(106, "Sebze Kap Devir"),
  // ÖZEL - Proje Yönetim
  LookupItem(121, "İş Emri"),
];

// ================== BELGE TİPLERİ ==================
static const List<LookupItem> belgeTipleri = [
  LookupItem(1, "Açık"),
  LookupItem(2, "Kapalı"),
  LookupItem(3, "İade"),
  LookupItem(4, "Zayi İade"),
  LookupItem(5, "İthalat"),
  LookupItem(6, "İhracat"),
  LookupItem(7, "İhracat Kayıtlı"),
  LookupItem(8, "Özel Matrah"),
  LookupItem(9, "SGK"),
  LookupItem(10, "Komisyoncu"),
  LookupItem(11, "HKS Satış"),
  LookupItem(12, "HKS Komisyoncu"),
  LookupItem(13, "Şarj"),
  LookupItem(14, "Şarjanlık"),
];
}
