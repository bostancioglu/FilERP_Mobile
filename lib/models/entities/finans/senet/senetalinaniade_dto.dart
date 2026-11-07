import 'senetalinaniadehareket_dto.dart';

class SenetalinaniadeDto {
  final String? Id;          // Guid
  final int?    Firmaid;
  final int?    Sirketid;
  final int?    Subeid;
  final int?    Cariid;
  final int?    Bankahesapid;

  final String? Belgeseri;
  final int?    Belgeyil;
  final String? Belgeno;
  final String? Belgeserino;
  final int?    Belgeturu;

  final DateTime? Tarih;
  final String?   Aciklama;
  final String?   Makbuzno;
  final int?      Iadeyeri; // EvrakYeriCouples: 1=Portföy,2=Tahsil,3=Teminat,4=Ciro
  final int       Belgedurum;

  // Navigasyon
  final String? CariAd;
  final String? BankahesapAd;
  final List<SenetalinaniadehareketDto>? Senetalinaniadehareket;

  SenetalinaniadeDto({
    this.Id,
    this.Firmaid,
    this.Sirketid,
    this.Subeid,
    this.Cariid,
    this.Bankahesapid,
    this.Belgeseri,
    this.Belgeyil,
    this.Belgeno,
    this.Belgeserino,
    this.Belgeturu,
    this.Tarih,
    this.Aciklama,
    this.Makbuzno,
    this.Iadeyeri,
    this.Belgedurum = 0,
    this.CariAd,
    this.BankahesapAd,
    this.Senetalinaniadehareket,
  });

  double get toplamTutar =>
      (Senetalinaniadehareket ?? []).fold(0.0, (s, h) => s + (h.Senetalinanhareket?.Tutar ?? 0.0));

  int get senetSayisi => (Senetalinaniadehareket ?? []).length;

  factory SenetalinaniadeDto.fromJson(Map<String, dynamic> json) {
    final cari       = json['Cari']       as Map<String, dynamic>?;
    final bankahesap = json['Bankahesap'] as Map<String, dynamic>?;
    final hareketler = json['Senetalinaniadehareket'] as List?;

    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    return SenetalinaniadeDto(
      Id:           json['Id']?.toString(),
      Firmaid:      json['Firmaid'],
      Sirketid:     json['Sirketid'],
      Subeid:       json['Subeid'],
      Cariid:       json['Cariid'],
      Bankahesapid: json['Bankahesapid'],
      Belgeseri:    json['Belgeseri'],
      Belgeyil:     json['Belgeyil'],
      Belgeno:      json['Belgeno'],
      Belgeserino:  json['Belgeserino'],
      Belgeturu:    json['Belgeturu'],
      Tarih:        _dt(json['Tarih']),
      Aciklama:     json['Aciklama'],
      Makbuzno:     json['Makbuzno'],
      Iadeyeri:     json['Iadeyeri'],
      Belgedurum:   json['Belgedurum'] ?? 0,
      CariAd:       cari?['Ad'],
      BankahesapAd: bankahesap?['Ad'],
      Senetalinaniadehareket: hareketler
          ?.map((e) => SenetalinaniadehareketDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
