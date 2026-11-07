class TahsilatDto {
  final String? Id;           // Guid
  final int?    Firmaid;
  final int?    Sirketid;
  final int?    Subeid;
  final int?    Cariid;
  final int?    Dovizid;
  final int?    Projeid;
  final int?    Plasiyerid;
  final int?    Bankahesapid;
  final int?    Kasaid;
  final int?    Kredikartisozlesmeid;

  final String? Belgeseri;
  final int?    Belgeyil;
  final String? Belgeno;
  final String? Belgeserino;
  final int?    Belgeturu;

  final DateTime? Tarih;
  final int?      Tip; // TahsilattipiCouples: 1=Nakit, 2=Banka
  final double?   Tahsilattutari;
  final double?   Kur;
  final DateTime? Doviztarih;
  final double?   Doviztutar;
  final int?      Taksitsayisi;
  final String?   Aciklama;

  final String? Islembelgeid;  // Guid — kaynak belge (ör. Sipariş/Fatura) id'si
  final int?    Islembelgeturu;

  // Navigasyon
  final String? CariAd;
  final String? DovizBirim;
  final String? ProjeAd;
  final String? PlasiyerAd;
  final String? BankahesapAd;
  final String? KasaAd;
  final String? KredikartisozlesmeAd;

  TahsilatDto({
    this.Id,
    this.Firmaid,
    this.Sirketid,
    this.Subeid,
    this.Cariid,
    this.Dovizid,
    this.Projeid,
    this.Plasiyerid,
    this.Bankahesapid,
    this.Kasaid,
    this.Kredikartisozlesmeid,
    this.Belgeseri,
    this.Belgeyil,
    this.Belgeno,
    this.Belgeserino,
    this.Belgeturu,
    this.Tarih,
    this.Tip,
    this.Tahsilattutari,
    this.Kur,
    this.Doviztarih,
    this.Doviztutar,
    this.Taksitsayisi,
    this.Aciklama,
    this.Islembelgeid,
    this.Islembelgeturu,
    this.CariAd,
    this.DovizBirim,
    this.ProjeAd,
    this.PlasiyerAd,
    this.BankahesapAd,
    this.KasaAd,
    this.KredikartisozlesmeAd,
  });

  factory TahsilatDto.fromJson(Map<String, dynamic> json) {
    final cari              = json['Cari']              as Map<String, dynamic>?;
    final doviz             = json['Doviz']              as Map<String, dynamic>?;
    final proje             = json['Proje']              as Map<String, dynamic>?;
    final plasiyer          = json['Plasiyer']           as Map<String, dynamic>?;
    final bankahesap        = json['Bankahesap']         as Map<String, dynamic>?;
    final kasa              = json['Kasa']               as Map<String, dynamic>?;
    final kredikartisozlesme = json['Kredikartisozlesme'] as Map<String, dynamic>?;

    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    return TahsilatDto(
      Id:                   json['Id']?.toString(),
      Firmaid:              json['Firmaid'],
      Sirketid:             json['Sirketid'],
      Subeid:               json['Subeid'],
      Cariid:               json['Cariid'],
      Dovizid:              json['Dovizid'],
      Projeid:              json['Projeid'],
      Plasiyerid:           json['Plasiyerid'],
      Bankahesapid:         json['Bankahesapid'],
      Kasaid:               json['Kasaid'],
      Kredikartisozlesmeid: json['Kredikartisozlesmeid'],
      Belgeseri:      json['Belgeseri'],
      Belgeyil:       json['Belgeyil'],
      Belgeno:        json['Belgeno'],
      Belgeserino:    json['Belgeserino'],
      Belgeturu:      json['Belgeturu'],
      Tarih:          _dt(json['Tarih']),
      Tip:            json['Tip'],
      Tahsilattutari: _d(json['Tahsilattutari']),
      Kur:            _d(json['Kur']),
      Doviztarih:     _dt(json['Doviztarih']),
      Doviztutar:     _d(json['Doviztutar']),
      Taksitsayisi:   json['Taksitsayisi'],
      Aciklama:       json['Aciklama'],
      Islembelgeid:   json['Islembelgeid']?.toString(),
      Islembelgeturu: json['Islembelgeturu'],
      CariAd:         cari?['Ad'],
      DovizBirim:     doviz?['Birim'],
      ProjeAd:        proje?['Ad'] ?? proje?['ad'],
      PlasiyerAd:     plasiyer?['Adsoyad'],
      BankahesapAd:   bankahesap?['Ad'],
      KasaAd:         kasa?['Ad'],
      KredikartisozlesmeAd: kredikartisozlesme?['Sozlesmeno'],
    );
  }
}
