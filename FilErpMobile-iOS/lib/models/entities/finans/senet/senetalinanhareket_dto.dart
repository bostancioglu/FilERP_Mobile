class SenetalinanhareketDto {
  final String? Id;           // Guid
  final int?    Firmaid;
  final int?    Projeid;
  final int?    Plasiyerid;
  final int?    Dovizid;
  final String? Senetalinanid;  // Guid — üst bordro

  final String? Belgeseri;
  final int?    Belgeyil;
  final String? Belgeno;
  final String? Belgeserino;

  final bool?   Asilciro;
  final String? Cirocariad;
  final String? Cirocarivergino;

  final DateTime? Vadetarihi;
  final DateTime? Odemetarihi;

  final double?   Kur;
  final DateTime? Doviztarih;
  final double?   Doviztutar;
  final double?   Tutar;

  final String? Kesideyeri;
  final String? Senetnumarasi;
  final String? Aciklama;

  final int?    Evrakdurum;   // EvrakDurumCouples
  final int?    Evrakyeri;    // EvrakYeriCouples
  final double? Kismitahsiltutar;

  // Navigasyon
  final String? ProjeAd;
  final String? PlasiyerAd;
  final String? DovizBirim;
  final String? CariAd; // Senetalinan.Cari.Ad (bordro cari — tahsil/protesto gibi carisiz akışlarda gösterim için)

  SenetalinanhareketDto({
    this.Id,
    this.Firmaid,
    this.Projeid,
    this.Plasiyerid,
    this.Dovizid,
    this.Senetalinanid,
    this.Belgeseri,
    this.Belgeyil,
    this.Belgeno,
    this.Belgeserino,
    this.Asilciro,
    this.Cirocariad,
    this.Cirocarivergino,
    this.Vadetarihi,
    this.Odemetarihi,
    this.Kur,
    this.Doviztarih,
    this.Doviztutar,
    this.Tutar,
    this.Kesideyeri,
    this.Senetnumarasi,
    this.Aciklama,
    this.Evrakdurum,
    this.Evrakyeri,
    this.Kismitahsiltutar,
    this.ProjeAd,
    this.PlasiyerAd,
    this.DovizBirim,
    this.CariAd,
  });

  factory SenetalinanhareketDto.fromJson(Map<String, dynamic> json) {
    final proje     = json['Proje']     as Map<String, dynamic>?;
    final plasiyer  = json['Plasiyer']  as Map<String, dynamic>?;
    final doviz     = json['Doviz']     as Map<String, dynamic>?;
    final senetalinan = json['Senetalinan'] as Map<String, dynamic>?;
    final cari      = senetalinan?['Cari'] as Map<String, dynamic>?;

    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    return SenetalinanhareketDto(
      Id:               json['Id']?.toString(),
      Firmaid:          json['Firmaid'],
      Projeid:          json['Projeid'],
      Plasiyerid:       json['Plasiyerid'],
      Dovizid:          json['Dovizid'],
      Senetalinanid:      json['Senetalinanid']?.toString(),
      Belgeseri:        json['Belgeseri'],
      Belgeyil:         json['Belgeyil'],
      Belgeno:          json['Belgeno'],
      Belgeserino:      json['Belgeserino'],
      Asilciro:         json['Asilciro'],
      Cirocariad:       json['Cirocariad'],
      Cirocarivergino:  json['Cirocarivergino'],
      Vadetarihi:       _dt(json['Vadetarihi']),
      Odemetarihi:      _dt(json['Odemetarihi']),
      Kur:              _d(json['Kur']),
      Doviztarih:       _dt(json['Doviztarih']),
      Doviztutar:       _d(json['Doviztutar']),
      Tutar:            _d(json['Tutar']),
      Kesideyeri:       json['Kesideyeri'],
      Senetnumarasi:      json['Senetnumarasi'],
      Aciklama:         json['Aciklama'],
      Evrakdurum:       json['Evrakdurum'],
      Evrakyeri:        json['Evrakyeri'],
      Kismitahsiltutar: _d(json['Kismitahsiltutar']),
      ProjeAd:          proje?['Ad'] ?? proje?['ad'],
      PlasiyerAd:       plasiyer?['Adsoyad'],
      DovizBirim:       doviz?['Birim'],
      CariAd:           cari?['Ad'],
    );
  }
}
