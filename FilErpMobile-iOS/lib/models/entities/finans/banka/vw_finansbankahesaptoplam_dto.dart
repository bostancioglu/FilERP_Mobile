import '../../../base_dto.dart';

class VwFinansbankahesaptoplamDto extends BaseDto {
  final int?     Firmaid;
  final int?     Sirketid;
  final int?     Subeid;
  final int?     Bankaid;
  final String?  Bankaanaadi;
  final int?     Bankahesapid;
  final String?  Bankakod;
  final String?  Bankaisim;
  final String?  Hesapno;
  final String?  Iban;
  final String?  Dovizbirim;
  final int?     Dovizid;
  final double?  Borctutar;
  final double?  Alacaktutar;
  final double?  Bakiyetutar;
  final double?  Borcbakiye;
  final double?  Alacakbakiye;
  final double?  Dovizborctutar;
  final double?  Dovizalacaktutar;
  final double?  Dovizbakiyetutar;
  final double?  Borcdovizbakiye;
  final double?  Alacakdovizbakiye;

  VwFinansbankahesaptoplamDto({
    super.Id,
    this.Firmaid,
    this.Sirketid,
    this.Subeid,
    this.Bankaid,
    this.Bankaanaadi,
    this.Bankahesapid,
    this.Bankakod,
    this.Bankaisim,
    this.Hesapno,
    this.Iban,
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

  factory VwFinansbankahesaptoplamDto.fromJson(Map<String, dynamic> json) {
    double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
    return VwFinansbankahesaptoplamDto(
      Id:                 json['Id'],
      Firmaid:            json['Firmaid'],
      Sirketid:           json['Sirketid'],
      Subeid:             json['Subeid'],
      Bankaid:            json['Bankaid'],
      Bankaanaadi:        json['Bankaanaadi'],
      Bankahesapid:       json['Bankahesapid'],
      Bankakod:           json['Bankakod'],
      Bankaisim:          json['Bankaisim'],
      Hesapno:            json['Hesapno'],
      Iban:               json['Iban'],
      Dovizbirim:         json['Dovizbirim'],
      Dovizid:            json['Dovizid'],
      Borctutar:          _d(json['Borctutar']),
      Alacaktutar:        _d(json['Alacaktutar']),
      Bakiyetutar:        _d(json['Bakiyetutar']),
      Borcbakiye:         _d(json['Borcbakiye']),
      Alacakbakiye:       _d(json['Alacakbakiye']),
      Dovizborctutar:     _d(json['Dovizborctutar']),
      Dovizalacaktutar:   _d(json['Dovizalacaktutar']),
      Dovizbakiyetutar:   _d(json['Dovizbakiyetutar']),
      Borcdovizbakiye:    _d(json['Borcdovizbakiye']),
      Alacakdovizbakiye:  _d(json['Alacakdovizbakiye']),
    );
  }
}
