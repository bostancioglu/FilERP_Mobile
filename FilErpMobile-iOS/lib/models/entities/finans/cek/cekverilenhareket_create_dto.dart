class CekverilenhareketCreateDto {
  int?    projeid;
  int?    plasiyerid;
  int?    dovizid;
  int?    bankahesapid;
  String? cekverilenid; // Guid — mevcut bordroya tekil hareket eklerken dolu

  String? belgeseri;
  int?    belgeyil;
  String? belgeno;
  String? belgeserino;

  DateTime? vadetarihi;
  DateTime? odemetarihi;

  double?   kur;
  DateTime? doviztarih;
  double?   doviztutar;
  double?   tutar;

  String? ceknumarasi;
  String? aciklama;

  CekverilenhareketCreateDto();

  Map<String, dynamic> toJson() => {
        if (projeid != null)         'Projeid':       projeid,
        if (plasiyerid != null)      'Plasiyerid':    plasiyerid,
        if (dovizid != null)         'Dovizid':       dovizid,
        if (bankahesapid != null)    'Bankahesapid':  bankahesapid,
        if (cekverilenid != null)    'Cekverilenid':  cekverilenid,
        if (belgeseri != null)       'Belgeseri':     belgeseri,
        if (belgeyil != null)        'Belgeyil':      belgeyil,
        if (belgeno != null)         'Belgeno':       belgeno,
        if (belgeserino != null)     'Belgeserino':   belgeserino,
        if (vadetarihi != null)      'Vadetarihi':    vadetarihi!.toIso8601String(),
        if (odemetarihi != null)     'Odemetarihi':   odemetarihi!.toIso8601String(),
        if (kur != null)             'Kur':           kur,
        if (doviztarih != null)      'Doviztarih':    doviztarih!.toIso8601String(),
        if (doviztutar != null)      'Doviztutar':    doviztutar,
        if (tutar != null)           'Tutar':         tutar,
        if (ceknumarasi != null)     'Ceknumarasi':   ceknumarasi,
        if (aciklama != null && aciklama!.isNotEmpty) 'Aciklama': aciklama,
      };
}
