import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import '../depo/depo_dto.dart';
import '../depo/depoadres_dto.dart';
import '../stok/stok_dto.dart';
import '../stok/stokozelliksabit_dto.dart';
import '../olcubirimi/olcubr_dto.dart';
import '../helper/doviz_dto.dart';
import '../proje/proje_dto.dart';
import '../plasiyer/plasiyer_dto.dart';
import '../cari/cari_dto.dart';
import '../uretim/uretimistasyon_dto.dart';

class StokhareketDto {
  String? id; // Guid

  int? firmaid;
  int? sirketid;
  String? relatedid;

  int? subeid;
  int? stokid;
  int? stokozelliksabitid;
  int? olcubrid;
  int? dovizid;
  int? uretimistasyonid;

  DateTime? tarih;
  String? giriscikis;
  String? belgeno;
  int? belgeturu;
  int? islemtipi;
  String? belgeid;
  int? belgehareketid;

  double? miktar;
  String? aciklama;
  bool? aktif;

  double? dovizfiyat;
  double? fiyat;
  double? olcubrcarpim;
  double? kdvorani;
  bool? kdvdahil;

  // Yeni
  double? miktar2;
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
  double? malfazlasiiskonto;
  double? tevkifatorani;
  double? tutar;
  double? geneliskontooran;

  double? kdvtutar;
  double? tevkifatmatrahi;
  double? tevkifattutar;
  double? bruttutar;
  double? iskontotutar;
  double? malfazlasitutar;
  double? aratoplam;
  double? aratoplamiskontolu;

  int? depoid;
  String? depoadresid;
  int? projeid;
  int? plasiyerid;
  int? cariid;

  // Navigation
  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;
  DepoDto? depo;
  DepoadresDto? depoadres;
  StokDto? stok;
  StokozelliksabitDto? stokozelliksabit;
  OlcubrDto? olcubr;
  DovizDto? doviz;
  ProjeDto? proje;
  PlasiyerDto? plasiyer;
  CariDto? cari;
  UretimistasyonDto? uretimistasyon;

  StokhareketDto();

  StokhareketDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"]?.toString();

    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    relatedid = json["Relatedid"]?.toString();

    subeid = json["Subeid"];
    stokid = json["Stokid"];
    stokozelliksabitid = json["Stokozelliksabitid"];
    olcubrid = json["Olcubrid"];
    dovizid = json["Dovizid"];
    uretimistasyonid = json["Uretimistasyonid"];

    tarih =
        json["Tarih"] != null ? DateTime.parse(json["Tarih"]) : null;
    giriscikis = json["Giriscikis"]?.toString();
    belgeno = json["Belgeno"];
    belgeturu = json["Belgeturu"];
    islemtipi = json["Islemtipi"];
    belgeid = json["Belgeid"]?.toString();
    belgehareketid = json["Belgehareketid"];

    miktar = (json["Miktar"] as num?)?.toDouble();
    aciklama = json["Aciklama"];
    aktif = json["Aktif"];

    dovizfiyat = (json["Dovizfiyat"] as num?)?.toDouble();
    fiyat = (json["Fiyat"] as num?)?.toDouble();
    olcubrcarpim = (json["Olcubrcarpim"] as num?)?.toDouble();
    kdvorani = (json["Kdvorani"] as num?)?.toDouble();
    kdvdahil = json["Kdvdahil"];

    miktar2 = (json["Miktar2"] as num?)?.toDouble();
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

    malfazlasiiskonto =
        (json["Malfazlasiiskonto"] as num?)?.toDouble();
    tevkifatorani =
        (json["Tevkifatorani"] as num?)?.toDouble();
    tutar = (json["Tutar"] as num?)?.toDouble();
    geneliskontooran =
        (json["Geneliskontooran"] as num?)?.toDouble();

    kdvtutar = (json["Kdvtutar"] as num?)?.toDouble();
    tevkifatmatrahi =
        (json["Tevkifatmatrahi"] as num?)?.toDouble();
    tevkifattutar =
        (json["Tevkifattutar"] as num?)?.toDouble();
    bruttutar = (json["Bruttutar"] as num?)?.toDouble();
    iskontotutar =
        (json["Iskontotutar"] as num?)?.toDouble();
    malfazlasitutar =
        (json["Malfazlasitutar"] as num?)?.toDouble();
    aratoplam = (json["Aratoplam"] as num?)?.toDouble();
    aratoplamiskontolu =
        (json["Aratoplamiskontolu"] as num?)?.toDouble();

    depoid = json["Depoid"];
    depoadresid = json["Depoadresid"]?.toString();
    projeid = json["Projeid"];
    plasiyerid = json["Plasiyerid"];
    cariid = json["Cariid"];

    firma =
        json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket =
        json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    sube = json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null;
    depo = json["Depo"] != null ? DepoDto.fromJson(json["Depo"]) : null;
    depoadres = json["Depoadres"] != null
        ? DepoadresDto.fromJson(json["Depoadres"])
        : null;
    stok = json["Stok"] != null ? StokDto.fromJson(json["Stok"]) : null;
    stokozelliksabit = json["Stokozelliksabit"] != null
        ? StokozelliksabitDto.fromJson(json["Stokozelliksabit"])
        : null;
    olcubr =
        json["Olcubr"] != null ? OlcubrDto.fromJson(json["Olcubr"]) : null;
    doviz =
        json["Doviz"] != null ? DovizDto.fromJson(json["Doviz"]) : null;
    proje =
        json["Proje"] != null ? ProjeDto.fromJson(json["Proje"]) : null;
    plasiyer = json["Plasiyer"] != null
        ? PlasiyerDto.fromJson(json["Plasiyer"])
        : null;
    cari = json["Cari"] != null ? CariDto.fromJson(json["Cari"]) : null;
    uretimistasyon = json["Uretimistasyon"] != null
        ? UretimistasyonDto.fromJson(json["Uretimistasyon"])
        : null;
  }
}
