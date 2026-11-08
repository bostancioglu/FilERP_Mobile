import '../../base_dto.dart';

class BankaMasterDto extends BaseDto {
  final String? Ad;
  final String? Kod;

  BankaMasterDto({super.Id, this.Ad, this.Kod});

  factory BankaMasterDto.fromJson(Map<String, dynamic> json) =>
      BankaMasterDto(Id: json['Id'], Ad: json['Ad'], Kod: json['Kod']);
}

class BankasubeMasterDto extends BaseDto {
  final String? Ad;
  final String? Kod;
  final String? Swiftkodu;
  final int?    Bankaid;

  BankasubeMasterDto({super.Id, this.Ad, this.Kod, this.Swiftkodu, this.Bankaid});

  factory BankasubeMasterDto.fromJson(Map<String, dynamic> json) =>
      BankasubeMasterDto(
        Id:         json['Id'],
        Ad:         json['Ad'],
        Kod:        json['Kod'],
        Swiftkodu:  json['Swiftkodu'],
        Bankaid:    json['Bankaid'],
      );
}
