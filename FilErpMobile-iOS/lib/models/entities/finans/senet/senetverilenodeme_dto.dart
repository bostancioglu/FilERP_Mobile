import 'senetverilenodemehareket_dto.dart';

class SenetverilenodemeDto {
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
  final int       Belgedurum;

  // Navigasyon
  final String? BankahesapAd;
  final List<SenetverilenodemehareketDto>? Senetverilenodemehareket;

  SenetverilenodemeDto({
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
    this.Senetverilenodemehareket,
  });

  double get toplamTutar =>
      (Senetverilenodemehareket ?? []).fold(0.0, (s, h) => s + (h.Senetverilenhareket?.Tutar ?? 0.0));

  int get senetSayisi => (Senetverilenodemehareket ?? []).length;

  factory SenetverilenodemeDto.fromJson(Map<String, dynamic> json) {
    final bankahesap = json['Bankahesap'] as Map<String, dynamic>?;
    final hareketler = json['Senetverilenodemehareket'] as List?;

    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    return SenetverilenodemeDto(
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
      Senetverilenodemehareket: hareketler
          ?.map((e) => SenetverilenodemehareketDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
