import '../../../base_dto.dart';

class VwFinanskasatoplamDto extends BaseDto {
  final int? Firmaid;
  final int? Sirketid;
  final int? Subeid;
  final int? Kasaid;
  final String? Kasakod;
  final String? Kasaisim;
  final String? Dovizbirim;
  final int? Dovizid;
  final double? Borctutar;
  final double? Alacaktutar;
  final double? Bakiyetutar;
  final double? Borcbakiye;
  final double? Alacakbakiye;
  final double? Dovizborctutar;
  final double? Dovizalacaktutar;
  final double? Dovizbakiyetutar;
  final double? Borcdovizbakiye;
  final double? Alacakdovizbakiye;

  VwFinanskasatoplamDto({
    super.Id,
    this.Firmaid,
    this.Sirketid,
    this.Subeid,
    this.Kasaid,
    this.Kasakod,
    this.Kasaisim,
    this.Dovizbirim,
    this.Dovizid,
    this.Borctutar,
    this.Alacaktutar,
    this.Bakiyetutar,
    this.Borcbakiye,
    this.Alacakbakiye,
    this.Dovizborctutar,
    this.Dovizalacaktutar,
    this.Dovizbakiyetutar,
    this.Borcdovizbakiye,
    this.Alacakdovizbakiye,
  });

  factory VwFinanskasatoplamDto.fromJson(Map<String, dynamic> json) {
    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    return VwFinanskasatoplamDto(
      Id: json['Id'],
      Firmaid: json['Firmaid'],
      Sirketid: json['Sirketid'],
      Subeid: json['Subeid'],
      Kasaid: json['Kasaid'],
      Kasakod: json['Kasakod'],
      Kasaisim: json['Kasaisim'],
      Dovizbirim: json['Dovizbirim'],
      Dovizid: json['Dovizid'],
      Borctutar: _d(json['Borctutar']),
      Alacaktutar: _d(json['Alacaktutar']),
      Bakiyetutar: _d(json['Bakiyetutar']),
      Borcbakiye: _d(json['Borcbakiye']),
      Alacakbakiye: _d(json['Alacakbakiye']),
      Dovizborctutar: _d(json['Dovizborctutar']),
      Dovizalacaktutar: _d(json['Dovizalacaktutar']),
      Dovizbakiyetutar: _d(json['Dovizbakiyetutar']),
      Borcdovizbakiye: _d(json['Borcdovizbakiye']),
      Alacakdovizbakiye: _d(json['Alacakdovizbakiye']),
    );
  }
}
