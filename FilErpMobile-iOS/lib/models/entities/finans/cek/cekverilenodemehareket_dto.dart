import 'cekverilenhareket_dto.dart';

class CekverilenodemehareketDto {
  final String? Id;                  // Guid
  final String? Cekverilenhareketid; // Guid — ödenen çek
  final String? Cekverilenodemeid;   // Guid — üst ödeme bordrosu
  final double? Kur;

  final CekverilenhareketDto? Cekverilenhareket; // nested — ödenen çekin kendisi

  CekverilenodemehareketDto({
    this.Id,
    this.Cekverilenhareketid,
    this.Cekverilenodemeid,
    this.Kur,
    this.Cekverilenhareket,
  });

  factory CekverilenodemehareketDto.fromJson(Map<String, dynamic> json) {
    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    final cek = json['Cekverilenhareket'] as Map<String, dynamic>?;
    return CekverilenodemehareketDto(
      Id:                  json['Id']?.toString(),
      Cekverilenhareketid: json['Cekverilenhareketid']?.toString(),
      Cekverilenodemeid:   json['Cekverilenodemeid']?.toString(),
      Kur:                 _d(json['Kur']),
      Cekverilenhareket:   cek != null ? CekverilenhareketDto.fromJson(cek) : null,
    );
  }
}
