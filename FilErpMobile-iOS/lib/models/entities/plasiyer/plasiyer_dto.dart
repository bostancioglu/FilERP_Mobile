import '../../base_dto.dart';

class PlasiyerDto extends BaseDto {
  final int? Firmaid;
  final int? Sirketid;

  final String? Adsoyad;
  final String? Kod;
  final String? Email;
  final String? Ceptel;
  final String? Aciklama;
  final bool? Subeortak;
  final bool? Ortakkoduvar;
  final String? Ortakkod;

  PlasiyerDto({
    super.Id,
    this.Firmaid,
    this.Sirketid,
    this.Adsoyad,
    this.Kod,
    this.Email,
    this.Ceptel,
    this.Aciklama,
    this.Subeortak,
    this.Ortakkoduvar,
    this.Ortakkod,
  });

  factory PlasiyerDto.fromJson(Map<String, dynamic> json) {
    return PlasiyerDto(
      Id: json['Id'],
      Firmaid: json['Firmaid'],
      Sirketid: json['Sirketid'],
      Adsoyad: json['Adsoyad'],
      Kod: json['Kod'],
      Email: json['Email'],
      Ceptel: json['Ceptel'],
      Aciklama: json['Aciklama'],
      Subeortak: json['Subeortak'],
      Ortakkoduvar: json['Ortakkoduvar'],
      Ortakkod: json['Ortakkod'],
    );
  }
}
