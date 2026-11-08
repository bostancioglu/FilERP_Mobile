import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import 'depoadres_dto.dart';

class DepoDto {
  int? id;

  int? firmaid;
  int? sirketid;
  int? subeid;

  String? ad;
  String? kod;

  bool? ortakkoduvar;
  bool? dinamikdepo;
  int? plasiyerid;
  bool? plasiyerdeposu;
  String? ortakkod;

  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;
  List<DepoadresDto>? depoadres;

  DepoDto();

  DepoDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    subeid = json["Subeid"];

    ad = json["Ad"];
    kod = json["Kod"];
    ortakkoduvar = json["Ortakkoduvar"];
    dinamikdepo = json["Dinamikdepo"];
    plasiyerid = json["Plasiyerid"];
    plasiyerdeposu = json["Plasiyerdeposu"];
    ortakkod = json["Ortakkod"];

    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket = json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    sube = json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null;

    depoadres = (json["Depoadres"] as List?)?.map((e) => DepoadresDto.fromJson(e)).toList();
  }
}
