class KasaCreateDto {
  int? Plasiyerid;
  bool? Plasiyerkasasi;

  final int? Id;
  final int? Dovizid;
  final int? Hesapplaniid;
  final int? Kurfarkigelirhesapplaniid;
  final int? Kurfarkigiderhesapplaniid;
  final String? Ad;
  final String? Kod;
  final bool Ortakkoduvar;
  final String? Ortakkod;
  final String? Muhasebeortakkod;

  KasaCreateDto({
    this.Plasiyerid,
    this.Plasiyerkasasi,
    this.Id,
    this.Dovizid,
    this.Hesapplaniid,
    this.Kurfarkigelirhesapplaniid,
    this.Kurfarkigiderhesapplaniid,
    this.Ad,
    this.Kod,
    this.Ortakkoduvar = false,
    this.Ortakkod,
    this.Muhasebeortakkod,
  });

  Map<String, dynamic> toJson() => {
        'Plasiyerid': Plasiyerid,
        'Plasiyerkasasi': Plasiyerkasasi,
        if (Id != null) 'Id': Id,
        'Dovizid': Dovizid,
        'Hesapplaniid': Hesapplaniid,
        'Kurfarkigelirhesapplaniid': Kurfarkigelirhesapplaniid,
        'Kurfarkigiderhesapplaniid': Kurfarkigiderhesapplaniid,
        'Ad': Ad,
        'Kod': Kod,
        'Ortakkoduvar': Ortakkoduvar,
        'Ortakkod': Ortakkod,
        'Muhasebeortakkod': Muhasebeortakkod,
      };
}
