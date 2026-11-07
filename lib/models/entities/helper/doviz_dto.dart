import '../../base_dto.dart';

class DovizDto extends BaseDto {
  final String? Ad;
  final String? Birim;
  final int? Sira; // byte? → int?

  DovizDto({
    super.Id,
    this.Ad,
    this.Birim,
    this.Sira,
  });

  factory DovizDto.fromJson(Map<String, dynamic> json) {
    return DovizDto(
      Id: json['Id'],
      Ad: json['Ad'],
      Birim: json['Birim'],
      Sira: json['Sira'],
    );
  }
}
