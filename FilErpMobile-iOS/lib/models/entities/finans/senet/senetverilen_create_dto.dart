import 'senetverilenhareket_create_dto.dart';

class SenetverilenCreateDto {
  int? cariid;
  int? projeid;
  int? plasiyerid;

  String? belgeseri;
  int?    belgeyil;
  String? belgeno;
  String? belgeserino;
  int?    belgeturu;

  DateTime? tarih;
  String?   aciklama;
  String?   makbuzno;
  bool?     devir;

  List<SenetverilenhareketCreateDto>? senetverilenhareket;

  SenetverilenCreateDto();

  Map<String, dynamic> toJson() => {
        if (cariid != null)      'Cariid':      cariid,
        if (projeid != null)     'Projeid':     projeid,
        if (plasiyerid != null)  'Plasiyerid':  plasiyerid,
        if (belgeseri != null)   'Belgeseri':   belgeseri,
        if (belgeyil != null)    'Belgeyil':    belgeyil,
        if (belgeno != null)     'Belgeno':     belgeno,
        if (belgeserino != null) 'Belgeserino': belgeserino,
        if (belgeturu != null)   'Belgeturu':   belgeturu,
        if (tarih != null)       'Tarih':       tarih!.toIso8601String(),
        if (aciklama != null && aciklama!.isNotEmpty) 'Aciklama': aciklama,
        if (makbuzno != null && makbuzno!.isNotEmpty) 'Makbuzno': makbuzno,
        'Devir':       devir ?? false,
        if (senetverilenhareket != null)
          'Senetverilenhareket': senetverilenhareket!.map((e) => e.toJson()).toList(),
      };
}
