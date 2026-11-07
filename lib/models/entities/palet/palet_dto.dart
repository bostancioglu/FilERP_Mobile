import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import '../palet/palettip_dto.dart';
import '../depo/depo_dto.dart';
import '../depo/depoadres_dto.dart';
import 'palethareket_dto.dart';

class PaletDto {
  String? id; // Guid

  int? firmaid;
  int? sirketid;
  int? subeid;
  int? palettipid;

  int? olusturuldugudepoid;
  String? olusturuldugudepoadresid;
  int? bulundugudepoid;
  String? bulundugudepoadresid;

  String? belgeseri;
  int? belgeyil;
  String? belgeno;
  String? belgeserino;
  int? belgeturu;
  String? aciklama;
  String? grupno;

  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;
  PalettipDto? palettip;
  DepoDto? olusturuldugudepo;
  DepoadresDto? olusturuldugudepoadres;
  DepoDto? bulundugudepo;
  DepoadresDto? bulundugudepoadres;

  List<PalethareketDto>? palethareket;

  PaletDto();

  PaletDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"]?.toString();

    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    subeid = json["Subeid"];
    palettipid = json["Palettipid"];

    olusturuldugudepoid = json["Olusturuldugudepoid"];
    olusturuldugudepoadresid =
        json["Olusturuldugudepoadresid"]?.toString();
    bulundugudepoid = json["Bulundugudepoid"];
    bulundugudepoadresid =
        json["Bulundugudepoadresid"]?.toString();

    belgeseri = json["Belgeseri"];
    belgeyil = json["Belgeyil"];
    belgeno = json["Belgeno"];
    belgeserino = json["Belgeserino"];
    belgeturu = json["Belgeturu"];
    aciklama = json["Aciklama"];
    grupno = json["Grupno"];

    firma =
        json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket =
        json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    sube = json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null;
    palettip = json["Palettip"] != null
        ? PalettipDto.fromJson(json["Palettip"])
        : null;
    olusturuldugudepo = json["Olusturuldugudepo"] != null
        ? DepoDto.fromJson(json["Olusturuldugudepo"])
        : null;
    olusturuldugudepoadres =
        json["Olusturuldugudepoadres"] != null
            ? DepoadresDto.fromJson(json["Olusturuldugudepoadres"])
            : null;
    bulundugudepo = json["Bulundugudepo"] != null
        ? DepoDto.fromJson(json["Bulundugudepo"])
        : null;
    bulundugudepoadres = json["Bulundugudepoadres"] != null
        ? DepoadresDto.fromJson(json["Bulundugudepoadres"])
        : null;

    palethareket = (json["Palethareket"] as List?)
        ?.map((e) => PalethareketDto.fromJson(e))
        .toList();
  }
}
