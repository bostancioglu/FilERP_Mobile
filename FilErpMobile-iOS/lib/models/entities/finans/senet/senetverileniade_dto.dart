import 'senetverileniadehareket_dto.dart';

class SenetverileniadeDto {
  final String? Id;          // Guid
  final int?    Firmaid;
  final int?    Sirketid;
  final int?    Subeid;
  final int?    Cariid;

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
  final String? CariAd;
  final List<SenetverileniadehareketDto>? Senetverileniadehareket;

  SenetverileniadeDto({
    this.Id,
    this.Firmaid,
    this.Sirketid,
    this.Subeid,
    this.Cariid,
    this.Belgeseri,
    this.Belgeyil,
    this.Belgeno,
    this.Belgeserino,
    this.Belgeturu,
    this.Tarih,
    this.Aciklama,
    this.Makbuzno,
    this.Belgedurum = 0,
    this.CariAd,
    this.Senetverileniadehareket,
  });

  double get toplamTutar =>
      (Senetverileniadehareket ?? []).fold(0.0, (s, h) => s + (h.Senetverilenhareket?.Tutar ?? 0.0));

  int get senetSayisi => (Senetverileniadehareket ?? []).length;

  factory SenetverileniadeDto.fromJson(Map<String, dynamic> json) {
    final cari       = json['Cari'] as Map<String, dynamic>?;
    final hareketler = json['Senetverileniadehareket'] as List?;

    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    return SenetverileniadeDto(
      Id:          json['Id']?.toString(),
      Firmaid:     json['Firmaid'],
      Sirketid:    json['Sirketid'],
      Subeid:      json['Subeid'],
      Cariid:      json['Cariid'],
      Belgeseri:   json['Belgeseri'],
      Belgeyil:    json['Belgeyil'],
      Belgeno:     json['Belgeno'],
      Belgeserino: json['Belgeserino'],
      Belgeturu:   json['Belgeturu'],
      Tarih:       _dt(json['Tarih']),
      Aciklama:    json['Aciklama'],
      Makbuzno:    json['Makbuzno'],
      Belgedurum:  json['Belgedurum'] ?? 0,
      CariAd:      cari?['Ad'],
      Senetverileniadehareket: hareketler
          ?.map((e) => SenetverileniadehareketDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
