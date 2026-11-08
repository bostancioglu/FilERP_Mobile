/// VW_Finanscekverilen ve VW_Finanscekverilenbeklemede view'ları aynı alan setine
/// sahip olduğu için tek bir DTO ile modellendi (backend DTO'ları birebir aynı).
class VwFinanscekverilenDto {
  final int?    Firmaid;
  final int?    Sirketid;
  final int?    Subeid;
  final int?    Plasiyerid;
  final int?    Projeid;
  final String? Projekodu;
  final DateTime? Kayittarihi;
  final DateTime? Belgetarihi;
  final DateTime? Vadetarihi;
  final String? Aciklama;
  final String? Asilborclu;
  final String? Asilborbluvergino;
  final String? Cekserino;
  final double? Doviztutar;
  final String? Plasiyerisim;
  final String? Plasiyerkodu;
  final String? Cekno;
  final double? Tutar;
  final int?    Kismiodeme;
  final double? Kalantutar;
  final DateTime? Tarih;
  final String? Bordrono;
  final String? Carikod;
  final String? Cariad;
  final String? Verilen_Ad;
  final String? Islem;
  final String? Durum;
  final int?    Islemtipi;
  final int?    Evrakdurum;
  final int?    Evrakyeri;
  final String? Bordrobasligi;
  final String? SuandaEvrakyeri;
  final String? SuandaEvrakdurum;
  final String? Cekbordroid;
  final String? Cekis;
  final String? Hesapno;
  final String? Iban;
  final String? Bankaadi;
  final String? Bankasubeadi;
  final String? Adres;
  final String? Vergino;
  final String? Vergidairesi;
  final String? Parabirimi;
  final double? Kur;

  VwFinanscekverilenDto({
    this.Firmaid,
    this.Sirketid,
    this.Subeid,
    this.Plasiyerid,
    this.Projeid,
    this.Projekodu,
    this.Kayittarihi,
    this.Belgetarihi,
    this.Vadetarihi,
    this.Aciklama,
    this.Asilborclu,
    this.Asilborbluvergino,
    this.Cekserino,
    this.Doviztutar,
    this.Plasiyerisim,
    this.Plasiyerkodu,
    this.Cekno,
    this.Tutar,
    this.Kismiodeme,
    this.Kalantutar,
    this.Tarih,
    this.Bordrono,
    this.Carikod,
    this.Cariad,
    this.Verilen_Ad,
    this.Islem,
    this.Durum,
    this.Islemtipi,
    this.Evrakdurum,
    this.Evrakyeri,
    this.Bordrobasligi,
    this.SuandaEvrakyeri,
    this.SuandaEvrakdurum,
    this.Cekbordroid,
    this.Cekis,
    this.Hesapno,
    this.Iban,
    this.Bankaadi,
    this.Bankasubeadi,
    this.Adres,
    this.Vergino,
    this.Vergidairesi,
    this.Parabirimi,
    this.Kur,
  });

  factory VwFinanscekverilenDto.fromJson(Map<String, dynamic> json) {
    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
    return VwFinanscekverilenDto(
      Firmaid:           json['Firmaid'],
      Sirketid:          json['Sirketid'],
      Subeid:            json['Subeid'],
      Plasiyerid:        json['Plasiyerid'],
      Projeid:           json['Projeid'],
      Projekodu:         json['Projekodu'],
      Kayittarihi:       _dt(json['Kayittarihi']),
      Belgetarihi:       _dt(json['Belgetarihi']),
      Vadetarihi:        _dt(json['Vadetarihi']),
      Aciklama:          json['Aciklama'],
      Asilborclu:        json['Asilborclu'],
      Asilborbluvergino: json['Asilborbluvergino'],
      Cekserino:         json['Cekserino'],
      Doviztutar:        _d(json['Doviztutar']),
      Plasiyerisim:      json['Plasiyerisim'],
      Plasiyerkodu:      json['Plasiyerkodu'],
      Cekno:             json['Cekno'],
      Tutar:             _d(json['Tutar']),
      Kismiodeme:        json['Kismiodeme'],
      Kalantutar:        _d(json['Kalantutar']),
      Tarih:             _dt(json['Tarih']),
      Bordrono:          json['Bordrono'],
      Carikod:           json['Carikod'],
      Cariad:            json['Cariad'],
      Verilen_Ad:        json['Verilen_Ad'],
      Islem:             json['Islem'],
      Durum:             json['Durum'],
      Islemtipi:         json['Islemtipi'],
      Evrakdurum:        json['Evrakdurum'],
      Evrakyeri:         json['Evrakyeri'],
      Bordrobasligi:     json['Bordrobasligi'],
      SuandaEvrakyeri:   json['SuandaEvrakyeri'],
      SuandaEvrakdurum:  json['SuandaEvrakdurum'],
      Cekbordroid:       json['Cekbordroid']?.toString(),
      Cekis:             json['Cekis']?.toString(),
      Hesapno:           json['Hesapno'],
      Iban:              json['Iban'],
      Bankaadi:          json['Bankaadi'],
      Bankasubeadi:      json['Bankasubeadi'],
      Adres:             json['Adres'],
      Vergino:           json['Vergino'],
      Vergidairesi:      json['Vergidairesi'],
      Parabirimi:        json['Parabirimi'],
      Kur:               _d(json['Kur']),
    );
  }
}
