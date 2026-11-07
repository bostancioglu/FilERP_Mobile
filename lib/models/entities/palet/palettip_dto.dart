import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';

class PalettipDto {
  int? id;

  int? firmaid;
  int? sirketid;
  int? subeid;

  String? kod;
  String? ad;
  String? aciklama;

  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;

  PalettipDto();

  PalettipDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    subeid = json["Subeid"];
    kod = json["Kod"];
    ad = json["Ad"];
    aciklama = json["Aciklama"];

    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket = json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    sube = json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null;
  }
}
