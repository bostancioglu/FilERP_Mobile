class StokkategoriDto {
  int? Id;
  String? Ad;
  String? Kod;

  StokkategoriDto({this.Id, this.Ad, this.Kod});

  factory StokkategoriDto.fromJson(Map<String, dynamic> json) {
    return StokkategoriDto(
      Id: json['Id'],
      Ad: json['Ad'],
      Kod: json['Kod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': Id,
      'Ad': Ad,
      'Kod': Kod,
    };
  }
}
