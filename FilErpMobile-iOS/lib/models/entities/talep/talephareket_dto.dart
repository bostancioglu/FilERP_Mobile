import '../firma/firma_dto.dart';
import '../depo/depo_dto.dart';
import '../stok/stok_dto.dart';
import '../stok/stokozelliksabit_dto.dart';
import '../olcubirimi/olcubr_dto.dart';
import '../proje/proje_dto.dart';
import '../cari/referans_dto.dart';
import '../teklif/teklifhareket_dto.dart';
import 'talep_dto.dart';

class TalephareketDto {
  String? id; // BaseDto -> Guid/String

  int? firmaid;
  int? depoid;
  String? talepid; // Guid
  int? stokid;
  int? stokozelliksabitid;
  int? olcubrid;
  int? projeid;
  int? referansid;

  double? olcubrcarpim;
  int? belgeturu;

  DateTime? tarih;
  DateTime? teslimtarihi;

  String? giriscikis; // char → String
  double? miktar;
  double? miktar2;

  String? aciklama;
  int? onaydurum;
  bool? acikkapali;
  String? kapanisnedeni;

  // Navigation
  TalepDto? talep;
  FirmaDto? firma;
  DepoDto? depo;
  StokDto? stok;
  StokozelliksabitDto? stokozelliksabit;
  OlcubrDto? olcubr;
  ProjeDto? proje;
  ReferansDto? referans;
  List<TeklifhareketDto>? teklifhareket;

  TalephareketDto();

  TalephareketDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"]?.toString();

    firmaid = json["Firmaid"];
    depoid = json["Depoid"];
    talepid = json["Talepid"]?.toString();
    stokid = json["Stokid"];
    stokozelliksabitid = json["Stokozelliksabitid"];
    olcubrid = json["Olcubrid"];
    projeid = json["Projeid"];
    referansid = json["Referansid"];

    olcubrcarpim = (json["Olcubrcarpim"] as num?)?.toDouble();
    belgeturu = json["Belgeturu"];

    tarih = json["Tarih"] != null ? DateTime.parse(json["Tarih"]) : null;
    teslimtarihi =
        json["Teslimtarihi"] != null ? DateTime.parse(json["Teslimtarihi"]) : null;

    giriscikis = json["Giriscikis"]?.toString();
    miktar = (json["Miktar"] as num?)?.toDouble();
    miktar2 = (json["Miktar2"] as num?)?.toDouble();

    aciklama = json["Aciklama"];
    onaydurum = json["Onaydurum"];
    acikkapali = json["Acikkapali"] ?? true;
    kapanisnedeni = json["Kapanisnedeni"];

    talep =
    json["Talep"] != null ? TalepDto.fromJson(json["Talep"]) : null;

    firma =
        json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    depo =
        json["Depo"] != null ? DepoDto.fromJson(json["Depo"]) : null;
    stok =
        json["Stok"] != null ? StokDto.fromJson(json["Stok"]) : null;
    stokozelliksabit = json["Stokozelliksabit"] != null
        ? StokozelliksabitDto.fromJson(json["Stokozelliksabit"])
        : null;
    olcubr =
        json["Olcubr"] != null ? OlcubrDto.fromJson(json["Olcubr"]) : null;
    proje =
        json["Proje"] != null ? ProjeDto.fromJson(json["Proje"]) : null;
    referans = json["Referans"] != null
        ? ReferansDto.fromJson(json["Referans"])
        : null;

    teklifhareket = (json["Teklifhareket"] as List?)
        ?.map((e) => TeklifhareketDto.fromJson(e))
        .toList();
  }
}
