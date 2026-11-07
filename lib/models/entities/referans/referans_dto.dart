class ReferansDto {
  final int? Id;
  int? Firmaid;
  int? Sirketid;
  String? Kod;
  String? Ad;
  int? Gidertipi;
  String? Giderkodu;
  bool? Ortakkoduvar;
  String? Ortakkod;

  ReferansDto({
    this.Id,
    this.Firmaid,
    this.Sirketid,
    this.Kod,
    this.Ad,
    this.Gidertipi,
    this.Giderkodu,
    this.Ortakkoduvar,
    this.Ortakkod,
  });

  factory ReferansDto.fromJson(Map<String, dynamic> json) {
    return ReferansDto(
      Id:           json['Id'],
      Firmaid:      json['Firmaid'],
      Sirketid:     json['Sirketid'],
      Kod:          json['Kod'],
      Ad:           json['Ad'],
      Gidertipi:    json['Gidertipi'],
      Giderkodu:    json['Giderkodu'],
      Ortakkoduvar: json['Ortakkoduvar'],
      Ortakkod:     json['Ortakkod'],
    );
  }
}