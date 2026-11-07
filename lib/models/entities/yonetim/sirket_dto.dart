// lib/models/sirket_dto.dart
import '../firma/firma_dto.dart';

class SirketDto {
  final int? id;
  final int? firmaId;
  final String? ad;
  final String? kod;

  final FirmaDto? firma;

  SirketDto({
    this.id,
    this.firmaId,
    this.ad,
    this.kod,
    this.firma,
  });

  factory SirketDto.fromJson(Map<String, dynamic> json) {
    return SirketDto(
      id: json["Id"],
      firmaId: json["Firmaid"],
      ad: json["Ad"],
      kod: json["Kod"],
      firma: json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null,
    );
  }
}
