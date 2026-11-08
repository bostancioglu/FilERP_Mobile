class CekverilenhareketDto {
  final String? Id;           // Guid
  final int?    Firmaid;
  final int?    Projeid;
  final int?    Plasiyerid;
  final int?    Dovizid;
  final int?    Bankahesapid; // şirketin kendi banka hesabı (FK)
  final String? Cekverilenid; // Guid — üst bordro

  final String? Belgeseri;
  final int?    Belgeyil;
  final String? Belgeno;
  final String? Belgeserino;

  final DateTime? Vadetarihi;
  final DateTime? Odemetarihi;

  final double?   Kur;
  final DateTime? Doviztarih;
  final double?   Doviztutar;
  final double?   Tutar;

  final String? Ceknumarasi;
  final String? Aciklama;

  final int?    Evrakdurum;   // EvrakDurumCouples
  final int?    Evrakyeri;    // EvrakYeriCouples — varsayılan Ciro(4)

  // Navigasyon
  final String? ProjeAd;
  final String? PlasiyerAd;
  final String? DovizBirim;
  final String? BankahesapAd;
  final String? BankaAd;
  final String? BankasubeAd;

  CekverilenhareketDto({
    this.Id,
    this.Firmaid,
    this.Projeid,
    this.Plasiyerid,
    this.Dovizid,
    this.Bankahesapid,
    this.Cekverilenid,
    this.Belgeseri,
    this.Belgeyil,
    this.Belgeno,
    this.Belgeserino,
    this.Vadetarihi,
    this.Odemetarihi,
    this.Kur,
    this.Doviztarih,
    this.Doviztutar,
    this.Tutar,
    this.Ceknumarasi,
    this.Aciklama,
    this.Evrakdurum,
    this.Evrakyeri,
    this.ProjeAd,
    this.PlasiyerAd,
    this.DovizBirim,
    this.BankahesapAd,
    this.BankaAd,
    this.BankasubeAd,
  });

  factory CekverilenhareketDto.fromJson(Map<String, dynamic> json) {
    final proje       = json['Proje']       as Map<String, dynamic>?;
    final plasiyer     = json['Plasiyer']    as Map<String, dynamic>?;
    final doviz        = json['Doviz']       as Map<String, dynamic>?;
    final bankahesap   = json['Bankahesap']  as Map<String, dynamic>?;
    final banka        = bankahesap?['Banka']      as Map<String, dynamic>?;
    final bankasube    = bankahesap?['Bankasube']  as Map<String, dynamic>?;

    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    return CekverilenhareketDto(
      Id:            json['Id']?.toString(),
      Firmaid:       json['Firmaid'],
      Projeid:       json['Projeid'],
      Plasiyerid:    json['Plasiyerid'],
      Dovizid:       json['Dovizid'],
      Bankahesapid:  json['Bankahesapid'],
      Cekverilenid:  json['Cekverilenid']?.toString(),
      Belgeseri:     json['Belgeseri'],
      Belgeyil:      json['Belgeyil'],
      Belgeno:       json['Belgeno'],
      Belgeserino:   json['Belgeserino'],
      Vadetarihi:    _dt(json['Vadetarihi']),
      Odemetarihi:   _dt(json['Odemetarihi']),
      Kur:           _d(json['Kur']),
      Doviztarih:    _dt(json['Doviztarih']),
      Doviztutar:    _d(json['Doviztutar']),
      Tutar:         _d(json['Tutar']),
      Ceknumarasi:   json['Ceknumarasi'],
      Aciklama:      json['Aciklama'],
      Evrakdurum:    json['Evrakdurum'],
      Evrakyeri:     json['Evrakyeri'],
      ProjeAd:       proje?['Ad'] ?? proje?['ad'],
      PlasiyerAd:    plasiyer?['Adsoyad'],
      DovizBirim:    doviz?['Birim'],
      BankahesapAd:  bankahesap?['Ad'],
      BankaAd:       banka?['Ad'],
      BankasubeAd:   bankasube?['Ad'],
    );
  }
}
