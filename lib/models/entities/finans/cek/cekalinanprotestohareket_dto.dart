import 'cekalinanhareket_dto.dart';

class CekalinanprotestohareketDto {
  final String? Id;                   // Guid
  final String? Cekalinanhareketid;   // Guid — protesto edilen çek
  final String? Cekalinanprotestoid;  // Guid — üst protesto bordrosu

  final CekalinanhareketDto? Cekalinanhareket; // nested — protesto edilen çekin kendisi

  CekalinanprotestohareketDto({
    this.Id,
    this.Cekalinanhareketid,
    this.Cekalinanprotestoid,
    this.Cekalinanhareket,
  });

  factory CekalinanprotestohareketDto.fromJson(Map<String, dynamic> json) {
    final cek = json['Cekalinanhareket'] as Map<String, dynamic>?;
    return CekalinanprotestohareketDto(
      Id:                  json['Id']?.toString(),
      Cekalinanhareketid:  json['Cekalinanhareketid']?.toString(),
      Cekalinanprotestoid: json['Cekalinanprotestoid']?.toString(),
      Cekalinanhareket:    cek != null ? CekalinanhareketDto.fromJson(cek) : null,
    );
  }
}
