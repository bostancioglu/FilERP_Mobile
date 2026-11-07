import 'senetverilenhareket_dto.dart';

class SenetverilenodemehareketDto {
  final String? Id;                  // Guid
  final String? Senetverilenhareketid; // Guid — ödenen senet
  final String? Senetverilenodemeid;   // Guid — üst ödeme bordrosu
  final double? Kur;

  final SenetverilenhareketDto? Senetverilenhareket; // nested — ödenen senetin kendisi

  SenetverilenodemehareketDto({
    this.Id,
    this.Senetverilenhareketid,
    this.Senetverilenodemeid,
    this.Kur,
    this.Senetverilenhareket,
  });

  factory SenetverilenodemehareketDto.fromJson(Map<String, dynamic> json) {
    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    final senet = json['Senetverilenhareket'] as Map<String, dynamic>?;
    return SenetverilenodemehareketDto(
      Id:                  json['Id']?.toString(),
      Senetverilenhareketid: json['Senetverilenhareketid']?.toString(),
      Senetverilenodemeid:   json['Senetverilenodemeid']?.toString(),
      Kur:                 _d(json['Kur']),
      Senetverilenhareket:   senet != null ? SenetverilenhareketDto.fromJson(senet) : null,
    );
  }
}
