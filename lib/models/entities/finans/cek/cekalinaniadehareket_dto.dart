import 'cekalinanhareket_dto.dart';

class CekalinaniadehareketDto {
  final String? Id;                  // Guid
  final String? Cekalinanhareketid;  // Guid — iade edilen çek
  final String? Cekalinaniadeid;     // Guid — üst iade bordrosu

  final CekalinanhareketDto? Cekalinanhareket; // nested — iade edilen çekin kendisi

  CekalinaniadehareketDto({
    this.Id,
    this.Cekalinanhareketid,
    this.Cekalinaniadeid,
    this.Cekalinanhareket,
  });

  factory CekalinaniadehareketDto.fromJson(Map<String, dynamic> json) {
    final cek = json['Cekalinanhareket'] as Map<String, dynamic>?;
    return CekalinaniadehareketDto(
      Id:                 json['Id']?.toString(),
      Cekalinanhareketid: json['Cekalinanhareketid']?.toString(),
      Cekalinaniadeid:    json['Cekalinaniadeid']?.toString(),
      Cekalinanhareket:   cek != null ? CekalinanhareketDto.fromJson(cek) : null,
    );
  }
}
