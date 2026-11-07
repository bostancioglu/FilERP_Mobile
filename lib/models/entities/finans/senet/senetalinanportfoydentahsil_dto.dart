import 'senetalinanportfoydentahsilhareket_dto.dart';

class SenetalinanportfoydentahsilDto {
  final String? Id;          // Guid
  final int?    Firmaid;
  final int?    Sirketid;
  final int?    Subeid;
  final int?    Kasaid;
  final int?    Bankahesapid;

  final String? Belgeseri;
  final int?    Belgeyil;
  final String? Belgeno;
  final String? Belgeserino;
  final int?    Belgeturu;

  final DateTime? Tarih;
  final String?   Aciklama;
  final String?   Makbuzno;
  final int?      Tahsilyeri; // TahsilyeriCouples: 1=Kasa, 2=Banka
  final int       Belgedurum;

  // Navigasyon
  final String? KasaAd;
  final String? BankahesapAd;
  final List<SenetalinanportfoydentahsilhareketDto>? Senetalinanportfoydentahsilhareket;

  SenetalinanportfoydentahsilDto({
    this.Id,
    this.Firmaid,
    this.Sirketid,
    this.Subeid,
    this.Kasaid,
    this.Bankahesapid,
    this.Belgeseri,
    this.Belgeyil,
    this.Belgeno,
    this.Belgeserino,
    this.Belgeturu,
    this.Tarih,
    this.Aciklama,
    this.Makbuzno,
    this.Tahsilyeri,
    this.Belgedurum = 0,
    this.KasaAd,
    this.BankahesapAd,
    this.Senetalinanportfoydentahsilhareket,
  });

  double get toplamTutar =>
      (Senetalinanportfoydentahsilhareket ?? []).fold(0.0, (s, h) => s + (h.Tutar ?? h.Senetalinanhareket?.Tutar ?? 0.0));

  int get senetSayisi => (Senetalinanportfoydentahsilhareket ?? []).length;

  factory SenetalinanportfoydentahsilDto.fromJson(Map<String, dynamic> json) {
    final kasa        = json['Kasa']        as Map<String, dynamic>?;
    final bankahesap   = json['Bankahesap']  as Map<String, dynamic>?;
    final hareketler   = json['Senetalinanportfoydentahsilhareket'] as List?;

    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    return SenetalinanportfoydentahsilDto(
      Id:           json['Id']?.toString(),
      Firmaid:      json['Firmaid'],
      Sirketid:     json['Sirketid'],
      Subeid:       json['Subeid'],
      Kasaid:       json['Kasaid'],
      Bankahesapid: json['Bankahesapid'],
      Belgeseri:    json['Belgeseri'],
      Belgeyil:     json['Belgeyil'],
      Belgeno:      json['Belgeno'],
      Belgeserino:  json['Belgeserino'],
      Belgeturu:    json['Belgeturu'],
      Tarih:        _dt(json['Tarih']),
      Aciklama:     json['Aciklama'],
      Makbuzno:     json['Makbuzno'],
      Tahsilyeri:   json['Tahsilyeri'],
      Belgedurum:   json['Belgedurum'] ?? 0,
      KasaAd:       kasa?['Ad'],
      BankahesapAd: bankahesap?['Ad'],
      Senetalinanportfoydentahsilhareket: hareketler
          ?.map((e) => SenetalinanportfoydentahsilhareketDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
