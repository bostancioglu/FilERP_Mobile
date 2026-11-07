import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';

class ProjekategoriDto {
  int? id;
  int? firmaid;
  int? sirketid;

  String? kod;
  String? aciklama;
  int? tur;

  FirmaDto? firma;
  SirketDto? sirket;

  ProjekategoriDto();

  ProjekategoriDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];

    kod = json["Kod"];
    aciklama = json["Aciklama"];
    tur = json["Tur"];

    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket = json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
  }
}
