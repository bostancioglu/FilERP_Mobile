import 'cekalinanhareket_dto.dart';

class CekalinantahsilhareketDto {
  final String? Id;                 // Guid
  final String? Cekalinanhareketid; // Guid — tahsil edilen çek
  final String? Cekalinantahsilid;  // Guid — üst tahsil bordrosu
  final double? Kur;

  final CekalinanhareketDto? Cekalinanhareket; // nested — tahsil edilen çekin kendisi

  CekalinantahsilhareketDto({
    this.Id,
    this.Cekalinanhareketid,
    this.Cekalinantahsilid,
    this.Kur,
    this.Cekalinanhareket,
  });

  factory CekalinantahsilhareketDto.fromJson(Map<String, dynamic> json) {
    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    final cek = json['Cekalinanhareket'] as Map<String, dynamic>?;
    return CekalinantahsilhareketDto(
      Id:                 json['Id']?.toString(),
      Cekalinanhareketid: json['Cekalinanhareketid']?.toString(),
      Cekalinantahsilid:  json['Cekalinantahsilid']?.toString(),
      Kur:                _d(json['Kur']),
      Cekalinanhareket:   cek != null ? CekalinanhareketDto.fromJson(cek) : null,
    );
  }
}
