import 'senetalinanhareket_dto.dart';

class SenetalinancirohareketDto {
  final String? Id;                 // Guid
  final String? Senetalinanhareketid; // Guid — cirolanan senet
  final String? Senetalinanciroid;    // Guid — üst ciro bordrosu
  final double? Kur;

  final SenetalinanhareketDto? Senetalinanhareket; // nested — cirolanan senedin kendisi

  SenetalinancirohareketDto({
    this.Id,
    this.Senetalinanhareketid,
    this.Senetalinanciroid,
    this.Kur,
    this.Senetalinanhareket,
  });

  factory SenetalinancirohareketDto.fromJson(Map<String, dynamic> json) {
    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    final senet = json['Senetalinanhareket'] as Map<String, dynamic>?;
    return SenetalinancirohareketDto(
      Id:                 json['Id']?.toString(),
      Senetalinanhareketid: json['Senetalinanhareketid']?.toString(),
      Senetalinanciroid:    json['Senetalinanciroid']?.toString(),
      Kur:                _d(json['Kur']),
      Senetalinanhareket:   senet != null ? SenetalinanhareketDto.fromJson(senet) : null,
    );
  }
}
