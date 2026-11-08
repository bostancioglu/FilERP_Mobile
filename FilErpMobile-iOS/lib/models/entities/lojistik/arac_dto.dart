import '../cari/cari_dto.dart';

class AracDto {
  int? id;

  int? lojistikcariid;

  String? plaka;
  String? tip;
  String? marka;
  String? model;
  int? bosagirlik;
  int? maxyuk;

  CariDto? lojistikcari;

  AracDto();

  AracDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];

    lojistikcariid = json["Lojistikcariid"];

    plaka = json["Plaka"];
    tip = json["Tip"];
    marka = json["Marka"];
    model = json["Model"];
    bosagirlik = json["Bosagirlik"];
    maxyuk = json["Maxyuk"];

    lojistikcari = json["Lojistikcari"] != null
        ? CariDto.fromJson(json["Lojistikcari"])
        : null;
  }
}
