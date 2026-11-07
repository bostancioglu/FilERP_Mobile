import '../../../base_dto.dart';

class BankahesapDto extends BaseDto {
  final int? Faizhesapplaniid;
  final int? Kkdfhesapplaniid;
  final int? Cezahesapplaniid;

  final int? Firmaid;
  final int? Sirketid;
  final int? Subeid;
  final int? Dovizid;
  final int? Bankaid;
  final int? Bankasubeid;
  final int? Hesapplaniid;
  final int? Komisyonhesapplaniid;
  final int? Bsmvhesapplaniid;
  final int? Kurfarkigelirhesapplaniid;
  final int? Kurfarkigiderhesapplaniid;
  final String? Ad;
  final String? Kod;
  final String? Hesapno;
  final String? Iban;
  final int? Hesaptipi;
  final bool? Ortakkoduvar;
  final String? Ortakkod;
  final String? Muhasebeortakkod;

  // Navigasyon (liste görünümü için)
  final String? DovizBirim;
  final String? DovizAd;
  final String? BankaAd;
  final String? BankaKod;
  final String? BankasubeAd;
  final String? HesapplaniKod;

  BankahesapDto({
    this.Faizhesapplaniid,
    this.Kkdfhesapplaniid,
    this.Cezahesapplaniid,
    super.Id,
    this.Firmaid,
    this.Sirketid,
    this.Subeid,
    this.Dovizid,
    this.Bankaid,
    this.Bankasubeid,
    this.Hesapplaniid,
    this.Komisyonhesapplaniid,
    this.Bsmvhesapplaniid,
    this.Kurfarkigelirhesapplaniid,
    this.Kurfarkigiderhesapplaniid,
    this.Ad,
    this.Kod,
    this.Hesapno,
    this.Iban,
    this.Hesaptipi,
    this.Ortakkoduvar,
    this.Ortakkod,
    this.Muhasebeortakkod,
    this.DovizBirim,
    this.DovizAd,
    this.BankaAd,
    this.BankaKod,
    this.BankasubeAd,
    this.HesapplaniKod,
  });

  factory BankahesapDto.fromJson(Map<String, dynamic> json) {
    final doviz = json['Doviz'] as Map<String, dynamic>?;
    final banka = json['Banka'] as Map<String, dynamic>?;
    final bankasube = json['Bankasube'] as Map<String, dynamic>?;
    final hesapplani = json['Hesapplani'] as Map<String, dynamic>?;
    return BankahesapDto(
      Faizhesapplaniid: json['Faizhesapplaniid'],
      Kkdfhesapplaniid: json['Kkdfhesapplaniid'],
      Cezahesapplaniid: json['Cezahesapplaniid'],
      Id: json['Id'],
      Firmaid: json['Firmaid'],
      Sirketid: json['Sirketid'],
      Subeid: json['Subeid'],
      Dovizid: json['Dovizid'],
      Bankaid: json['Bankaid'],
      Bankasubeid: json['Bankasubeid'],
      Hesapplaniid: json['Hesapplaniid'],
      Komisyonhesapplaniid: json['Komisyonhesapplaniid'],
      Bsmvhesapplaniid: json['Bsmvhesapplaniid'],
      Kurfarkigelirhesapplaniid: json['Kurfarkigelirhesapplaniid'],
      Kurfarkigiderhesapplaniid: json['Kurfarkigiderhesapplaniid'],
      Ad: json['Ad'],
      Kod: json['Kod'],
      Hesapno: json['Hesapno'],
      Iban: json['Iban'],
      Hesaptipi: json['Hesaptipi'],
      Ortakkoduvar: json['Ortakkoduvar'],
      Ortakkod: json['Ortakkod'],
      Muhasebeortakkod: json['Muhasebeortakkod'],
      DovizBirim: doviz?['Birim'],
      DovizAd: doviz?['Ad'],
      BankaAd: banka?['Ad'],
      BankaKod: banka?['Kod'],
      BankasubeAd: bankasube?['Ad'],
      HesapplaniKod: hesapplani?['Kod'],
    );
  }
}
