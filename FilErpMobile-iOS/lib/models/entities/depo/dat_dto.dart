import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import '../proje/proje_dto.dart';
import '../plasiyer/plasiyer_dto.dart';
import '../referans/referans_dto.dart';
import 'dathareket_dto.dart';

class DatDto {
  String? id;

  int?    firmaid;
  int?    sirketid;
  int?    subeid;
  int?    projeid;
  int?    gidecegisubeid;
  int?    plasiyerid;
  int?    referansid;

  String?   belgeserino;
  int?      belgeyil;
  String?   belgeseri;
  String?   belgeno;
  DateTime? tarih;
  DateTime? teslimtarihi;
  int?      belgeturu;
  String?   aciklama;
  int?      ebelgetip;
  int?      localerpentegrasyondurum;
  int?      localerpdenkilitli;
  int?      belgedurum;
  int?      kayityeri;

  FirmaDto?    firma;
  SirketDto?   sirket;
  SubeDto?     sube;
  ProjeDto?    proje;
  SubeDto?     gidecegisube;
  PlasiyerDto? plasiyer;
  ReferansDto? referans;

  List<DathareketDto> dathareket;

  DatDto() : dathareket = [];

  DatDto.fromJson(Map<String, dynamic> json) : dathareket = [] {
    id            = json['Id']?.toString();
    firmaid       = json['Firmaid'];
    sirketid      = json['Sirketid'];
    subeid        = json['Subeid'];
    projeid       = json['Projeid'];
    gidecegisubeid = json['Gidecegisubeid'];
    plasiyerid    = json['Plasiyerid'];
    referansid    = json['Referansid'];

    belgeserino   = json['Belgeserino'];
    belgeyil      = json['Belgeyil'];
    belgeseri     = json['Belgeseri'];
    belgeno       = json['Belgeno'];
    tarih         = json['Tarih'] != null ? DateTime.tryParse(json['Tarih']) : null;
    teslimtarihi  = json['Teslimtarihi'] != null ? DateTime.tryParse(json['Teslimtarihi']) : null;
    belgeturu     = json['Belgeturu'];
    aciklama      = json['Aciklama'];
    ebelgetip     = json['Ebelgetip'];
    localerpentegrasyondurum = json['Localerpentegrasyondurum'];
    localerpdenkilitli       = json['Localerpdenkilitli'];
    belgedurum    = json['Belgedurum'];
    kayityeri     = json['Kayityeri'];

    firma        = json['Firma']        != null ? FirmaDto.fromJson(json['Firma'])         : null;
    sirket       = json['Sirket']       != null ? SirketDto.fromJson(json['Sirket'])       : null;
    sube         = json['Sube']         != null ? SubeDto.fromJson(json['Sube'])           : null;
    proje        = json['Proje']        != null ? ProjeDto.fromJson(json['Proje'])         : null;
    gidecegisube = json['Gidecegisube'] != null ? SubeDto.fromJson(json['Gidecegisube'])   : null;
    plasiyer     = json['Plasiyer']     != null ? PlasiyerDto.fromJson(json['Plasiyer'])   : null;
    referans     = json['Referans']     != null ? ReferansDto.fromJson(json['Referans'])   : null;

    if (json['Dathareket'] is List) {
      dathareket = (json['Dathareket'] as List)
          .map((e) => DathareketDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }
}