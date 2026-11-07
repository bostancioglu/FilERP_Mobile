import '../../../base_dto.dart';

class KredikartisozlesmeDto extends BaseDto {
  final int?    Bankahesapid;
  final String? Sozlesmeno;
  final String? Aciklama;
  final int?    Baslangictaksit;
  final int?    Bitistaksit;

  final String? BankahesapAd;
  final String? BankaAd;
  final String? BankaKod;

  KredikartisozlesmeDto({
    super.Id,
    this.Bankahesapid,
    this.Sozlesmeno,
    this.Aciklama,
    this.Baslangictaksit,
    this.Bitistaksit,
    this.BankahesapAd,
    this.BankaAd,
    this.BankaKod,
  });

  factory KredikartisozlesmeDto.fromJson(Map<String, dynamic> json) {
    final bankahesap = json['Bankahesap'] as Map<String, dynamic>?;
    final banka       = bankahesap?['Banka'] as Map<String, dynamic>?;
    return KredikartisozlesmeDto(
      Id:              json['Id'],
      Bankahesapid:    json['Bankahesapid'],
      Sozlesmeno:      json['Sozlesmeno'],
      Aciklama:        json['Aciklama'],
      Baslangictaksit: json['Baslangictaksit'],
      Bitistaksit:     json['Bitistaksit'],
      BankahesapAd:    bankahesap?['Ad'],
      BankaAd:         banka?['Ad'],
      BankaKod:        banka?['Kod'],
    );
  }
}
