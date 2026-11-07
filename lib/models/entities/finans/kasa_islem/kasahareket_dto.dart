class KasahareketDto {
  final int? Islemmasrafid;
  final String? IslemmasrafAd;
  final double? Masraf;

  final String? Id;
  final int? Kasaid;
  final int? Dovizid;
  final int? Islemcariid;
  final int? Islemkasaid;
  final int? Islembankahesapid;
  final int? Projeid;
  final int? Plasiyerid;

  final String? Belgeseri;
  final int? Belgeyil;
  final String? Belgeno;
  final String? Belgeserino;
  final int? Belgeturu;
  final int? Giriscikis; // 1=Giriş 2=Çıkış
  final int?
      Islemtipi; // 1=Cari 2=Banka 3=KasaTransfer 4=Devir 5=Tahsilat 6=Ödeme

  final double? Kur;
  final DateTime? Doviztarih;
  final double? Doviztutar;
  final double? Tutar;
  final String? Aciklama;
  final DateTime? Tarih;
  final DateTime? Evraktarih;
  final String? Evrakno;

  // Görüntüleme için navigasyon alanları
  final String? KasaAd;
  final String? IslemkasaAd;
  final String? IslemcariAd;
  final String? IslembankahesapAd;
  final String? DovizBirim;
  final String? ProjeAd;
  final String? PlasiyerAd;

  KasahareketDto({
    this.IslemmasrafAd,
    this.Islemmasrafid,
    this.Masraf,
    this.Id,
    this.Kasaid,
    this.Dovizid,
    this.Islemcariid,
    this.Islemkasaid,
    this.Islembankahesapid,
    this.Projeid,
    this.Plasiyerid,
    this.Belgeseri,
    this.Belgeyil,
    this.Belgeno,
    this.Belgeserino,
    this.Belgeturu,
    this.Giriscikis,
    this.Islemtipi,
    this.Kur,
    this.Doviztarih,
    this.Doviztutar,
    this.Tutar,
    this.Aciklama,
    this.Tarih,
    this.Evraktarih,
    this.Evrakno,
    this.KasaAd,
    this.IslemkasaAd,
    this.IslemcariAd,
    this.IslembankahesapAd,
    this.DovizBirim,
    this.ProjeAd,
    this.PlasiyerAd,
  });

  factory KasahareketDto.fromJson(Map<String, dynamic> json) {
    double? d(dynamic v) => v == null ? null : (v as num).toDouble();
    DateTime? dt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    final kasa = json['Kasa'] as Map<String, dynamic>?;
    final islemkasa = json['Islemkasa'] as Map<String, dynamic>?;
    final islemcari = json['Islemcari'] as Map<String, dynamic>?;
    final islembankahesap = json['Islembankahesap'] as Map<String, dynamic>?;
    final doviz = json['Doviz'] as Map<String, dynamic>?;
    final proje = json['Proje'] as Map<String, dynamic>?;
    final plasiyer = json['Plasiyer'] as Map<String, dynamic>?;

    return KasahareketDto(
      IslemmasrafAd: (json['Islemmasraf'] as Map?)?['Ad'],
      Islemmasrafid: json['Islemmasrafid'],
      Masraf: d(json['Masraf']),
      Id: json['Id']?.toString(),
      Kasaid: json['Kasaid'],
      Dovizid: json['Dovizid'],
      Islemcariid: json['Islemcariid'],
      Islemkasaid: json['Islemkasaid'],
      Islembankahesapid: json['Islembankahesapid'],
      Projeid: json['Projeid'],
      Plasiyerid: json['Plasiyerid'],
      Belgeseri: json['Belgeseri'],
      Belgeyil: json['Belgeyil'],
      Belgeno: json['Belgeno'],
      Belgeserino: json['Belgeserino'],
      Belgeturu: json['Belgeturu'],
      Giriscikis: json['Giriscikis'],
      Islemtipi: json['Islemtipi'],
      Kur: d(json['Kur']),
      Doviztarih: dt(json['Doviztarih']),
      Doviztutar: d(json['Doviztutar']),
      Tutar: d(json['Tutar']),
      Aciklama: json['Aciklama'],
      Tarih: dt(json['Tarih']),
      Evraktarih: dt(json['Evraktarih']),
      Evrakno: json['Evrakno'],
      KasaAd: kasa?['Ad'],
      IslemkasaAd: islemkasa?['Ad'],
      IslemcariAd: islemcari?['Ad'],
      IslembankahesapAd: islembankahesap?['Ad'],
      DovizBirim: doviz?['Birim'],
      ProjeAd: proje?['Ad'],
      PlasiyerAd: plasiyer?['Adsoyad'],
    );
  }
}
