import '../adres/ulke_dto.dart';
import '../adres/il_dto.dart';
import '../adres/ilce_dto.dart';
import '../adres/mahalle_dto.dart';

class CariadresDto {
  int? id;
  int? cariid;

  int? ulkeid;
  int? ilid;
  int? ilceid;
  int? mahalleid;

  int? sira;
  String? adres;
  String? bolge;
  String? semt;
  String? postakodu;
  String? email;
  String? fax;
  String? telefon;

  UlkeDto? ulke;
  IlDto? il;
  IlceDto? ilce;
  MahalleDto? mahalle;

  CariadresDto();

  CariadresDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    cariid = json["Cariid"];

    ulkeid = json["Ulkeid"];
    ilid = json["Ilid"];
    ilceid = json["Ilceid"];
    mahalleid = json["Mahalleid"];

    sira = json["Sira"];
    adres = json["Adres"];
    bolge = json["Bolge"];
    semt = json["Semt"];
    postakodu = json["Postakodu"];
    email = json["Email"];
    fax = json["Fax"];
    telefon = json["Telefon"];

    ulke = json["Ulke"] != null ? UlkeDto.fromJson(json["Ulke"]) : null;
    il = json["Il"] != null ? IlDto.fromJson(json["Il"]) : null;
    ilce = json["Ilce"] != null ? IlceDto.fromJson(json["Ilce"]) : null;
    mahalle =
        json["Mahalle"] != null ? MahalleDto.fromJson(json["Mahalle"]) : null;
  }
}
