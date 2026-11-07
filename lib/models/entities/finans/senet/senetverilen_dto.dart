import 'senetverilenhareket_dto.dart';

class SenetverilenDto {
  final String? Id;          // Guid
  final int?    Firmaid;
  final int?    Sirketid;
  final int?    Subeid;
  final int?    Cariid;
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
  final bool?     Devir;
  final int       Belgedurum; // BelgeDurumCouples

  // Navigasyon
  final String? CariAd;
  final String? ProjeAd;
  final String? PlasiyerAd;
  final List<SenetverilenhareketDto>? Senetverilenhareket;

  SenetverilenDto({
    this.Id,
    this.Firmaid,
    this.Sirketid,
    this.Subeid,
    this.Cariid,
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
    this.Devir,
    this.Belgedurum = 0,
    this.CariAd,
    this.ProjeAd,
    this.PlasiyerAd,
    this.Senetverilenhareket,
  });

  double get toplamTutar =>
      (Senetverilenhareket ?? []).fold(0.0, (s, h) => s + (h.Tutar ?? 0.0));

  int get senetSayisi => (Senetverilenhareket ?? []).length;

  factory SenetverilenDto.fromJson(Map<String, dynamic> json) {
    final cari     = json['Cari']     as Map<String, dynamic>?;
    final proje    = json['Proje']    as Map<String, dynamic>?;
    final plasiyer = json['Plasiyer'] as Map<String, dynamic>?;
    final hareketler = json['Senetverilenhareket'] as List?;

    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    return SenetverilenDto(
      Id:           json['Id']?.toString(),
      Firmaid:      json['Firmaid'],
      Sirketid:     json['Sirketid'],
      Subeid:       json['Subeid'],
      Cariid:       json['Cariid'],
      Projeid:      json['Projeid'],
      Plasiyerid:   json['Plasiyerid'],
      Belgeseri:    json['Belgeseri'],
      Belgeyil:     json['Belgeyil'],
      Belgeno:      json['Belgeno'],
      Belgeserino:  json['Belgeserino'],
      Belgeturu:    json['Belgeturu'],
      Tarih:        _dt(json['Tarih']),
      Aciklama:     json['Aciklama'],
      Makbuzno:     json['Makbuzno'],
      Devir:        json['Devir'],
      Belgedurum:   json['Belgedurum'] ?? 0,
      CariAd:       cari?['Ad'],
      ProjeAd:      proje?['Ad'] ?? proje?['ad'],
      PlasiyerAd:   plasiyer?['Adsoyad'],
      Senetverilenhareket: hareketler
          ?.map((e) => SenetverilenhareketDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
