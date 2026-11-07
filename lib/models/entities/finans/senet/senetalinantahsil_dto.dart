import 'senetalinantahsilhareket_dto.dart';

class SenetalinantahsilDto {
  final String? Id;          // Guid
  final int?    Firmaid;
  final int?    Sirketid;
  final int?    Subeid;
  final int?    Bankahesapid;

  final String? Belgeseri;
  final int?    Belgeyil;
  final String? Belgeno;
  final String? Belgeserino;
  final int?    Belgeturu;

  final DateTime? Tarih;
  final String?   Aciklama;
  final String?   Makbuzno;
  final int       Belgedurum; // BelgeDurumCouples

  // Navigasyon
  final String? BankahesapAd;
  final List<SenetalinantahsilhareketDto>? Senetalinantahsilhareket;

  SenetalinantahsilDto({
    this.Id,
    this.Firmaid,
    this.Sirketid,
    this.Subeid,
    this.Bankahesapid,
    this.Belgeseri,
    this.Belgeyil,
    this.Belgeno,
    this.Belgeserino,
    this.Belgeturu,
    this.Tarih,
    this.Aciklama,
    this.Makbuzno,
    this.Belgedurum = 0,
    this.BankahesapAd,
    this.Senetalinantahsilhareket,
  });

  double get toplamTutar =>
      (Senetalinantahsilhareket ?? []).fold(0.0, (s, h) => s + (h.Senetalinanhareket?.Tutar ?? 0.0));

  int get senetSayisi => (Senetalinantahsilhareket ?? []).length;

  factory SenetalinantahsilDto.fromJson(Map<String, dynamic> json) {
    final bankahesap = json['Bankahesap'] as Map<String, dynamic>?;
    final hareketler = json['Senetalinantahsilhareket'] as List?;

    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    return SenetalinantahsilDto(
      Id:           json['Id']?.toString(),
      Firmaid:      json['Firmaid'],
      Sirketid:     json['Sirketid'],
      Subeid:       json['Subeid'],
      Bankahesapid: json['Bankahesapid'],
      Belgeseri:    json['Belgeseri'],
      Belgeyil:     json['Belgeyil'],
      Belgeno:      json['Belgeno'],
      Belgeserino:  json['Belgeserino'],
      Belgeturu:    json['Belgeturu'],
      Tarih:        _dt(json['Tarih']),
      Aciklama:     json['Aciklama'],
      Makbuzno:     json['Makbuzno'],
      Belgedurum:   json['Belgedurum'] ?? 0,
      BankahesapAd: bankahesap?['Ad'],
      Senetalinantahsilhareket: hareketler
          ?.map((e) => SenetalinantahsilhareketDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
