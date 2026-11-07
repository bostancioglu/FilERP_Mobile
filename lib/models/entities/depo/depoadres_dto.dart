import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import 'depo_dto.dart';

class DepoadresDto {
  String? id;

  int? firmaid;
  int? sirketid;
  int? subeid;
  int? depoid;

  String? kod;
  String? ad;
  String? bolum;
  String? aciklama;

  String? searchtext;

  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;
  DepoDto? depo;


  DepoadresDto();

  DepoadresDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"]?.toString();

    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    subeid = json["Subeid"];
    depoid = json["Depoid"];

    kod = json["Kod"];
    ad = json["Ad"];
    bolum = json["Bolum"];
    aciklama = json["Aciklama"];
    searchtext = json["Searchtext"];

    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket = json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    sube = json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null;
    depo = json["Depo"] != null ? DepoDto.fromJson(json["Depo"]) : null;
  }
}
