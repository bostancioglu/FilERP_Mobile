import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';

class StokozelliksabitDto {
  int? id;
  int? firmaid;
  int? sirketid;

  String? ad;

  FirmaDto? firma;
  SirketDto? sirket;

  StokozelliksabitDto();

  StokozelliksabitDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    ad = json["Ad"];

    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket = json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
  }
}
