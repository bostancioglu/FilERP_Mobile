/// Müşteri Çek raporları (VW_Finanscekalinan, ...ciro, ...portfoy, ...tahsil,
/// ...teminat, ...protesto) hepsi aynı alan setine sahip olduğu için tek bir
/// DTO ile modellendi (backend view DTO'ları birebir aynı).
class VwFinanscekalinanDto {
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
  final double? Kismiodeme;
  final double? Kalantutar;
  final DateTime? Tarih;
  final String? Bordrono;
  final String? Carikod;
  final String? Cariad;
  final String? Verilenad;
  final String? Islem;
  final String? Durum;
  final int?    Islemtipi;
  final int?    Evrakdurum;
  final int?    Evrakyeri;
  final int?    Bordrotipi;
  final String? Bordrobasligi;
  final String? SuandaEvrakyeri;
  final String? SuandaEvrakdurum;
  final String? Cekbordroid;
  final String? Cekid;
  final String? Hesapno;
  final String? Iban;
  final String? Bankaadi;
  final String? Bankasubeadi;
  final String? Adres;
  final String? Vergino;
  final String? Vergidairesi;
  final int?    Cariid;
  final String? Cariisim;
  final bool?   Asilciro;
  final String? Cekis;
  final String? Verilenkod;
  final int?    Verilencariid;
  final String? Parabirimi;
  final double? Kur;

  VwFinanscekalinanDto({
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
    this.Verilenad,
    this.Islem,
    this.Durum,
    this.Islemtipi,
    this.Evrakdurum,
    this.Evrakyeri,
    this.Bordrotipi,
    this.Bordrobasligi,
    this.SuandaEvrakyeri,
    this.SuandaEvrakdurum,
    this.Cekbordroid,
    this.Cekid,
    this.Hesapno,
    this.Iban,
    this.Bankaadi,
    this.Bankasubeadi,
    this.Adres,
    this.Vergino,
    this.Vergidairesi,
    this.Cariid,
    this.Cariisim,
    this.Asilciro,
    this.Cekis,
    this.Verilenkod,
    this.Verilencariid,
    this.Parabirimi,
    this.Kur,
  });

  factory VwFinanscekalinanDto.fromJson(Map<String, dynamic> json) {
    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
    return VwFinanscekalinanDto(
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
      Kismiodeme:        _d(json['Kismiodeme']),
      Kalantutar:        _d(json['Kalantutar']),
      Tarih:             _dt(json['Tarih']),
      Bordrono:          json['Bordrono'],
      Carikod:           json['Carikod'],
      Cariad:            json['Cariad'],
      Verilenad:         json['Verilenad'],
      Islem:             json['Islem'],
      Durum:             json['Durum'],
      Islemtipi:         json['Islemtipi'],
      Evrakdurum:        json['Evrakdurum'],
      Evrakyeri:         json['Evrakyeri'],
      Bordrotipi:        json['Bordrotipi'],
      Bordrobasligi:     json['Bordrobasligi'],
      SuandaEvrakyeri:   json['SuandaEvrakyeri'],
      SuandaEvrakdurum:  json['SuandaEvrakdurum'],
      Cekbordroid:       json['Cekbordroid']?.toString(),
      Cekid:             json['Cekid']?.toString(),
      Hesapno:           json['Hesapno'],
      Iban:              json['Iban'],
      Bankaadi:          json['Bankaadi'],
      Bankasubeadi:      json['Bankasubeadi'],
      Adres:             json['Adres'],
      Vergino:           json['Vergino'],
      Vergidairesi:      json['Vergidairesi'],
      Cariid:            json['cariid'] ?? json['Cariid'],
      Cariisim:          json['Cariisim'],
      Asilciro:          json['Asilciro'],
      Cekis:             json['Cekis']?.toString(),
      Verilenkod:        json['Verilenkod'],
      Verilencariid:     json['Verilencariid'],
      Parabirimi:        json['Parabirimi'],
      Kur:               _d(json['Kur']),
    );
  }
}
