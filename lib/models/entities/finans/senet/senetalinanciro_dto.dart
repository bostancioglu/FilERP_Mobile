import 'senetalinancirohareket_dto.dart';

class SenetalinanciroDto {
  final String? Id;          // Guid
  final int?    Firmaid;
  final int?    Sirketid;
  final int?    Subeid;
  final int?    Cariid;
  final int?    Bankahesapid;
  final int?    Projeid;
  final int?    Plasiyerid;

  final String? Belgeseri;
  final int?    Belgeyil;
  final String? Belgeno;
  final String? Belgeserino;
  final int?    Belgeturu;

  final DateTime? Tarih;
  final String?   Aciklama;
  final String?   Makbuzno;
  final int?      Ciroturu;    // CiroTuruCouples
  final int       Belgedurum;  // BelgeDurumCouples

  // Navigasyon
  final String? CariAd;
  final String? BankahesapAd;
  final List<SenetalinancirohareketDto>? Senetalinancirohareket;

  SenetalinanciroDto({
    this.Id,
    this.Firmaid,
    this.Sirketid,
    this.Subeid,
    this.Cariid,
    this.Bankahesapid,
    this.Projeid,
    this.Plasiyerid,
    this.Belgeseri,
    this.Belgeyil,
    this.Belgeno,
    this.Belgeserino,
    this.Belgeturu,
    this.Tarih,
    this.Aciklama,
    this.Makbuzno,
    this.Ciroturu,
    this.Belgedurum = 0,
    this.CariAd,
    this.BankahesapAd,
    this.Senetalinancirohareket,
  });

  double get toplamTutar =>
      (Senetalinancirohareket ?? []).fold(0.0, (s, h) => s + (h.Senetalinanhareket?.Tutar ?? 0.0));

  int get senetSayisi => (Senetalinancirohareket ?? []).length;

  factory SenetalinanciroDto.fromJson(Map<String, dynamic> json) {
    final cari       = json['Cari']       as Map<String, dynamic>?;
    final bankahesap = json['Bankahesap'] as Map<String, dynamic>?;
    final hareketler = json['Senetalinancirohareket'] as List?;

    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    return SenetalinanciroDto(
      Id:            json['Id']?.toString(),
      Firmaid:       json['Firmaid'],
      Sirketid:      json['Sirketid'],
      Subeid:        json['Subeid'],
      Cariid:        json['Cariid'],
      Bankahesapid:  json['Bankahesapid'],
      Projeid:       json['Projeid'],
      Plasiyerid:    json['Plasiyerid'],
      Belgeseri:     json['Belgeseri'],
      Belgeyil:      json['Belgeyil'],
      Belgeno:       json['Belgeno'],
      Belgeserino:   json['Belgeserino'],
      Belgeturu:     json['Belgeturu'],
      Tarih:         _dt(json['Tarih']),
      Aciklama:      json['Aciklama'],
      Makbuzno:      json['Makbuzno'],
      Ciroturu:      json['Ciroturu'],
      Belgedurum:    json['Belgedurum'] ?? 0,
      CariAd:        cari?['Ad'],
      BankahesapAd:  bankahesap?['Ad'],
      Senetalinancirohareket: hareketler
          ?.map((e) => SenetalinancirohareketDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
