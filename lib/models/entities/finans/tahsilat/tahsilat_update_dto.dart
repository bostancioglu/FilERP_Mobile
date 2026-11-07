class TahsilatUpdateDto {
  String? id; // Guid
  int? cariid;
  int? dovizid;
  int? projeid;
  int? plasiyerid;
  int? bankahesapid;
  int? kasaid;
  int? kredikartisozlesmeid;

  DateTime? tarih;
  int?      tip;
  double?   tahsilattutari;
  double?   kur;
  DateTime? doviztarih;
  double?   doviztutar;
  int?      taksitsayisi;
  String?   aciklama;

  TahsilatUpdateDto();

  Map<String, dynamic> toJson() => {
        if (id != null)                   'Id':                   id,
        if (cariid != null)               'Cariid':               cariid,
        if (dovizid != null)              'Dovizid':              dovizid,
        if (projeid != null)              'Projeid':              projeid,
        if (plasiyerid != null)           'Plasiyerid':           plasiyerid,
        if (bankahesapid != null)         'Bankahesapid':         bankahesapid,
        if (kasaid != null)               'Kasaid':               kasaid,
        if (kredikartisozlesmeid != null) 'Kredikartisozlesmeid': kredikartisozlesmeid,
        if (tarih != null)                'Tarih':                tarih!.toIso8601String(),
        if (tip != null)                  'Tip':                  tip,
        if (tahsilattutari != null)       'Tahsilattutari':       tahsilattutari,
        if (kur != null)                  'Kur':                  kur,
        if (doviztarih != null)           'Doviztarih':           doviztarih!.toIso8601String(),
        if (doviztutar != null)           'Doviztutar':           doviztutar,
        if (taksitsayisi != null)         'Taksitsayisi':         taksitsayisi,
        if (aciklama != null && aciklama!.isNotEmpty) 'Aciklama': aciklama,
      };
}
