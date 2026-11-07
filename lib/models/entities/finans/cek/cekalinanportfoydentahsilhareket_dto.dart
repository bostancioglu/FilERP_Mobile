import 'cekalinanhareket_dto.dart';

class CekalinanportfoydentahsilhareketDto {
  final String? Id;                            // Guid
  final String? Cekalinanhareketid;             // Guid — tahsil edilen çek
  final String? Cekalinanportfoydentahsilid;    // Guid — üst tahsil bordrosu
  final double? Kur;
  final double? Doviztutar;
  final double? Tutar;
  final double? Masraf;
  final bool?   Masraficindenmi;

  final CekalinanhareketDto? Cekalinanhareket; // nested — tahsil edilen çekin kendisi

  CekalinanportfoydentahsilhareketDto({
    this.Id,
    this.Cekalinanhareketid,
    this.Cekalinanportfoydentahsilid,
    this.Kur,
    this.Doviztutar,
    this.Tutar,
    this.Masraf,
    this.Masraficindenmi,
    this.Cekalinanhareket,
  });

  factory CekalinanportfoydentahsilhareketDto.fromJson(Map<String, dynamic> json) {
    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    final cek = json['Cekalinanhareket'] as Map<String, dynamic>?;
    return CekalinanportfoydentahsilhareketDto(
      Id:                          json['Id']?.toString(),
      Cekalinanhareketid:          json['Cekalinanhareketid']?.toString(),
      Cekalinanportfoydentahsilid: json['Cekalinanportfoydentahsilid']?.toString(),
      Kur:                         _d(json['Kur']),
      Doviztutar:                  _d(json['Doviztutar']),
      Tutar:                       _d(json['Tutar']),
      Masraf:                      _d(json['Masraf']),
      Masraficindenmi:             json['Masraficindenmi'],
      Cekalinanhareket:            cek != null ? CekalinanhareketDto.fromJson(cek) : null,
    );
  }
}
