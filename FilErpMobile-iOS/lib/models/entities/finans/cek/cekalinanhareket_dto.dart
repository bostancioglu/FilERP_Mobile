class CekalinanhareketDto {
  final String? Id;           // Guid
  final int?    Firmaid;
  final int?    Projeid;
  final int?    Plasiyerid;
  final int?    Dovizid;
  final String? Cekalinanid;  // Guid — üst bordro

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

  final String? Bankaadi;
  final String? Bankasubeadi;
  final String? Hesapno;
  final String? Iban;
  final String? Ceknumarasi;
  final String? Aciklama;

  final int?    Evrakdurum;   // EvrakDurumCouples
  final int?    Evrakyeri;    // EvrakYeriCouples
  final double? Kismitahsiltutar;

  // Navigasyon
  final String? ProjeAd;
  final String? PlasiyerAd;
  final String? DovizBirim;
  final String? CariAd; // Cekalinan.Cari.Ad (bordro cari — tahsil/protesto gibi carisiz akışlarda gösterim için)

  CekalinanhareketDto({
    this.Id,
    this.Firmaid,
    this.Projeid,
    this.Plasiyerid,
    this.Dovizid,
    this.Cekalinanid,
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
    this.Bankaadi,
    this.Bankasubeadi,
    this.Hesapno,
    this.Iban,
    this.Ceknumarasi,
    this.Aciklama,
    this.Evrakdurum,
    this.Evrakyeri,
    this.Kismitahsiltutar,
    this.ProjeAd,
    this.PlasiyerAd,
    this.DovizBirim,
    this.CariAd,
  });

  factory CekalinanhareketDto.fromJson(Map<String, dynamic> json) {
    final proje     = json['Proje']     as Map<String, dynamic>?;
    final plasiyer  = json['Plasiyer']  as Map<String, dynamic>?;
    final doviz     = json['Doviz']     as Map<String, dynamic>?;
    final cekalinan = json['Cekalinan'] as Map<String, dynamic>?;
    final cari      = cekalinan?['Cari'] as Map<String, dynamic>?;

    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    return CekalinanhareketDto(
      Id:               json['Id']?.toString(),
      Firmaid:          json['Firmaid'],
      Projeid:          json['Projeid'],
      Plasiyerid:       json['Plasiyerid'],
      Dovizid:          json['Dovizid'],
      Cekalinanid:      json['Cekalinanid']?.toString(),
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
      Bankaadi:         json['Bankaadi'],
      Bankasubeadi:     json['Bankasubeadi'],
      Hesapno:          json['Hesapno'],
      Iban:             json['Iban'],
      Ceknumarasi:      json['Ceknumarasi'],
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
