import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/entities/cari/cari_dto_lite.dart';
import '../../../models/entities/depo/depo_dto.dart';
import '../../../models/entities/finans/banka/bankahesap_dto.dart';
import '../../../models/entities/finans/kasa_islem/kasa_dto.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../models/entities/stok/stok_list_dto.dart';

final _tarihFmt = DateFormat('dd.MM.yyyy');
final _tutarFmt = NumberFormat('#,##0.00', 'tr_TR');
final _miktarFmt = NumberFormat('#,##0.####', 'tr_TR');

String rapTarih(DateTime? d) => d == null ? '' : _tarihFmt.format(d);
String rapTutar(num v) => _tutarFmt.format(v);
String rapMiktar(num v) => _miktarFmt.format(v);

/// İşaretli bakiye (borç +, alacak −) → "1.234,56 B" / "1.234,56 A".
String rapBakiye(num v) {
  if (v.abs() < 0.005) return '0,00';
  return '${_tutarFmt.format(v.abs())} ${v > 0 ? 'B' : 'A'}';
}

enum RaporKolonTipi { metin, tarih, tutar, miktar, bakiye }

class RaporKolon {
  final String baslik;
  final RaporKolonTipi tip;

  /// Kart başlığında (üst satırda) gösterilir.
  final bool baslikKolonu;

  /// Özet çubuğunda toplamı gösterilir (tutar / miktar / bakiye kolonları).
  final bool toplamla;

  const RaporKolon(this.baslik,
      {this.tip = RaporKolonTipi.metin,
      this.baslikKolonu = false,
      this.toplamla = false});

  /// Hücre değerinin ekranda / dışa aktarmada görünen metni.
  String bicim(Object? v) {
    if (v == null) return '';
    switch (tip) {
      case RaporKolonTipi.tarih:
        return v is DateTime ? rapTarih(v) : v.toString();
      case RaporKolonTipi.tutar:
        return v is num ? rapTutar(v) : v.toString();
      case RaporKolonTipi.miktar:
        return v is num ? rapMiktar(v) : v.toString();
      case RaporKolonTipi.bakiye:
        return v is num ? rapBakiye(v) : v.toString();
      case RaporKolonTipi.metin:
        return v.toString();
    }
  }
}

class RaporSatir {
  /// Kolon sırasıyla değerler: String, DateTime veya num.
  final List<Object?> degerler;

  /// Satıra dokununca açılan detay (ör. cari ekstresi). Yoksa satır dokunulmaz.
  final void Function(BuildContext context)? detay;

  const RaporSatir(this.degerler, {this.detay});
}

class RaporOzet {
  final String etiket;
  final String deger;
  final Color renk;
  const RaporOzet(this.etiket, this.deger, this.renk);
}

class RaporSonuc {
  final List<RaporKolon> kolonlar;
  final List<RaporSatir> satirlar;

  /// Tanıma özel ek özetler (ör. "Toplam Giriş").
  final List<RaporOzet> ozetler;

  const RaporSonuc(this.kolonlar, this.satirlar, {this.ozetler = const []});
}

/// Kullanıcının seçtiği filtre değerleri (rapor tanımı hangi alanları kullanacağını belirler).
class RaporFiltre {
  DateTime? tarih1;
  DateTime? tarih2;
  CariDtoLite? cari;
  StokListDto? stok;
  DepoDto? depo;
  KasaDto? kasa;
  BankahesapDto? banka;
  DovizDto? doviz;
  int segment = 0;
  int segment2 = 0;
  bool anahtar = false;
  String? belgeno;
}

enum RaporFiltreTuru {
  tarih,
  cari,
  stok,
  depo,
  kasa,
  banka,
  doviz,
  segment,
  segment2,
  anahtar
}

class RaporTanim {
  final String no;
  final String baslik;
  final String aciklama;
  final IconData ikon;
  final Color renk;
  final List<RaporFiltreTuru> filtreler;

  final String segmentEtiketi;
  final List<String> segmentler;
  final String segment2Etiketi;
  final List<String> segmentler2;

  final String anahtarEtiketi;
  final bool anahtarVarsayilan;

  /// true: tarih aralığı bugün → bugün (günün tarihi) olarak gelir; false: boş (güncel durum / tüm zamanlar).
  final bool tarihVarsayilan;

  final Future<RaporSonuc> Function(RaporFiltre f) getir;

  const RaporTanim({
    required this.no,
    required this.baslik,
    required this.aciklama,
    required this.ikon,
    required this.renk,
    required this.filtreler,
    required this.getir,
    this.segmentEtiketi = '',
    this.segmentler = const [],
    this.segment2Etiketi = '',
    this.segmentler2 = const [],
    this.anahtarEtiketi = '',
    this.anahtarVarsayilan = false,
    this.tarihVarsayilan = true,
  });

  RaporFiltre varsayilanFiltre() {
    final f = RaporFiltre()..anahtar = anahtarVarsayilan;
    if (tarihVarsayilan) {
      final now = DateTime.now();
      f.tarih1 = DateTime(now.year, now.month, now.day);
      f.tarih2 = f.tarih1;
    }
    return f;
  }
}

/// Çok bölümlü rapor çıktısı (ör. Plasiyer Özeti): her bölüm ya "etiket: değer" satırları
/// ya da bir tablo içerir. PDF dışa aktarmada kullanılır.
class RaporBolum {
  final String baslik;
  final String? sagBaslik; // bölüm başlığının sağında (ör. toplam)
  final List<(String, String)> degerler;
  final RaporSonuc? tablo;

  const RaporBolum(this.baslik,
      {this.sagBaslik, this.degerler = const [], this.tablo});
}
