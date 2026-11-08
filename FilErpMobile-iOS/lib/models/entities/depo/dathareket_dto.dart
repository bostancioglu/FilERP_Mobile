import 'package:FilERP/models/entities/stok/stokhareket_dto.dart';

import '../firma/firma_dto.dart';
import '../firma/sube_dto.dart';
import '../proje/proje_dto.dart';
import '../stok/stok_dto.dart';
import '../olcubirimi/olcubr_dto.dart';
import 'depo_dto.dart';
import 'depoadres_dto.dart';

class DathareketDto {
  String? id;

  int?    firmaid;
  int?    cikacagisubeid;
  int?    cikacagidepoid;
  String? cikacagidepoadresid;
  int?    gidecegisubeid;
  int?    gidecegidepoid;
  String? gidecegidepoadresid;
  String? datid;
  int?    stokid;
  int?    stokozelliksabitid;
  int?    olcubrid;
  int?    projeid;
  String? stokhareketid;
  double? olcubrcarpim;
  int?    belgeturu;
  DateTime? tarih;
  String? giriscikis;
  double? miktar;
  double? miktar2;
  String? aciklama;

  FirmaDto?     firma;
  SubeDto?      cikacagisube;
  DepoDto?      cikacagidepo;
  DepoadresDto? cikacagidepoadres;
  SubeDto?      gidecegisube;
  DepoDto?      gidecegidepo;
  DepoadresDto? gidecegidepoadres;
  StokDto?      stok;
  OlcubrDto?    olcubr;
  ProjeDto?     proje;
  StokhareketDto? stokhareket;

  DathareketDto();

  DathareketDto.fromJson(Map<String, dynamic> json) {
    id                    = json['Id']?.toString();
    firmaid               = json['Firmaid'];
    cikacagisubeid        = json['Cikacagisubeid'];
    cikacagidepoid        = json['Cikacagidepoid'];
    cikacagidepoadresid   = json['Cikacagidepoadresid']?.toString();
    gidecegisubeid        = json['Gidecegisubeid'];
    gidecegidepoid        = json['Gidecegidepoid'];
    gidecegidepoadresid   = json['Gidecegidepoadresid']?.toString();
    datid                 = json['Datid']?.toString();
    stokid                = json['Stokid'];
    stokozelliksabitid    = json['Stokozelliksabitid'];
    olcubrid              = json['Olcubrid'];
    projeid               = json['Projeid'];
    stokhareketid         = json['Stokhareketid']?.toString();
    olcubrcarpim          = (json['Olcubrcarpim'] as num?)?.toDouble();
    belgeturu             = json['Belgeturu'];
    tarih                 = json['Tarih'] != null ? DateTime.tryParse(json['Tarih']) : null;
    giriscikis            = json['Giriscikis']?.toString();
    miktar                = (json['Miktar'] as num?)?.toDouble();
    miktar2               = (json['Miktar2'] as num?)?.toDouble();
    aciklama              = json['Aciklama'];

    firma             = json['Firma']             != null ? FirmaDto.fromJson(json['Firma'])                 : null;
    cikacagisube      = json['Cikacagisube']      != null ? SubeDto.fromJson(json['Cikacagisube'])           : null;
    cikacagidepo      = json['Cikacagidepo']      != null ? DepoDto.fromJson(json['Cikacagidepo'])           : null;
    cikacagidepoadres = json['Cikacagidepoadres'] != null ? DepoadresDto.fromJson(json['Cikacagidepoadres']) : null;
    gidecegisube      = json['Gidecegisube']      != null ? SubeDto.fromJson(json['Gidecegisube'])           : null;
    gidecegidepo      = json['Gidecegidepo']      != null ? DepoDto.fromJson(json['Gidecegidepo'])           : null;
    gidecegidepoadres = json['Gidecegidepoadres'] != null ? DepoadresDto.fromJson(json['Gidecegidepoadres']) : null;
    stok              = json['Stok']              != null ? StokDto.fromJson(json['Stok'])                   : null;
    olcubr            = json['Olcubr']            != null ? OlcubrDto.fromJson(json['Olcubr'])               : null;
    proje             = json['Proje']             != null ? ProjeDto.fromJson(json['Proje'])                 : null;
    stokhareket       = json['Stokhareket']       != null ? StokhareketDto.fromJson(json['Stokhareket'])     : null;
  }
}