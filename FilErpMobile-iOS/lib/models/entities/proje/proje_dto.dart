import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';


class ProjeDto {
  int? id;
  int? firmaid;
  int? sirketid;


  String? kod;
  String? ad;
  String? sorumlu;

  DateTime? baslangictarihi;
  DateTime? bitistarihi;

  bool? ortakkoduvar;
  String? ortakkod;

  int? tip;
  int? tur;

  FirmaDto? firma;
  SirketDto? sirket;

  ProjeDto();

  ProjeDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    sorumlu = json["Sorumlu"];

    kod = json["Kod"];
    ad = json["Ad"];
    baslangictarihi = json["Baslangictarihi"] != null
        ? DateTime.parse(json["Baslangictarihi"])
        : null;

    bitistarihi = json["Bitistarihi"] != null
        ? DateTime.parse(json["Bitistarihi"])
        : null;

    ortakkoduvar = json["Ortakkoduvar"];
    ortakkod = json["Ortakkod"];

    tip = json["Tip"];
    tur = json["Tur"];

    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket = json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;

  }
}
