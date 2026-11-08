import '../olcubirimi/olcubr_dto.dart';

class StokBarkodDto {
  String? Id; // Guid
  int? Stokid;
  int? Olcubrid;

  String? Barkod;
  int? Sira;

  OlcubrDto? Olcubr;

  StokBarkodDto({
    this.Id,
    this.Stokid,
    this.Olcubrid,
    this.Barkod,
    this.Sira,
    this.Olcubr,
  });

  factory StokBarkodDto.fromJson(Map<String, dynamic> json) {
    return StokBarkodDto(
      Id: json['Id'],
      Stokid: json['Stokid'],
      Olcubrid: json['Olcubrid'],
      Barkod: json['Barkod'],
      Sira: json['Sira'],
      Olcubr: json['Olcubr'] != null ? OlcubrDto.fromJson(json['Olcubr']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': Id,
      'Stokid': Stokid,
      'Olcubrid': Olcubrid,
      'Barkod': Barkod,
      'Sira': Sira,
      'Olcubr': Olcubr?.toJson(),
    };
  }
}
