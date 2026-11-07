import 'senetalinanhareket_dto.dart';

class SenetalinantahsilhareketDto {
  final String? Id;                 // Guid
  final String? Senetalinanhareketid; // Guid — tahsil edilen senet
  final String? Senetalinantahsilid;  // Guid — üst tahsil bordrosu
  final double? Kur;

  final SenetalinanhareketDto? Senetalinanhareket; // nested — tahsil edilen senedin kendisi

  SenetalinantahsilhareketDto({
    this.Id,
    this.Senetalinanhareketid,
    this.Senetalinantahsilid,
    this.Kur,
    this.Senetalinanhareket,
  });

  factory SenetalinantahsilhareketDto.fromJson(Map<String, dynamic> json) {
    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    final senet = json['Senetalinanhareket'] as Map<String, dynamic>?;
    return SenetalinantahsilhareketDto(
      Id:                 json['Id']?.toString(),
      Senetalinanhareketid: json['Senetalinanhareketid']?.toString(),
      Senetalinantahsilid:  json['Senetalinantahsilid']?.toString(),
      Kur:                _d(json['Kur']),
      Senetalinanhareket:   senet != null ? SenetalinanhareketDto.fromJson(senet) : null,
    );
  }
}
