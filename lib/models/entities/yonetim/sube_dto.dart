// lib/models/sube_dto.dart
import '../firma/firma_dto.dart';
import 'sirket_dto.dart';

class SubeDto {
  final int? id;
  final int? firmaId;
  final int? sirketId;
  final String? ad;
  final String? kod;
  final String? adres;
  final String? bolge;
  final String? semt;
  final String? postaKodu;
  final String? email;
  final String? fax;
  final String? telefon;
  final bool? ortakKoduVar;
  final String? ortakKod;

  final FirmaDto? firma;
  final SirketDto? sirket;

  SubeDto({
    this.id,
    this.firmaId,
    this.sirketId,
    this.ad,
    this.kod,
    this.adres,
    this.bolge,
    this.semt,
    this.postaKodu,
    this.email,
    this.fax,
    this.telefon,
    this.ortakKoduVar,
    this.ortakKod,
    this.firma,
    this.sirket,
  });

  factory SubeDto.fromJson(Map<String, dynamic> json) {
    return SubeDto(
      id: json["Id"],
      firmaId: json["Firmaid"],
      sirketId: json["Sirketid"],
      ad: json["Ad"],
      kod: json["Kod"],
      adres: json["Adres"],
      bolge: json["Bolge"],
      semt: json["Semt"],
      postaKodu: json["Postakodu"],
      email: json["Email"],
      fax: json["Fax"],
      telefon: json["Telefon"],
      ortakKoduVar: json["Ortakkoduvar"],
      ortakKod: json["Ortakkod"],
      firma: json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null,
      sirket: json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null,
    );
  }
}
