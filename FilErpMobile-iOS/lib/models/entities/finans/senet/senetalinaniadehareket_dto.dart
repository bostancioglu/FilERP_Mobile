import 'senetalinanhareket_dto.dart';

class SenetalinaniadehareketDto {
  final String? Id;                  // Guid
  final String? Senetalinanhareketid;  // Guid — iade edilen senet
  final String? Senetalinaniadeid;     // Guid — üst iade bordrosu

  final SenetalinanhareketDto? Senetalinanhareket; // nested — iade edilen senedin kendisi

  SenetalinaniadehareketDto({
    this.Id,
    this.Senetalinanhareketid,
    this.Senetalinaniadeid,
    this.Senetalinanhareket,
  });

  factory SenetalinaniadehareketDto.fromJson(Map<String, dynamic> json) {
    final senet = json['Senetalinanhareket'] as Map<String, dynamic>?;
    return SenetalinaniadehareketDto(
      Id:                 json['Id']?.toString(),
      Senetalinanhareketid: json['Senetalinanhareketid']?.toString(),
      Senetalinaniadeid:    json['Senetalinaniadeid']?.toString(),
      Senetalinanhareket:   senet != null ? SenetalinanhareketDto.fromJson(senet) : null,
    );
  }
}
