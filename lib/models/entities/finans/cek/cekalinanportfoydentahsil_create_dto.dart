class CekalinanportfoydentahsilCreateDto {
  int? kasaid;
  int? bankahesapid;

  String? belgeseri;
  int?    belgeyil;
  String? belgeno;
  String? belgeserino;
  int?    belgeturu;

  DateTime? tarih;
  String?   aciklama;
  String?   makbuzno;
  int?      tahsilyeri;

  CekalinanportfoydentahsilCreateDto();

  Map<String, dynamic> toJson() => {
        if (kasaid != null)       'Kasaid':       kasaid,
        if (bankahesapid != null) 'Bankahesapid': bankahesapid,
        if (belgeseri != null)    'Belgeseri':    belgeseri,
        if (belgeyil != null)     'Belgeyil':     belgeyil,
        if (belgeno != null)      'Belgeno':      belgeno,
        if (belgeserino != null)  'Belgeserino':  belgeserino,
        if (belgeturu != null)    'Belgeturu':    belgeturu,
        if (tarih != null)        'Tarih':        tarih!.toIso8601String(),
        if (aciklama != null && aciklama!.isNotEmpty) 'Aciklama': aciklama,
        if (makbuzno != null && makbuzno!.isNotEmpty) 'Makbuzno': makbuzno,
        if (tahsilyeri != null)   'Tahsilyeri':   tahsilyeri,
      };
}
