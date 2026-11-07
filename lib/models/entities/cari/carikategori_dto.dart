import '../../base_dto.dart';

class CarikategoriDto extends BaseDto {
  final String? Ad;
  final String? Kod;

  CarikategoriDto({
    super.Id,
    this.Ad,
    this.Kod,
  });

  factory CarikategoriDto.fromJson(Map<String, dynamic> json) {
    return CarikategoriDto(
      Id: json['Id'],
      Ad: json['Ad'],
      Kod: json['Kod'],
    );
  }
}
