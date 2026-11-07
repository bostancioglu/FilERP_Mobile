import 'senetalinanhareket_dto.dart';

class SenetalinanportfoydentahsilhareketDto {
  final String? Id;                            // Guid
  final String? Senetalinanhareketid;             // Guid — tahsil edilen senet
  final String? Senetalinanportfoydentahsilid;    // Guid — üst tahsil bordrosu
  final double? Kur;
  final double? Doviztutar;
  final double? Tutar;
  final double? Masraf;
  final bool?   Masraficindenmi;

  final SenetalinanhareketDto? Senetalinanhareket; // nested — tahsil edilen senedin kendisi

  SenetalinanportfoydentahsilhareketDto({
    this.Id,
    this.Senetalinanhareketid,
    this.Senetalinanportfoydentahsilid,
    this.Kur,
    this.Doviztutar,
    this.Tutar,
    this.Masraf,
    this.Masraficindenmi,
    this.Senetalinanhareket,
  });

  factory SenetalinanportfoydentahsilhareketDto.fromJson(Map<String, dynamic> json) {
    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    final senet = json['Senetalinanhareket'] as Map<String, dynamic>?;
    return SenetalinanportfoydentahsilhareketDto(
      Id:                          json['Id']?.toString(),
      Senetalinanhareketid:          json['Senetalinanhareketid']?.toString(),
      Senetalinanportfoydentahsilid: json['Senetalinanportfoydentahsilid']?.toString(),
      Kur:                         _d(json['Kur']),
      Doviztutar:                  _d(json['Doviztutar']),
      Tutar:                       _d(json['Tutar']),
      Masraf:                      _d(json['Masraf']),
      Masraficindenmi:             json['Masraficindenmi'],
      Senetalinanhareket:            senet != null ? SenetalinanhareketDto.fromJson(senet) : null,
    );
  }
}
