import 'fatura_hareket_create_dto.dart';

class FaturaCreateDto {
  int? cariid;
  int? cariadresid;
  int? plasiyerid;
  int? dovizid;
  int? projeid;
  int? subeid;
  int? referansid;

  String? belgeserino;
  int? belgeyil;
  String? belgeseri;
  String? belgeno;
  String? gibbelgeno;

  DateTime? tarih;
  DateTime? fiilitarih;
  DateTime? teslimtarihi;
  DateTime? tahsilattarihi;
  DateTime? vadetarihi;
  int? vadegunu;

  int? belgetipi;
  int? ithalatihracattipi;
  bool? bformu;
  int? odemesekli;
  bool? kdvdahil;
  DateTime? doviztarih;
  double? kur;
  int? belgeturu;
  int? kayityeri;

  double? geneliskontooran;
  double? geneliskontotutar;
  double? dovizgeneliskontotutar;

  double? bruttutar;
  double? iskontotutar;
  double? malfazlasitutar;
  double? aratoplam;
  double? aratoplam2;

  double? kdv1matrah;
  double? kdv2matrah;
  double? kdv3matrah;
  double? kdv4matrah;

  double? kdv1tutar;
  double? kdv2tutar;
  double? kdv3tutar;
  double? kdv4tutar;

  double? kdvaratoplam;
  double? tevkifatmatrah;
  double? tevkifattutar;
  double? kdvtoplam;
  double? geneltoplam;
  double? doviztoplam;

  int? ebelgetip;
  String? aciklama;

  int? odemekodu;
  String? odemenotu;

  String? aciklama1;
  String? aciklama2;
  String? aciklama3;
  String? aciklama4;
  String? aciklama5;
  String? aciklama6;
  String? aciklama7;
  String? aciklama8;
  String? aciklama9;
  String? aciklama10;
  String? aciklama11;
  String? aciklama12;
  String? aciklama13;
  String? aciklama14;
  String? aciklama15;
  String? aciklama16;
  String? aciklama17;
  String? aciklama18;
  String? aciklama19;
  String? aciklama20;

  List<FaturaHareketCreateDto> faturahareket;

  FaturaCreateDto({List<FaturaHareketCreateDto>? faturahareket})
      : faturahareket = faturahareket ?? [];

  /// Mevcut faturayı düzenleme için forma yükler
  static FaturaCreateDto fromFaturaDto(dynamic dto) {
    final f = FaturaCreateDto();
    f.cariid            = dto.cariid;
    f.cariadresid       = dto.cariadresid;
    f.plasiyerid        = dto.plasiyerid;
    f.dovizid           = dto.dovizid;
    f.projeid           = dto.projeid;
    f.subeid            = dto.subeid;
    f.referansid        = dto.referansid;
    f.belgeyil          = dto.belgeyil;
    f.belgeseri         = dto.belgeseri;
    f.belgeno           = dto.belgeno;
    f.gibbelgeno        = dto.gibbelgeno;
    f.tarih             = dto.tarih;
    f.fiilitarih        = dto.fiilitarih;
    f.teslimtarihi      = dto.teslimtarihi;
    f.tahsilattarihi    = dto.tahsilattarihi;
    f.vadetarihi        = dto.vadetarihi;
    f.vadegunu          = dto.vadegunu;
    f.belgetipi         = dto.belgetipi;
    f.ithalatihracattipi = dto.ithalatihracattipi;
    f.odemesekli        = dto.odemesekli;
    f.kdvdahil          = dto.kdvdahil;
    f.doviztarih        = dto.doviztarih;
    f.kur               = dto.kur;
    f.belgeturu         = dto.belgeturu;
    f.geneliskontooran  = dto.geneliskontooran;
    f.geneliskontotutar = dto.geneliskontotutar;
    f.dovizgeneliskontotutar = dto.dovizgeneliskontotutar;
    f.bruttutar         = dto.bruttutar;
    f.iskontotutar      = dto.iskontotutar;
    f.malfazlasitutar   = dto.malfazlasitutar;
    f.aratoplam         = dto.aratoplam;
    f.kdvtoplam         = dto.kdvtoplam;
    f.geneltoplam       = dto.geneltoplam;
    f.aciklama          = dto.aciklama;
    f.kayityeri         = dto.kayityeri;
    return f;
  }

  Map<String, dynamic> toJson() => {
        "cariid": cariid,
        "cariadresid": cariadresid,
        "plasiyerid": plasiyerid,
        "dovizid": dovizid,
        "projeid": projeid,
        "subeid": subeid,
        "referansid": referansid,
        "belgeserino": belgeserino,
        "belgeyil": belgeyil,
        "belgeseri": belgeseri,
        "belgeno": belgeno,
        "gibbelgeno": gibbelgeno,
        "tarih": tarih?.toIso8601String(),
        "fiilitarih": fiilitarih?.toIso8601String(),
        "teslimtarihi": teslimtarihi?.toIso8601String(),
        "tahsilattarihi": tahsilattarihi?.toIso8601String(),
        "vadetarihi": vadetarihi?.toIso8601String(),
        "vadegunu": vadegunu,
        "belgetipi": belgetipi,
        "ithalatihracattipi": ithalatihracattipi,
        "bformu": bformu,
        "odemesekli": odemesekli,
        "kdvdahil": kdvdahil,
        "doviztarih": doviztarih?.toIso8601String(),
        "kur": kur,
        "belgeturu": belgeturu,
        "geneliskontooran": geneliskontooran,
        "geneliskontotutar": geneliskontotutar,
        "dovizgeneliskontotutar": dovizgeneliskontotutar,
        "bruttutar": bruttutar,
        "iskontotutar": iskontotutar,
        "malfazlasitutar": malfazlasitutar,
        "aratoplam": aratoplam,
        "aratoplam2": aratoplam2,
        "kdv1matrah": kdv1matrah,
        "kdv2matrah": kdv2matrah,
        "kdv3matrah": kdv3matrah,
        "kdv4matrah": kdv4matrah,
        "kdv1tutar": kdv1tutar,
        "kdv2tutar": kdv2tutar,
        "kdv3tutar": kdv3tutar,
        "kdv4tutar": kdv4tutar,
        "kdvaratoplam": kdvaratoplam,
        "tevkifatmatrah": tevkifatmatrah,
        "tevkifattutar": tevkifattutar,
        "kdvtoplam": kdvtoplam,
        "geneltoplam": geneltoplam,
        "doviztoplam": doviztoplam,
        "ebelgetip": ebelgetip,
        "aciklama": aciklama,
        "odemekodu": odemekodu,
        "odemenotu": odemenotu,
        "aciklama1": aciklama1,
        "aciklama2": aciklama2,
        "aciklama3": aciklama3,
        "aciklama4": aciklama4,
        "aciklama5": aciklama5,
        "aciklama6": aciklama6,
        "aciklama7": aciklama7,
        "aciklama8": aciklama8,
        "aciklama9": aciklama9,
        "aciklama10": aciklama10,
        "aciklama11": aciklama11,
        "aciklama12": aciklama12,
        "aciklama13": aciklama13,
        "aciklama14": aciklama14,
        "aciklama15": aciklama15,
        "aciklama16": aciklama16,
        "aciklama17": aciklama17,
        "aciklama18": aciklama18,
        "aciklama19": aciklama19,
        "aciklama20": aciklama20,
        "kayityeri" : 2,
        "faturahareket":
            faturahareket.map((e) => e.toJson()).toList(),
      };
}