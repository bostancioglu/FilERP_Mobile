import 'senetalinanhareket_dto.dart';

class SenetalinanprotestohareketDto {
  final String? Id;                   // Guid
  final String? Senetalinanhareketid;   // Guid — protesto edilen senet
  final String? Senetalinanprotestoid;  // Guid — üst protesto bordrosu

  final SenetalinanhareketDto? Senetalinanhareket; // nested — protesto edilen senedin kendisi

  SenetalinanprotestohareketDto({
    this.Id,
    this.Senetalinanhareketid,
    this.Senetalinanprotestoid,
    this.Senetalinanhareket,
  });

  factory SenetalinanprotestohareketDto.fromJson(Map<String, dynamic> json) {
    final senet = json['Senetalinanhareket'] as Map<String, dynamic>?;
    return SenetalinanprotestohareketDto(
      Id:                  json['Id']?.toString(),
      Senetalinanhareketid:  json['Senetalinanhareketid']?.toString(),
      Senetalinanprotestoid: json['Senetalinanprotestoid']?.toString(),
      Senetalinanhareket:    senet != null ? SenetalinanhareketDto.fromJson(senet) : null,
    );
  }
}
