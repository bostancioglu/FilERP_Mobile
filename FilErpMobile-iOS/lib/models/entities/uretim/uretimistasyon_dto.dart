import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';

class UretimistasyonDto {
  int? id;

  int? firmaid;
  int? sirketid;
  int? subeid;

  String? ad;
  String? kod;
  String? aciklama;

  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;

  UretimistasyonDto();

  UretimistasyonDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    subeid = json["Subeid"];

    ad = json["Ad"];
    kod = json["Kod"];
    aciklama = json["Aciklama"];

    firma =
        json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket =
        json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    sube = json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null;
  }
}
