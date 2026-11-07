import 'senetverilenhareket_dto.dart';

class SenetverileniadehareketDto {
  final String? Id;                  // Guid
  final String? Senetverilenhareketid; // Guid — iade edilen senet
  final String? Senetverileniadeid;    // Guid — üst iade bordrosu

  final SenetverilenhareketDto? Senetverilenhareket; // nested — iade edilen senetin kendisi

  SenetverileniadehareketDto({
    this.Id,
    this.Senetverilenhareketid,
    this.Senetverileniadeid,
    this.Senetverilenhareket,
  });

  factory SenetverileniadehareketDto.fromJson(Map<String, dynamic> json) {
    final senet = json['Senetverilenhareket'] as Map<String, dynamic>?;
    return SenetverileniadehareketDto(
      Id:                  json['Id']?.toString(),
      Senetverilenhareketid: json['Senetverilenhareketid']?.toString(),
      Senetverileniadeid:    json['Senetverileniadeid']?.toString(),
      Senetverilenhareket:   senet != null ? SenetverilenhareketDto.fromJson(senet) : null,
    );
  }
}
