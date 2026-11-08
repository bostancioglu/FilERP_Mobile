import '../firma/firma_dto.dart';
import 'sirket_dto.dart';
import 'sube_dto.dart';

class BelgeSeriDto {
  int? id;
  int? firmaid;
  int? sirketid;
  int? subeid;

  int? belgeturu;
  String? seri;
  int? ebelgetip;

  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;

  BelgeSeriDto({
    this.id,
    this.firmaid,
    this.sirketid,
    this.subeid,
    this.belgeturu,
    this.seri,
    this.ebelgetip,
    this.firma,
    this.sirket,
    this.sube,
  });

  factory BelgeSeriDto.fromJson(Map<String, dynamic> json) {
    return BelgeSeriDto(
      id: json['Id'],
      firmaid: json['Firmaid'],
      sirketid: json['Sirketid'],
      subeid: json['Subeid'],
      belgeturu: json['Belgeturu'],
      seri: json['Seri'],
      ebelgetip: json['Ebelgetip'],
      firma: json['Firma'] != null ? FirmaDto.fromJson(json['Firma']) : null,
      sirket: json['Sirket'] != null ? SirketDto.fromJson(json['Sirket']) : null,
      sube: json['Sube'] != null ? SubeDto.fromJson(json['Sube']) : null,
    );
  }
}