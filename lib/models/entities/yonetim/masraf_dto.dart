import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../muhasebe/hesapplani_dto.dart';

class MasrafDto {
  int?    id;
  int?    firmaid;
  int?    sirketid;
  int?    hesapplaniid;
  String? kod;
  String? ad;
  int?    gidertipi;
  String? giderkodu;
  bool?   ortakkoduvar;
  String? ortakkod;

  // Navigation
  FirmaDto?      firma;
  SirketDto?     sirket;
  HesapplaniDto? hesapplani;

  MasrafDto();

  MasrafDto.fromJson(Map<String, dynamic> json) {
    id           = json["Id"];
    firmaid      = json["Firmaid"];
    sirketid     = json["Sirketid"];
    hesapplaniid = json["Hesapplaniid"];
    kod          = json["Kod"];
    ad           = json["Ad"];
    gidertipi    = json["Gidertipi"];
    giderkodu    = json["Giderkodu"];
    ortakkoduvar = json["Ortakkoduvar"];
    ortakkod     = json["Ortakkod"];

    firma      = json["Firma"]      != null ? FirmaDto.fromJson(json["Firma"])           : null;
    sirket     = json["Sirket"]     != null ? SirketDto.fromJson(json["Sirket"])         : null;
    hesapplani = json["Hesapplani"] != null ? HesapplaniDto.fromJson(json["Hesapplani"]) : null;
  }
}