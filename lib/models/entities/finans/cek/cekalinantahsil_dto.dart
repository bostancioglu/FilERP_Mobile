import 'cekalinantahsilhareket_dto.dart';

class CekalinantahsilDto {
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
  final List<CekalinantahsilhareketDto>? Cekalinantahsilhareket;

  CekalinantahsilDto({
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
    this.Cekalinantahsilhareket,
  });

  double get toplamTutar =>
      (Cekalinantahsilhareket ?? []).fold(0.0, (s, h) => s + (h.Cekalinanhareket?.Tutar ?? 0.0));

  int get cekSayisi => (Cekalinantahsilhareket ?? []).length;

  factory CekalinantahsilDto.fromJson(Map<String, dynamic> json) {
    final bankahesap = json['Bankahesap'] as Map<String, dynamic>?;
    final hareketler = json['Cekalinantahsilhareket'] as List?;

    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    return CekalinantahsilDto(
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
      Cekalinantahsilhareket: hareketler
          ?.map((e) => CekalinantahsilhareketDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
