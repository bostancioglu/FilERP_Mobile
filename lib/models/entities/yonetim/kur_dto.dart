import '../../base_dto.dart';

class KurDto extends BaseDto {
  final int? Dovizid;
  final DateTime? Tarih;
  final DateTime? Mbtarih;
  final double? Dovizalis;
  final double? Dovizsatis;
  final double? Dovizefektifalis;
  final double? Dovizefektifsatis;

  KurDto({
    this.Dovizid,
    this.Tarih,
    this.Mbtarih,
    this.Dovizalis,
    this.Dovizsatis,
    this.Dovizefektifalis,
    this.Dovizefektifsatis,
  });

  factory KurDto.fromJson(Map<String, dynamic> json) {
    return KurDto(
      Dovizid: json['Dovizid'],
      Tarih: json['Tarih'] != null ? DateTime.parse(json['Tarih']) : null,
      Mbtarih: json['Mbtarih'] != null ? DateTime.parse(json['Mbtarih']) : null,
      Dovizalis: json['Dovizalis'] != null ? double.parse(json['Dovizalis'].toString()) : null,
      Dovizsatis: json['Dovizsatis'] != null ? double.parse(json['Dovizsatis'].toString()) : null,
      Dovizefektifalis: json['Dovizefektifalis'] != null ? double.parse(json['Dovizefektifalis'].toString()) : null,
      Dovizefektifsatis: json['Dovizefektifsatis'] != null ? double.parse(json['Dovizefektifsatis'].toString()) : null,
    );
  }
}