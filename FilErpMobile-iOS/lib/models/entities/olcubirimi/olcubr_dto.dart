class OlcubrDto {
  int? Id;
  String? Ad;
  String? Kod;
  String? Aciklama;
  int? Sira;
  int? Tip;
  int? Firmaid;

  OlcubrDto({
    this.Id,
    this.Ad,
    this.Kod,
    this.Aciklama,
    this.Sira,
    this.Tip,
    this.Firmaid,
  });

  factory OlcubrDto.fromJson(Map<String, dynamic> json) {
    return OlcubrDto(
      Id: json['Id'],
      Ad: json['Ad'],
      Kod: json['Kod'],
      Aciklama: json['Aciklama'],
      Sira: json['Sira'],
      Tip: json['Tip'],
      Firmaid: json['Firmaid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': Id,
      'Ad': Ad,
      'Kod': Kod,
      'Aciklama': Aciklama,
      'Sira': Sira,
      'Tip': Tip,
      'Firmaid': Firmaid,
    };
  }
}
