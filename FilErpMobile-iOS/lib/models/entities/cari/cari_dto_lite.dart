import '../../base_dto.dart';

class CariDtoLite extends BaseDto {
  final String? Kod;
  final String? Ad;
  final String? Vergino;
  final String? Vergidairesi;
  final int? Vadegunu;

  final int? Ulkeid;
  final int? Ilid;
  final int? Ilceid;

  CariDtoLite({
    super.Id,
    this.Kod,
    this.Ad,
    this.Vergino,
    this.Vergidairesi,
    this.Ulkeid,
    this.Ilid,
    this.Ilceid,
    this.Vadegunu,
  });

  factory CariDtoLite.fromJson(Map<String, dynamic> json) {
    return CariDtoLite(
      Id: json['Id'],
      Kod: json['Kod'],
      Ad: json['Ad'],
      Vergino: json['Vergino'],
      Vergidairesi:
          json['Vergidairesi'] ??
          json['VergiDairesi'] ??
          json['vergiDairesi'],
      Ulkeid: json['Ulkeid'],
      Ilid: json['Ilid'],
      Ilceid: json['Ilceid'],
      Vadegunu: json['Vadegunu'],
    );
  }
}
