import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';

class ReferansDto {
  int? id;
  int? firmaid;
  int? sirketid;

  String? kod;
  String? ad;

  int? gidertipi;
  String? giderkodu;

  bool? ortakkoduvar;
  String? ortakkod;

  FirmaDto? firma;
  SirketDto? sirket;

  ReferansDto();

  ReferansDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];

    kod = json["Kod"];
    ad = json["Ad"];

    gidertipi = json["Gidertipi"];
    giderkodu = json["Giderkodu"];

    ortakkoduvar = json["Ortakkoduvar"];
    ortakkod = json["Ortakkod"];

    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket = json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
  }
}
