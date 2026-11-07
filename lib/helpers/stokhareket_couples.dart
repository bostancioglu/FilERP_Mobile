import 'package:flutter/material.dart';
import 'stok_couples.dart';

class StokHareketCouples {
  // =======================
  // BELGE TÜRÜ
  // =======================
  static const List<ByteStrCouple> belgeTurleri = [
    ByteStrCouple(1, "Satış Faturası"),
    ByteStrCouple(2, "Alış Faturası"),
    ByteStrCouple(3, "Satış İrsaliyesi"),
    ByteStrCouple(4, "Alış İrsaliyesi"),
    ByteStrCouple(5, "Satış Sipariş"),
    ByteStrCouple(6, "Alış Sipariş"),
    ByteStrCouple(7, "Üretim"),
    ByteStrCouple(8, "Dep. Ara. Tra."),
    ByteStrCouple(9, "Şub. Ara. Tra."),
    ByteStrCouple(10, "Ambar Çıkış Fişi"),
    ByteStrCouple(11, "Ambar Giriş Fişi"),
    ByteStrCouple(12, "Gider Pusulası"),
    ByteStrCouple(13, "Stoklar Arası Virman"),
    ByteStrCouple(14, "Stok Devir"),
    ByteStrCouple(15, "Stok Sayım"),
    ByteStrCouple(16, "Müstahsil"),
    ByteStrCouple(17, "Satış Teklif"),
    ByteStrCouple(18, "Alış Teklif"),
    ByteStrCouple(19, "Satış Talep"),
    ByteStrCouple(20, "Alış Talep"),
    ByteStrCouple(21, "Kasa Hareket"),
    ByteStrCouple(22, "Banka Hareket"),
    ByteStrCouple(23, "Çek Bordro Müşteri"),
    ByteStrCouple(24, "Çek Müşteri"),
    ByteStrCouple(25, "Çek Bordro Müşteri Ciro"),
    ByteStrCouple(26, "Çek Müşteri Ciro"),
    ByteStrCouple(27, "Çek Bordro Müşteri Tahsil"),
    ByteStrCouple(28, "Çek Müşteri Tahsil"),
    ByteStrCouple(29, "Çek Bordro Müşteri Protesto"),
    ByteStrCouple(30, "Çek Müşteri Protesto"),
    ByteStrCouple(31, "Çek Bordro Müşteri İade"),
    ByteStrCouple(32, "Çek Müşteri İade"),
    ByteStrCouple(33, "Çek Bordro Müşteri Portföyden Tahsil"),
    ByteStrCouple(34, "Çek Portföyden Müşteri Tahsil"),
    ByteStrCouple(35, "Alış Bağlantı Sipariş"),
    ByteStrCouple(36, "Satış Bağlantı Sipariş"),
    ByteStrCouple(37, "Teklif Karşılaştırma"),
    ByteStrCouple(38, "Üretim Planlama"),
    ByteStrCouple(39, "Üretim Emri"),
    ByteStrCouple(40, "Palet"),
    ByteStrCouple(41, "Sevk Emri"),
    ByteStrCouple(42, "Mal Toplama"),
    ByteStrCouple(43, "Çek Bordro Borç"),
    ByteStrCouple(44, "Çek Borç"),
    ByteStrCouple(45, "Çek Bordro Borç Ödeme"),
    ByteStrCouple(46, "Çek Borç Ödeme"),
    ByteStrCouple(47, "Çek Bordro Borç İade"),
    ByteStrCouple(48, "Çek Borç İade"),
    ByteStrCouple(49, "Senet Bordro Müşteri"),
    ByteStrCouple(50, "Senet Müşteri"),
    ByteStrCouple(51, "Senet Bordro Müşteri Ciro"),
    ByteStrCouple(52, "Senet Müşteri Ciro"),
    ByteStrCouple(53, "Senet Bordro Müşteri Tahsil"),
    ByteStrCouple(54, "Senet Müşteri Tahsil"),
    ByteStrCouple(55, "Senet Bordro Müşteri Protesto"),
    ByteStrCouple(56, "Senet Müşteri Protesto"),
    ByteStrCouple(57, "Senet Bordro Müşteri İade"),
    ByteStrCouple(58, "Senet Müşteri İade"),
    ByteStrCouple(59, "Senet Bordro Müşteri Portföyden Tahsil"),
    ByteStrCouple(60, "Senet Portföyden Müşteri Tahsil"),
    ByteStrCouple(61, "Senet Bordro Borç"),
    ByteStrCouple(62, "Senet Borç"),
    ByteStrCouple(63, "Senet Bordro Borç Ödeme"),
    ByteStrCouple(64, "Senet Borç Ödeme"),
    ByteStrCouple(65, "Senet Bordro Borç İade"),
    ByteStrCouple(66, "Senet Borç İade"),
    ByteStrCouple(67, "Yükleme Planı"),
    ByteStrCouple(68, "Yevmiye Fişi"),
    ByteStrCouple(69, "Proforma Fatura"),
    ByteStrCouple(70, "Cari Devir"),
    ByteStrCouple(71, "Gider Fişi"),
    ByteStrCouple(72, "Tahsilat"),
    ByteStrCouple(73, "Ödeme"),
    ByteStrCouple(74, "Finans Planlama"),
    // ÖZEL - Sebze
    ByteStrCouple(101, "Sebze Boş Kap Transfer"),
    ByteStrCouple(102, "Sebze Dolu Kap Transfer"),
    ByteStrCouple(103, "Sebze Üretim"),
    ByteStrCouple(104, "Sebze Elek İşlem"),
    ByteStrCouple(105, "Sebze Kap Boşaltma"),
    ByteStrCouple(106, "Sebze Kap Devir"),
    // ÖZEL - Proje Yönetim
    ByteStrCouple(121, "İş Emri"),
  ];

  // =======================
  // BELGE TİPİ
  // =======================
  static const List<ByteStrCouple> belgeTipleri = [
    ByteStrCouple(1, "Açık"),
    ByteStrCouple(2, "Kapalı"),
    ByteStrCouple(3, "İade"),
    ByteStrCouple(4, "Zayi İade"),
    ByteStrCouple(5, "İthalat"),
    ByteStrCouple(6, "İhracat"),
    ByteStrCouple(7, "İhracat Kayıtlı"),
    ByteStrCouple(8, "Özel Matrah"),
    ByteStrCouple(9, "SGK"),
    ByteStrCouple(10, "Komisyoncu"),
    ByteStrCouple(11, "HKS Satış"),
    ByteStrCouple(12, "HKS Komisyoncu"),
    ByteStrCouple(13, "Şarj"),
    ByteStrCouple(14, "Şarjanlık"),
  ];

  static String? captionOf(int? value, List<ByteStrCouple> list) {
    if (value == null) return null;
    final found = list.where((e) => e.value == value);
    return found.isEmpty ? null : found.first.text;
  }

  // =======================
  // ÖDEME ŞEKLİ
  // =======================
  static const List<ByteStrCouple> odemeSekilleri = [
    ByteStrCouple(1,  "Banka Havale"),
    ByteStrCouple(2,  "Kredi Kartı"),
    ByteStrCouple(3,  "Nakit"),
    ByteStrCouple(4,  "Çek Senet"),
    ByteStrCouple(5,  "Mal Mukabili"),
    ByteStrCouple(99, "Diğer"),
  ];

  // =======================
  // İTHALAT / İHRACAT TİPİ (Turler enum)
  // =======================
  static const List<ByteStrCouple> ihracatTipleri = [
    ByteStrCouple(1,  "FOB"),
    ByteStrCouple(2,  "CIF"),
    ByteStrCouple(3,  "CF"),
    ByteStrCouple(4,  "FOT"),
    ByteStrCouple(5,  "İHRACAT KAYITLI"),
    ByteStrCouple(6,  "DAF"),
    ByteStrCouple(7,  "EXW"),
    ByteStrCouple(8,  "İHRACAT KUR FARKI"),
    ByteStrCouple(9,  "CIP"),
    ByteStrCouple(10, "CPT"),
    ByteStrCouple(11, "DAT"),
    ByteStrCouple(12, "DAP"),
    ByteStrCouple(13, "DDP"),
    ByteStrCouple(14, "DAS"),
    ByteStrCouple(15, "DEQ"),
    ByteStrCouple(16, "DDU"),
    ByteStrCouple(17, "FCA"),
    ByteStrCouple(18, "FAS"),
    ByteStrCouple(19, "CFR"),
    ByteStrCouple(20, "DPU"),
  ];

  // Belge tipi 5=İthalat, 6=İhracat, 7=İhracat Kayıtlı → ihracatTipleri göster
  static bool isIhracatTipi(int? belgetipi) =>
      belgetipi == 5 || belgetipi == 6 || belgetipi == 7;

  // =======================
  // E-FATURA DURUM
  // =======================
  static const List<ByteStrCouple> efaturaDurumlari = [
    ByteStrCouple(0, "Yeni"),
    ByteStrCouple(1, "Portala Gönderildi"),
    ByteStrCouple(2, "Taslak"),
    ByteStrCouple(3, "E-Belge"),
    ByteStrCouple(4, "İptal"),
    ByteStrCouple(5, "Red"),
  ];

  static String efaturaDurumAdi(int? durum) {
    if (durum == null) return "";
    final found = efaturaDurumlari.where((e) => e.value == durum);
    return found.isEmpty ? "" : found.first.text;
  }

  static Color efaturaDurumRenk(int? durum) {
    switch (durum) {
      case 0: return const Color(0xFF6B7280); // Yeni - gri
      case 1: return const Color(0xFF3B82F6); // Portala Gönderildi - mavi
      case 2: return const Color(0xFFF59E0B); // Taslak - turuncu
      case 3: return const Color(0xFF10B981); // E-Belge - yeşil
      case 4: return const Color(0xFFEF4444); // İptal - kırmızı
      case 5: return const Color(0xFFEF4444); // Red - kırmızı
      default: return const Color(0xFF6B7280);
    }
  }
}