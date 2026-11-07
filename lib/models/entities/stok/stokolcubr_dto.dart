import '../olcubirimi/olcubr_dto.dart';

class StokolcubrDto {
  int? Id; // BaseDto
  int? Stokid;
  int? Olcubrid;
  double? Pay;
  double? Payda;
  double? Carpim;
  int? Sira;

  OlcubrDto? Olcubr;

  StokolcubrDto({
    this.Id,
    this.Stokid,
    this.Olcubrid,
    this.Pay,
    this.Payda,
    this.Carpim,
    this.Sira,
    this.Olcubr,
  });

  factory StokolcubrDto.fromJson(Map<String, dynamic> json) {
    return StokolcubrDto(
      Id: json['Id'],
      Stokid: json['Stokid'],
      Olcubrid: json['Olcubrid'],
      Pay: (json['Pay'] as num?)?.toDouble(),
      Payda: (json['Payda'] as num?)?.toDouble(),
      Carpim: (json['Carpim'] as num?)?.toDouble(),
      Sira: json['Sira'],
      Olcubr:
          json['Olcubr'] != null ? OlcubrDto.fromJson(json['Olcubr']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': Id,
      'Stokid': Stokid,
      'Olcubrid': Olcubrid,
      'Pay': Pay,
      'Payda': Payda,
      'Carpim': Carpim,
      'Sira': Sira,
      'Olcubr': Olcubr?.toJson(),
    };
  }
}
