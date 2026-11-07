import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import '../cari/cari_dto.dart';
import '../cari/cariadres_dto.dart';
import '../plasiyer/plasiyer_dto.dart';
import '../helper/doviz_dto.dart';
import '../proje/proje_dto.dart';
import '../cari/referans_dto.dart';
import '../dosya/dosyabelge_dto.dart';
import 'siparishareket_dto.dart';

class SiparisDto {
  String? id;

  // Referans alanlar
  int? firmaid;
  int? sirketid;
  int? subeid;
  int? cariid;
  int? cariadresid;
  int? plasiyerid;
  int? dovizid;
  int? projeid;
  int? referansid;

  // Temel alanlar
  String? belgeserino;
  int? belgeyil;
  String? belgeseri;
  String? belgeno;
  String? referansbelgeno;
  DateTime? tarih;
  DateTime? fiilitarih;
  DateTime? teslimtarihi;
  DateTime? tahsilattarihi;
  DateTime? vadetarihi;
  int? vadegunu;
  int? belgetipi;
  int? ithalatihracattipi;
  int? odemesekli;
  bool? kdvdahil;
  DateTime? doviztarih;
  double? kur;
  int? belgeturu;
  double? geneliskontooran;
  double? geneliskontotutar;
  double? dovizgeneliskontotutar;
  String? aciklama;
  bool? onayagonderildi;
  int? onaydurum;
  int? oncelik;
  int? teslimattipi;
  bool? onaylanabilir;
  bool? onaykaldirilabilir;
  bool? baglanti;
  int? baglantituru;
  int? localerpentegrasyondurum;
  int? localerpdenkilitli;
  int? belgedurum;
  int? kayityeri;
  bool? optiksiparisi;

  // Hesaplanan alanlar
  double? bruttutar;
  double? malfazlasitutar;
  double? iskontotutar;
  double? aratoplam;
  double? sonaratoplam;
  double? kdv1matrah;
  double? kdv2matrah;
  double? kdv3matrah;
  double? kdv4matrah;
  double? kdv1tutar;
  double? kdv2tutar;
  double? kdv3tutar;
  double? kdv4tutar;
  double? netaratoplam;
  double? geneltoplam;
  double? tevkifattutar;
  double? songeneltoplam;

  // KDV listeleri
  List<double>? kdvoranlist;
  List<double>? kdvmatrahlist;
  List<double>? kdvtutarList;

  // Entity dışı
  String? baglantidurum;

  // Dart'ta ekstra (hesaplama için)
  double? kdvtoplam;
  double? doviztoplam;

  // Navigation
  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;
  CariDto? cari;
  CariadresDto? cariadres;
  PlasiyerDto? plasiyer;
  DovizDto? doviz;
  ProjeDto? proje;
  ReferansDto? referans;
  List<SiparishareketDto> siparishareket = [];
  List<DosyabelgeDto>? belge;

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
  SiparisDto();

  SiparisDto.fromJson(Map<String, dynamic> json) {
    aciklama1 = json["Aciklama1"];
    aciklama2 = json["Aciklama2"];
    aciklama3 = json["Aciklama3"];
    aciklama4 = json["Aciklama4"];
    aciklama5 = json["Aciklama5"];
    aciklama6 = json["Aciklama6"];
    aciklama7 = json["Aciklama7"];
    aciklama8 = json["Aciklama8"];
    aciklama9 = json["Aciklama9"];
    aciklama10 = json["Aciklama10"];
    aciklama11 = json["Aciklama11"];
    aciklama12 = json["Aciklama12"];
    aciklama13 = json["Aciklama13"];
    aciklama14 = json["Aciklama14"];
    aciklama15 = json["Aciklama15"];
    aciklama16 = json["Aciklama16"];
    aciklama17 = json["Aciklama17"];
    aciklama18 = json["Aciklama18"];
    aciklama19 = json["Aciklama19"];
    aciklama20 = json["Aciklama20"];
    id = json["Id"]?.toString();

    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    subeid = json["Subeid"];
    cariid = json["Cariid"];
    cariadresid = json["Cariadresid"];
    plasiyerid = json["Plasiyerid"];
    dovizid = json["Dovizid"];
    projeid = json["Projeid"];
    referansid = json["Referansid"];

    belgeserino = json["Belgeserino"];
    belgeyil = json["Belgeyil"];
    belgeseri = json["Belgeseri"];
    belgeno = json["Belgeno"];
    referansbelgeno = json["Referansbelgeno"];

    tarih = json["Tarih"] != null ? DateTime.parse(json["Tarih"]) : null;
    fiilitarih =
        json["Fiilitarih"] != null ? DateTime.parse(json["Fiilitarih"]) : null;
    teslimtarihi = json["Teslimtarihi"] != null
        ? DateTime.parse(json["Teslimtarihi"])
        : null;
    tahsilattarihi = json["Tahsilattarihi"] != null
        ? DateTime.parse(json["Tahsilattarihi"])
        : null;
    vadetarihi =
        json["Vadetarihi"] != null ? DateTime.parse(json["Vadetarihi"]) : null;

    vadegunu = json["Vadegunu"];
    belgetipi = json["Belgetipi"];
    ithalatihracattipi = json["Ithalatihracattipi"];
    odemesekli = json["Odemesekli"];
    kdvdahil = json["Kdvdahil"];
    doviztarih =
        json["Doviztarih"] != null ? DateTime.parse(json["Doviztarih"]) : null;
    kur = (json["Kur"] as num?)?.toDouble();
    belgeturu = json["Belgeturu"];

    geneliskontooran = (json["Geneliskontooran"] as num?)?.toDouble();
    geneliskontotutar = (json["Geneliskontotutar"] as num?)?.toDouble();
    dovizgeneliskontotutar =
        (json["Dovizgeneliskontotutar"] as num?)?.toDouble();
    aciklama = json["Aciklama"];

    onayagonderildi = json["Onayagonderildi"];
    onaydurum = json["Onaydurum"];
    oncelik = json["Oncelik"];
    teslimattipi = json["Teslimattipi"];
    onaylanabilir = json["Onaylanabilir"];
    onaykaldirilabilir = json["Onaykaldirilabilir"];
    baglanti = json["Baglanti"];
    baglantituru = json["Baglantituru"];

    localerpentegrasyondurum = json["Localerpentegrasyondurum"];
    localerpdenkilitli = json["Localerpdenkilitli"];
    belgedurum = json["Belgedurum"];
    kayityeri = json["Kayityeri"];
    optiksiparisi = json["Optiksiparisi"];

    bruttutar = (json["Bruttutar"] as num?)?.toDouble();
    malfazlasitutar = (json["Malfazlasitutar"] as num?)?.toDouble();
    iskontotutar = (json["Iskontotutar"] as num?)?.toDouble();
    aratoplam = (json["Aratoplam"] as num?)?.toDouble();
    sonaratoplam = (json["Sonaratoplam"] as num?)?.toDouble();
    kdv1matrah = (json["Kdv1matrah"] as num?)?.toDouble();
    kdv2matrah = (json["Kdv2matrah"] as num?)?.toDouble();
    kdv3matrah = (json["Kdv3matrah"] as num?)?.toDouble();
    kdv4matrah = (json["Kdv4matrah"] as num?)?.toDouble();
    kdv1tutar = (json["Kdv1tutar"] as num?)?.toDouble();
    kdv2tutar = (json["Kdv2tutar"] as num?)?.toDouble();
    kdv3tutar = (json["Kdv3tutar"] as num?)?.toDouble();
    kdv4tutar = (json["Kdv4tutar"] as num?)?.toDouble();
    netaratoplam = (json["Netaratoplam"] as num?)?.toDouble();
    geneltoplam = (json["Geneltoplam"] as num?)?.toDouble();
    tevkifattutar = (json["Tevkifattutar"] as num?)?.toDouble();
    songeneltoplam = (json["Songeneltoplam"] as num?)?.toDouble();

    kdvtoplam = (json["Kdvtoplam"] as num?)?.toDouble();
    doviztoplam = (json["Doviztoplam"] as num?)?.toDouble();

    kdvoranlist = (json["Kdvoranlist"] as List?)
        ?.map((e) => (e as num).toDouble())
        .toList();
    kdvmatrahlist = (json["Kdvmatrahlist"] as List?)
        ?.map((e) => (e as num).toDouble())
        .toList();
    kdvtutarList = (json["KdvtutarList"] as List?)
        ?.map((e) => (e as num).toDouble())
        .toList();

    baglantidurum = json["Baglantidurum"];

    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket = json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    sube = json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null;
    cari = json["Cari"] != null ? CariDto.fromJson(json["Cari"]) : null;
    cariadres = json["Cariadres"] != null
        ? CariadresDto.fromJson(json["Cariadres"])
        : null;
    plasiyer = json["Plasiyer"] != null
        ? PlasiyerDto.fromJson(json["Plasiyer"])
        : null;
    doviz = json["Doviz"] != null ? DovizDto.fromJson(json["Doviz"]) : null;
    proje = json["Proje"] != null ? ProjeDto.fromJson(json["Proje"]) : null;
    referans = json["Referans"] != null
        ? ReferansDto.fromJson(json["Referans"])
        : null;

    siparishareket = (json["Siparishareket"] as List?)
            ?.where((e) => e != null)
            .map((e) => SiparishareketDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    belge = (json["Belge"] as List?)
        ?.where((e) => e != null)
        .map((e) => DosyabelgeDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  List<String?> get extraNotes => [
        aciklama1,
        aciklama2,
        aciklama3,
        aciklama4,
        aciklama5,
        aciklama6,
        aciklama7,
        aciklama8,
        aciklama9,
        aciklama10,
        aciklama11,
        aciklama12,
        aciklama13,
        aciklama14,
        aciklama15,
        aciklama16,
        aciklama17,
        aciklama18,
        aciklama19,
        aciklama20
      ];
  set extraNotes(List<String?> values) {
    aciklama1 = values.length >= 1 ? values[0] : null;
    aciklama2 = values.length >= 2 ? values[1] : null;
    aciklama3 = values.length >= 3 ? values[2] : null;
    aciklama4 = values.length >= 4 ? values[3] : null;
    aciklama5 = values.length >= 5 ? values[4] : null;
    aciklama6 = values.length >= 6 ? values[5] : null;
    aciklama7 = values.length >= 7 ? values[6] : null;
    aciklama8 = values.length >= 8 ? values[7] : null;
    aciklama9 = values.length >= 9 ? values[8] : null;
    aciklama10 = values.length >= 10 ? values[9] : null;
    aciklama11 = values.length >= 11 ? values[10] : null;
    aciklama12 = values.length >= 12 ? values[11] : null;
    aciklama13 = values.length >= 13 ? values[12] : null;
    aciklama14 = values.length >= 14 ? values[13] : null;
    aciklama15 = values.length >= 15 ? values[14] : null;
    aciklama16 = values.length >= 16 ? values[15] : null;
    aciklama17 = values.length >= 17 ? values[16] : null;
    aciklama18 = values.length >= 18 ? values[17] : null;
    aciklama19 = values.length >= 19 ? values[18] : null;
    aciklama20 = values.length >= 20 ? values[19] : null;
  }

  Map<String, dynamic> get extraNotesJson => {
        for (var i = 0; i < extraNotes.length; i++)
          'aciklama${i + 1}': extraNotes[i]
      };
}
