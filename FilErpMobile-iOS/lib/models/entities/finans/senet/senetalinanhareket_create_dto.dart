class SenetalinanhareketCreateDto {
  int?    projeid;
  int?    plasiyerid;
  int?    dovizid;
  String? senetalinanid; // Guid — mevcut bordroya tekil hareket eklerken dolu

  String? belgeseri;
  int?    belgeyil;
  String? belgeno;
  String? belgeserino;

  bool?   asilciro;
  String? cirocariad;
  String? cirocarivergino;

  DateTime? vadetarihi;
  DateTime? odemetarihi;

  double?   kur;
  DateTime? doviztarih;
  double?   doviztutar;
  double?   tutar;

  String? kesideyeri;
  String? senetnumarasi;
  String? aciklama;

  int?    evrakdurum;
  int?    evrakyeri;
  double? kismitahsiltutar;

  SenetalinanhareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (projeid != null)          'Projeid':          projeid,
        if (plasiyerid != null)       'Plasiyerid':       plasiyerid,
        if (dovizid != null)          'Dovizid':          dovizid,
        if (senetalinanid != null)      'Senetalinanid':      senetalinanid,
        if (belgeseri != null)        'Belgeseri':        belgeseri,
        if (belgeyil != null)         'Belgeyil':         belgeyil,
        if (belgeno != null)          'Belgeno':          belgeno,
        if (belgeserino != null)      'Belgeserino':      belgeserino,
        if (asilciro != null)         'Asilciro':         asilciro,
        if (cirocariad != null)       'Cirocariad':       cirocariad,
        if (cirocarivergino != null)  'Cirocarivergino':  cirocarivergino,
        if (vadetarihi != null)       'Vadetarihi':       vadetarihi!.toIso8601String(),
        if (odemetarihi != null)      'Odemetarihi':      odemetarihi!.toIso8601String(),
        if (kur != null)              'Kur':              kur,
        if (doviztarih != null)       'Doviztarih':       doviztarih!.toIso8601String(),
        if (doviztutar != null)       'Doviztutar':       doviztutar,
        if (tutar != null)            'Tutar':            tutar,
        'Kesideyeri':         (kesideyeri ?? '').trim(),
        if (senetnumarasi != null)      'Senetnumarasi':      senetnumarasi,
        if (aciklama != null && aciklama!.isNotEmpty) 'Aciklama': aciklama,
        if (evrakdurum != null)       'Evrakdurum':       evrakdurum,
        if (evrakyeri != null)        'Evrakyeri':        evrakyeri,
        if (kismitahsiltutar != null) 'Kismitahsiltutar': kismitahsiltutar,
      };
}
