class BankahesapCreateDto {
  int? Faizhesapplaniid;
  int? Kkdfhesapplaniid;
  int? Cezahesapplaniid;

  final int? Id;
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
  final bool Ortakkoduvar;
  final String? Ortakkod;
  final String? Muhasebeortakkod;

  BankahesapCreateDto({
    this.Faizhesapplaniid,
    this.Kkdfhesapplaniid,
    this.Cezahesapplaniid,
    this.Id,
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
    this.Ortakkoduvar = false,
    this.Ortakkod,
    this.Muhasebeortakkod,
  });

  Map<String, dynamic> toJson() => {
        'Faizhesapplaniid': Faizhesapplaniid,
        'Kkdfhesapplaniid': Kkdfhesapplaniid,
        'Cezahesapplaniid': Cezahesapplaniid,
        if (Id != null) 'Id': Id,
        'Dovizid': Dovizid,
        'Bankaid': Bankaid,
        'Bankasubeid': Bankasubeid,
        'Hesapplaniid': Hesapplaniid,
        'Komisyonhesapplaniid': Komisyonhesapplaniid,
        'Bsmvhesapplaniid': Bsmvhesapplaniid,
        'Kurfarkigelirhesapplaniid': Kurfarkigelirhesapplaniid,
        'Kurfarkigiderhesapplaniid': Kurfarkigiderhesapplaniid,
        'Ad': Ad,
        'Kod': Kod,
        'Hesapno': Hesapno,
        'Iban': Iban,
        'Hesaptipi': Hesaptipi,
        'Ortakkoduvar': Ortakkoduvar,
        'Ortakkod': Ortakkod,
        'Muhasebeortakkod': Muhasebeortakkod,
      };
}
