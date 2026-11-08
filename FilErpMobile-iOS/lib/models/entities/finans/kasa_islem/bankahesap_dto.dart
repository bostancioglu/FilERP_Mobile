import '../../../base_dto.dart';

class BankahesapDto extends BaseDto {
  final int? Firmaid;
  final int? Sirketid;
  final int? Subeid;
  final int? Dovizid;
  final int? Bankaid;
  final String? Ad;
  final String? Kod;
  final String? Hesapno;
  final String? Iban;

  BankahesapDto({
    super.Id,
    this.Firmaid,
    this.Sirketid,
    this.Subeid,
    this.Dovizid,
    this.Bankaid,
    this.Ad,
    this.Kod,
    this.Hesapno,
    this.Iban,
  });

  factory BankahesapDto.fromJson(Map<String, dynamic> json) {
    return BankahesapDto(
      Id: json['Id'],
      Firmaid: json['Firmaid'],
      Sirketid: json['Sirketid'],
      Subeid: json['Subeid'],
      Dovizid: json['Dovizid'],
      Bankaid: json['Bankaid'],
      Ad: json['Ad'],
      Kod: json['Kod'],
      Hesapno: json['Hesapno'],
      Iban: json['Iban'],
    );
  }
}
