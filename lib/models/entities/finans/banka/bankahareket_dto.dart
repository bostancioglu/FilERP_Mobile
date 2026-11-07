class BankahareketDto {
  final int? Islemmasrafid;
  final String? IslemmasrafAd;
  final double? Faiz;
  final double? Faizdoviz;
  final double? Kkdf;
  final double? Kkdfdoviz;
  final double? Ceza;
  final double? Cezadoviz;

  final String? Id; // Guid
  final int? Bankahesapid;
  final int? Islemcariid;
  final int? Islembankahesapid;
  final int? Dovizid;
  final int? Projeid;
  final int? Plasiyerid;

  final String? Belgeseri;
  final int? Belgeyil;
  final String? Belgeno;
  final String? Belgeserino;
  final int? Belgeturu;
  final int? Giriscikis; // 1=Giriş 2=Çıkış
  final int?
      Islemtipi; // 1=Havale 2=HesapVirman 3=BankaVirman 4=Devir 5=Muhtelif

  final double? Kur;
  final DateTime? Doviztarih;
  final double? Doviztutar;
  final double? Tutar;
  final double? Komisyon;
  final double? Dovizkomisyon;
  final double? Bsmv;
  final double? Dovizbsmv;
  final double? Digerucretler;
  final double? Dovizdigerucretler;
  final String? Aciklama;
  final DateTime? Tarih;
  final DateTime? Evraktarih;
  final DateTime? Valortarihi;
  final String? Evrakno;

  // Navigasyon
  final String? BankahesapAd;
  final String? IslemcariAd;
  final String? IslembankahesapAd;
  final String? DovizBirim;

  BankahareketDto({
    this.IslemmasrafAd,
    this.Islemmasrafid,
    this.Faiz,
    this.Faizdoviz,
    this.Kkdf,
    this.Kkdfdoviz,
    this.Ceza,
    this.Cezadoviz,
    this.Id,
    this.Bankahesapid,
    this.Islemcariid,
    this.Islembankahesapid,
    this.Dovizid,
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
    this.Komisyon,
    this.Dovizkomisyon,
    this.Bsmv,
    this.Dovizbsmv,
    this.Digerucretler,
    this.Dovizdigerucretler,
    this.Aciklama,
    this.Tarih,
    this.Evraktarih,
    this.Valortarihi,
    this.Evrakno,
    this.BankahesapAd,
    this.IslemcariAd,
    this.IslembankahesapAd,
    this.DovizBirim,
  });

  factory BankahareketDto.fromJson(Map<String, dynamic> json) {
    final bankahesap = json['Bankahesap'] as Map<String, dynamic>?;
    final islemcari = json['Islemcari'] as Map<String, dynamic>?;
    final islembankahesap = json['Islembankahesap'] as Map<String, dynamic>?;
    final doviz = json['Doviz'] as Map<String, dynamic>?;

    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    DateTime? _dt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return BankahareketDto(
      IslemmasrafAd: (json['Islemmasraf'] as Map?)?['Ad'],
      Islemmasrafid: json['Islemmasrafid'],
      Faiz: _d(json['Faiz']),
      Faizdoviz: _d(json['Faizdoviz']),
      Kkdf: _d(json['Kkdf']),
      Kkdfdoviz: _d(json['Kkdfdoviz']),
      Ceza: _d(json['Ceza']),
      Cezadoviz: _d(json['Cezadoviz']),
      Id: json['Id']?.toString(),
      Bankahesapid: json['Bankahesapid'],
      Islemcariid: json['Islemcariid'],
      Islembankahesapid: json['Islembankahesapid'],
      Dovizid: json['Dovizid'],
      Projeid: json['Projeid'],
      Plasiyerid: json['Plasiyerid'],
      Belgeseri: json['Belgeseri'],
      Belgeyil: json['Belgeyil'],
      Belgeno: json['Belgeno'],
      Belgeserino: json['Belgeserino'],
      Belgeturu: json['Belgeturu'],
      Giriscikis: json['Giriscikis'],
      Islemtipi: json['Islemtipi'],
      Kur: _d(json['Kur']),
      Doviztarih: _dt(json['Doviztarih']),
      Doviztutar: _d(json['Doviztutar']),
      Tutar: _d(json['Tutar']),
      Komisyon: _d(json['Komisyon']),
      Dovizkomisyon: _d(json['Dovizkomisyon']),
      Bsmv: _d(json['Bsmv']),
      Dovizbsmv: _d(json['Dovizbsmv']),
      Digerucretler: _d(json['Digerucretler']),
      Dovizdigerucretler: _d(json['Dovizdigerucretler']),
      Aciklama: json['Aciklama'],
      Tarih: _dt(json['Tarih']),
      Evraktarih: _dt(json['Evraktarih']),
      Valortarihi: _dt(json['Valortarihi']),
      Evrakno: json['Evrakno'],
      BankahesapAd: bankahesap?['Ad'],
      IslemcariAd: islemcari?['Ad'],
      IslembankahesapAd: islembankahesap?['Ad'],
      DovizBirim: doviz?['Birim'],
    );
  }
}
