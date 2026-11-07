import '../firma/firma_dto.dart';
import '../depo/depo_dto.dart';
import '../stok/stok_dto.dart';
import '../stok/stokozelliksabit_dto.dart';
import '../olcubirimi/olcubr_dto.dart';
import '../proje/proje_dto.dart';
import '../helper/istisna_dto.dart';
import '../cari/referans_dto.dart';
import '../siparis/siparishareket_dto.dart';
import 'teklif_dto.dart';
import '../talep/talephareket_dto.dart';

class TeklifhareketDto {
  int? id;

  int? firmaid;
  String? teklifid; // Guid → String
  int? depoid;
  int? stokid;
  int? stokozelliksabitid;
  int? olcubrid;
  int? olcubr2id;
  int? projeid;
  int? istisnaId;
  int? talephareketid;
  int? referansid;

  double? olcubrcarpim;
  int? belgeturu;
  String? giriscikis; // char → String
  DateTime? tarih;
  DateTime? teslimtarihi;
  double? miktar;
  double? miktar2;
  double? dovizfiyat;
  double? fiyat;
  double? malfazlasiiskonto;

  double? iskontoorani1;
  double? iskontotutari1;
  double? iskontoorani2;
  double? iskontotutari2;
  double? iskontoorani3;
  double? iskontotutari3;
  double? iskontoorani4;
  double? iskontotutari4;
  double? iskontoorani5;
  double? iskontotutari5;
  double? iskontoorani6;
  double? iskontotutari6;

  double? tutar;
  double? kdvorani;
  double? tevkifatorani;

  double? bruttutar;
  double? iskontotutar;
  double? malfazlasitutar;
  double? aratoplam;
  double? aratoplamiskontolu;
  double? kdvtutar;
  double? tevkifatmatrahi;
  double? tevkifattutar;

  String? aciklama;
  int? onaydurum;
  bool? acikkapali;
  String? kapanisnedeni;

  // Navigation
  TeklifDto? teklif;
  FirmaDto? firma;
  DepoDto? depo;
  StokDto? stok;
  StokozelliksabitDto? stokozelliksabit;
  OlcubrDto? olcubr;
  ProjeDto? proje;
  IstisnaDto? istisna;
  ReferansDto? referans;
  List<SiparishareketDto>? siparishareket;
  TalephareketDto? talephareket;

  String? stokadiaciklama;
  OlcubrDto? olcubr2;
  double? doviziskontotutari1;
  double? doviziskontotutari2;
  double? doviziskontotutari3;
  double? doviziskontotutari4;
  double? doviziskontotutari5;
  double? doviziskontotutari6;
  TeklifhareketDto();

  TeklifhareketDto.fromJson(Map<String, dynamic> json) {
    olcubr2id = json["Olcubr2id"];
    olcubr2 =
        json["Olcubr2"] == null ? null : OlcubrDto.fromJson(json["Olcubr2"]);
    stokadiaciklama = json["Stokadiaciklama"];
    doviziskontotutari1 = (json["Doviziskontotutari1"] as num?)?.toDouble();
    doviziskontotutari2 = (json["Doviziskontotutari2"] as num?)?.toDouble();
    doviziskontotutari3 = (json["Doviziskontotutari3"] as num?)?.toDouble();
    doviziskontotutari4 = (json["Doviziskontotutari4"] as num?)?.toDouble();
    doviziskontotutari5 = (json["Doviziskontotutari5"] as num?)?.toDouble();
    doviziskontotutari6 = (json["Doviziskontotutari6"] as num?)?.toDouble();
    id = json["Id"];

    firmaid = json["Firmaid"];
    teklifid = json["Teklifid"]?.toString();
    depoid = json["Depoid"];
    stokid = json["Stokid"];
    stokozelliksabitid = json["Stokozelliksabitid"];
    olcubrid = json["Olcubrid"];
    projeid = json["Projeid"];
    istisnaId = json["IstisnaId"];
    talephareketid = json["Talephareketid"];
    referansid = json["Referansid"];

    olcubrcarpim = (json["Olcubrcarpim"] as num?)?.toDouble();
    belgeturu = json["Belgeturu"];
    giriscikis = json["Giriscikis"]?.toString();
    tarih = json["Tarih"] != null ? DateTime.parse(json["Tarih"]) : null;
    teslimtarihi = json["Teslimtarihi"] != null
        ? DateTime.parse(json["Teslimtarihi"])
        : null;

    miktar = (json["Miktar"] as num?)?.toDouble();
    miktar2 = (json["Miktar2"] as num?)?.toDouble();
    dovizfiyat = (json["Dovizfiyat"] as num?)?.toDouble();
    fiyat = (json["Fiyat"] as num?)?.toDouble();
    malfazlasiiskonto = (json["Malfazlasiiskonto"] as num?)?.toDouble();

    iskontoorani1 = (json["Iskontoorani1"] as num?)?.toDouble();
    iskontotutari1 = (json["Iskontotutari1"] as num?)?.toDouble();
    iskontoorani2 = (json["Iskontoorani2"] as num?)?.toDouble();
    iskontotutari2 = (json["Iskontotutari2"] as num?)?.toDouble();
    iskontoorani3 = (json["Iskontoorani3"] as num?)?.toDouble();
    iskontotutari3 = (json["Iskontotutari3"] as num?)?.toDouble();
    iskontoorani4 = (json["Iskontoorani4"] as num?)?.toDouble();
    iskontotutari4 = (json["Iskontotutari4"] as num?)?.toDouble();
    iskontoorani5 = (json["Iskontoorani5"] as num?)?.toDouble();
    iskontotutari5 = (json["Iskontotutari5"] as num?)?.toDouble();
    iskontoorani6 = (json["Iskontoorani6"] as num?)?.toDouble();
    iskontotutari6 = (json["Iskontotutari6"] as num?)?.toDouble();

    tutar = (json["Tutar"] as num?)?.toDouble();
    kdvorani = (json["Kdvorani"] as num?)?.toDouble();
    tevkifatorani = (json["Tevkifatorani"] as num?)?.toDouble();

    bruttutar = (json["Bruttutar"] as num?)?.toDouble();
    iskontotutar = (json["Iskontotutar"] as num?)?.toDouble();
    malfazlasitutar = (json["Malfazlasitutar"] as num?)?.toDouble();
    aratoplam = (json["Aratoplam"] as num?)?.toDouble();
    aratoplamiskontolu = (json["Aratoplamiskontolu"] as num?)?.toDouble();
    kdvtutar = (json["Kdvtutar"] as num?)?.toDouble();
    tevkifatmatrahi = (json["Tevkifatmatrahi"] as num?)?.toDouble();
    tevkifattutar = (json["Tevkifattutar"] as num?)?.toDouble();

    aciklama = json["Aciklama"];
    onaydurum = json["Onaydurum"];
    acikkapali = json["Acikkapali"];
    kapanisnedeni = json["Kapanisnedeni"];

    // Döngüsel referans önlemi: teklif parse edilmiyor
    // teklif = json["Teklif"] != null ? TeklifDto.fromJson(json["Teklif"]) : null;
    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    depo = json["Depo"] != null ? DepoDto.fromJson(json["Depo"]) : null;
    stok = json["Stok"] != null ? StokDto.fromJson(json["Stok"]) : null;
    stokozelliksabit = json["Stokozelliksabit"] != null
        ? StokozelliksabitDto.fromJson(json["Stokozelliksabit"])
        : null;
    olcubr = json["Olcubr"] != null ? OlcubrDto.fromJson(json["Olcubr"]) : null;
    proje = json["Proje"] != null ? ProjeDto.fromJson(json["Proje"]) : null;
    istisna =
        json["Istisna"] != null ? IstisnaDto.fromJson(json["Istisna"]) : null;
    referans = json["Referans"] != null
        ? ReferansDto.fromJson(json["Referans"])
        : null;

    siparishareket = (json["Siparishareket"] as List?)
        ?.where((e) => e != null)
        .map((e) => SiparishareketDto.fromJson(e as Map<String, dynamic>))
        .toList();

    talephareket = json["Talephareket"] != null
        ? TalephareketDto.fromJson(json["Talephareket"])
        : null;
  }
}
