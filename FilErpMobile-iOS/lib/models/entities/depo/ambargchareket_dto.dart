import '../firma/firma_dto.dart';
import '../depo/depo_dto.dart';
import '../depo/depoadres_dto.dart';
import '../stok/stok_dto.dart';
import '../stok/stokozelliksabit_dto.dart';
import '../olcubirimi/olcubr_dto.dart';
import '../proje/proje_dto.dart';
import '../stok/stokhareket_dto.dart';
import '../uretim/uretimpartitakip_rec_dto.dart';

class AmbargchareketDto {
  String? id;

  int?    firmaid;
  int?    depoid;
  String? depoadresid;
  String? ambargcid;
  int?    stokid;
  int?    stokozelliksabitid;
  int?    olcubrid;
  int?    projeid;
  String? stokhareketid;

  double?   olcubrcarpim;
  int?      belgeturu;
  DateTime? tarih;
  double?   miktar;
  double?   miktar2;
  double?   dovizfiyat;
  double?   fiyat;
  double?   tutar;
  String?   aciklama;

  // Navigation
  FirmaDto?             firma;
  DepoDto?              depo;
  DepoadresDto?         depoadres;
  StokDto?              stok;
  StokozelliksabitDto?  stokozelliksabit;
  OlcubrDto?            olcubr;
  ProjeDto?             proje;
  StokhareketDto?       stokhareket;
  UretimpartitakipRecDto? uretimpartitakip;

  AmbargchareketDto();

  AmbargchareketDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"]?.toString();

    firmaid            = json["Firmaid"];
    depoid             = json["Depoid"];
    depoadresid        = json["Depoadresid"]?.toString();
    ambargcid          = json["Ambargcid"]?.toString();
    stokid             = json["Stokid"];
    stokozelliksabitid = json["Stokozelliksabitid"];
    olcubrid           = json["Olcubrid"];
    projeid            = json["Projeid"];
    stokhareketid      = json["Stokhareketid"]?.toString();

    olcubrcarpim = (json["Olcubrcarpim"] as num?)?.toDouble();
    belgeturu    = json["Belgeturu"];
    tarih        = json["Tarih"] != null ? DateTime.parse(json["Tarih"]) : null;
    miktar       = (json["Miktar"]     as num?)?.toDouble();
    miktar2      = (json["Miktar2"]    as num?)?.toDouble();
    dovizfiyat   = (json["Dovizfiyat"] as num?)?.toDouble();
    fiyat        = (json["Fiyat"]      as num?)?.toDouble();
    tutar        = (json["Tutar"]      as num?)?.toDouble();
    aciklama     = json["Aciklama"];

    firma    = json["Firma"]    != null ? FirmaDto.fromJson(json["Firma"])       : null;
    depo     = json["Depo"]     != null ? DepoDto.fromJson(json["Depo"])         : null;
    depoadres = json["Depoadres"] != null ? DepoadresDto.fromJson(json["Depoadres"]) : null;
    stok     = json["Stok"]     != null ? StokDto.fromJson(json["Stok"])         : null;
    stokozelliksabit = json["Stokozelliksabit"] != null
        ? StokozelliksabitDto.fromJson(json["Stokozelliksabit"]) : null;
    olcubr   = json["Olcubr"]   != null ? OlcubrDto.fromJson(json["Olcubr"])     : null;
    proje    = json["Proje"]    != null ? ProjeDto.fromJson(json["Proje"])       : null;
    stokhareket = json["Stokhareket"] != null
        ? StokhareketDto.fromJson(json["Stokhareket"]) : null;
    uretimpartitakip = json["Uretimpartitakip"] != null
        ? UretimpartitakipRecDto.fromJson(json["Uretimpartitakip"]) : null;
  }
}