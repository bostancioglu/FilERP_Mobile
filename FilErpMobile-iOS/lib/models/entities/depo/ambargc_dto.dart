import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import '../plasiyer/plasiyer_dto.dart';
import '../proje/proje_dto.dart';
import '../helper/doviz_dto.dart';
import '../cari/referans_dto.dart';
import '../stok/stok_dto.dart';
import '../yonetim/masraf_dto.dart';
import 'ambargchareket_dto.dart';

class AmbargcDto {
  String? id;

  int?    firmaid;
  int?    sirketid;
  int?    subeid;
  int?    plasiyerid;
  int?    projeid;
  int?    dovizid;
  int?    referansid;
  int?    stokid;
  int?    masrafid;

  int?      giriscikis;
  int?      islemyeri;
  String?   belgeseri;
  int?      belgeyil;
  String?   belgeno;
  String?   belgeserino;
  DateTime? tarih;
  DateTime? doviztarih;
  double?   kur;
  int?      belgeturu;
  int?      belgedurum;

  double?   geneltoplam;
  double?   doviztoplam;
  String?   aciklama;
  int?      localerpentegrasyondurum;
  int?      localerpdenkilitli;
  int?      kayityeri;

  // Navigation
  FirmaDto?    firma;
  SirketDto?   sirket;
  SubeDto?     sube;
  PlasiyerDto? plasiyer;
  ProjeDto?    proje;
  DovizDto?    doviz;
  ReferansDto? referans;
  StokDto?     stok;
  MasrafDto?   masraf;
  List<AmbargchareketDto> ambargchareket = [];

  AmbargcDto();

  AmbargcDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"]?.toString();

    firmaid    = json["Firmaid"];
    sirketid   = json["Sirketid"];
    subeid     = json["Subeid"];
    plasiyerid = json["Plasiyerid"];
    projeid    = json["Projeid"];
    dovizid    = json["Dovizid"];
    referansid = json["Referansid"];
    stokid     = json["Stokid"];
    masrafid   = json["Masrafid"];

    giriscikis = json["Giriscikis"];
    islemyeri  = json["Islemyeri"];
    belgeseri  = json["Belgeseri"];
    belgeyil   = json["Belgeyil"];
    belgeno    = json["Belgeno"];
    belgeserino = json["Belgeserino"];

    tarih      = json["Tarih"]      != null ? DateTime.parse(json["Tarih"])      : null;
    doviztarih = json["Doviztarih"] != null ? DateTime.parse(json["Doviztarih"]) : null;
    kur        = (json["Kur"]       as num?)?.toDouble();
    belgeturu  = json["Belgeturu"];
    belgedurum = json["Belgedurum"];

    geneltoplam  = (json["Geneltoplam"]  as num?)?.toDouble();
    doviztoplam  = (json["Doviztoplam"]  as num?)?.toDouble();
    aciklama     = json["Aciklama"];
    localerpentegrasyondurum = json["Localerpentegrasyondurum"];
    localerpdenkilitli       = json["Localerpdenkilitli"];
    kayityeri                = json["Kayityeri"];

    firma    = json["Firma"]    != null ? FirmaDto.fromJson(json["Firma"])       : null;
    sirket   = json["Sirket"]   != null ? SirketDto.fromJson(json["Sirket"])     : null;
    sube     = json["Sube"]     != null ? SubeDto.fromJson(json["Sube"])         : null;
    plasiyer = json["Plasiyer"] != null ? PlasiyerDto.fromJson(json["Plasiyer"]) : null;
    proje    = json["Proje"]    != null ? ProjeDto.fromJson(json["Proje"])       : null;
    doviz    = json["Doviz"]    != null ? DovizDto.fromJson(json["Doviz"])       : null;
    referans = json["Referans"] != null ? ReferansDto.fromJson(json["Referans"]) : null;
    stok     = json["Stok"]     != null ? StokDto.fromJson(json["Stok"])         : null;
    masraf   = json["Masraf"]   != null ? MasrafDto.fromJson(json["Masraf"])     : null;

    ambargchareket = (json["Ambargchareket"] as List?)
        ?.where((e) => e != null)
        .map((e) => AmbargchareketDto.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
  }
}