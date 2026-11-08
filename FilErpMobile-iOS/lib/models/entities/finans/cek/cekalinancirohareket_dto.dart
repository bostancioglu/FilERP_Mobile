import 'cekalinanhareket_dto.dart';

class CekalinancirohareketDto {
  final String? Id;                 // Guid
  final String? Cekalinanhareketid; // Guid — cirolanan çek
  final String? Cekalinanciroid;    // Guid — üst ciro bordrosu
  final double? Kur;

  final CekalinanhareketDto? Cekalinanhareket; // nested — cirolanan çekin kendisi

  CekalinancirohareketDto({
    this.Id,
    this.Cekalinanhareketid,
    this.Cekalinanciroid,
    this.Kur,
    this.Cekalinanhareket,
  });

  factory CekalinancirohareketDto.fromJson(Map<String, dynamic> json) {
    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    final cek = json['Cekalinanhareket'] as Map<String, dynamic>?;
    return CekalinancirohareketDto(
      Id:                 json['Id']?.toString(),
      Cekalinanhareketid: json['Cekalinanhareketid']?.toString(),
      Cekalinanciroid:    json['Cekalinanciroid']?.toString(),
      Kur:                _d(json['Kur']),
      Cekalinanhareket:   cek != null ? CekalinanhareketDto.fromJson(cek) : null,
    );
  }
}
