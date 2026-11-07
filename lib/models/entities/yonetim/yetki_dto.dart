import 'sube_dto.dart';

class YetkiDto {
  final int? subeId;
  final SubeDto? sube;
  final int? modulAltId;
  final bool tumunuOkuma, ekleme, guncelleme, silme;

  YetkiDto({
    this.subeId,
    this.sube,
    this.modulAltId,
    this.tumunuOkuma = false,
    this.ekleme = false,
    this.guncelleme = false,
    this.silme = false,
  });

  factory YetkiDto.fromJson(Map<String, dynamic> json) {
    return YetkiDto(
      subeId: json["Subeid"],
      sube: json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null,
      modulAltId: json['Modulaltid'],
      tumunuOkuma: json['TumunuOkuma'] == true,
      ekleme: json['Ekleme'] == true,
      guncelleme: json['Guncelleme'] == true,
      silme: json['Silme'] == true,
    );
  }

  Map<String, dynamic> toPermissionJson() => {
        'Subeid': subeId,
        'Modulaltid': modulAltId,
        'TumunuOkuma': tumunuOkuma,
        'Ekleme': ekleme,
        'Guncelleme': guncelleme,
        'Silme': silme,
      };
}
