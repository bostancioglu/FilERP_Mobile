import 'base_update_dto.dart';
import 'fatura_hareket_create_dto.dart';


class FaturaUpdateDto extends BaseUpdateDtoT<String> {
  int? cariid;
  int? cariadresid;
  int? plasiyerid;
  int? dovizid;
  int? projeid;
  int? subeid;
  int? referansid;

  // Belge numarası alanları — API tarafında zorunlu
  String? belgeserino;
  String? belgeseri;
  int?    belgeyil;
  String? belgeno;
  String? gibbelgeno;
  int?    ebelgetip;

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

  double? geneliskontooran;
  double? geneliskontotutar;
  double? dovizgeneliskontotutar;

  // Tüm değerler
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

  String? aciklama;
  int? odemekodu;
  String? odemenotu;

  // Açıklama alanları
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

  /// Satırlar: Sadece update değil yeni hareket de eklenebileceği
  /// için CreateDto ile gönderilir
  List<FaturaHareketCreateDto> faturahareket;

  FaturaUpdateDto({String? id})
      : faturahareket = [],
        super(id: id);

  @override
  Map<String, dynamic> toJson() => {
        "id": id,
        "cariid": cariid,
        "cariadresid": cariadresid,
        "plasiyerid": plasiyerid,
        "dovizid": dovizid,
        "projeid": projeid,
        "subeid": subeid,
        "referansid": referansid,
        "belgeserino": belgeserino,
        "belgeseri": belgeseri,
        "belgeyil": belgeyil,
        "belgeno": belgeno,
        "gibbelgeno": gibbelgeno,
        "ebelgetip": ebelgetip,
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
        "faturahareket": faturahareket.map((h) => h.toJson()).toList(),
      };
}