import 'cekverilenhareket_dto.dart';

class CekverileniadehareketDto {
  final String? Id;                  // Guid
  final String? Cekverilenhareketid; // Guid — iade edilen çek
  final String? Cekverileniadeid;    // Guid — üst iade bordrosu

  final CekverilenhareketDto? Cekverilenhareket; // nested — iade edilen çekin kendisi

  CekverileniadehareketDto({
    this.Id,
    this.Cekverilenhareketid,
    this.Cekverileniadeid,
    this.Cekverilenhareket,
  });

  factory CekverileniadehareketDto.fromJson(Map<String, dynamic> json) {
    final cek = json['Cekverilenhareket'] as Map<String, dynamic>?;
    return CekverileniadehareketDto(
      Id:                  json['Id']?.toString(),
      Cekverilenhareketid: json['Cekverilenhareketid']?.toString(),
      Cekverileniadeid:    json['Cekverileniadeid']?.toString(),
      Cekverilenhareket:   cek != null ? CekverilenhareketDto.fromJson(cek) : null,
    );
  }
}
