import '../cari/cari_dto.dart';
import '../adres/ulke_dto.dart';
import '../adres/il_dto.dart';
import '../adres/ilce_dto.dart';
import '../adres/mahalle_dto.dart';

class SurucuDto {
  int? id;

  int? ulkeid;
  int? ilid;
  int? ilceid;
  int? mahalleid;
  int? ehliyetilid;
  int? lojistikcariid;

  String? adsoyad;
  String? adres;
  String? postakodu;
  String? semt;
  String? bolge;
  String? email;
  String? telefon;
  String? ehliyetno;
  DateTime? ehliyettarih;

  // Relations
  CariDto? lojistikcari;
  IlDto? ehliyetil;
  IlDto? il;
  IlceDto? ilce;
  MahalleDto? mahalle;
  UlkeDto? ulke;

  SurucuDto();

  SurucuDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];

    ulkeid = json["Ulkeid"];
    ilid = json["Ilid"];
    ilceid = json["Ilceid"];
    mahalleid = json["Mahalleid"];
    ehliyetilid = json["Ehliyetilid"];
    lojistikcariid = json["Lojistikcariid"];

    adsoyad = json["Adsoyad"];
    adres = json["Adres"];
    postakodu = json["Postakodu"];
    semt = json["Semt"];
    bolge = json["Bolge"];
    email = json["Email"];
    telefon = json["Telefon"];
    ehliyetno = json["Ehliyetno"];

    ehliyettarih = json["Ehliyettarih"] != null
        ? DateTime.parse(json["Ehliyettarih"])
        : null;

    lojistikcari = json["Lojistikcari"] != null
        ? CariDto.fromJson(json["Lojistikcari"])
        : null;

    ehliyetil =
        json["Ehliyetil"] != null ? IlDto.fromJson(json["Ehliyetil"]) : null;

    il = json["Il"] != null ? IlDto.fromJson(json["Il"]) : null;
    ilce = json["Ilce"] != null ? IlceDto.fromJson(json["Ilce"]) : null;
    mahalle =
        json["Mahalle"] != null ? MahalleDto.fromJson(json["Mahalle"]) : null;
    ulke = json["Ulke"] != null ? UlkeDto.fromJson(json["Ulke"]) : null;
  }
}
