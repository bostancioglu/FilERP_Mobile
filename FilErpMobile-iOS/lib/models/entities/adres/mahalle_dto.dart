import 'ilce_dto.dart';

class MahalleDto {
  int? id;

  String? ad;
  String? postakodu;
  int? ilceid;

  IlceDto? ilce;

  MahalleDto();

  MahalleDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    ad = json["Ad"];
    postakodu = json["Postakodu"];
    ilceid = json["Ilceid"];

    ilce = json["Ilce"] != null
        ? IlceDto.fromJson(json["Ilce"])
        : null;
  }
}
