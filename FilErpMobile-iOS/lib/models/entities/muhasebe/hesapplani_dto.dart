import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import '../helper/doviz_dto.dart';
import '../cari/referans_dto.dart';

class HesapplaniDto {
  int?    id;
  int?    firmaid;
  int?    sirketid;
  int?    subeid;
  int?    dovizid;
  int?    referansid;
  int?    enflasonfarkihesabiid;
  String? ad;
  String? kod;
  int?    tur;
  String? bilancotip;
  String? borcalacak;
  String? yabanciad;
  bool?   baglantilimi;
  int?    baglantimodultip;
  bool?   dovizkontrol;
  String? hesaplamaturu;
  bool?   ortakkoduvar;
  String? ortakkod;

  // Navigation
  FirmaDto?      firma;
  SirketDto?     sirket;
  SubeDto?       sube;
  DovizDto?      doviz;
  ReferansDto?   referans;
  HesapplaniDto? enflasonfarkihesabi;

  HesapplaniDto();

  HesapplaniDto.fromJson(Map<String, dynamic> json) {
    id                     = json["Id"];
    firmaid                = json["Firmaid"];
    sirketid               = json["Sirketid"];
    subeid                 = json["Subeid"];
    dovizid                = json["Dovizid"];
    referansid             = json["Referansid"];
    enflasonfarkihesabiid  = json["Enflasonfarkihesabiid"];
    ad                     = json["Ad"];
    kod                    = json["Kod"];
    tur                    = json["Tur"];
    bilancotip             = json["Bilancotip"]?.toString();
    borcalacak             = json["Borcalacak"]?.toString();
    yabanciad              = json["Yabanciad"];
    baglantilimi           = json["Baglantilimi"];
    baglantimodultip       = json["Baglantimodultip"];
    dovizkontrol           = json["Dovizkontrol"];
    hesaplamaturu          = json["Hesaplamaturu"]?.toString();
    ortakkoduvar           = json["Ortakkoduvar"];
    ortakkod               = json["Ortakkod"];

    firma    = json["Firma"]    != null ? FirmaDto.fromJson(json["Firma"])       : null;
    sirket   = json["Sirket"]   != null ? SirketDto.fromJson(json["Sirket"])     : null;
    sube     = json["Sube"]     != null ? SubeDto.fromJson(json["Sube"])         : null;
    doviz    = json["Doviz"]    != null ? DovizDto.fromJson(json["Doviz"])       : null;
    referans = json["Referans"] != null ? ReferansDto.fromJson(json["Referans"]) : null;
    enflasonfarkihesabi = json["Enflasonfarkihesabi"] != null
        ? HesapplaniDto.fromJson(json["Enflasonfarkihesabi"]) : null;
  }
}