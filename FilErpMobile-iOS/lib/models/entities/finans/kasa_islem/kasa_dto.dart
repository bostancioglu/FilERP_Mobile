import '../../../base_dto.dart';

class KasaDto extends BaseDto {
  final int?    Firmaid;
  final int?    Sirketid;
  final int?    Subeid;
  final int?    Dovizid;
  final int?    Hesapplaniid;
  final int?    Kurfarkigelirhesapplaniid;
  final int?    Kurfarkigiderhesapplaniid;
  final String? Ad;
  final String? Kod;
  final bool?   Ortakkoduvar;
  final String? Ortakkod;
  final String? Muhasebeortakkod;
  final int?    Plasiyerid;       // Plasiyer kasasıysa sahibi (sunucu bu alanı döndürürse dolar)
  final bool?   Plasiyerkasasi;

  // Navigasyon (liste görünümü için)
  final String? HesapplaniKod;

  KasaDto({
    super.Id,
    this.Firmaid,
    this.Sirketid,
    this.Subeid,
    this.Dovizid,
    this.Hesapplaniid,
    this.Kurfarkigelirhesapplaniid,
    this.Kurfarkigiderhesapplaniid,
    this.Ad,
    this.Kod,
    this.Ortakkoduvar,
    this.Ortakkod,
    this.Muhasebeortakkod,
    this.Plasiyerid,
    this.Plasiyerkasasi,
    this.HesapplaniKod,
  });

  factory KasaDto.fromJson(Map<String, dynamic> json) {
    final hesapplani = json['Hesapplani'] as Map<String, dynamic>?;
    return KasaDto(
      Id:                          json['Id'],
      Firmaid:                     json['Firmaid'],
      Sirketid:                    json['Sirketid'],
      Subeid:                      json['Subeid'],
      Dovizid:                     json['Dovizid'],
      Hesapplaniid:                json['Hesapplaniid'],
      Kurfarkigelirhesapplaniid:   json['Kurfarkigelirhesapplaniid'],
      Kurfarkigiderhesapplaniid:   json['Kurfarkigiderhesapplaniid'],
      Ad:                          json['Ad'],
      Kod:                         json['Kod'],
      Ortakkoduvar:                json['Ortakkoduvar'],
      Ortakkod:                    json['Ortakkod'],
      Muhasebeortakkod:            json['Muhasebeortakkod'],
      Plasiyerid:                  json['Plasiyerid'],
      Plasiyerkasasi:              json['Plasiyerkasasi'],
      HesapplaniKod:               hesapplani?['Kod'],
    );
  }
}
