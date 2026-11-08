// lib/models/firma_dto.dart
class FirmaDto {
  final int? id;
  final String? ad;
  final String? kod;

  FirmaDto({
    this.id,
    this.ad,
    this.kod,
  });

  factory FirmaDto.fromJson(Map<String, dynamic> json) {
    return FirmaDto(
      id: json["Id"],
      ad: json["Ad"],
      kod: json["Kod"],
    );
  }
}
