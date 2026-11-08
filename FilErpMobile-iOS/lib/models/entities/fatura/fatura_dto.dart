import '../cari/cari_dto.dart';
import '../helper/doviz_dto.dart';
import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import '../plasiyer/plasiyer_dto.dart';
import '../proje/proje_dto.dart';
import '../cari/referans_dto.dart';
import 'faturahareket_dto.dart';
import '../cari/cariadres_dto.dart';

class FaturaDto {
  String? id;

  int? firmaid;
  int? sirketid;
  int? subeid;
  int? cariid;
  int? cariadresid;
  int? plasiyerid;
  int? dovizid;
  int? projeid;
  int? referansid;
  String? iadeedilenfaturaid;

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
  double? dovizgeneliskontotutar; // ← YENİ

  double? bruttutar;
  double? iskontotutar;
  double? malfazlasitutar;
  double? aratoplam;
  double? aratoplam2;

  List<double>? kdvoranlist;
  List<double>? kdvmatrahlist;
  List<double>? kdvtutarList;

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

  int? localerpentegrasyondurum;
  int? localerpdenkilitli;
  int? belgedurum;

  int? efaturadurum;
  String? efaturalink;

  String? ortakislemno;

  // Açıklamalar
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

  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;
  CariDto? cari;
  CariadresDto? cariadres;
  PlasiyerDto? plasiyer;
  DovizDto? doviz;
  ProjeDto? proje;
  ReferansDto? referans;
  FaturaDto? iadeedilenfatura;
  List<FaturahareketDto>? faturahareket;

  FaturaDto();

  FaturaDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"]?.toString();

    firmaid    = json["Firmaid"];
    sirketid   = json["Sirketid"];
    subeid     = json["Subeid"];
    cariid     = json["Cariid"];
    cariadresid = json["Cariadresid"];
    plasiyerid = json["Plasiyerid"];
    dovizid    = json["Dovizid"];
    projeid    = json["Projeid"];
    referansid = json["Referansid"];
    iadeedilenfaturaid = json["Iadeedilenfaturaid"]?.toString();

    belgeserino = json["Belgeserino"];
    belgeyil    = json["Belgeyil"];
    belgeseri   = json["Belgeseri"];
    belgeno     = json["Belgeno"];
    gibbelgeno  = json["Gibbelgeno"];

    tarih          = json["Tarih"]          != null ? DateTime.parse(json["Tarih"])          : null;
    fiilitarih     = json["Fiilitarih"]     != null ? DateTime.parse(json["Fiilitarih"])     : null;
    teslimtarihi   = json["Teslimtarihi"]   != null ? DateTime.parse(json["Teslimtarihi"])   : null;
    tahsilattarihi = json["Tahsilattarihi"] != null ? DateTime.parse(json["Tahsilattarihi"]) : null;
    vadetarihi     = json["Vadetarihi"]     != null ? DateTime.parse(json["Vadetarihi"])     : null;

    vadegunu           = json["Vadegunu"];
    belgetipi          = json["Belgetipi"];
    ithalatihracattipi = json["Ithalatihracattipi"];
    bformu             = json["Bformu"];
    odemesekli         = json["Odemesekli"];
    kdvdahil           = json["Kdvdahil"];
    kayityeri          = json["Kayityeri"];

    doviztarih = json["Doviztarih"] != null ? DateTime.parse(json["Doviztarih"]) : null;
    kur        = (json["Kur"] as num?)?.toDouble();
    belgeturu  = json["Belgeturu"];

    geneliskontooran       = (json["Geneliskontooran"]       as num?)?.toDouble();
    geneliskontotutar      = (json["Geneliskontotutar"]      as num?)?.toDouble();
    dovizgeneliskontotutar = (json["Dovizgeneliskontotutar"] as num?)?.toDouble();

    bruttutar       = (json["Bruttutar"]       as num?)?.toDouble();
    iskontotutar    = (json["Iskontotutar"]    as num?)?.toDouble();
    malfazlasitutar = (json["Malfazlasitutar"] as num?)?.toDouble();
    aratoplam       = (json["Aratoplam"]       as num?)?.toDouble();
    aratoplam2      = (json["Aratoplam2"]      as num?)?.toDouble();

    kdvoranlist   = (json["Kdvoranlist"]   as List?)?.map((e) => (e as num).toDouble()).toList();
    kdvmatrahlist = (json["Kdvmatrahlist"] as List?)?.map((e) => (e as num).toDouble()).toList();
    kdvtutarList  = (json["KdvtutarList"]  as List?)?.map((e) => (e as num).toDouble()).toList();

    kdvaratoplam   = (json["Kdvaratoplam"]   as num?)?.toDouble();
    tevkifatmatrah = (json["Tevkifatmatrah"] as num?)?.toDouble();
    tevkifattutar  = (json["Tevkifattutar"]  as num?)?.toDouble();
    kdvtoplam      = (json["Kdvtoplam"]      as num?)?.toDouble();
    geneltoplam    = (json["Geneltoplam"]    as num?)?.toDouble();
    doviztoplam    = (json["Doviztoplam"]    as num?)?.toDouble();

    ebelgetip = json["Ebelgetip"];
    aciklama  = json["Aciklama"];

    odemekodu  = json["Odemekodu"];
    odemenotu  = json["Odemenotu"];

    localerpentegrasyondurum = json["Localerpentegrasyondurum"];
    localerpdenkilitli       = json["Localerpdenkilitli"];
    belgedurum               = json["Belgedurum"];

    efaturadurum = json["EFaturadurum"];
    efaturalink  = json["EFaturalink"];

    ortakislemno = json["Ortakislemno"]?.toString();

    firma     = json["Firma"]     != null ? FirmaDto.fromJson(json["Firma"])         : null;
    sirket    = json["Sirket"]    != null ? SirketDto.fromJson(json["Sirket"])       : null;
    sube      = json["Sube"]      != null ? SubeDto.fromJson(json["Sube"])           : null;
    cari      = json["Cari"]      != null ? CariDto.fromJson(json["Cari"])           : null;
    cariadres = json["Cariadres"] != null ? CariadresDto.fromJson(json["Cariadres"]) : null;
    plasiyer  = json["Plasiyer"]  != null ? PlasiyerDto.fromJson(json["Plasiyer"])   : null;
    doviz     = json["Doviz"]     != null ? DovizDto.fromJson(json["Doviz"])         : null;
    proje     = json["Proje"]     != null ? ProjeDto.fromJson(json["Proje"])         : null;
    referans  = json["Referans"]  != null ? ReferansDto.fromJson(json["Referans"])   : null;

    faturahareket = (json["Faturahareket"] as List?)
        ?.where((e) => e != null).map((e) => FaturahareketDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}