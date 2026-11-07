class TahsilatCreateDto {
  int? cariid;
  int? dovizid;
  int? projeid;
  int? plasiyerid;
  int? bankahesapid;
  int? kasaid;
  int? kredikartisozlesmeid;

  String? belgeseri;
  int?    belgeyil;
  String? belgeno;
  String? belgeserino;

  DateTime? tarih;
  int?      tip; // TahsilattipiCouples: 1=Nakit, 2=Banka, 3=Kredi Kartı
  double?   tahsilattutari;
  double?   kur;
  DateTime? doviztarih;
  double?   doviztutar;
  int?      taksitsayisi;
  String?   aciklama;

  // Bir sipariş/fatura üzerinden açılan tahsilatlarda kaynak belgeyi işaretler.
  String? islembelgeid;  // Guid — kaynak belgenin id'si (ör. Sipariş/Fatura)
  int?    islembelgeturu; // kaynak belgenin BelgeTuru değeri

  TahsilatCreateDto();

  Map<String, dynamic> toJson() => {
        if (cariid != null)               'Cariid':               cariid,
        if (dovizid != null)              'Dovizid':              dovizid,
        if (projeid != null)              'Projeid':              projeid,
        if (plasiyerid != null)           'Plasiyerid':           plasiyerid,
        if (bankahesapid != null)         'Bankahesapid':         bankahesapid,
        if (kasaid != null)               'Kasaid':               kasaid,
        if (kredikartisozlesmeid != null) 'Kredikartisozlesmeid': kredikartisozlesmeid,
        if (belgeseri != null)            'Belgeseri':            belgeseri,
        if (belgeyil != null)             'Belgeyil':             belgeyil,
        if (belgeno != null)              'Belgeno':              belgeno,
        if (belgeserino != null)          'Belgeserino':          belgeserino,
        if (tarih != null)                'Tarih':                tarih!.toIso8601String(),
        if (tip != null)                  'Tip':                  tip,
        if (tahsilattutari != null)       'Tahsilattutari':       tahsilattutari,
        if (kur != null)                  'Kur':                  kur,
        if (doviztarih != null)           'Doviztarih':           doviztarih!.toIso8601String(),
        if (doviztutar != null)           'Doviztutar':           doviztutar,
        if (taksitsayisi != null)         'Taksitsayisi':         taksitsayisi,
        if (islembelgeid != null)         'Islembelgeid':         islembelgeid,
        if (islembelgeturu != null)       'Islembelgeturu':       islembelgeturu,
        if (aciklama != null && aciklama!.isNotEmpty) 'Aciklama': aciklama,
      };
}
